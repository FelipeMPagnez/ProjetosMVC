-- Relatorio de compras
CREATE OR ALTER PROCEDURE dbo.usp_RelatorioCompras
    @Data           DATE =NULL,
    @FornecedorId   INT = NULL,
    @DataInicio     DATE = NULL,
    @DataFim        DATE = NULL,
    @NumeroNFe      NVARCHAR(9) = NULL,
    @CodigoProduto  NVARCHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validações básicas
    IF @Data IS NULL 
        AND @DataInicio IS NULL
        AND @FornecedorId IS NULL 
        AND @NumeroNFe IS NULL 
        AND @CodigoProduto IS NULL
        THROW 5000, 'Tipo de consulta inválido. Use: DATA, FORNECEDOR, INTERVALO DE DATAS, NOTA_FISCAL, PRODUTO', 1;

    -- Atribuição para data fim vazia
    IF @DataInicio IS NOT NULL AND @DataFim IS NULL
        SET @DataFim =  '2099-12-31';

    DECLARE
        @SQLQuery           NVARCHAR(MAX),
        @ParamDefinitions   NVARCHAR(MAX),
        @Contador           INT = 0;

    -- Consulta principal com paginação
    SET @SQLQuery = 
    'SELECT 
        E.Id,
        E.NumeroNotaFiscal,
        E.Serie,
        E.Modelo,
        E.ChaveAcesso,
        E.DataEmissao,
        E.DataEntrada,
        E.FornecedorId,
        F.NomeFantasia,
        E.ValorTotal,
        E.ICMS_Total,
        E.IPI_Total,
        E.PIS_Total,
        E.COFINS_Total,
        E.Observacoes,
        EI.CodigoProduto,
        EI.Quantidade,
        EI.PrecoUnitario,
        EI.ValorTotal AS ValorTotalItem,
        EI.ICMS_Valor,
        EI.IPI_Valor,
        EI.PIS_Valor,
        EI.COFINS_Valor,
        EI.CustoUnitario
    FROM dbo.ENTRADAS E
    INNER JOIN dbo.FORNECEDORES F ON E.FornecedorId = F.Id
    INNER JOIN dbo.ENTRADAITENS EI ON E.Id = EI.EntradaId
    WHERE ';
    
        
    IF @Data IS NOT NULL
    BEGIN
        SET @SQLQuery += '(CAST(E.DataEntrada AS DATE) = @Data)';
        SET @Contador += 1;
    END;

    IF @FornecedorId IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @SQLQuery += ' AND ';
        SET @SQLQuery += '(E.FornecedorId = @FornecedorId)';
        SET @Contador += 1
    END;

    IF @NumeroNFe IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @SQLQuery += ' AND ';
        SET @SQLQuery += '(E.NumeroNotaFiscal = @NumeroNFe)';
        SET @Contador += 1
    END;

    IF @CodigoProduto IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @SQLQuery += ' AND ';
        SET @SQLQuery += '(EI.CodigoProduto = @CodigoProduto)';
        SET @Contador += 1
    END;

    IF @DataInicio IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @SQLQuery += ' AND ';
        SET @SQLQuery += '(CAST(E.DataEntrada AS DATE) BETWEEN @DataInicio AND @DataFim)';
    END;
    
    SET @SQLQuery += 
    'ORDER BY E.DataEntrada DESC, E.Id DESC;'

    SET @ParamDefinitions = N'
        @Data DATE,
        @FornecedorId INT,
        @DataInicio DATE,
        @DataFim DATE,
        @NumeroNFe NVARCHAR(9),
        @CodigoProduto NVARCHAR(5)';

    EXEC sp_executesql 
        @SQLQuery, 
        @ParamDefinitions, 
        @Data,
        @FornecedorId,
        @DataInicio,
        @DataFim,
        @NumeroNFe,
        @CodigoProduto;
END;
GO

