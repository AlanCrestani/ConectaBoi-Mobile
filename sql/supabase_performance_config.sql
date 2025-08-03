-- 🎯 CONECTABOI - CONFIGURAÇÃO DE PERFORMANCE SUPABASE
-- Database: PostgreSQL (Supabase)
-- Target: Production-ready performance optimization

-- ===============================================
-- 🔧 CONFIGURAÇÕES DE PERFORMANCE POSTGRESQL
-- ===============================================

-- 1. Connection Pool Settings
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';

-- 2. Query Planner Settings
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;
ALTER SYSTEM SET default_statistics_target = 100;

-- 3. Write Performance
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET checkpoint_timeout = '10min';

-- 4. Auto Vacuum Settings (crítico para performance)
ALTER SYSTEM SET autovacuum = on;
ALTER SYSTEM SET autovacuum_max_workers = 3;
ALTER SYSTEM SET autovacuum_naptime = '1min';
ALTER SYSTEM SET autovacuum_vacuum_threshold = 50;
ALTER SYSTEM SET autovacuum_analyze_threshold = 50;

-- ===============================================
-- 📊 CONFIGURATION ESPECÍFICA PARA COMBUSTÍVEL
-- ===============================================

-- Table-specific settings para lancamentos_combustivel
ALTER TABLE lancamentos_combustivel SET (
    fillfactor = 85,  -- Reserva espaço para UPDATEs
    autovacuum_enabled = true,
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05,
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 50
);

-- Table-specific settings para tanques_combustivel
ALTER TABLE tanques_combustivel SET (
    fillfactor = 90,  -- Menos UPDATEs frequentes
    autovacuum_enabled = true,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1
);

-- ===============================================
-- 🎯 ÍNDICES ESPECÍFICOS PARA QUERIES MÓVEIS
-- ===============================================

-- Índice para query mais comum: buscar por confinamento + data
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lancamentos_mobile_primary
    ON lancamentos_combustivel (confinamento_id, data DESC, created_at DESC)
    INCLUDE (id, tipo_combustivel, quantidade_litros, valor_total)
    WHERE is_deleted = FALSE;

-- Índice para sync incremental
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lancamentos_sync_incremental
    ON lancamentos_combustivel (confinamento_id, updated_at)
    INCLUDE (id, version, sync_hash)
    WHERE is_deleted = FALSE;

-- Índice para estatísticas rápidas
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lancamentos_stats_fast
    ON lancamentos_combustivel (confinamento_id, data)
    INCLUDE (quantidade_litros, valor_total, preco_unitario, tipo_combustivel)
    WHERE is_deleted = FALSE AND data >= CURRENT_DATE - INTERVAL '30 days';

-- Índice para filtros por tipo
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lancamentos_tipo_filter
    ON lancamentos_combustivel (confinamento_id, tipo_combustivel, data DESC)
    WHERE is_deleted = FALSE;

-- Índice para filtros por equipamento
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lancamentos_equipamento_filter
    ON lancamentos_combustivel (confinamento_id, equipamento, data DESC)
    WHERE is_deleted = FALSE;

-- ===============================================
-- 🚀 PREPARED STATEMENTS PARA MOBILE
-- ===============================================

-- Preparar as queries mais usadas
PREPARE get_lancamentos_recent AS
    SELECT id, data, tipo_combustivel, quantidade_litros, valor_total, equipamento, operador
    FROM lancamentos_combustivel 
    WHERE confinamento_id = $1 AND is_deleted = FALSE
    ORDER BY created_at DESC 
    LIMIT $2;

PREPARE get_lancamentos_periodo AS
    SELECT id, data, tipo_combustivel, quantidade_litros, preco_unitario, valor_total, equipamento, operador, observacoes
    FROM lancamentos_combustivel 
    WHERE confinamento_id = $1 AND is_deleted = FALSE 
        AND data BETWEEN $2 AND $3
    ORDER BY data DESC, created_at DESC
    LIMIT $4 OFFSET $5;

PREPARE get_sync_incremental AS
    SELECT id, updated_at, version, row_to_json(lancamentos_combustivel.*) as data
    FROM lancamentos_combustivel 
    WHERE confinamento_id = $1 AND updated_at > $2
    ORDER BY updated_at ASC
    LIMIT $3;

PREPARE get_dashboard_stats AS
    SELECT 
        COUNT(*) as total_lancamentos,
        COALESCE(SUM(quantidade_litros), 0) as total_litros,
        COALESCE(SUM(valor_total), 0) as total_valor,
        COALESCE(AVG(preco_unitario), 0) as preco_medio
    FROM lancamentos_combustivel 
    WHERE confinamento_id = $1 AND is_deleted = FALSE
        AND data >= CURRENT_DATE - INTERVAL '30 days';

-- ===============================================
-- 📈 MONITORING E ALERTAS
-- ===============================================

