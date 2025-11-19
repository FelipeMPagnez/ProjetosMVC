-- Remove tabela anterior, se existir
IF OBJECT_ID('dbo.CLIENTES', 'U') IS NOT NULL
    DROP TABLE dbo.CLIENTES;
GO


-- Criação da tabela
CREATE TABLE CLIENTES (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Nome            NVARCHAR(100) NOT NULL,
    CPF             CHAR(11) NOT NULL UNIQUE,
    DataNascimento  DATE,
    Email           NVARCHAR(150),
    Telefone        VARCHAR(17),
    Logradouro      NVARCHAR(120),
    Numero          NVARCHAR(4),
    Complemento     NVARCHAR(50),
    Bairro          NVARCHAR(80),
    Cidade          NVARCHAR(100) NOT NULL,
    UF              CHAR(2) NOT NULL CHECK (UF IN (
                        'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
                        'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
                    )),
    CEP             VARCHAR(10),
    Historico       NVARCHAR(MAX),
    Ativo           BIT NOT NULL DEFAULT 1,
    DataCadastro    DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE PROCEDURE dbo.usp_GerarCPF
    @CPF CHAR(11) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @rand9 VARCHAR(9),
        @d1 INT, @d2 INT,
        @i INT,
        @sum INT,
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

-- População automática de 100 registros realistas
CREATE or alter PROCEDURE dbo.usp_PopulaClientes
     @Quantidade INT
AS
DECLARE @i INT = 1;
WHILE @i <= @Quantidade
BEGIN
    DECLARE 
        @Nome           NVARCHAR(50),
        @Sobrenome      NVARCHAR(50),
        @CPF            CHAR(11),
        @DataNascimento DATE,
        @Email          NVARCHAR(150),
        @Telefone       VARCHAR(17),
        @Logradouro     NVARCHAR(120),
        @Numero         NVARCHAR(4),
        @Complemento    NVARCHAR(50),
        @Bairro         NVARCHAR(80),
        @Cidade         NVARCHAR(100),
        @UF             CHAR(2),
        @CEP            VARCHAR(10);

    -- Listas de nomes e cidades (poderiam vir de tabelas auxiliares)
    DECLARE @Nomes TABLE (Nome NVARCHAR(50));
    INSERT INTO @Nomes VALUES 
        ('Ana'),('Bruno'),('Carlos'),('Daniela'),('Eduardo'),
        ('Fernanda'),('Gabriel'),('Helena'),('Igor'),('Juliana'),
        ('Karla'),('Lucas'),('Mariana'),('Nicolas'), ('Otávio'),
        ('Patrícia'), ('Quitéria'), ('Rafael'),('Sofia'),('Tiago'),
        ('Ulisses'),('Vitória'),('Xavier'), ('William'), ('Yago'),
        ('Zumira');

    DECLARE @Sobrenomes TABLE (Sobrenome NVARCHAR(50));
    INSERT INTO @Sobrenomes VALUES 
        ('Almeida'),('Borges'),('Campos'),('Duarte'),('Esteves'),
        ('Ferreira'),('Garcia'),('Hernandez'),('Isidoro'),('Jardim'), 
        ('Kennedy'),('Lopes'),('Martins'),('Neves'),('Osório'), 
        ('Pereira'),('Quadros'),('Ramos'),('Silva'),('Teixeira'), 
        ('Urich'),('Vieira'),('Wenceslau'),('Ximenes'),('York'),
        ('Zanetti');

    DECLARE @Cidades TABLE (Cidade NVARCHAR(100), UF CHAR(2), DDD CHAR(4), CEP CHAR(10));
    INSERT INTO @Cidades VALUES
        ('São Paulo','SP','(11)','01.000-000'),('Rio de Janeiro','RJ','(21)','20.000-000'),
        ('Belo Horizonte','MG','(31)','30.000-000'),
        ('Salvador','BA','(71)','40.000-000'),('Fortaleza','CE','(85)','60.000-000'),
        ('Recife','PE','(81)','50.000-000'),
        ('Belém','PA','(91)','66.000-000'),('Porto Velho','RO','(69)','76.800-000'),
        ('Curitiba','PR','(41)','80.000-000'),('Porto Alegre','RS','(51)','90.000-000'),
        ('Goiânia','GO','(62)','74.000-000'),('Brasília','DF','(61)','70.000-000');

    DECLARE @ProvedoresEmail TABLE (Provedor NVARCHAR(20));
    INSERT INTO @ProvedoresEmail VALUES 
        ('@gmail.com'),('@hotmail.com'),('@outlook.com'),('@yahoo.com'),('@icloud.com');

    -- Seleciona valores aleatórios das tabelas temporárias
    SELECT TOP 1 @Nome = Nome FROM @Nomes ORDER BY NEWID();
    SELECT TOP 1 @Sobrenome = Sobrenome FROM @Sobrenomes ORDER BY NEWID();
    SELECT TOP 1 @Cidade = Cidade, @UF = UF , @Telefone = DDD, @CEP = CEP FROM @Cidades ORDER BY NEWID();

    -- Gera data de nascimento aleatória (entre 1970 e 2005)
    SET @DataNascimento = DATEADD(DAY, -1 * (ABS(CHECKSUM(NEWID())) % 20000), GETDATE() - 7300);

    -- Gera e-mail com base no nome
    SET @Email = LOWER(@Nome + '.' + @Sobrenome + CAST(YEAR(@DataNascimento) AS VARCHAR) + 
                        (SELECT TOP 1 Provedor FROM @ProvedoresEmail ORDER BY NEWID()));

    -- Gera telefone aleatório (formato 11 9XXXX-XXXX)
    SET @Telefone += 
        CONCAT('9',
            CAST(1000 + (ABS(CHECKSUM(NEWID())) % 9000) AS VARCHAR(4)),
            '-',
            CAST(1000 + (ABS(CHECKSUM(NEWID())) % 9000) AS VARCHAR(4))
        );

    -- Gera CPF fictício (sem cálculo de dígitos válidos)
    EXEC dbo.usp_GerarCPF @CPF OUTPUT;

    -- Endereço fictício
    SET @Logradouro = CONCAT('Rua ', @Nome);
    SET @Numero = CAST(ABS(CHECKSUM(NEWID())) % 999 AS VARCHAR(4));
    SET @Complemento = CONCAT('Apto ', ABS(CHECKSUM(NEWID())) % 100);
    SET @Bairro = CONCAT('Bairro ', ABS(CHECKSUM(NEWID())) % 200);


    -- Insere o registro    
    INSERT INTO dbo.CLIENTES
        (Nome, CPF, DataNascimento, Email, Telefone,
            Logradouro, Numero, Complemento, Bairro, Cidade,
            UF, CEP)
    VALUES
        (CONCAT(@Nome, ' ', @Sobrenome), @CPF, @DataNascimento, @Email, @Telefone,
            @Logradouro, @Numero, @Complemento, @Bairro, @Cidade, @UF, @CEP);

    SET @i += 1;
END;
GO


EXEC dbo.usp_PopulaClientes @Quantidade = 10000;
-- Verifica os dados inseridos
SELECT * FROM dbo.CLIENTES ORDER BY CPF;

SELECT NOME, COUNT(NOME) AS QUANTIDADE
FROM CLIENTES
GROUP BY NOME
HAVING COUNT(NOME) > 1
ORDER BY NOME


DECLARE @data DATE = '2025-10-16';
SELECT CAST(YEAR(@data) AS VARCHAR) AS AnoEmString;
GO

---------------------------
DROP TABLE ENTRADAITEM;
DROP TABLE INSERTEDITEM;
DROP TABLE DELETEDITEM;
DROP TABLE ENTRADA;
DROP TABLE PRODUTO;


CREATE TABLE PRODUTO(ID INT IDENTITY PRIMARY KEY, NOME CHAR(3), VALOR DECIMAL(10,2), QTD INT);

CREATE TABLE ENTRADA(ID INT PRIMARY KEY, NOME CHAR(3), VALOR DECIMAL(10,2));

CREATE TABLE ENTRADAITEM(ID INT PRIMARY KEY, ENTRADAID INT NOT NULL FOREIGN KEY REFERENCES ENTRADA(ID), NOME CHAR(5), VALORUN DECIMAL(10,2), QTD INT);

CREATE TABLE INSERTEDITEM(ID INT PRIMARY KEY, INSERTEDID INT NOT NULL FOREIGN KEY REFERENCES ENTRADA(ID), NOME CHAR(5), VALORUN DECIMAL(10,2), QTD INT);

CREATE TABLE DELETEDITEM(ID INT PRIMARY KEY, DELETEDID INT NOT NULL FOREIGN KEY REFERENCES ENTRADA(ID), NOME CHAR(5), VALORUN DECIMAL(10,2), QTD INT);


--INSERT INTO PRODUTO (NOME, VALOR,QTD) VALUES
--('PR',10.50,5),('PA',11.50,6),('PS',12.50,7),('PW',13.50,8),('PQ',14.50,9),('PF',15.50,10),('PV',16.50,11),('PC',17.50,12);
INSERT INTO ENTRADA (ID, NOME, VALOR) VALUES
(1,'01',10.50),(2, '02', 11.50),(3, '03', 12.50),(4, '04', 13.50),(5, '05', 14.50),(6, '06', 15.50),(7, '07', 16.50),(8, '08', 17.50);
INSERT INTO ENTRADAITEM (ID, ENTRADAID, NOME, VALORUN, QTD) VALUES
(1,1,'PRS',10.50,2),(2, 2,'PAS',11.50,3),(7,7,'PV',16.50,8),(8,8,'PC',17.50,9);
INSERT INTO INSERTEDITEM (ID, INSERTEDID, NOME, VALORUN,QTD) VALUES
(1,1,'PRS',10.50,2),(2, 2,'PAS',11.50,3),(7,7,'PV',16.50,8),(8,8,'PC',17.50,9);
INSERT INTO DELETEDITEM (ID, DELETEDID, NOME, VALORUN,QTD) VALUES
(6,6,'PF',15.50,7),(7,7,'PV',16.50,8);


SELECT * FROM PRODUTO
SELECT * FROM ENTRADA
SELECT * FROM ENTRADAITEM
SELECT * FROM INSERTEDITEM
SELECT * FROM DELETEDITEM
GO

DECLARE @NP TABLE (ID INT);
DECLARE CUR CURSOR FOR
    SELECT I.NOME, I.VALORUN, I.QTD FROM INSERTEDITEM I
    WHERE ID NOT IN (SELECT I.ID FROM PRODUTO P INNER JOIN INSERTEDITEM I ON P.NOME = I.NOME);

DECLARE @NOME CHAR(5),@VALORUN DECIMAL(10,2),@QTD INT, @ID INT;

OPEN CUR;
FETCH NEXT FROM CUR INTO @NOME,@VALORUN,@QTD

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO PRODUTO(NOME,VALOR,QTD) VALUES (@NOME,@VALORUN,@QTD);
    SET @ID = SCOPE_IDENTITY();
    INSERT INTO @NP VALUES (@ID);
    
    FETCH NEXT FROM CUR INTO @NOME,@VALORUN,@QTD
END

CLOSE CUR;
DEALLOCATE CUR;
SELECT * FROM @NP;
SELECT * FROM PRODUTO;
GO

UPDATE P
SET QTD += ISNULL(I.QTD,0) - ISNULL(D.QTD,0)
FROM PRODUTO P
FULL JOIN INSERTEDITEM I ON P.NOME = I.NOME
FULL JOIN DELETEDITEM  D ON P.NOME = D.NOME
WHERE 
(ISNULL(I.QTD,0) <> ISNULL(D.QTD,0) OR ISNULL(I.VALORUN,0) <> ISNULL(D.VALORUN,0))
AND P.ID NOT IN(SELECT N.ID FROM @NP N);
SELECT *
FROM PRODUTO P 
FULL JOIN INSERTEDITEM I ON P.NOME = I.NOME 
FULL JOIN DELETEDITEM D ON P.NOME = D.NOME 
WHERE (ISNULL(I.QTD,0) <> ISNULL(D.QTD,0) OR ISNULL(I.VALORUN,0) <> ISNULL(D.VALORUN,0)) AND P.ID NOT IN(9,10);
SELECT *
FROM INSERTEDITEM I
FULL JOIN DELETEDITEM D ON I.NOME = D.NOME 
WHERE (ISNULL(I.QTD,0) <> ISNULL(D.QTD,0) OR ISNULL(I.VALORUN,0) <> ISNULL(D.VALORUN,0)) AND P.ID NOT IN(9,10);

SELECT MAX(ID) FROM PRODUTO
SELECT * FROM ENTRADA
SELECT * FROM ENTRADAITEM
GO

--DECLARE @ChaveSemDV NVARCHAR(43) = 
--        CONVERT(NVARCHAR,RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 9999999999 AS VARCHAR(10)), 10)) +
--        CONVERT(NVARCHAR,RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 9999999999 AS VARCHAR(10)), 10)) +
--        CONVERT(NVARCHAR,RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 9999999999 AS VARCHAR(10)), 10)) +
--        CONVERT(NVARCHAR,RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 9999999999 AS VARCHAR(10)), 10)) +
--        CONVERT(NVARCHAR,RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 999 AS VARCHAR(3)), 3)),
--        @i INT = 43, @Peso INT = 2, @Soma INT = 0, @DV INT, @RESTO INT;
--PRINT @ChaveSemDV;
--PRINT SUBSTRING(@ChaveSemDV,1,2);
--WHILE @i > 0
--BEGIN
--    SET @Soma += (SUBSTRING(@ChaveSemDV, @i, 1) * @Peso);
--    SET @Peso = CASE WHEN @Peso = 9 THEN 2 ELSE @Peso + 1 END;
--    SET @i -= 1;
--END
--PRINT @Soma;
--SET @Resto = @Soma % 11;
--SET @DV = CASE WHEN @Resto = 0 OR @Resto = 1 THEN 0 ELSE 11 - @Resto END;
--PRINT @DV


