-- 🚀 CONECTABOI - QUERIES OTIMIZADAS PARA MOBILE SYNC
-- Target: <200ms execution | <500ms sync operations
-- Uso: Integration com Flutter SyncService

-- ===============================================
-- 📱 QUERIES CORE MOBILE - PERFORMANCE CRITICAL
-- ===============================================

-- 1. BUSCAR LANÇAMENTOS COM PAGINAÇÃO (mais usado)
-- Target: <150ms
-- Cache: 5 min
SELECT 
    id, confinamento_id, data, tipo_combustivel,
    quantidade_litros, preco_unitario, valor_total,
    equipamento, operador, observacoes,
    created_at, updated_at, mobile_synced_at, version
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND ($2::DATE IS NULL OR data >= $2)
    AND ($3::DATE IS NULL OR data <= $3)
ORDER BY data DESC, created_at DESC
LIMIT $4 OFFSET $5;

-- 2. SYNC INCREMENTAL (crítico para performance)
-- Target: <100ms
-- Usado a cada sync automático
SELECT 
    id, 
    CASE 
        WHEN is_deleted THEN 'DELETE'
        WHEN created_at = updated_at THEN 'INSERT'
        ELSE 'UPDATE'
    END as operation,
    row_to_json(lancamentos_combustivel.*) as data,
    updated_at,
    version,
    sync_hash
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND updated_at > $2::TIMESTAMPTZ
ORDER BY updated_at ASC
LIMIT $3;

-- 3. DASHBOARD STATS RÁPIDO
-- Target: <50ms
-- Cache: 2 min
SELECT 
    COUNT(*) as total_lancamentos,
    COALESCE(SUM(quantidade_litros), 0) as total_litros,
    COALESCE(SUM(valor_total), 0) as total_valor,
    COALESCE(AVG(preco_unitario), 0) as preco_medio,
    COUNT(DISTINCT tipo_combustivel) as tipos_diferentes,
    MAX(data) as ultimo_lancamento
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND data >= CURRENT_DATE - INTERVAL '30 days';

-- 4. ESTATÍSTICAS POR PERÍODO
-- Target: <200ms
-- Cache: 10 min
SELECT 
    tipo_combustivel,
    SUM(quantidade_litros) as total_litros,
    SUM(valor_total) as total_valor,
    AVG(preco_unitario) as preco_medio,
    COUNT(*) as total_abastecimentos,
    MIN(data) as primeira_data,
    MAX(data) as ultima_data
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND data BETWEEN $2::DATE AND $3::DATE
GROUP BY tipo_combustivel
ORDER BY total_valor DESC;

-- 5. ÚLTIMOS LANÇAMENTOS (tela inicial)
-- Target: <100ms
-- Cache: 1 min
SELECT 
    id, data, tipo_combustivel, quantidade_litros,
    valor_total, equipamento, operador,
    created_at
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
ORDER BY created_at DESC
LIMIT $2;

-- ===============================================
-- 🔄 QUERIES PARA CONFLICT RESOLUTION
-- ===============================================

-- 6. VERIFICAR CONFLITOS POR HASH
-- Target: <50ms
SELECT 
    id, sync_hash, version, updated_at,
    client_id, mobile_synced_at
FROM lancamentos_combustivel 
WHERE id = $1 
    AND sync_hash != $2;

-- 7. RESOLVER CONFLITO POR TIMESTAMP
-- Target: <100ms
SELECT 
    id, updated_at, version,
    row_to_json(lancamentos_combustivel.*) as local_data
FROM lancamentos_combustivel 
WHERE id = $1
    AND updated_at > $2::TIMESTAMPTZ;

-- ===============================================
-- 📊 QUERIES PARA ANALYTICS E RELATÓRIOS
-- ===============================================

-- 8. CONSUMO POR DIA (gráficos)
-- Target: <300ms
-- Cache: 30 min
SELECT 
    data,
    SUM(quantidade_litros) as litros_dia,
    SUM(valor_total) as valor_dia,
    COUNT(*) as abastecimentos_dia
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND data >= $2::DATE 
    AND data <= $3::DATE
GROUP BY data
ORDER BY data;

-- 9. TOP EQUIPAMENTOS (analytics)
-- Target: <200ms
-- Cache: 1 hora
SELECT 
    equipamento,
    SUM(quantidade_litros) as total_litros,
    SUM(valor_total) as total_valor,
    COUNT(*) as total_abastecimentos,
    AVG(quantidade_litros) as media_litros_abastecimento
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND data >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY equipamento
ORDER BY total_valor DESC
LIMIT 10;

-- 10. VARIAÇÃO DE PREÇOS (trends)
-- Target: <250ms
-- Cache: 2 horas
SELECT 
    tipo_combustivel,
    DATE_TRUNC('week', data) as semana,
    AVG(preco_unitario) as preco_medio_semana,
    MIN(preco_unitario) as preco_min_semana,
    MAX(preco_unitario) as preco_max_semana,
    COUNT(*) as abastecimentos_semana
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND data >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY tipo_combustivel, DATE_TRUNC('week', data)
ORDER BY tipo_combustivel, semana;