-- Compras
EXEC usp_RelatorioCompras;
EXEC usp_RelatorioCompras @Data = '2025-11-25';
EXEC usp_RelatorioCompras @FornecedorId = 15;
EXEC usp_RelatorioCompras @FornecedorId = 17, @DataInicio = '2025-10-01';
EXEC usp_RelatorioCompras @NumeroNFe = '263374278';
EXEC usp_RelatorioCompras @CodigoProduto = 'LR657';
EXEC usp_RelatorioCompras @DataInicio = '2025-10-01', @DataFim = '2025-12-31'
GO

-- Relatorios de movimentação de estoque
CREATE OR ALTER PROCEDURE usp_RelatorioMovimentacoesEstoque
    @CodigoProduto      NVARCHAR(5) = NULL,
    @NomeProduto        NVARCHAR(80) = NULL,
    @DocumentoId        INT = NULL,
    @NumeroNFe          INT = NULL,
    @NumeroVenda        INT = NULL,
    @DataInicio         DATE = NULL,
    @DataFim            DATE = '2099-12-31',
    @TipoMovimentacao   CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validações básicas
    IF @CodigoProduto IS NULL 
        AND @NomeProduto IS NULL 
        AND @DocumentoId IS NULL 
        AND @NumeroNFe IS NULL 
        AND @NumeroVenda IS NULL 
        AND @DataInicio IS NULL
        AND @TipoMovimentacao IS NULL
        THROW 50001, 'Pelo menos um parâmetro de filtro deve ser informado.', 1;

    DECLARE
        @SQLQuery          NVARCHAR(MAX) = '',
        @WhereClause       NVARCHAR(MAX) = '',
        @JoinClause        NVARCHAR(MAX) = '',
        @ParamDefinitions  NVARCHAR(MAX),
        @Contador          INT = 0;

    -- Construção dinâmica do WHERE
    IF @CodigoProduto IS NOT NULL
    BEGIN
        SET @WhereClause += '(ME.CodigoProduto = @CodigoProduto)';
        SET @Contador += 1;
    END;

    IF @NomeProduto IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(ME.NomeProduto LIKE ''%'' + @NomeProduto + ''%'')';
        SET @Contador += 1;
    END;

    IF @DocumentoId IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(ME.DocumentoId = @DocumentoId)';
        SET @Contador += 1;
    END;

    IF @NumeroVenda IS NOT NULL
    BEGIN    
        SET @JoinClause += 'INNER JOIN dbo.VENDAS V ON ME.DocumentoId = V.Id'
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(V.NumeroVenda = @NumeroVenda AND ME.Observacao LIKE ''%venda%'')';
        SET @Contador += 1;
    END;

    IF @NumeroNFe IS NOT NULL
    BEGIN
        SET @JoinClause += 'INNER JOIN dbo.ENTRADAS E ON ME.DocumentoId = E.Id'
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(E.NumeroNotaFiscal = @NumeroNFe AND ME.Observacao LIKE ''%NF%'')';
        SET @Contador += 1;
    END;

    IF @TipoMovimentacao IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(ME.TipoMovimentacao = @TipoMovimentacao)';
        SET @Contador += 1;
    END;

    IF @DataInicio IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(CAST(ME.DataMovimentacao AS DATE) BETWEEN @DataInicio AND @DataFim)';
        SET @Contador += 1;
    END;

    -- Consulta principal com cálculo de saldo acumulado
    SET @SQLQuery = 
    'WITH MovimentacoesOrdenadas AS (
        SELECT 
            ME.Id,
            ME.TipoMovimentacao,
            ME.CodigoProduto,
            ME.NomeProduto,
            ME.Quantidade,
            ME.PrecoVenda,
            ME.ValorVendido,
            ME.Custo,
            ME.DocumentoId,
            ME.Observacao,
            U.Nome AS UsuarioNome,
            ME.DataMovimentacao,
            ImpactoEstoque = CASE 
                WHEN ME.TipoMovimentacao = ''E'' THEN ME.Quantidade
                WHEN ME.TipoMovimentacao = ''S'' THEN -ME.Quantidade
                WHEN ME.TipoMovimentacao = ''A'' THEN ME.Quantidade
                ELSE 0
            END,
            ROW_NUMBER() OVER (PARTITION BY ME.CodigoProduto ORDER BY ME.DataMovimentacao, ME.Id) AS OrdemProduto
        FROM dbo.MOVIMENTACOESESTOQUE ME 
        ' + CASE WHEN @JoinClause <> '' THEN @JoinClause ELSE '' END + '
        LEFT JOIN dbo.USUARIOS U ON ME.UsuarioMovimentacao = U.Id
        ' + CASE WHEN @Contador > 0 THEN 'WHERE ' + @WhereClause ELSE '' END + '
    )
    SELECT 
        M.Id,
        M.TipoMovimentacao,
        CASE 
            WHEN M.TipoMovimentacao = ''E'' THEN ''Entrada''
            WHEN M.TipoMovimentacao = ''S'' THEN ''Saída''
            WHEN M.TipoMovimentacao = ''A'' THEN ''Ajuste''
            ELSE ''Desconhecido''
        END AS DescricaoMovimentacao,
        M.CodigoProduto,
        M.NomeProduto,
        M.Quantidade,
        SaldoPeriodo = SUM(M.ImpactoEstoque) OVER (
            PARTITION BY M.CodigoProduto 
            ORDER BY M.DataMovimentacao, M.Id 
            ROWS UNBOUNDED PRECEDING
        ),
        M.PrecoVenda,
        M.ValorVendido,
        M.Custo,
        M.DocumentoId,
        M.Observacao,
        M.UsuarioNome,
        CAST(M.DataMovimentacao AS DATE) AS DataMovimentacao
    FROM MovimentacoesOrdenadas M
    ORDER BY M.CodigoProduto, M.DataMovimentacao, M.Id;';

    -- Definir os parâmetros para sp_executesql
    SET @ParamDefinitions = N'
        @CodigoProduto      NVARCHAR(5),
        @NomeProduto        NVARCHAR(80),
        @DocumentoId        INT,
        @NumeroNFe          INT,
        @NumeroVenda        INT,
        @DataInicio         DATE,
        @DataFim            DATE,
        @TipoMovimentacao   CHAR(1)';
        
    -- Executar a query dinâmica para debug
    -- PRINT @SQLQuery; 

    EXEC sp_executesql 
        @SQLQuery,
        @ParamDefinitions,
        @CodigoProduto,
        @NomeProduto,
        @DocumentoId,
        @NumeroNFe,
        @NumeroVenda,
        @DataInicio,
        @DataFim,
        @TipoMovimentacao;