--SELECT CONVERT(VARCHAR(43), CRYPT_GEN_RANDOM(32), 2);


--DECLARE @DataInicial DATE;
--DECLARE @DataFinal DATE;

---- Define o período
--SELECT '2019-01-01', '2021-12-31';

---- Seleciona a data aleatória
--SELECT DATEADD(DAY, ROUND(RAND() * 305,0), '2025-01-01') AS DataEmissaoAleatoria;
--GO


EXEC dbo.usp_GeraDadosEntradaItens 1
EXEC dbo.usp_PopulaProdutos 2

SELECT * FROM USUARIOS
SELECT * FROM ENTRADAS
SELECT * FROM EntradaItens --WHERE CodigoProduto = 'DE552' ORDER BY CodigoProduto
SELECT * FROM PRODUTOS WHERE Codigo = 'JF386' ORDER BY Codigo
SELECT * FROM MOVIMENTACOESESTOQUE WHERE CodigoProduto = 'JF386' ORDER BY CodigoProduto
SELECT * FROM FORNECEDORES

DELETE FROM PRODUTOS
DELETE FROM EntradaItens
DELETE FROM MOVIMENTACOESESTOQUE
DELETE FROM ENTRADAS
DELETE FROM FORNECEDORES

UPDATE P SET P.Ativo = 0 FROM PRODUTOS P WHERE P.Codigo = 'JF386';
UPDATE P SET P.Ativo = 1 FROM PRODUTOS P WHERE P.Codigo = 'JF386';
UPDATE P SET P.PrecoVenda = 32.50*1.75 FROM PRODUTOS P WHERE P.Codigo = 'JF386';
UPDATE P SET P.PrecoCompra = 32.50/1.30 FROM PRODUTOS P WHERE P.Codigo = 'JF386';
UPDATE P SET P.Custo = 32.50 FROM PRODUTOS P WHERE P.Codigo = 'JF386';
UPDATE P SET P.Estoque = 15 FROM PRODUTOS P WHERE P.Codigo = 'JF386';

