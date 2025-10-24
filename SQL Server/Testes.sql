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


DROP TABLE ENTRADAITEM;
DROP TABLE ENTRADA;
DROP TABLE PRODUTO;
CREATE TABLE PRODUTO(ID INT PRIMARY KEY, NOME CHAR(3), VALOR DECIMAL(10,2));
GO

CREATE TABLE ENTRADA(ID INT PRIMARY KEY, NOME CHAR(3), VALOR DECIMAL(10,2));
GO

CREATE TABLE ENTRADAITEM(ID INT PRIMARY KEY, ENTRADAID INT NOT NULL FOREIGN KEY REFERENCES ENTRADA(ID), NOME CHAR(5), VALORUN DECIMAL(10,2));
GO

DECLARE @ID INT;
INSERT INTO PRODUTO (ID, NOME, VALOR) VALUES
(7, 'PR', 10.50);
SELECT TOP 1 @ID = ID FROM PRODUTO ORDER BY ID DESC;
PRINT @@IDENTITY;
INSERT INTO ENTRADA (ID, NOME, VALOR) SELECT ID, NOME, VALOR FROM PRODUTO WHERE ID = SCOPE_IDENTITY();
INSERT INTO ENTRADA (ID, NOME, VALOR) SELECT ID, NOME, VALOR FROM PRODUTO WHERE ID = @@IDENTITY;
INSERT INTO ENTRADA (ID, NOME, VALOR) VALUES (SELECT IDENT_CURRENT(PRODUTO), '', 10.55);
INSERT INTO ENTRADA (ID, NOME, VALOR) SELECT ID, NOME, VALOR FROM PRODUTO WHERE ID = @ID;

(LAST_INSERT_ID(), LAST_INSERT_ID(), LAST_INSERT_ID()),(2, '02', 11.50),(3, '03', 12.50),(4, '04', 13.50),(5, '05', 14.50),(6, '06', 15.50),(7, '07', 16.50),(8, '08', 17.50);
GO
INSERT INTO ENTRADAITEM (ID, ENTRADAID, NOME, VALORUN) VALUES
(1,1,'PRS',10.50),(2, 2,'PAS',11.50),(3,3,'PSS',12.50),(4,4,'PWS',13.50),(5,5,'PQ',14.50),(6,6,'PF',15.50),(7,7,'PV',16.50),(8,8,'PC',17.50);

SELECT * FROM ENTRADAITEM 
WHERE ID NOT IN (SELECT I.ID FROM PRODUTO P INNER JOIN ENTRADAITEM I ON P.NOME = I.NOME)

SELECT * FROM PRODUTO
SELECT * FROM ENTRADA
SELECT * FROM ENTRADAITEM