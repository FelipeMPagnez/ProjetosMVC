USE Treinamento;
GO

-- Tenta gerar CPFs aleatórios até um máximo de 20 tentaivas
CREATE OR ALTER PROCEDURE dbo.usp_GerarCPF
    @CPF CHAR(11) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @rand9      VARCHAR(9),
        @d1         INT, 
        @d2         INT,
        @i          INT,
        @sum        INT,
        @tentativas INT = 0;

    WHILE 1 = 1  -- Loop até gerar um CPF único
    BEGIN
        SET @tentativas += 1;

        -- Gera os 9 primeiros dígitos aleatórios
        SET @rand9 = RIGHT('000000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR(9)), 9);

        -- 1º dígito verificador (peso 10..2)
        SET @sum = 0;
        SET @i = 1;
        WHILE @i <= 9
        BEGIN
            SET @sum += CAST(SUBSTRING(@rand9, @i, 1) AS INT) * (11 - @i);
            SET @i += 1;
        END
        SET @d1 = (@sum * 10) % 11;
        IF @d1 = 10 SET @d1 = 0;

        -- 2º dígito verificador (peso 11..2)
        SET @sum = 0;
        SET @i = 1;
        WHILE @i <= 9
        BEGIN
            SET @sum += CAST(SUBSTRING(@rand9, @i, 1) AS INT) * (12 - @i);
            SET @i += 1;
        END
        SET @sum += @d1 * 2;
        SET @d2 = (@sum * 10) % 11;
        IF @d2 = 10 SET @d2 = 0;

        SET @CPF = @rand9 + CAST(@d1 AS CHAR(1)) + CAST(@d2 AS CHAR(1));
                
        IF NOT EXISTS (SELECT 1 FROM dbo.CLIENTES WHERE CPF = @CPF)
            BREAK; -- CPF é único → sai do loop
                    
        IF @tentativas > 20
            RETURN;
    END
END;
GO

-- Tenta gerar CNPJs aleatórios até um máximo de 20 tentaivas
CREATE OR ALTER PROCEDURE dbo.usp_GerarCNPJ
    @CNPJ CHAR(14) OUTPUT
AS
BEGIN
    DECLARE 
        @base       VARCHAR(12),
        @soma       INT,
        @resto      INT,
        @d1         INT,
        @d2         INT,
        @i          INT,
        @pesos1     VARCHAR(12) = '543298765432',
        @pesos2     VARCHAR(13) = '6543298765432',
        @tentativas INT = 0;
    
    WHILE 1 = 1  -- Loop até gerar um CPF único
    BEGIN
        -- 8 dígitos aleatórios + '0001' (filial)
        SET @base = RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8)), 8) + '0001';

        -- Calcula primeiro dígito verificador
        SET @soma = 0;
        SET @i = 1;
        WHILE @i <= 12
        BEGIN
            SET @soma += CAST(SUBSTRING(@base, @i, 1) AS INT) * CAST(SUBSTRING(@pesos1, @i, 1) AS INT);
            SET @i += 1;
        END
        SET @resto = @soma % 11;
        SET @d1 = CASE WHEN @resto < 2 THEN 0 ELSE 11 - @resto END;

        -- Calcula segundo dígito verificador
        SET @soma = 0;
        SET @i = 1;
        WHILE @i <= 12
        BEGIN
            SET @soma += CAST(SUBSTRING(@base, @i, 1) AS INT) * CAST(SUBSTRING(@pesos2, @i, 1) AS INT);
            SET @i += 1;
        END
        SET @soma += @d1 * 2;
        SET @resto = @soma % 11;
        SET @d2 = CASE WHEN @resto < 2 THEN 0 ELSE 11 - @resto END;

        SET @CNPJ = @base + CAST(@d1 AS CHAR(1)) + CAST(@d2 AS CHAR(1));
                
        IF NOT EXISTS (SELECT 1 FROM dbo.FORNECEDORES WHERE CNPJ = @CNPJ)
            BREAK; -- CNPJ é único → sai do loop
                    
        IF @tentativas > 20
            RETURN;
    END;

END;
GO

-- Gera Chaves de acesso para NFs
CREATE OR ALTER PROCEDURE dbo.usp_GerarChaveNF   
    @NumeroNF       CHAR(9),
    @Serie          CHAR(3),
    @Modelo         CHAR(2),
    @CNPJ           CHAR(14),
    @cUF            CHAR(2),
    @ChaveFinal     CHAR(44) OUTPUT

AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE 
        @AnoMes         CHAR(4) = FORMAT(GETDATE(), 'yyMM'),
        @TipoEmissao    CHAR(1) = '1',
        @CodigoNumerico CHAR(8) = RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999 AS VARCHAR(8)), 8),        
        @ChaveSemDV     CHAR(43),
        @DV             INT,
        @Resto          INT,
        @Soma           INT = 0,
        @Peso           INT = 2,
        @Digito         CHAR(1);

    -- Monta a chave sem o dígito verificador
    SET @ChaveSemDV = @cUF + @AnoMes + @CNPJ + @Modelo + @Serie + @NumeroNF + @TipoEmissao + @CodigoNumerico;

    -- Calcula o DV (dígito verificador) com base no módulo 11
    DECLARE @i INT = LEN(@ChaveSemDV);
    WHILE @i > 0
    BEGIN
        SET @Soma += (SUBSTRING(@ChaveSemDV, @i, 1) * @Peso);
        SET @Peso = CASE WHEN @Peso = 9 THEN 2 ELSE @Peso + 1 END;
        SET @i -= 1;
    END

    SET @Resto = @Soma % 11;
    SET @DV = CASE WHEN @Resto = 0 OR @Resto = 1 THEN 0 ELSE 11 - @Resto END;

    SET @ChaveFinal = @ChaveSemDV + CAST(@DV AS CHAR(1));
END
GO

-- Gera códigos para os produtos
CREATE OR ALTER PROCEDURE dbo.usp_GerarCodigoProduto
    @CODIGO CHAR(5) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Lista Código de produtos por prefixo e sufixo
    DECLARE @PrefixoCodigosProdutos TABLE (Prefixo CHAR(2));
    INSERT INTO @PrefixoCodigosProdutos VALUES
        ('PR'),('CP'),('PC'),('IT'),('DE'),
        ('KP'),('OP'),('RT'),('JF'),('LR');

    DECLARE @SufixoCodigosProdutos TABLE (Sufixo CHAR(3));
    INSERT INTO @SufixoCodigosProdutos VALUES
        ('001'),('138'),('684'),('657'),('987'),('486'),('552'),('342'),('219'),('185'),
        ('163'),('094'),('415'),('875'),('726'),('801'),('749'),('924'),('527'),('386');

    DECLARE
        @PrefixoCodigo  CHAR(2) = (SELECT TOP 1 * FROM @PrefixoCodigosProdutos ORDER BY NEWID()),
        @SufixoCodigo   CHAR(3) = (SELECT TOP 1 * FROM @SufixoCodigosProdutos  ORDER BY NEWID());
    
    SET @CODIGO = CONCAT(@PrefixoCodigo,@SufixoCodigo);
END;
GO

-- Gera UDTTs
IF TYPE_ID('dbo.TypeTable_EntradaItens') IS NULL
    CREATE TYPE TypeTable_EntradaItens AS TABLE
    (
        CodigoProduto     NVARCHAR(5),
        Quantidade        INT,
        PrecoUnitario     DECIMAL(10,2),
        ICMS_Aliquota     DECIMAL(5,2),
        IPI_Aliquota      DECIMAL(5,2),
        PIS_Aliquota      DECIMAL(5,2),
        COFINS_Aliquota   DECIMAL(5,2)
    );
GO

IF TYPE_ID('dbo.TypeTable_VendaItens') IS NULL
    CREATE TYPE TypeTable_VendaItens AS TABLE
    (
        ProdutoId       INT NULL,
        ServicoId       INT NULL,
        Quantidade      INT NOT NULL CHECK (Quantidade > 0),
        PrecoUnitario   DECIMAL(10,2) NOT NULL CHECK (PrecoUnitario >= 0)
    );
GO


