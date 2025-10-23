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
        IF NOT EXISTS (SELECT 1 FROM dbo.FORNECEDORES)
            PRINT('Tabela fornecedores vazia.');
            RETURN;

    DECLARE
        @Produtos   NVARCHAR(30),
        @Estoque    INT,
        @i          INT = 1;

    DECLARE @ProdutosTemp TABLE (
            Codigo          VARCHAR(5),
            Nome            NVARCHAR(80),
            Descricao       NVARCHAR(150),
            Preco           DECIMAL(10,2),
            Estoque         INT,
            Unidade         CHAR(2), 
            FornecedorId    INT);

    INSERT INTO @ProdutosTemp VALUES
        ('P001', 'Caderno Espiral 100 Folhas', 'Caderno de espiral com capa dura, 100 folhas pautadas.', 12.50, 'UN'),
        ('P002', 'Caneta Esferográfica Azul', 'Caneta esferográfica azul com corpo de plástico.', 1.80, 'UN'),
        ('P003', 'Lápis Preto HB', 'Lápis preto HB com ponta de alta qualidade.', 0.50, 'UN'),
        ('P004', 'Borracha Branca', 'Borracha branca macia para apagar lápis.', 0.30, 'UN'),
        ('P005', 'Caderno Argolado 200 Folhas', 'Caderno argolado com 200 folhas pautadas.', 20.00, 'UN'),
        ('P006', 'Estojos de Plástico', 'Estojo de plástico resistente para lápis e canetas.', 8.00, 'UN'),
        ('P007', 'Marcador de Quadro Branco', 'Marcador de ponta fina para quadro branco.', 3.50, 'UN'),
        ('P008', 'Papel A4 500 Folhas', 'Papel sulfite A4, 75g, pacote com 500 folhas.', 15.00, 'pacote'),
        ('P009', 'Tesoura Escolar', 'Tesoura de plástico e aço com ponta afiada.', 4.00, 'UN'),
        ('P010', 'Calculadora Simples', 'Calculadora básica de 8 dígitos.', 25.00, 'UN');

    WHILE 1 <= @Quantidade
    BEGIN
        
        
        DECLARE @Produtos
        
       -- SET @NomeProduto = CONCAT('Produto ', @i);

            INSERT INTO Produtos (Nome, Descricao, Preco, Estoque, Unidade, FornecedorId)
            VALUES (
                @NomeProduto,
                CONCAT('Descrição do ', @NomeProduto),
                ROUND((RAND() * 500) + 10, 2),
                (ABS(CHECKSUM(NEWID())) % 100) + 1,
                'UN',
                @FornecedorId
            );

            --SET @j += 1;
            
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GerarEntradaGenerica
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
        NomeProduto       NVARCHAR(80),
        Descricao         NVARCHAR(150),
        Unidade           CHAR(2),
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

    -------------------------------------------------------------
    -- 1️⃣ LOCALIZA OU CADASTRA O FORNECEDOR
    -------------------------------------------------------------
    SELECT @FornecedorId = Id 
    FROM Fornecedores 
    WHERE CNPJ = @FornecedorCNPJ;

    IF @FornecedorId IS NULL
    BEGIN
        EXEC dbo.usp_PopularFornecedores(1,@FornecedorNome,@FornecedorNome,@FornecedorCNPJ,@FornecedorCidade,@FornecedorUF);
        SET @FornecedorId = SCOPE_IDENTITY();
    END

    -------------------------------------------------------------
    -- 2️⃣ INSERE A CABEÇA DA NOTA (TABELA ENTRADAS)
    -------------------------------------------------------------
    INSERT INTO dbo.ENTRADAS (NumeroNotaFiscal, Serie, ChaveAcesso, DataEmissao, FornecedorId,
                              ValorTotal, ICMS_Total, IPI_Total, PIS_Total, COFINS_Total,
                              Observacoes, UsuarioCadastro, Ativo)
    SELECT 
        @NumeroNotaFiscal, @Serie, @ChaveAcesso, @DataEmissao, @FornecedorId,
        SUM((I.Quantidade * I.PrecoUnitario) + ((I.Quantidade * I.PrecoUnitario) * 
            (I.ICMS_Aliquota + I.IPI_Aliquota + I.PIS_Aliquota + I.COFINS_Aliquota) / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.ICMS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.IPI_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.PIS_Aliquota / 100)),
        SUM((I.Quantidade * I.PrecoUnitario) * (I.COFINS_Aliquota / 100)),
        'Entrada gerada automaticamente', @UsuarioCadastro, 1
    FROM @Itens AS I;

    SET @EntradaId = SCOPE_IDENTITY();

    -------------------------------------------------------------
    -- 3️⃣ INSERE ITENS E CRIA PRODUTOS SE NÃO EXISTIREM
    -------------------------------------------------------------
    DECLARE @ProdutoId INT, 
            @ICMS_Valor DECIMAL(10,2),
            @IPI_Valor DECIMAL(10,2),
            @PIS_Valor DECIMAL(10,2),
            @COFINS_Valor DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT NomeProduto, Descricao, Unidade, Quantidade, PrecoUnitario, 
               ICMS_Aliquota, IPI_Aliquota, PIS_Aliquota, COFINS_Aliquota
        FROM @Itens;

    DECLARE 
        @NomeProduto NVARCHAR(80),
        @Descricao NVARCHAR(150),
        @Unidade CHAR(2),
        @Quantidade INT,
        @PrecoUnitario DECIMAL(10,2),
        @ICMS_Aliquota DECIMAL(5,2),
        @IPI_Aliquota DECIMAL(5,2),
        @PIS_Aliquota DECIMAL(5,2),
        @COFINS_Aliquota DECIMAL(5,2);

    OPEN cur;
    FETCH NEXT FROM cur INTO 
        @NomeProduto, @Descricao, @Unidade, @Quantidade, @PrecoUnitario,
        @ICMS_Aliquota, @IPI_Aliquota, @PIS_Aliquota, @COFINS_Aliquota;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcula valores de impostos
        SET @ICMS_Valor   = (@PrecoUnitario * @Quantidade) * (@ICMS_Aliquota / 100);
        SET @IPI_Valor    = (@PrecoUnitario * @Quantidade) * (@IPI_Aliquota / 100);
        SET @PIS_Valor    = (@PrecoUnitario * @Quantidade) * (@PIS_Aliquota / 100);
        SET @COFINS_Valor = (@PrecoUnitario * @Quantidade) * (@COFINS_Aliquota / 100);

        -----------------------------------------------------
        -- Verifica se o produto já existe
        -----------------------------------------------------
        SELECT @ProdutoId = Id FROM Produtos WHERE Nome = @NomeProduto;

        IF @ProdutoId IS NULL
        BEGIN
            INSERT INTO Produtos (Codigo, Nome, Descricao, Preco, PrecoCompra, Custo, Estoque, Unidade, FornecedorId)
            VALUES (
                RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 99999 AS VARCHAR(5)), 5),
                @NomeProduto, @Descricao,
                @PrecoUnitario, @PrecoUnitario, 
                @PrecoUnitario + ((@ICMS_Valor + @IPI_Valor + @PIS_Valor + @COFINS_Valor) / NULLIF(@Quantidade, 0)),
                @Quantidade, @Unidade, @FornecedorId
            );

            SET @ProdutoId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE Produtos
            SET Estoque = Estoque + @Quantidade,
                PrecoCompra = @PrecoUnitario,
                Custo = @PrecoUnitario + ((@ICMS_Valor + @IPI_Valor + @PIS_Valor + @COFINS_Valor) / NULLIF(@Quantidade, 0))
            WHERE Id = @ProdutoId;
        END

        -----------------------------------------------------
        -- Insere item da nota
        -----------------------------------------------------
        INSERT INTO EntradaItens (
            EntradaId, ProdutoId, Quantidade, PrecoUnitario,
            ICMS_Aliquota, ICMS_Valor, IPI_Aliquota, IPI_Valor,
            PIS_Aliquota, PIS_Valor, COFINS_Aliquota, COFINS_Valor, 
            CustoUnitario
        )
        VALUES (
            @EntradaId, @ProdutoId, @Quantidade, @PrecoUnitario,
            @ICMS_Aliquota, @ICMS_Valor, @IPI_Aliquota, @IPI_Valor,
            @PIS_Aliquota, @PIS_Valor, @COFINS_Aliquota, @COFINS_Valor,
            @PrecoUnitario + ((@ICMS_Valor + @IPI_Valor + @PIS_Valor + @COFINS_Valor) / NULLIF(@Quantidade, 0))
        );

        FETCH NEXT FROM cur INTO 
            @NomeProduto, @Descricao, @Unidade, @Quantidade, @PrecoUnitario,
            @ICMS_Aliquota, @IPI_Aliquota, @PIS_Aliquota, @COFINS_Aliquota;
    END

    CLOSE cur;
    DEALLOCATE cur;

    PRINT 'Entrada de nota fiscal registrada com sucesso!';
END;
GO