END;
GO

CREATE OR ALTER PROCEDURE usp_ResumoMovimentacoesEstoque
    @CodigoProduto      NVARCHAR(5) = NULL,
    @NomeProduto        NVARCHAR(80) = NULL,
    @DataInicio         DATE = NULL,
    @DataFim           DATE = '2099-12-31',
    @TipoMovimentacao   CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validações básicas
    IF @CodigoProduto IS NULL 
        AND @NomeProduto IS NULL 
        AND @DataInicio IS NULL
        AND @TipoMovimentacao IS NULL
        THROW 50001, 'Pelo menos um parâmetro de filtro deve ser informado.', 1;

    DECLARE
        @SQLQuery          NVARCHAR(MAX),
        @WhereClause       NVARCHAR(MAX) = '',
        @ParamDefinitions  NVARCHAR(500),
        @Contador          INT = 0;

    -- Construção dinâmica do WHERE (mesma lógica da procedure principal)
    IF @CodigoProduto IS NOT NULL
    BEGIN
        SET @WhereClause += '(CodigoProduto = @CodigoProduto)';
        SET @Contador += 1;
    END;

    IF @NomeProduto IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(NomeProduto LIKE ''%'' + @NomeProduto + ''%'')';
        SET @Contador += 1;
    END;

    IF @TipoMovimentacao IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(TipoMovimentacao = @TipoMovimentacao)';
        SET @Contador += 1;
    END;

    IF @DataInicio IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(CAST(DataMovimentacao AS DATE) BETWEEN @DataInicio AND @DataFim)';
        SET @Contador += 1;
    END;

    -- Query de resumo
    SET @SQLQuery = 
    'SELECT 
        TotalMovimentacoes = COUNT(*),
        EntradasTotalProdutos = SUM(CASE WHEN TipoMovimentacao = ''E'' THEN Quantidade ELSE 0 END),
        SaidasTotalProdutos = SUM(CASE WHEN TipoMovimentacao = ''S'' THEN Quantidade ELSE 0 END),
        AjustesTotalProdutos = SUM(CASE WHEN TipoMovimentacao = ''A'' THEN Quantidade ELSE 0 END),
        ValorTotalEntradas = SUM(CASE WHEN TipoMovimentacao = ''E'' THEN Quantidade * Custo ELSE 0 END),
        ValorTotalVendido = SUM(CASE WHEN TipoMovimentacao = ''S'' THEN Quantidade * ValorVendido ELSE 0 END),
        CustoTotalSaidas = SUM(CASE WHEN TipoMovimentacao = ''S'' THEN Quantidade * Custo ELSE 0 END),
        SaldoProdutos = SUM(CASE 
                                WHEN TipoMovimentacao = ''E'' THEN Quantidade
                                WHEN TipoMovimentacao = ''S'' THEN -Quantidade
                                ELSE Quantidade
                             END)
    FROM dbo.MOVIMENTACOESESTOQUE';

    -- Adicionar WHERE clause se houver filtros
    IF @Contador > 0
        SET @SQLQuery += ' WHERE ' + @WhereClause;

    SET @ParamDefinitions = N'
        @CodigoProduto NVARCHAR(5),
        @NomeProduto NVARCHAR(80),
        @DataInicio DATE,
        @DataFim DATE,
        @TipoMovimentacao CHAR(1)';

    EXEC sp_executesql 
        @SQLQuery,
        @ParamDefinitions,
        @CodigoProduto,
        @NomeProduto,
        @DataInicio,
        @DataFim,
        @TipoMovimentacao;