-- Gera clientes aleatórios para popular a tabela CLIENTES
CREATE OR ALTER PROCEDURE dbo.usp_PopulaClientes
     @Quantidade INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE 
            @Nome           NVARCHAR(20),
            @Sobrenome      NVARCHAR(20),
            @CPF            CHAR(11),
            @DataNascimento DATE,
            @Email          NVARCHAR(80),
            @Telefone       VARCHAR(17),
            @Logradouro     NVARCHAR(50),
            @Numero         NVARCHAR(4),
            @Complemento    NVARCHAR(50),
            @Bairro         NVARCHAR(30),
            @Cidade         NVARCHAR(30),
            @UF             CHAR(2),
            @CEP            VARCHAR(10),
            @i              INT = 1;

    WHILE @i <= @Quantidade
    BEGIN
        
        -- Listas de nomes e sobrenome, provedor de e-mail e cidades com UF, DDD e CEP
        DECLARE @Nomes TABLE (Nome NVARCHAR(20));
        INSERT INTO @Nomes VALUES 
            ('Ana'),('Bruno'),('Carlos'),('Daniela'),('Eduardo'),
            ('Fernanda'),('Gabriel'),('Helena'),('Igor'),('Juliana'),
            ('Karla'),('Lucas'),('Mariana'),('Nicolas'), ('Otávio'),
            ('Patrícia'), ('Quitéria'), ('Rafael'),('Sofia'),('Tiago'),
            ('Ulisses'),('Vitória'),('Xavier'), ('William'), ('Yago'),
            ('Zumira');

        DECLARE @Sobrenomes TABLE (Sobrenome NVARCHAR(20));
        INSERT INTO @Sobrenomes VALUES 
            ('Almeida'),('Borges'),('Campos'),('Duarte'),('Esteves'),
            ('Ferreira'),('Garcia'),('Hernandez'),('Isidoro'),('Jardim'), 
            ('Kennedy'),('Lopes'),('Martins'),('Neves'),('Osório'), 
            ('Pereira'),('Quadros'),('Ramos'),('Silva'),('Teixeira'), 
            ('Urich'),('Vieira'),('Wenceslau'),('Ximenes'),('York'),
            ('Zanetti');

        DECLARE @ProvedoresEmail TABLE (Provedor NVARCHAR(15));
        INSERT INTO @ProvedoresEmail VALUES 
            ('@gmail.com'),('@hotmail.com'),('@outlook.com'),('@yahoo.com'),('@icloud.com');

        DECLARE @Cidades TABLE (Cidade NVARCHAR(100), UF CHAR(2), DDD CHAR(4), CEP CHAR(10));
        INSERT INTO @Cidades VALUES
            ('São Paulo','SP','(11)','01.000-000'),('Rio de Janeiro','RJ','(21)','20.000-000'),
            ('Belo Horizonte','MG','(31)','30.000-000'),
            ('Salvador','BA','(71)','40.000-000'),('Fortaleza','CE','(85)','60.000-000'),
            ('Recife','PE','(81)','50.000-000'),
            ('Belém','PA','(91)','66.000-000'),('Porto Velho','RO','(69)','76.800-000'),
            ('Curitiba','PR','(41)','80.000-000'),('Porto Alegre','RS','(51)','90.000-000'),
            ('Goiânia','GO','(62)','74.000-000'),('Brasília','DF','(61)','70.000-000');

        -- Seleciona valores aleatórios das tabelas temporárias
        SELECT TOP 1 @Nome = Nome FROM @Nomes ORDER BY NEWID();
        SELECT TOP 1 @Sobrenome = Sobrenome FROM @Sobrenomes ORDER BY NEWID();
        SELECT TOP 1 @Cidade = Cidade, @UF = UF , @Telefone = DDD, @CEP = CEP FROM @Cidades ORDER BY NEWID();

        -- Gera data de nascimento aleatória (entre 1970 e 2005)
        SET @DataNascimento = DATEADD(DAY, -1 * (ABS(CHECKSUM(NEWID())) % 20000), GETDATE() - 7300);

        -- Gera e-mail com base no nome, sobrenome, ano de nascimento e seleciona valores aleatórios da tabela ProvedoresEmail
        SET @Email = LOWER(@Nome + '.' + @Sobrenome + CAST(YEAR(@DataNascimento) AS VARCHAR) + 
                            (SELECT TOP 1 Provedor FROM @ProvedoresEmail ORDER BY NEWID()));

        -- Gera telefone aleatório (formato 11 9XXXX-XXXX)
        SET @Telefone += 
            CONCAT('9',
                CAST(1000 + (ABS(CHECKSUM(NEWID())) % 9000) AS VARCHAR(4)),
                '-',
                CAST(1000 + (ABS(CHECKSUM(NEWID())) % 9000) AS VARCHAR(4))
            );

        -- Gera CPF fictício
        EXEC dbo.usp_GerarCPF @CPF OUTPUT;

        -- Endereço fictício
        SET @Logradouro = CONCAT('Rua ', @Nome);
        SET @Numero = CAST(ABS(CHECKSUM(NEWID())) % 999 AS VARCHAR(4));
        SET @Complemento = CONCAT('Apto ', ABS(CHECKSUM(NEWID())) % 100);
        SET @Bairro = CONCAT('Bairro ', ABS(CHECKSUM(NEWID())) % 200);


        -- Insere o registro    
        INSERT INTO dbo.CLIENTES (Nome,CPF,DataNascimento,Email,Telefone,Logradouro,
                                  Numero,Complemento,Bairro,Cidade,UF,CEP)
        VALUES(CONCAT(@Nome,' ',@Sobrenome),@CPF,@DataNascimento,@Email,@Telefone,
               @Logradouro,@Numero,@Complemento,@Bairro,@Cidade,@UF,@CEP);

        SET @i += 1;
    END;