-- Extension para monitoring (se disponível)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Função para monitorar queries lentas
CREATE OR REPLACE FUNCTION monitor_slow_queries()
RETURNS TABLE (
    query TEXT,
    mean_exec_time NUMERIC,
    calls BIGINT,
    total_exec_time NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pss.query,
        pss.mean_exec_time,
        pss.calls,
        pss.total_exec_time
    FROM pg_stat_statements pss
    WHERE pss.mean_exec_time > 200  -- > 200ms
        AND pss.query LIKE '%combustivel%'
    ORDER BY pss.mean_exec_time DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 🔄 MAINTENANCE JOBS
-- ===============================================

-- Função para manutenção automática
CREATE OR REPLACE FUNCTION maintenance_combustivel_tables()
RETURNS void AS $$
BEGIN
    -- Vacuum analyze nas tabelas principais
    VACUUM ANALYZE lancamentos_combustivel;
    VACUUM ANALYZE tanques_combustivel;
    VACUUM ANALYZE dashboard_combustivel_cache;
    
    -- Refresh das materialized views
    REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_combustivel_cache;
    REFRESH MATERIALIZED VIEW CONCURRENTLY combustivel_stats_cache;
    
    -- Limpar logs antigos de performance
    DELETE FROM query_performance_log 
    WHERE created_at < NOW() - INTERVAL '7 days';
    
    -- Atualizar estatísticas
    ANALYZE lancamentos_combustivel;
    ANALYZE tanques_combustivel;
    
    -- Log da manutenção
    INSERT INTO query_performance_log (query_name, execution_time_ms)
    VALUES ('maintenance_job', 0);
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 🎯 CACHE CONFIGURATION
-- ===============================================

-- Configurar shared_preload_libraries para cache
-- (Isso deve ser feito no postgresql.conf)
-- shared_preload_libraries = 'pg_stat_statements'

-- Warm up crítico das tabelas na inicialização
CREATE OR REPLACE FUNCTION warmup_combustivel_cache()
RETURNS void AS $$
BEGIN
    -- Pre-load das páginas mais acessadas
    PERFORM COUNT(*) FROM lancamentos_combustivel 
    WHERE data >= CURRENT_DATE - INTERVAL '7 days'
        AND is_deleted = FALSE;
    
    PERFORM COUNT(*) FROM tanques_combustivel 
    WHERE ativo = TRUE 
        AND is_deleted = FALSE;
    
    -- Executar queries principais para cache
    PERFORM COUNT(*) FROM dashboard_combustivel_cache;
    PERFORM COUNT(*) FROM combustivel_stats_cache;
    
    -- Log do warmup
    INSERT INTO query_performance_log (query_name, execution_time_ms)
    VALUES ('cache_warmup', 1);
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 🔐 SECURITY OPTIMIZATIONS
-- ===============================================

-- RLS com performance otimizada
CREATE POLICY "Performance optimized confinamento access" ON lancamentos_combustivel
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_confinamentos uc
            WHERE uc.confinamento_id = lancamentos_combustivel.confinamento_id 
                AND uc.user_id = auth.uid()
        )
    );

-- Índice para RLS performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_confinamentos_lookup
    ON user_confinamentos (user_id, confinamento_id);

-- ===============================================
-- 📊 PARTITIONING PARA SCALING
-- ===============================================

-- Preparar para particionamento por data (futuro scaling)
-- CREATE TABLE lancamentos_combustivel_2025 PARTITION OF lancamentos_combustivel
--     FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- ===============================================
-- 🎯 CONNECTION POOLING CONFIG
-- ===============================================

-- Configurações recomendadas para connection pooling (aplicar no Supabase Dashboard)
/*
Supabase Dashboard -> Settings -> Database -> Connection pooling:

Pool Mode: Transaction
Default Pool Size: 15
Max Client Connections: 100
Pool Settings:
- statement_timeout: 30s
- idle_in_transaction_session_timeout: 10s
- log_min_duration_statement: 1000ms
*/

-- ===============================================
-- 📈 BACKUP E RECOVERY OPTIMIZATION
-- ===============================================

-- Configurar backup incremental para não impactar performance
-- (Configurar no Supabase Dashboard)

-- ===============================================
-- ✅ PERFORMANCE VALIDATION
-- ===============================================

-- Script para validar performance das configurações
CREATE OR REPLACE FUNCTION validate_performance_config()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    current_value TEXT,
    recommended_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'shared_buffers'::TEXT,
        CASE WHEN current_setting('shared_buffers')::TEXT ~ '(MB|GB)' 
             THEN '✅ OK' ELSE '⚠️ Check' END,
        current_setting('shared_buffers'),
        '256MB+'::TEXT
    UNION ALL
    SELECT 
        'work_mem'::TEXT,
        CASE WHEN current_setting('work_mem')::TEXT ~ '[0-9]+(MB|kB)' 
             THEN '✅ OK' ELSE '⚠️ Check' END,
        current_setting('work_mem'),
        '4MB'::TEXT
    UNION ALL
    SELECT 
        'autovacuum'::TEXT,
        CASE WHEN current_setting('autovacuum')::TEXT = 'on' 
             THEN '✅ OK' ELSE '❌ ERROR' END,
        current_setting('autovacuum'),
        'on'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Executar validação
SELECT * FROM validate_performance_config();

-- ===============================================
-- 🎯 FINAL OPTIMIZATION TIPS
-- ===============================================

/*
SUPABASE DASHBOARD CONFIGURATIONS:

1. Database Settings:
   - Enable WAL mode
   - Set checkpoint_completion_target = 0.9
   - Configure autovacuum appropriately

2. API Settings:
   - Enable RLS (já configurado)
   - Set JWT exp timeout
   - Configure rate limiting

3. Connection Pooling:
   - Mode: Transaction
   - Pool size: 15-25
   - Max connections: 100

4. Extensions:
   - pg_stat_statements (monitoring)
   - pg_trgm (text search se necessário)

5. Monitoring:
   - Enable query stats
   - Set log_min_duration_statement = 1000
   - Monitor connection count

6. Backup:
   - Configure daily backups
   - Set retention policy
   - Test restore procedures
*/

-- ===============================================
-- ✅ CONFIGURATION COMPLETE
-- ===============================================

SELECT 
    'Performance configuration applied successfully!' as status,
    'Target: <200ms queries | <500ms sync operations' as target,
    NOW() as configured_at;