END;
GO

-- Movimentações
EXEC usp_RelatorioMovimentacoesEstoque;
EXEC usp_RelatorioMovimentacoesEstoque @CodigoProduto = 'CP163';
EXEC usp_RelatorioMovimentacoesEstoque @NomeProduto = 'RT';
EXEC usp_RelatorioMovimentacoesEstoque @DocumentoId = 4;
EXEC usp_RelatorioMovimentacoesEstoque @NumeroVenda = 20;
EXEC usp_RelatorioMovimentacoesEstoque @NumeroNFe = '916254593';
EXEC usp_RelatorioMovimentacoesEstoque @DataInicio = '2025-10-01', @DataFim = '2025-11-30';
EXEC usp_RelatorioMovimentacoesEstoque @TipoMovimentacao = 'E';
EXEC usp_RelatorioMovimentacoesEstoque @TipoMovimentacao = 'S';
EXEC usp_RelatorioMovimentacoesEstoque @TipoMovimentacao = 'A';
EXEC usp_RelatorioMovimentacoesEstoque @CodigoProduto = 'CP163', @DataInicio = '2025-11-20', @TipoMovimentacao = 'E';

-- Resumo das movimentações
EXEC usp_ResumoMovimentacoesEstoque;
EXEC usp_ResumoMovimentacoesEstoque @CodigoProduto = 'CP163';
EXEC usp_ResumoMovimentacoesEstoque @NomeProduto = 'Produto-CP163';
EXEC usp_ResumoMovimentacoesEstoque @DataInicio = '2024-01-01',  @DataFim = '2025-11-30';
EXEC usp_ResumoMovimentacoesEstoque @TipoMovimentacao = 'E';
EXEC usp_ResumoMovimentacoesEstoque @TipoMovimentacao = 'S';
EXEC usp_ResumoMovimentacoesEstoque @TipoMovimentacao = 'A';
GO

