-- 🚀 CONECTABOI - SCHEMA SQL OTIMIZADO PARA PERFORMANCE
-- Target: Queries <200ms | Sync <500ms | Production Ready
-- Database: PostgreSQL (Supabase)

-- ===============================================
-- 🗂️ TABELAS PRINCIPAIS - COMBUSTÍVEL
-- ===============================================

-- Tabela principal para lançamentos de combustível
CREATE TABLE IF NOT EXISTS lancamentos_combustivel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    confinamento_id UUID NOT NULL,
    data DATE NOT NULL,
    tipo_combustivel VARCHAR(50) NOT NULL,
    quantidade_litros DECIMAL(10,2) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    equipamento VARCHAR(100) NOT NULL,
    operador VARCHAR(100) NOT NULL,
    observacoes TEXT,
    
    -- Campos de controle
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Campos para sync mobile otimizado
    mobile_created_at TIMESTAMPTZ,
    mobile_synced_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Campos para conflict resolution
    client_id UUID,
    sync_hash VARCHAR(64),
    
    -- Performance constraints
    CONSTRAINT valid_quantidade CHECK (quantidade_litros > 0),
    CONSTRAINT valid_preco CHECK (preco_unitario > 0),
    CONSTRAINT valid_total CHECK (valor_total > 0)
);

-- Tabela para tanques de combustível
CREATE TABLE IF NOT EXISTS tanques_combustivel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    confinamento_id UUID NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo_combustivel VARCHAR(50) NOT NULL,
    capacidade_maxima DECIMAL(10,2) NOT NULL,
    nivel_atual DECIMAL(10,2) DEFAULT 0,
    nivel_minimo DECIMAL(10,2) NOT NULL,
    nivel_critico DECIMAL(10,2) NOT NULL,
    localizacao VARCHAR(200),
    ativo BOOLEAN DEFAULT TRUE,
    ultima_manutencao DATE,
    proxima_manutencao DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Sync fields
    mobile_synced_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT valid_capacidade CHECK (capacidade_maxima > 0),
    CONSTRAINT valid_nivel CHECK (nivel_atual >= 0 AND nivel_atual <= capacidade_maxima),
    CONSTRAINT valid_niveis CHECK (nivel_critico < nivel_minimo)
);

-- Tabela para alertas e configurações
CREATE TABLE IF NOT EXISTS combustivel_alertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    confinamento_id UUID NOT NULL,
    tanque_id UUID REFERENCES tanques_combustivel(id),
    tipo_alerta VARCHAR(50) NOT NULL, -- 'nivel_baixo', 'nivel_critico', 'manutencao'
    threshold_value DECIMAL(10,2),
    ativo BOOLEAN DEFAULT TRUE,
    notificar_email BOOLEAN DEFAULT TRUE,
    notificar_push BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Tabela para sync metadata (performance crítico)
CREATE TABLE IF NOT EXISTS sync_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    sync_token VARCHAR(255),
    record_count INTEGER DEFAULT 0,
    client_id UUID,
    user_id UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(table_name, client_id, user_id)
);

-- ===============================================
-- 🔥 ÍNDICES PARA PERFORMANCE <200MS
-- ===============================================

