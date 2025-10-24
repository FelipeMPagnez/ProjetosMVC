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

        SET @cnpj = @base + CAST(@d1 AS CHAR(1)) + CAST(@d2 AS CHAR(1));
                
        IF NOT EXISTS (SELECT 1 FROM dbo.FORNECEDORES WHERE CNPJ = @CNPJ)
            BREAK; -- CNPJ é único → sai do loop
                    
        IF @tentativas > 20
            RETURN
    END;

END;
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
    @FornecedorNome     NVARCHAR(150) = 'Fornecedor',
    @RazaoSocial        NVARCHAR(150) = 'Razao Social',
    @CNPJ               CHAR(14),    
    @Cidade             CHAR(30),
    @UF                 CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @FornecedorId   INT,
        @DDD            CHAR(4),
        @i              INT = 1;

    IF EXISTS (SELECT 1 FROM dbo.FORNECEDORES)
        SELECT @FornecedorId = MAX(Id) FROM dbo.FORNECEDORES;
    ELSE
        SET @FornecedorId = @i;

    WHILE @i <= @QtdFornecedores
    BEGIN
        -- Gera CNPJ único
        IF @CNPJ IS NULL
            SET @CNPJ = dbo.usp_GerarCNPJ();

        -- Lista de cidades com UF e DDD
        DECLARE @Cidades TABLE (Cidade NVARCHAR(50), UF CHAR(2), DDD CHAR(4));
        INSERT INTO @Cidades VALUES
            ('Goiânia','GO','(62)'),('Brasília','DF','(61)');
        
        -- Lista de provedores de e-mail
        DECLARE @ProvedoresEmail TABLE (Provedor NVARCHAR(15));
        INSERT INTO @ProvedoresEmail VALUES
            ('@gmail.com'),('@outlook.com'),('@yahoo.com'),('@icloud.com');
        
        -- atribui valores as variáveis 
        SELECT TOP 1 @Cidade = Cidade, @UF = UF, @DDD = DDD FROM @Cidades ORDER BY NEWID();

        -- Insere fornecedor
        INSERT INTO dbo.FORNECEDORES (NomeFantasia, RazaoSocial, CNPJ, Email, Telefone, Cidade, UF)
        VALUES (
            CONCAT(@FornecedorNome, @FornecedorId),
            CONCAT(@RazaoSocial, @FornecedorId),
            @CNPJ,
            CONCAT('fornecedor', @FornecedorId, (SELECT TOP 1 Provedor FROM @ProvedoresEmail ORDER BY NEWID())),
            CONCAT(@DDD, '9', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999 AS VARCHAR(8)), 8)),
            @Cidade,
            @UF
        );
        
        SET @FornecedorId = SCOPE_IDENTITY();
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

    -- Só cadastra se existe fornecedor para vincular
        IF NOT EXISTS (SELECT TOP 1 FROM dbo.FORNECEDORES)
            PRINT 'Tabela fornecedores vazia.';
            RETURN;

    DECLARE
        @FornecedorId   INT,
        @Produtos       NVARCHAR(30),
        @Estoque        INT,
        @i              INT = 1;

    -- Atribui um valor aleatorio para Fornecedor
    SELECT TOP 1 @FornecedorId = Id FROM dbo.FORNECEDORES ORDER BY NEWID();

    -- Lista Código de produtos por prefixo e sufixo
    DECLARE @PrefixoCodigosProdutos TABLE (Prefixo CHAR(2));
    INSERT INTO @PrefixoCodigosProdutos VALUES
        ('PR'),('CP'),('PC'),('IT'),('DE'),
        ('KP'),('OP'),('RT'),('JF'),('LR');

    DECLARE @SufixoCodigosProdutos TABLE (Sufixo CHAR(3));
    INSERT INTO @SufixoCodigosProdutos VALUES
        ('001'),('138'),('684'),('657'),('987'),('486'),('552'),('342'),('219'),('185'),
        ('163'),('094'),('415'),('875'),('726'),('801'),('749'),('924'),('527'),('386');
    
    DECLARE @UnidadesMedida TABLE (Unidade CHAR(2));
    INSERT INTO @UnidadesMedida VALUES
        ('UN'),('KG'),('CX'),('PC'),('MT'),('LT');

    WHILE @i <= @Quantidade
    BEGIN        
        -- Atribui um novo valor aleatorio para Fornecedor
        IF @Quantidade % 4 = 0
            SELECT TOP 1 @FornecedorId = Id FROM dbo.FORNECEDORES ORDER BY NEWID();

        DECLARE
            @PrefixoCodigo  CHAR(2) = (SELECT TOP 1 * FROM @PrefixoCodigosProdutos ORDER BY NEWID()),
            @SufixoCodigo   CHAR(3) = (SELECT TOP 1 * FROM @SufixoCodigosProdutos  ORDER BY NEWID()),
            @PrecoCompra    DECIMAL(10,2) = ROUND((RAND() * 200) + 10, 2),
            @UN             CHAR(2) = (SELECT TOP 1 * FROM @UnidadesMedida ORDER BY NEWID());
        
        INSERT INTO dbo.PRODUTOS (Codigo,Nome,Descricao,PrecoVenda,PrecoCompra,Custo,Estoque,Unidade,FornecedorId)
        VALUES (
            CONCAT(@PrefixoCodigo,@SufixoCodigo),
            CONCAT('Produto',@PrefixoCodigo,@SufixoCodigo),
            CONCAT('Descrição do Produto',@PrefixoCodigo,@SufixoCodigo),
            @PrecoCompra*1,15*1,75,
            @PrecoCompra,
            @PrecoCompra*1,15,
            ROUND(RAND() * 29 + 1, 0),
            @UN,
            @FornecedorId
        );

        SET @i += 1;            
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_PopulaEntradaItens
    @NumeroNotaFiscal    NVARCHAR(20),
    @Serie               NVARCHAR(10),
    @ChaveAcesso         CHAR(44),
    @DataEmissao         DATETIME2,
    @FornecedorCNPJ      CHAR(14),
    @FornecedorNome      NVARCHAR(150),
    @FornecedorCidade    NVARCHAR(100),
    @FornecedorUF        CHAR(2),
    @UsuarioCadastro     NVARCHAR(100),
    @Itens TABLE
    (
        CodigoProduto     NVARCHAR(5),
        Quantidade        INT,
        PrecoUnitario     DECIMAL(10,2),
        ICMS_Aliquota     DECIMAL(5,2),
        IPI_Aliquota      DECIMAL(5,2),
        PIS_Aliquota      DECIMAL(5,2),
        COFINS_Aliquota   DECIMAL(5,2)
    )
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FornecedorId INT, @EntradaId INT;

    -- Localiza ou cadastra o fornecedor    
    SELECT @FornecedorId = Id 
    FROM Fornecedores 
    WHERE CNPJ = @FornecedorCNPJ;

    IF @FornecedorId IS NULL
    BEGIN
        EXEC dbo.usp_PopularFornecedores(1,@FornecedorNome,@FornecedorNome,@FornecedorCNPJ,@FornecedorCidade,@FornecedorUF);
        SET @FornecedorId = SCOPE_IDENTITY();
    END

    -- Insere a cabeçalho da nota
    INSERT INTO dbo.ENTRADAS (NumeroNotaFiscal, Serie, ChaveAcesso, DataEmissao, FornecedorId,
                              ValorTotal, ICMS_Total, IPI_Total, PIS_Total, COFINS_Total,
                              Observacoes, UsuarioCadastro)
    SELECT 
        @NumeroNotaFiscal, @Serie, @ChaveAcesso, @DataEmissao, @FornecedorId,
        SUM((I.Quantidade * I.PrecoUnitario) + ((I.Quantidade * I.PrecoUnitario) * 
            (I.ICMS_Aliquota + I.IPI_Aliquota + I.PIS_Aliquota + I.COFINS_Aliquota) / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.ICMS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.IPI_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.PIS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.COFINS_Aliquota / 100)),
        'Entrada gerada automaticamente', @UsuarioCadastro
    FROM @Itens AS I;

    SET @EntradaId = SCOPE_IDENTITY();

    -- Insere itens da nota
    DECLARE 
        @ICMS_Valor     DECIMAL(10,2),
        @IPI_Valor      DECIMAL(10,2),
        @PIS_Valor      DECIMAL(10,2),
        @COFINS_Valor   DECIMAL(10,2);

    DECLARE cur_TabelaItens CURSOR FOR
        SELECT CodigoProduto,Quantidade,PrecoUnitario,ICMS_Aliquota,IPI_Aliquota,PIS_Aliquota,COFINS_Aliquota
        FROM @Itens;

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
        INSERT INTO EntradaItens (EntradaId,CodigoProduto,Quantidade,PrecoUnitario,ICMS_Aliquota,ICMS_Valor,IPI_Aliquota, 
                                  IPI_Valor,PIS_Aliquota,PIS_Valor,COFINS_Aliquota,COFINS_Valor,CustoUnitario)
        VALUES (@EntradaId,@CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@ICMS_Valor,@IPI_Aliquota,@IPI_Valor,
                @PIS_Aliquota, @PIS_Valor, @COFINS_Aliquota, @COFINS_Valor,
                @PrecoUnitario + ((@ICMS_Valor + @IPI_Valor + @PIS_Valor + @COFINS_Valor) / NULLIF(@Quantidade, 0)));
                
        FETCH NEXT FROM cur INTO 
            @CodigoProduto,@Quantidade,@PrecoUnitario,@ICMS_Aliquota,@IPI_Aliquota,@PIS_Aliquota,@COFINS_Aliquota;
    END

    CLOSE cur_TabelaItens;
    DEALLOCATE cur_TabelaItens;

    PRINT 'Entrada de nota fiscal registrada com sucesso!';
END;
GO