END;
GO

-- Gera Fornecedores aleatórios para popular a tabela FORNECEDORES
CREATE OR ALTER PROCEDURE dbo.usp_PopularFornecedores
    @QtdFornecedores    INT,
    @CNPJ               CHAR(14) = NULL,
    @UF                 CHAR(2)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @FornecedorId   INT,
        @Cidade         CHAR(30),
        @DDD            CHAR(4),
        @i              INT = 1;

    IF EXISTS (SELECT 1 FROM dbo.FORNECEDORES)
        SELECT @FornecedorId = MAX(Id) FROM dbo.FORNECEDORES;
    ELSE
        SET @FornecedorId = @@IDENTITY;

    WHILE @i <= @QtdFornecedores
    BEGIN
        -- Gera CNPJ único
        IF @CNPJ IS NULL
            EXEC dbo.usp_GerarCNPJ @CNPJ = @CNPJ OUTPUT;

        -- Lista de cidades com UF e DDD
        DECLARE @Cidades TABLE (Cidade NVARCHAR(50), UF CHAR(2), DDD CHAR(4));
        INSERT INTO @Cidades VALUES
            ('Goiânia','GO','(62)'),('Brasília','DF','(61)');
        
        -- Lista de provedores de e-mail
        DECLARE @ProvedoresEmail TABLE (Provedor NVARCHAR(15));
        INSERT INTO @ProvedoresEmail VALUES
            ('@gmail.com'),('@outlook.com'),('@yahoo.com'),('@icloud.com');
        
        -- atribui valores as variáveis 
        IF @UF IS NULL
            SELECT TOP 1 @Cidade = Cidade, @UF = UF, @DDD = DDD FROM @Cidades ORDER BY NEWID();
        ELSE
            SELECT TOP 1 @Cidade = Cidade, @DDD = DDD FROM @Cidades WHERE UF = @UF;

        -- Insere fornecedor
        INSERT INTO dbo.FORNECEDORES (NomeFantasia, RazaoSocial, CNPJ, Email, Telefone, Cidade, UF)
        VALUES (
            CONCAT('Fornecedor', @FornecedorId),
            CONCAT('Razao Social', @FornecedorId),
            @CNPJ,
            CONCAT('fornecedor', @FornecedorId, (SELECT TOP 1 Provedor FROM @ProvedoresEmail ORDER BY NEWID())),
            CONCAT(@DDD, '9', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999 AS VARCHAR(8)), 8)),
            @Cidade,
            @UF
        );
        
        SET @FornecedorId = SCOPE_IDENTITY();
        SET @CNPJ = NULL;
        SET @i += 1;
    END;
END;
GO

-- Popula a tabela PRODUTOS
CREATE OR ALTER PROCEDURE dbo.usp_PopulaProdutos
    @Quantidade INT
AS
BEGIN    
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    
    DECLARE @UnidadesMedida TABLE (Unidade CHAR(2));
    INSERT INTO @UnidadesMedida VALUES
        ('UN'),('KG'),('CX'),('PC'),('MT'),('LT');

    WHILE @i <= @Quantidade
    BEGIN
        DECLARE
            @Codigo         CHAR(5),
            @PrecoCompra    DECIMAL(10,2) = ROUND((RAND() * 250) + 8, 2),
            @UN             CHAR(2) = (SELECT TOP 1 * FROM @UnidadesMedida ORDER BY NEWID());

        EXEC dbo.usp_GerarCodigoProduto @CODIGO = @Codigo OUTPUT;
        
        IF NOT EXISTS (SELECT 1 FROM dbo.PRODUTOS WHERE Codigo = @Codigo)
        BEGIN
            INSERT INTO dbo.PRODUTOS (Codigo,Nome,Descricao,PrecoVenda,PrecoCompra,Custo,Estoque,Unidade)
            VALUES (
                @Codigo,
                CONCAT('Produto-',@Codigo),
                CONCAT('Descrição do Produto Produto-',@Codigo),
                @PrecoCompra*1.30*1.75,
                @PrecoCompra,
                @PrecoCompra*1.30,
                ROUND(RAND() * 10 + 1, 0),
                @UN
            );
        END
        ELSE 
        BEGIN
            UPDATE P
            SET P.PrecoVenda = @PrecoCompra*1.15*1.75, 
                P.PrecoCompra = @PrecoCompra,
                P.Custo = @PrecoCompra*1.15,
                P.Estoque = ROUND(RAND() * 10 + 1, 0)
            FROM dbo.PRODUTOS P
            WHERE Codigo = @Codigo
        END

        SET @i += 1;            
    END;