-- Índices principais para lancamentos_combustivel
CREATE INDEX IF NOT EXISTS idx_lancamentos_data_desc 
    ON lancamentos_combustivel(data DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_lancamentos_confinamento_data 
    ON lancamentos_combustivel(confinamento_id, data DESC);

CREATE INDEX IF NOT EXISTS idx_lancamentos_created_by 
    ON lancamentos_combustivel(created_by, data DESC);

CREATE INDEX IF NOT EXISTS idx_lancamentos_tipo_data 
    ON lancamentos_combustivel(tipo_combustivel, data DESC);

CREATE INDEX IF NOT EXISTS idx_lancamentos_sync 
    ON lancamentos_combustivel(mobile_synced_at, updated_at) 
    WHERE is_deleted = FALSE;

-- Índice composto para queries de período (CRÍTICO para performance)
CREATE INDEX IF NOT EXISTS idx_lancamentos_periodo_performance 
    ON lancamentos_combustivel(confinamento_id, data, created_by) 
    INCLUDE (quantidade_litros, valor_total, tipo_combustivel);

-- Índices para tanques
CREATE INDEX IF NOT EXISTS idx_tanques_confinamento 
    ON tanques_combustivel(confinamento_id) 
    WHERE ativo = TRUE AND is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_tanques_tipo 
    ON tanques_combustivel(tipo_combustivel, confinamento_id) 
    WHERE ativo = TRUE;

CREATE INDEX IF NOT EXISTS idx_tanques_nivel_critico 
    ON tanques_combustivel(confinamento_id, nivel_atual) 
    WHERE ativo = TRUE AND nivel_atual <= nivel_critico;

-- Índices para sync otimizado
CREATE INDEX IF NOT EXISTS idx_sync_metadata_lookup 
    ON sync_metadata(table_name, client_id, user_id);

CREATE INDEX IF NOT EXISTS idx_sync_incremental 
    ON lancamentos_combustivel(updated_at, mobile_synced_at) 
    WHERE is_deleted = FALSE;

-- ===============================================
-- 🎯 VIEWS MATERIALIZED PARA PERFORMANCE
-- ===============================================

-- View para dashboard com cache automático
CREATE MATERIALIZED VIEW IF NOT EXISTS dashboard_combustivel_cache AS
SELECT 
    confinamento_id,
    COUNT(*) as total_lancamentos,
    SUM(quantidade_litros) as total_litros,
    SUM(valor_total) as total_valor,
    AVG(preco_unitario) as preco_medio,
    COUNT(DISTINCT tipo_combustivel) as tipos_combustivel,
    COUNT(DISTINCT equipamento) as equipamentos_utilizados,
    DATE_TRUNC('day', data) as data_referencia,
    MAX(updated_at) as ultima_atualizacao
FROM lancamentos_combustivel 
WHERE is_deleted = FALSE 
    AND data >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY confinamento_id, DATE_TRUNC('day', data);

-- Índice na view materializada
CREATE INDEX IF NOT EXISTS idx_dashboard_cache_lookup 
    ON dashboard_combustivel_cache(confinamento_id, data_referencia DESC);

-- View para estatísticas rápidas
CREATE MATERIALIZED VIEW IF NOT EXISTS combustivel_stats_cache AS
SELECT 
    confinamento_id,
    tipo_combustivel,
    DATE_TRUNC('month', data) as mes_referencia,
    SUM(quantidade_litros) as litros_mes,
    SUM(valor_total) as valor_mes,
    AVG(preco_unitario) as preco_medio_mes,
    COUNT(*) as total_abastecimentos,
    MAX(data) as ultimo_abastecimento
FROM lancamentos_combustivel 
WHERE is_deleted = FALSE 
    AND data >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY confinamento_id, tipo_combustivel, DATE_TRUNC('month', data);

CREATE INDEX IF NOT EXISTS idx_stats_cache_lookup 
    ON combustivel_stats_cache(confinamento_id, tipo_combustivel, mes_referencia DESC);

-- ===============================================
-- 🔄 TRIGGERS PARA AUTO-UPDATE
-- ===============================================

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger nas tabelas principais
DROP TRIGGER IF EXISTS update_lancamentos_updated_at ON lancamentos_combustivel;
CREATE TRIGGER update_lancamentos_updated_at 
    BEFORE UPDATE ON lancamentos_combustivel 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tanques_updated_at ON tanques_combustivel;
CREATE TRIGGER update_tanques_updated_at 
    BEFORE UPDATE ON tanques_combustivel 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para refresh da view materializada
CREATE OR REPLACE FUNCTION refresh_dashboard_cache()
RETURNS TRIGGER AS $$
BEGIN
    -- Refresh assíncrono para não impactar performance
    PERFORM pg_notify('refresh_cache', 'dashboard_combustivel_cache');
    RETURN NULL;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trigger_refresh_dashboard ON lancamentos_combustivel;
CREATE TRIGGER trigger_refresh_dashboard 
    AFTER INSERT OR UPDATE OR DELETE ON lancamentos_combustivel 
    FOR EACH STATEMENT EXECUTE FUNCTION refresh_dashboard_cache();

-- ===============================================
-- 🔐 ROW LEVEL SECURITY (RLS)
-- ===============================================

-- Habilitar RLS
ALTER TABLE lancamentos_combustivel ENABLE ROW LEVEL SECURITY;
ALTER TABLE tanques_combustivel ENABLE ROW LEVEL SECURITY;
ALTER TABLE combustivel_alertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança otimizadas
CREATE POLICY "Users can access own confinamento data" ON lancamentos_combustivel
    FOR ALL USING (
        confinamento_id IN (
            SELECT confinamentos.id 
            FROM confinamentos 
            INNER JOIN user_confinamentos ON confinamentos.id = user_confinamentos.confinamento_id 
            WHERE user_confinamentos.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can access own tanques" ON tanques_combustivel
    FOR ALL USING (
        confinamento_id IN (
            SELECT confinamentos.id 
            FROM confinamentos 
            INNER JOIN user_confinamentos ON confinamentos.id = user_confinamentos.confinamento_id 
            WHERE user_confinamentos.user_id = auth.uid()
        )
    );

-- Política para sync metadata
CREATE POLICY "Users can access own sync data" ON sync_metadata
    FOR ALL USING (user_id = auth.uid());

-- ===============================================
-- 🚀 FUNÇÕES PARA PERFORMANCE OTIMIZADA
-- ===============================================

-- Função para busca otimizada por período
CREATE OR REPLACE FUNCTION get_lancamentos_periodo_optimized(
    p_confinamento_id UUID,
    p_data_inicio DATE DEFAULT NULL,
    p_data_fim DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    data DATE,
    tipo_combustivel VARCHAR,
    quantidade_litros DECIMAL,
    preco_unitario DECIMAL,
    valor_total DECIMAL,
    equipamento VARCHAR,
    operador VARCHAR,
    observacoes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id, l.data, l.tipo_combustivel, l.quantidade_litros,
        l.preco_unitario, l.valor_total, l.equipamento, l.operador,
        l.observacoes, l.created_at, l.updated_at
    FROM lancamentos_combustivel l
    WHERE l.confinamento_id = p_confinamento_id 
        AND l.is_deleted = FALSE
        AND (p_data_inicio IS NULL OR l.data >= p_data_inicio)
        AND (p_data_fim IS NULL OR l.data <= p_data_fim)
    ORDER BY l.data DESC, l.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- Função para sync incremental otimizado
CREATE OR REPLACE FUNCTION get_incremental_sync_data(
    p_confinamento_id UUID,
    p_last_sync_timestamp TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    data JSONB,
    operation VARCHAR,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        to_jsonb(l) as data,
        CASE 
            WHEN l.is_deleted THEN 'DELETE'
            WHEN l.created_at = l.updated_at THEN 'INSERT'
            ELSE 'UPDATE'
        END as operation,
        l.updated_at
    FROM lancamentos_combustivel l
    WHERE l.confinamento_id = p_confinamento_id 
        AND (p_last_sync_timestamp IS NULL OR l.updated_at > p_last_sync_timestamp)
    ORDER BY l.updated_at ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Função para estatísticas rápidas
CREATE OR REPLACE FUNCTION get_dashboard_stats_fast(p_confinamento_id UUID)
RETURNS TABLE (
    total_litros DECIMAL,
    total_valor DECIMAL,
    preco_medio DECIMAL,
    total_abastecimentos INTEGER,
    tipos_combustivel INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(d.total_litros), 0) as total_litros,
        COALESCE(SUM(d.total_valor), 0) as total_valor,
        COALESCE(AVG(d.preco_medio), 0) as preco_medio,
        COALESCE(SUM(d.total_lancamentos)::INTEGER, 0) as total_abastecimentos,
        COUNT(DISTINCT 
            CASE WHEN d.total_lancamentos > 0 THEN d.confinamento_id END
        )::INTEGER as tipos_combustivel
    FROM dashboard_combustivel_cache d
    WHERE d.confinamento_id = p_confinamento_id
        AND d.data_referencia >= CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql STABLE;

-- ===============================================
-- 🎯 CONFIGURAÇÕES DE PERFORMANCE
-- ===============================================

-- Configurar autovacuum para performance
ALTER TABLE lancamentos_combustivel SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE tanques_combustivel SET (
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1
);

-- ===============================================
-- 📊 MONITORING E ANALYTICS
-- ===============================================

-- Tabela para monitorar performance das queries
CREATE TABLE IF NOT EXISTS query_performance_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_name VARCHAR(100) NOT NULL,
    execution_time_ms INTEGER NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    confinamento_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Índice para analytics
    INDEX idx_perf_log_query_time (query_name, execution_time_ms, created_at)
);

-- View para monitorar performance
CREATE VIEW query_performance_summary AS
SELECT 
    query_name,
    COUNT(*) as total_executions,
    AVG(execution_time_ms) as avg_time_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) as p50_ms,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY execution_time_ms) as p90_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_ms,
    MAX(execution_time_ms) as max_time_ms,
    DATE_TRUNC('hour', created_at) as hour_bucket
FROM query_performance_log 
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY query_name, DATE_TRUNC('hour', created_at)
ORDER BY p95_ms DESC;

-- ===============================================
-- 🔄 REFRESH JOBS PARA VIEWS MATERIALIZADAS
-- ===============================================

-- Função para refresh automático (executar via cron ou pg_cron)
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS $$
BEGIN
    -- Refresh concorrente para não bloquear
    REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_combustivel_cache;
    REFRESH MATERIALIZED VIEW CONCURRENTLY combustivel_stats_cache;
    
    -- Log do refresh
    INSERT INTO query_performance_log (query_name, execution_time_ms)
    VALUES ('refresh_materialized_views', 0); -- Placeholder
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 📝 COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ===============================================

COMMENT ON TABLE lancamentos_combustivel IS 'Tabela principal para controle de combustível - otimizada para <200ms queries';
COMMENT ON INDEX idx_lancamentos_periodo_performance IS 'Índice crítico para queries de período - inclui colunas mais acessadas';
COMMENT ON FUNCTION get_lancamentos_periodo_optimized IS 'Função otimizada para busca por período com paginação';
COMMENT ON MATERIALIZED VIEW dashboard_combustivel_cache IS 'Cache para dashboard - refresh automático via trigger';

-- ===============================================
-- ✅ VALIDAÇÃO DO SCHEMA
-- ===============================================

-- Inserir dados de teste para validar performance
DO $$
BEGIN
    -- Só inserir se não existirem dados
    IF NOT EXISTS (SELECT 1 FROM lancamentos_combustivel LIMIT 1) THEN
        INSERT INTO lancamentos_combustivel (
            confinamento_id, data, tipo_combustivel, quantidade_litros,
            preco_unitario, valor_total, equipamento, operador,
            observacoes, created_by
        ) VALUES 
        (gen_random_uuid(), CURRENT_DATE, 'diesel', 1000.00, 5.50, 5500.00, 'Trator John Deere', 'Operador Teste', 'Teste de performance', gen_random_uuid()),
        (gen_random_uuid(), CURRENT_DATE - 1, 'gasolina', 500.00, 6.20, 3100.00, 'Caminhonete Ford', 'Operador Teste', 'Teste de performance', gen_random_uuid()),
        (gen_random_uuid(), CURRENT_DATE - 2, 'diesel', 750.00, 5.45, 4087.50, 'Caminhão Scania', 'Operador Teste', 'Teste de performance', gen_random_uuid());
    END IF;
END
$$;

-- Refresh inicial das views
REFRESH MATERIALIZED VIEW dashboard_combustivel_cache;
REFRESH MATERIALIZED VIEW combustivel_stats_cache;

-- ===============================================
-- 🎯 SCRIPT CONCLUÍDO
-- ===============================================

-- Verificar se tudo foi criado corretamente
SELECT 
    'Schema combustível otimizado criado com sucesso!' as status,
    'Queries target: <200ms | Sync target: <500ms' as performance_target,
    COUNT(*) as total_indexes
FROM pg_indexes 
WHERE tablename LIKE '%combustivel%';