INSERT INTO PERFIS (Nome, Descricao) 
    VALUES ('Administrador','Usuário master'),
           ('Gerente','Responsável por setores da empresa');

INSERT INTO USUARIOS (Nome, Email, SenhaHash, PerfilId) 
    VALUES ('Administrador','admin@empresa.com',CONVERT(VARBINARY(MAX), 'Master123'),1),
           ('Astolfo','astolfo@empresa.com',CONVERT(VARBINARY(MAX), 'Astolfo123'),2),
           ('Maria','maria@empresa.com',CONVERT(VARBINARY(MAX), 'Maria123'),2);

SELECT * FROM PERFIS;
SELECT * FROM USUARIOS;
SELECT CONVERT(VARCHAR(MAX),SenhaHash) FROM USUARIOS

USE master;



IF(ROUND(RAND(), 0) = 1)
PRINT 'TRUE'
ELSE
PRINT'FALSE'

SELECT CAST(ROUND(RAND(), 0) AS BIT) AS RandomBoolean;


WITH MovimentacoesOrdenadas AS (
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
                WHEN ME.TipoMovimentacao = 'E' THEN ME.Quantidade
                WHEN ME.TipoMovimentacao = 'S' THEN -ME.Quantidade
                WHEN ME.TipoMovimentacao = 'A' THEN ME.Quantidade
                ELSE 0
            END,
            ROW_NUMBER() OVER (PARTITION BY ME.CodigoProduto ORDER BY ME.DataMovimentacao, ME.Id) AS OrdemProduto
        FROM dbo.MOVIMENTACOESESTOQUE ME 
        INNER JOIN dbo.VENDAS V ON ME.DocumentoId = V.Id
        LEFT JOIN dbo.USUARIOS U ON ME.UsuarioMovimentacao = U.Id
        WHERE V.NumeroVenda = 154 and ME.Observacao LIKE '%venda%'
    )
    SELECT 
        M.Id,
        M.TipoMovimentacao,
        CASE 
            WHEN M.TipoMovimentacao = 'E' THEN 'Entrada'
            WHEN M.TipoMovimentacao = 'S' THEN 'Saída'
            WHEN M.TipoMovimentacao = 'A' THEN 'Ajuste'
            ELSE 'Desconhecido'
        END AS DescricaoMovimentacao,
        M.CodigoProduto,
        M.NomeProduto,
        M.Quantidade,
        SaldoAcumulado = SUM(M.ImpactoEstoque) OVER (
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
        M.DataMovimentacao
    FROM MovimentacoesOrdenadas M
    ORDER BY M.CodigoProduto, M.DataMovimentacao, M.Id


UPDATE VENDAS
SET NUMEROVENDA = 154
WHERE ID = 4

UPDATE MOVIMENTACOESESTOQUE
SET OBSERVACAO = 'Inclusão do produto na venda nº 154'
WHERE ID = 48

SELECT * FROM VENDAS