END;
GO

-- Popula a tabela PRODUTOS
CREATE OR ALTER PROCEDURE dbo.usp_PopulaServicos
    @Quantidade INT
AS
BEGIN    
    SET NOCOUNT ON;

    DECLARE @PrefixoCodigos TABLE (Prefixo CHAR(3));
    INSERT INTO @PrefixoCodigos VALUES
        ('SER'),('SEV'),('SVC');

    DECLARE @SufixoCodigos TABLE (Sufixo CHAR(3));
    INSERT INTO @SufixoCodigos VALUES
        ('001'),('138'),('684'),('657'),('987'),('486'),('552'),('342'),('219'),('185'),
        ('163'),('094'),('415'),('875'),('726'),('801'),('749'),('924'),('527'),('386');

    DECLARE
        @Codigo         NVARCHAR(6),
        @Preco          DECIMAL(10,2),
        @i              INT = 0;

    WHILE @i < @Quantidade
    BEGIN
        
        SET @Codigo = CONCAT((SELECT TOP 1 * FROM @SufixoCodigos  ORDER BY NEWID()),
                             (SELECT TOP 1 * FROM @PrefixoCodigos ORDER BY NEWID()));
        SET @Preco  = ROUND((RAND() * 250) + 8, 2);
        
        IF NOT EXISTS (SELECT 1 FROM dbo.SERVICOS WHERE Codigo = @Codigo)
        BEGIN
            INSERT INTO dbo.SERVICOS (Codigo,Nome, Descricao,Preco)
            VALUES (
                @Codigo,
                CONCAT('Serviço-',@Codigo),
                CONCAT('Descrição do Serviço Serviço-',@Codigo),
                @Preco
            );
        END
        ELSE 
        BEGIN
            UPDATE S
            SET S.Preco = @Preco
            FROM dbo.SERVICOS S
            WHERE Codigo = @Codigo
        END

        SET @i += 1;            
    END;
END;
GO

-- Popula a tabela ENTRADAS e EntradaItens
CREATE OR ALTER PROCEDURE dbo.usp_PopulaEntradaItens
    @NumeroNotaFiscal   NVARCHAR(9),
    @Serie              NVARCHAR(3),
    @Modelo             NVARCHAR(2),
    @ChaveAcesso        NVARCHAR(44),
    @DataEmissao        DATETIME2,
    @FornecedorCNPJ     CHAR(14),
    @UsuarioCadastro    INT,
    @TabelaItens        TypeTable_EntradaItens READONLY
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @FornecedorId   INT, 
        @UF             CHAR(2) = IIF(SUBSTRING(@ChaveAcesso, 1, 2) = 53,'DF','GO'),
        @EntradaId      INT;

    -- Localiza ou cadastra o fornecedor    
    SELECT @FornecedorId = Id
    FROM Fornecedores 
    WHERE CNPJ = @FornecedorCNPJ;

    IF @FornecedorId IS NULL
    BEGIN
        EXEC dbo.usp_PopularFornecedores 1,@FornecedorCNPJ,@UF;
        SET @FornecedorId = @@IDENTITY;
    END

    -- Insere a cabeçalho da nota
    INSERT INTO dbo.ENTRADAS (NumeroNotaFiscal, Serie, Modelo, ChaveAcesso, DataEmissao, FornecedorId,
                              ValorTotal, ICMS_Total, IPI_Total, PIS_Total, COFINS_Total,
                              Observacoes, UsuarioCadastro)
    SELECT 
        @NumeroNotaFiscal, @Serie, @Modelo, @ChaveAcesso, @DataEmissao, @FornecedorId,
        SUM((I.Quantidade * I.PrecoUnitario) + ((I.Quantidade * I.PrecoUnitario) * 
            (I.ICMS_Aliquota + I.IPI_Aliquota + I.PIS_Aliquota + I.COFINS_Aliquota) / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.ICMS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.IPI_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.PIS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.COFINS_Aliquota / 100)),
        'Entrada gerada automaticamente', @UsuarioCadastro
    FROM @TabelaItens I;

    SET @EntradaId = SCOPE_IDENTITY();

    -- Insere itens da nota
    DECLARE 
        @ICMS_Valor     DECIMAL(10,2),
        @IPI_Valor      DECIMAL(10,2),
        @PIS_Valor      DECIMAL(10,2),
        @COFINS_Valor   DECIMAL(10,2);

    DECLARE cur_TabelaItens CURSOR FOR
        SELECT CodigoProduto,Quantidade,PrecoUnitario,ICMS_Aliquota,IPI_Aliquota,PIS_Aliquota,COFINS_Aliquota
        FROM @TabelaItens;

    DECLARE 
        @CodigoProduto      NVARCHAR(5),
        @Quantidade         INT,
        @PrecoUnitario      DECIMAL(10,2),
        @ICMS_Aliquota      DECIMAL(5,2),
        @IPI_Aliquota       DECIMAL(5,2),
        @PIS_Aliquota       DECIMAL(5,2),
        @COFINS_Aliquota    DECIMAL(5,2);

    OPEN cur_TabelaItens;
    FETCH NEXT FROM cur_TabelaItens INTO 
        @CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@IPI_Aliquota,@PIS_Aliquota,@COFINS_Aliquota;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcula valores de impostos
        SET @ICMS_Valor   = (@PrecoUnitario * @Quantidade) * (@ICMS_Aliquota / 100);
        SET @IPI_Valor    = (@PrecoUnitario * @Quantidade) * (@IPI_Aliquota / 100);
        SET @PIS_Valor    = (@PrecoUnitario * @Quantidade) * (@PIS_Aliquota / 100);
        SET @COFINS_Valor = (@PrecoUnitario * @Quantidade) * (@COFINS_Aliquota / 100);        

        -- Insere item da nota
        INSERT INTO dbo.EntradaItens (EntradaId,CodigoProduto,Quantidade,PrecoUnitario,ICMS_Aliquota,ICMS_Valor,IPI_Aliquota, 
                                  IPI_Valor,PIS_Aliquota,PIS_Valor,COFINS_Aliquota,COFINS_Valor,CustoUnitario)
        VALUES (@EntradaId,@CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@ICMS_Valor,@IPI_Aliquota,@IPI_Valor,
                @PIS_Aliquota, @PIS_Valor, @COFINS_Aliquota, @COFINS_Valor,
                @PrecoUnitario + ((@ICMS_Valor + @IPI_Valor + @PIS_Valor + @COFINS_Valor) / NULLIF(@Quantidade, 0)));
                
        FETCH NEXT FROM cur_TabelaItens INTO 
            @CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@IPI_Aliquota,@PIS_Aliquota,@COFINS_Aliquota;
    END

    CLOSE cur_TabelaItens;
    DEALLOCATE cur_TabelaItens;

    PRINT 'Entrada de nota fiscal registrada com sucesso!';