-- Relatorio de vendas
CREATE OR ALTER PROCEDURE usp_BuscarVendas
    @CodigoProduto  VARCHAR(5) = NULL,
    @NomeProduto    NVARCHAR(80) = NULL,
    @CodigoServico  VARCHAR(6) = NULL,
    @NomeServico    NVARCHAR(80) = NULL,
    @NumeroVenda    INT = NULL,
    @Cliente        NVARCHAR(100) = NULL,
    @DataInicio     DATETIME2 = NULL,
    @DataFim        DATETIME2 = '2099-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validações básicas
    IF @CodigoProduto IS NULL 
        AND @NomeProduto IS NULL 
        AND @CodigoServico IS NULL 
        AND @NomeServico IS NULL 
        AND @NumeroVenda IS NULL 
        AND @Cliente IS NULL 
        AND @DataInicio IS NULL
        THROW 50001, 'Pelo menos um parâmetro de filtro deve ser informado.', 1;

    DECLARE
        @SQLQuery          NVARCHAR(MAX),
        @WhereClause       NVARCHAR(MAX) = '',
        @ParamDefinitions  NVARCHAR(1000),
        @Contador          INT = 0;

    -- Construção dinâmica do WHERE
    IF @CodigoProduto IS NOT NULL
    BEGIN
        SET @WhereClause += '(P.Codigo = @CodigoProduto)';
        SET @Contador += 1;
    END;

    IF @NomeProduto IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(P.Nome LIKE ''%'' + @NomeProduto + ''%'')';
        SET @Contador += 1;
    END;

    IF @CodigoServico IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(S.Codigo = @CodigoServico)';
        SET @Contador += 1;
    END;

    IF @NomeServico IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(S.Nome LIKE ''%'' + @NomeServico + ''%'')';
        SET @Contador += 1;
    END;

    IF @NumeroVenda IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(V.NumeroVenda = @NumeroVenda)';
        SET @Contador += 1;
    END;

    IF @Cliente IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(C.Nome LIKE ''%'' + @Cliente + ''%'' OR C.CPF LIKE ''%'' + @Cliente + ''%'')';
        SET @Contador += 1;
    END;

    IF @DataInicio IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(CAST(V.DataVenda AS DATE) BETWEEN @DataInicio AND @DataFim)';
        SET @Contador += 1;
    END;

    -- Query principal
    SET @SQLQuery = 
    'SELECT 
        V.Id AS VendaId,
        V.NumeroVenda,
        CAST(V.DataVenda AS DATE) AS DataVenda,
        V.Total AS TotalVenda,
        V.Estatus,
        C.Id AS ClienteId,
        C.Nome AS ClienteNome,
        C.CPF AS ClienteCPF,
        VI.Id AS ItemId,
        VI.ProdutoId,
        P.Codigo AS ProdutoCodigo,
        P.Nome AS ProdutoNome,
        VI.ServicoId,
        S.Codigo AS ServicoCodigo,
        S.Nome AS ServicoNome,
        VI.Quantidade,
        VI.PrecoUnitario,
        VI.Total AS TotalItem
    FROM VENDAS V
    INNER JOIN CLIENTES C ON V.ClienteId = C.Id
    INNER JOIN VendaItens VI ON V.Id = VI.VendaId
    LEFT JOIN PRODUTOS P ON VI.ProdutoId = P.Id
    LEFT JOIN SERVICOS S ON VI.ServicoId = S.Id';

    -- Adicionar WHERE clause se houver filtros
    IF @Contador > 0
        SET @SQLQuery += ' WHERE ' + @WhereClause;

    -- Ordenação padrão
    SET @SQLQuery += ' ORDER BY V.DataVenda DESC, V.NumeroVenda DESC';
        
    -- Executar a query dinâmica para debug
    -- PRINT @SQLQuery; 

    SET @ParamDefinitions = N'
        @CodigoProduto VARCHAR(5),
        @NomeProduto NVARCHAR(80),
        @CodigoServico VARCHAR(6),
        @NomeServico NVARCHAR(80),
        @NumeroVenda INT,
        @Cliente NVARCHAR(100),
        @DataInicio DATETIME2,
        @DataFim DATETIME2';

    EXEC sp_executesql 
        @SQLQuery,
        @ParamDefinitions,
        @CodigoProduto,
        @NomeProduto,
        @CodigoServico,
        @NomeServico,
        @NumeroVenda,
        @Cliente,
        @DataInicio,
        @DataFim;