-- ===============================================
-- 🎯 QUERIES PARA VALIDAÇÃO E INTEGRAÇÃO
-- ===============================================

-- 11. VALIDAR LANÇAMENTO DUPLICADO
-- Target: <50ms
SELECT COUNT(*) as duplicatas
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND data = $2::DATE
    AND tipo_combustivel = $3
    AND quantidade_litros = $4
    AND equipamento = $5
    AND is_deleted = FALSE;

-- 12. BUSCAR POR FILTROS COMPLEXOS
-- Target: <300ms
SELECT 
    id, data, tipo_combustivel, quantidade_litros,
    preco_unitario, valor_total, equipamento, operador,
    created_at, updated_at
FROM lancamentos_combustivel 
WHERE confinamento_id = $1 
    AND is_deleted = FALSE
    AND ($2::VARCHAR IS NULL OR tipo_combustivel = $2)
    AND ($3::VARCHAR IS NULL OR equipamento ILIKE '%' || $3 || '%')
    AND ($4::VARCHAR IS NULL OR operador ILIKE '%' || $4 || '%')
    AND ($5::DATE IS NULL OR data >= $5)
    AND ($6::DATE IS NULL OR data <= $6)
    AND ($7::DECIMAL IS NULL OR quantidade_litros >= $7)
    AND ($8::DECIMAL IS NULL OR preco_unitario >= $8)
ORDER BY data DESC, created_at DESC
LIMIT $9 OFFSET $10;

-- ===============================================
-- 🔧 QUERIES PARA MANUTENÇÃO E MONITORING
-- ===============================================

-- 13. PERFORMANCE STATS POR QUERY
-- Target: <100ms
SELECT 
    query_name,
    COUNT(*) as executions,
    AVG(execution_time_ms) as avg_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_time,
    MAX(execution_time_ms) as max_time
FROM query_performance_log 
WHERE created_at >= NOW() - INTERVAL '1 hour'
GROUP BY query_name
ORDER BY p95_time DESC;

-- 14. SYNC STATUS SUMMARY
-- Target: <50ms
SELECT 
    table_name,
    last_sync_at,
    record_count,
    user_id,
    COUNT(*) as sync_clients
FROM sync_metadata 
WHERE user_id = $1
GROUP BY table_name, last_sync_at, record_count, user_id
ORDER BY last_sync_at DESC;

-- 15. DATABASE HEALTH CHECK
-- Target: <200ms
SELECT 
    'lancamentos_combustivel' as tabela,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN is_deleted = TRUE THEN 1 END) as registros_deletados,
    COUNT(CASE WHEN mobile_synced_at IS NULL THEN 1 END) as pendentes_sync,
    MAX(updated_at) as ultima_atualizacao
FROM lancamentos_combustivel
UNION ALL
SELECT 
    'tanques_combustivel' as tabela,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN is_deleted = TRUE THEN 1 END) as registros_deletados,
    COUNT(CASE WHEN mobile_synced_at IS NULL THEN 1 END) as pendentes_sync,
    MAX(updated_at) as ultima_atualizacao
FROM tanques_combustivel;

-- ===============================================
-- 📱 STORED PROCEDURES PARA MOBILE
-- ===============================================

-- 16. BULK INSERT OTIMIZADO (sync upload)
-- Target: <500ms para 100 registros
CREATE OR REPLACE FUNCTION bulk_insert_lancamentos(
    p_data JSONB
) RETURNS TABLE (
    inserted_count INTEGER,
    error_count INTEGER,
    execution_time_ms INTEGER
) AS $$
DECLARE
    start_time TIMESTAMPTZ;
    inserted INTEGER := 0;
    errors INTEGER := 0;
    record JSONB;
BEGIN
    start_time := clock_timestamp();
    
    -- Loop através dos registros
    FOR record IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        BEGIN
            INSERT INTO lancamentos_combustivel (
                id, confinamento_id, data, tipo_combustivel,
                quantidade_litros, preco_unitario, valor_total,
                equipamento, operador, observacoes,
                mobile_created_at, client_id, version
            ) VALUES (
                COALESCE((record->>'id')::UUID, gen_random_uuid()),
                (record->>'confinamento_id')::UUID,
                (record->>'data')::DATE,
                record->>'tipo_combustivel',
                (record->>'quantidade_litros')::DECIMAL,
                (record->>'preco_unitario')::DECIMAL,
                (record->>'valor_total')::DECIMAL,
                record->>'equipamento',
                record->>'operador',
                record->>'observacoes',
                COALESCE((record->>'mobile_created_at')::TIMESTAMPTZ, NOW()),
                (record->>'client_id')::UUID,
                COALESCE((record->>'version')::INTEGER, 1)
            ) ON CONFLICT (id) DO UPDATE SET
                updated_at = NOW(),
                version = lancamentos_combustivel.version + 1,
                mobile_synced_at = NOW();
                
            inserted := inserted + 1;
        EXCEPTION 
            WHEN OTHERS THEN
                errors := errors + 1;
                -- Log error but continue
                CONTINUE;
        END;
    END LOOP;
    
    RETURN QUERY SELECT 
        inserted,
        errors,
        EXTRACT(EPOCH FROM (clock_timestamp() - start_time) * 1000)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- 17. SMART SYNC - apenas mudanças relevantes