END;
GO

-- Gera dados para populador de notas
CREATE OR ALTER PROCEDURE dbo.usp_GeraDadosEntradaItens
    @QtdNotas INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- LOOPING COM QUANTIDADE DE NOTAS
    DECLARE 
        @i  INT = 0,
        @j  INT;

    WHILE @i < @QtdNotas
    BEGIN
        SET @j = 0;

        -- GERAR O CABEÇALHO DA NOTA
        DECLARE
            @NumeroNotaFiscal   NVARCHAR(9) = RIGHT('000000000' + CAST(ABS(CHECKSUM(NEWID())) % 999999999 AS VARCHAR(9)), 9),
            @Serie              NVARCHAR(3) = RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 002 + 1 AS VARCHAR(3)), 3),
            @Modelo             NVARCHAR(2) = '55',
            @ChaveAcesso        CHAR(44),
            @DataEmissao        DATETIME2   = DATEADD(DAY, ROUND(RAND() * 305,0), '2025-01-01'),
            @FornecedorCNPJ     CHAR(14),
            @FornecedorUF       CHAR(2),
            @UsuarioCadastro    INT         = 1,
            @QtdProdutos        INT         = ROUND(ABS(CHECKSUM(NEWID())) % 3 + 3 ,0),
            @Itens              TypeTable_EntradaItens;
        
        EXEC dbo.usp_GerarCNPJ @CNPJ = @FornecedorCNPJ OUTPUT;

        DECLARE @Aliquotas TABLE (
            UF              CHAR(2),
            ICMS_Aliquota   DECIMAL(5,2),
            IPI_Aliquota    DECIMAL(5,2),
            PIS_Aliquota    DECIMAL(5,2),
            COFINS_Aliquota DECIMAL(5,2)
        );

        INSERT INTO @Aliquotas VALUES
        ('53',20,0,1.65,7.6),
        ('52',19,0,1.65,7.6);
        
        SELECT @FornecedorUF = UF FROM @Aliquotas ORDER BY NEWID();
       
        -- GERAR CHAVE DE ACESSO
        EXEC dbo.usp_GerarChaveNF 
            @NumeroNotaFiscal,@Serie,@Modelo,@FornecedorCNPJ, @FornecedorUF, @ChaveFinal = @ChaveAcesso OUTPUT;

        WHILE @j < @QtdProdutos
        BEGIN
            -- GERAR OS ITENS DA NOTAS COM IMPOSTOS
            DECLARE
                @CodigoProduto     NVARCHAR(5),
                @Quantidade        INT              = ROUND(ABS(CHECKSUM(NEWID())) % 10 + 1 ,0),
                @PrecoUnitario     DECIMAL(10,2)    = ROUND(ABS(CHECKSUM(NEWID())) % 250 + 8 ,2),
                @ICMS_Aliquota     DECIMAL(5,2),
                @IPI_Aliquota      DECIMAL(5,2),
                @PIS_Aliquota      DECIMAL(5,2),
                @COFINS_Aliquota   DECIMAL(5,2);
                       
            EXEC dbo.usp_GerarCodigoProduto @CODIGO = @CodigoProduto OUTPUT;

            SELECT 
            @ICMS_Aliquota = ICMS_Aliquota, @IPI_Aliquota = IPI_Aliquota, @PIS_Aliquota = PIS_Aliquota, @COFINS_Aliquota = COFINS_Aliquota
            FROM
            @Aliquotas
            WHERE UF = @FornecedorUF;

            INSERT INTO @Itens 
            VALUES(@CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@IPI_Aliquota,@PIS_Aliquota,@COFINS_Aliquota);

            SET @j += 1;

        END;

        -- ENVIA A NOTA PARA POPULADOR
        EXEC dbo.usp_PopulaEntradaItens @NumeroNotaFiscal,@Serie,@Modelo,@ChaveAcesso,@DataEmissao,@FornecedorCNPJ,@UsuarioCadastro,@Itens;

        -- Limpa a tabela de itens
        DELETE FROM @Itens;

        -- FINALIZA LOOPING NOTAS
        SET @i += 1;
    END;