END;
GO

CREATE OR ALTER PROCEDURE usp_ResumoVendas
    @CodigoProduto      VARCHAR(5) = NULL,
    @NomeProduto        NVARCHAR(80) = NULL,
    @CodigoServico      VARCHAR(6) = NULL,
    @NomeServico        NVARCHAR(80) = NULL,
    @Cliente            NVARCHAR(100) = NULL,
    @DataInicio         DATETIME2 = NULL,
    @DataFim           DATETIME2 = '2099-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validações básicas
    IF @CodigoProduto IS NULL 
        AND @NomeProduto IS NULL 
        AND @CodigoServico IS NULL 
        AND @NomeServico IS NULL 
        AND @Cliente IS NULL 
        AND @DataInicio IS NULL
        THROW 50001, 'Pelo menos um parâmetro de filtro deve ser informado.', 1;

    DECLARE
        @SQLQuery          NVARCHAR(MAX),
        @WhereClause       NVARCHAR(MAX) = '',
        @ParamDefinitions  NVARCHAR(1000),
        @Contador          INT = 0;


    -- Construção dinâmica do WHERE
    IF @CodigoProduto IS NOT NULL
    BEGIN
        SET @WhereClause += '(P.Codigo = @CodigoProduto)';
        SET @Contador += 1;
    END;

    IF @NomeProduto IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(P.Nome LIKE ''%'' + @NomeProduto + ''%'')';
        SET @Contador += 1;
    END;

    IF @CodigoServico IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(S.Codigo = @CodigoServico)';
        SET @Contador += 1;
    END;

    IF @NomeServico IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(S.Nome LIKE ''%'' + @NomeServico + ''%'')';
        SET @Contador += 1;
    END;

    IF @Cliente IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(C.Nome LIKE ''%'' + @Cliente + ''%'' OR C.CPF LIKE ''%'' + @Cliente + ''%'')';
        SET @Contador += 1;
    END;

    IF @DataInicio IS NOT NULL
    BEGIN
        IF @Contador > 0
            SET @WhereClause += ' AND ';
        SET @WhereClause += '(CAST(V.DataVenda AS DATE) BETWEEN @DataInicio AND @DataFim)';
        SET @Contador += 1;
    END;


    -- Query de resumo
    SET @SQLQuery = 
    'IF EXISTS (
        SELECT 1
        FROM VENDAS V
        INNER JOIN CLIENTES C ON V.ClienteId = C.Id
        INNER JOIN VendaItens VI ON V.Id = VI.VendaId
        LEFT JOIN PRODUTOS P ON VI.ProdutoId = P.Id
        LEFT JOIN SERVICOS S ON VI.ServicoId = S.Id';

    -- Adicionar WHERE clause se houver filtros
    IF @Contador > 0
        SET @SQLQuery += ' WHERE ' + @WhereClause;

    SET @SQLQuery += ')
    SELECT 
        -- Métricas principais
        TotalVendas = COUNT(V.Id),
        TotalItensVendidos = SUM(VI.Quantidade),
        ValorTotalVendas = SUM(VI.Total),
        TicketMedio = CAST(AVG(VI.Total) AS DECIMAL(10,2)),
        
        -- Métricas por tipo de item
        TotalProdutosVendidos = SUM(CASE WHEN VI.ProdutoId IS NOT NULL THEN VI.Quantidade ELSE 0 END),
        TotalServicosVendidos = SUM(CASE WHEN VI.ServicoId IS NOT NULL THEN VI.Quantidade ELSE 0 END),
        ValorTotalProdutos = SUM(CASE WHEN VI.ProdutoId IS NOT NULL THEN VI.Total ELSE 0 END),
        ValorTotalServicos = SUM(CASE WHEN VI.ServicoId IS NOT NULL THEN VI.Total ELSE 0 END),
        
        -- Métricas por status
        VendasAbertas = SUM(CASE WHEN V.Estatus = ''Aberta'' THEN 1 ELSE 0 END),
        VendasFechadas = SUM(CASE WHEN V.Estatus = ''Fechada'' THEN 1 ELSE 0 END),
        VendasCanceladas = SUM(CASE WHEN V.Estatus = ''Cancelada'' THEN 1 ELSE 0 END),
        
        -- Métricas temporais
        MaiorVenda = MAX(VI.Total),
        MenorVenda = MIN(VI.Total),
        MediaItensPorVenda = CAST(AVG(VI.Quantidade * 1.0) AS DECIMAL(10,2)),
        
        -- Métricas de clientes
        TotalClientesAtendidos = COUNT(V.ClienteId),
        ClientesNovos = COUNT(CASE WHEN C.DataCadastro >= @DataInicio THEN C.Id END)
        
    FROM VENDAS V
    INNER JOIN CLIENTES C ON V.ClienteId = C.Id
    INNER JOIN VendaItens VI ON V.Id = VI.VendaId
    LEFT JOIN PRODUTOS P ON VI.ProdutoId = P.Id
    LEFT JOIN SERVICOS S ON VI.ServicoId = S.Id';

    -- Adicionar WHERE clause se houver filtros
    IF @Contador > 0
        SET @SQLQuery += ' WHERE ' + @WhereClause;
        
    -- Executar a query dinâmica para debug
    -- PRINT @SQLQuery; 

    SET @ParamDefinitions = N'
        @CodigoProduto VARCHAR(5),
        @NomeProduto NVARCHAR(80),
        @CodigoServico VARCHAR(6),
        @NomeServico NVARCHAR(80),
        @Cliente NVARCHAR(100),
        @DataInicio DATETIME2,
        @DataFim DATETIME2';

    EXEC sp_executesql 
        @SQLQuery,
        @ParamDefinitions,
        @CodigoProduto,
        @NomeProduto,
        @CodigoServico,
        @NomeServico,
        @Cliente,
        @DataInicio,
        @DataFim;