-- Target: <200ms
CREATE OR REPLACE FUNCTION get_smart_sync_data(
    p_confinamento_id UUID,
    p_last_sync TIMESTAMPTZ,
    p_client_id UUID
) RETURNS TABLE (
    sync_token VARCHAR,
    total_changes INTEGER,
    data JSONB
) AS $$
DECLARE
    changes_count INTEGER;
    sync_token_generated VARCHAR;
BEGIN
    -- Gerar token único para este sync
    sync_token_generated := encode(gen_random_bytes(16), 'hex');
    
    -- Contar mudanças
    SELECT COUNT(*) INTO changes_count
    FROM lancamentos_combustivel 
    WHERE confinamento_id = p_confinamento_id 
        AND updated_at > p_last_sync;
    
    -- Retornar dados se houver mudanças
    IF changes_count > 0 THEN
        RETURN QUERY
        SELECT 
            sync_token_generated,
            changes_count,
            jsonb_agg(
                jsonb_build_object(
                    'id', id,
                    'operation', CASE 
                        WHEN is_deleted THEN 'DELETE'
                        WHEN created_at = updated_at THEN 'INSERT'
                        ELSE 'UPDATE'
                    END,
                    'data', row_to_json(lancamentos_combustivel.*),
                    'timestamp', updated_at
                )
                ORDER BY updated_at
            ) as data
        FROM lancamentos_combustivel 
        WHERE confinamento_id = p_confinamento_id 
            AND updated_at > p_last_sync
        LIMIT 50; -- Limite para não sobrecarregar mobile
        
        -- Atualizar metadata do sync
        INSERT INTO sync_metadata (table_name, last_sync_at, sync_token, record_count, client_id, user_id)
        VALUES ('lancamentos_combustivel', NOW(), sync_token_generated, changes_count, p_client_id, auth.uid())
        ON CONFLICT (table_name, client_id, user_id) 
        DO UPDATE SET 
            last_sync_at = NOW(),
            sync_token = sync_token_generated,
            record_count = changes_count;
    ELSE
        -- Sem mudanças
        RETURN QUERY SELECT sync_token_generated, 0, NULL::JSONB;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 🎯 PERFORMANCE MONITORING QUERIES
-- ===============================================

-- 18. QUERY PERFORMANCE em tempo real
-- Target: <50ms
CREATE OR REPLACE FUNCTION log_query_performance(
    p_query_name VARCHAR,
    p_execution_time_ms INTEGER,
    p_confinamento_id UUID DEFAULT NULL
) RETURNS void AS $$
BEGIN
    INSERT INTO query_performance_log (
        query_name, 
        execution_time_ms, 
        user_id, 
        confinamento_id
    ) VALUES (
        p_query_name,
        p_execution_time_ms,
        auth.uid(),
        p_confinamento_id
    );
    
    -- Alert se query estiver muito lenta
    IF p_execution_time_ms > 500 THEN
        PERFORM pg_notify('slow_query_alert', 
            json_build_object(
                'query', p_query_name,
                'time', p_execution_time_ms,
                'user_id', auth.uid()
            )::text
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 📈 CACHE WARMING QUERIES
-- ===============================================

-- 19. WARM UP CACHE - executar periodicamente
-- Target: <1000ms total
SELECT pg_prewarm('lancamentos_combustivel');
SELECT pg_prewarm('dashboard_combustivel_cache');
SELECT pg_prewarm('combustivel_stats_cache');

-- 20. ANALYZE TABLES - manter estatísticas atualizadas
ANALYZE lancamentos_combustivel;
ANALYZE tanques_combustivel;
ANALYZE dashboard_combustivel_cache;

-- ===============================================
-- ✅ VALIDATION QUERIES
-- ===============================================

-- Verificar performance dos índices
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    CASE WHEN idx_tup_read > 0 
         THEN round((idx_tup_fetch::decimal / idx_tup_read * 100), 2) 
         ELSE 0 
    END as hit_ratio
FROM pg_stat_user_indexes 
WHERE tablename LIKE '%combustivel%'
ORDER BY hit_ratio DESC;

-- Verificar tamanho das tabelas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE tablename LIKE '%combustivel%'
ORDER BY size_bytes DESC;