END;
GO

-- Popula a tabela VENDAS e VendaItens
CREATE OR ALTER PROCEDURE dbo.usp_PopulaVendas
    @QtdVendas INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @ClienteId      INT,
        @TotalVenda     DECIMAL(10,2),
        @VendaId        INT,
        @NumeroVenda    INT = 1,
        @ProdutoId      INT,
        @Estoque        INT,
        @ServicoId      INT,
        @Quantidade     INT,
        @PrecoUnitario  DECIMAL(10,2),
        @Itens          TypeTable_VendaItens,
        @QtdItens       INT,
        @i              INT = 0,
        @j              INT;

    BEGIN TRY
        WHILE @i < @QtdVendas
        BEGIN
            BEGIN TRANSACTION;
            -- Gera a quantidade de itens da venda
            SET @QtdItens = ROUND(RAND() * 5 + 1,0);
            SET @j = 0;

            WHILE @j < @QtdItens
            BEGIN
                -- Escolhe um produto ou serviço para adicionar a venda
                IF(ROUND(RAND(), 0) = 1)
                BEGIN
                    -- Seleciona um produto aleatório
                    SELECT TOP 1 
                        @ProdutoId = P.Id, 
                        @Estoque = P.Estoque, 
                        @PrecoUnitario = P.PrecoVenda
                    FROM dbo.PRODUTOS P 
                    WHERE P.Estoque > 0
                    ORDER BY NEWID();

                    -- Ajusta valores
                    SET @Quantidade = ROUND(RAND() * @Estoque + 1, 0);
                    SET @Quantidade = IIF(@Quantidade > @Estoque,@Estoque,@Quantidade);
                    SET @ServicoId = NULL;

                END
                ELSE
                BEGIN
                    -- Seleciona um serviço aleatório
                    SELECT TOP 1 
                        @ServicoId = S.Id,
                        @PrecoUnitario = S.Preco
                    FROM dbo.SERVICOS S
                    ORDER BY NEWID();

                    -- Ajusta valores
                    SET @Quantidade = 1;
                    SET @ProdutoId = NULL;

                END
        
                -- Insere itens na tabela temporaria
                INSERT INTO @Itens VALUES (@ProdutoId,@ServicoId,@Quantidade,@PrecoUnitario);

                SET @j +=1;
            END

            -- Seleciona um cliente aleatório para venda
            SELECT TOP 1 @ClienteId = C.Id FROM dbo.CLIENTES C ORDER BY NEWID();

            -- Calcula o total da venda com base nos itens
            SELECT @TotalVenda = SUM(Quantidade * PrecoUnitario)
            FROM @Itens;

            -- Verfica o numero do ultima venda
            SELECT TOP 1 @NumeroVenda = NumeroVenda + 1
            FROM dbo.VENDAS 
            ORDER BY NumeroVenda DESC;

            -- Insere a venda principal
            INSERT INTO dbo.VENDAS (NumeroVenda, ClienteId, Total)
            VALUES (@NumeroVenda, @ClienteId, ISNULL(@TotalVenda, 0));

            SET @VendaId = SCOPE_IDENTITY();

            -- Insere os itens da venda
            INSERT INTO dbo.VendaItens (VendaId, ProdutoId, ServicoId, Quantidade, PrecoUnitario)
            SELECT 
                @VendaId,
                ProdutoId,
                ServicoId,
                Quantidade,
                PrecoUnitario
            FROM @Itens;

            COMMIT TRANSACTION;
            PRINT 'Venda registrada com sucesso! VendaId = ' + CAST(@VendaId AS NVARCHAR(10));

            DELETE FROM @Itens;
            SET @i += 1;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @Erro NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Erro ao registrar venda: %s', 16, 1, @Erro);
    END CATCH