END;
GO

-- Vendas
EXEC usp_BuscarVendas;
EXEC usp_BuscarVendas @CodigoProduto = 'KP924';
EXEC usp_BuscarVendas @NomeProduto = 'Produto-JF684';
EXEC usp_BuscarVendas @CodigoServico = 'SEV657';
EXEC usp_BuscarVendas @NomeServico = 'Serviço-SEV657';
EXEC usp_BuscarVendas @NumeroVenda = 5;
EXEC usp_BuscarVendas @Cliente = 'Xavier Martins'; 
EXEC usp_BuscarVendas @Cliente = 'Rafael Esteves';
EXEC usp_BuscarVendas @DataInicio = '2025-11-01', @DataFim = '2025-11-30';
EXEC usp_BuscarVendas @NomeProduto = 'KP924', @DataInicio = '2025-11-01';

-- Resumo
EXEC usp_ResumoVendas;
EXEC usp_ResumoVendas @DataInicio = '2025-11-01', @DataFim = '2025-11-30';
EXEC usp_ResumoVendas @NomeProduto = 'KP924', @DataInicio = '2025-11-01';
EXEC usp_ResumoVendas @NomeServico = 'Serviço-SEV657', @DataInicio = '2025-11-01';
EXEC usp_ResumoVendas @Cliente = 'Xavier Martins', @DataInicio = '2025-11-26';
GO