END;
GO


INSERT INTO PERFIS (Nome, Descricao) 
    VALUES ('Administrador','Usuário master'),
           ('Gerente','Responsável por setores da empresa');

INSERT INTO USUARIOS (Nome, Email, SenhaHash, PerfilId) 
    VALUES ('Administrador','admin@empresa.com',CONVERT(VARBINARY(MAX), 'Master123'),1),
           ('Astolfo','astolfo@empresa.com',CONVERT(VARBINARY(MAX), 'Astolfo123'),2),
           ('Maria','maria@empresa.com',CONVERT(VARBINARY(MAX), 'Maria123'),2);

EXEC dbo.usp_PopulaClientes 50
EXEC dbo.usp_PopularFornecedores 10
EXEC dbo.usp_PopulaProdutos 10
EXEC dbo.usp_PopulaServicos 8
EXEC dbo.usp_GeraDadosEntradaItens 8
EXEC dbo.usp_PopulaVendas 20

UPDATE P SET P.Ativo = 0 FROM PRODUTOS P WHERE P.Id = 25;
UPDATE P SET P.Ativo = 1 FROM PRODUTOS P WHERE P.Id = 25;
UPDATE P SET P.PrecoVenda = 32.50*1.75 FROM PRODUTOS P WHERE P.Id = 25;
UPDATE P SET P.PrecoCompra = 32.50/1.30 FROM PRODUTOS P WHERE P.Id = 25;
UPDATE P SET P.Custo = 32.50 FROM PRODUTOS P WHERE P.Id = 25;
UPDATE P SET P.Estoque = 15 FROM PRODUTOS P WHERE P.Id = 25;

--SELECT * FROM PRODUTOS 
--SELECT * FROM EntradaItens 
--SELECT * FROM ENTRADAS
--SELECT * FROM MOVIMENTACOESESTOQUE
--SELECT * FROM FORNECEDORES
--SELECT * FROM CLIENTES
--SELECT * FROM SERVICOS

-- VENDAS
SELECT * FROM PRODUTOS
SELECT * FROM SERVICOS
SELECT * FROM VENDAS
SELECT * FROM VENDAITENS 
SELECT * FROM MOVIMENTACOESESTOQUE 

SELECT * FROM MOVIMENTACOESESTOQUE WHERE OBSERVACAO LIKE'%VENDA%' ORDER BY CODIGOPRODUTO


SELECT * FROM PRODUTOS WHERE CODIGO = 'CP987'
SELECT * FROM MOVIMENTACOESESTOQUE WHERE CODIGOPRODUTO = 'CP987'
SELECT * FROM SERVICOS
SELECT * FROM VENDAS
SELECT * FROM VENDAITENS WHERE PRODUTOID = 19


--UPDATE P SET P.Estoque = 6 FROM PRODUTOS P WHERE P.Id = 19;
--UPDATE V SET V.Quantidade = 3 FROM VENDAITENS V WHERE V.Id = 10;


--SELECT * FROM PRODUTOS P WHERE P.Id = 10;
--SELECT * FROM MOVIMENTACOESESTOQUE M INNER JOIN PRODUTOS P ON M.CodigoProduto = P.Codigo 
--WHERE P.Id = 25

--DELETE FROM EntradaItens
--DELETE FROM MOVIMENTACOESESTOQUE
--DELETE FROM PRODUTOS
--DELETE FROM ENTRADAS
--DELETE FROM FORNECEDORES

--UPDATE I SET I.Quantidade = 2 FROM EntradaItens I WHERE ID = 796
--DELETE FROM EntradaItens WHERE ID = 783;

--DECLARE @NovoCNPJ CHAR(14);
--EXEC dbo.usp_GerarCNPJ @CNPJ = @NovoCNPJ OUTPUT;
--SELECT @NovoCNPJ AS CNPJGerado;


--SELECT * FROM sys.objects WHERE type = 'P';