DROP DATABASE Treinamento;
GO

CREATE DATABASE Treinamento;
GO

USE Treinamento;
GO

-- Cria algumas tabelas para o projeto inicial
CREATE TABLE PERFIS (
    Id          INT IDENTITY PRIMARY KEY,
    Nome        NVARCHAR(50) NOT NULL UNIQUE,
    Descricao   NVARCHAR(200)
);
GO

CREATE TABLE USUARIOS (
    Id              INT IDENTITY PRIMARY KEY,
    Nome            NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(150) NOT NULL UNIQUE,
    SenhaHash       VARBINARY(256) NOT NULL,
    PerfilId        INT NOT NULL FOREIGN KEY REFERENCES Perfis(Id),
    Ativo           BIT NOT NULL DEFAULT 1,
    DataCadastro    DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE FUNCIONARIOS (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,                            
    Nome                NVARCHAR(100) NOT NULL,                             
    CPF                 CHAR(11) NOT NULL UNIQUE,
    DataNascimento      DATE NOT NULL CHECK (DataNascimento <= GETDATE()),                
    Email               NVARCHAR(120),                                     
    Telefone            VARCHAR(17),                                    
    Cargo               NVARCHAR(80) NOT NULL,                             
    Departamento        NVARCHAR(80) NOT NULL,                      
    Salario             DECIMAL(10,2) CHECK (Salario >= 0),                  
    DataAdmissao        DATE NOT NULL DEFAULT GETDATE(),            
    DataDemissao        DATE NULL,                                                             
    Ativo               BIT NOT NULL DEFAULT 1,                            
    Observacoes         NVARCHAR(500),                                   
    UF                  CHAR(2) NOT NULL CHECK (UF IN (                      
                            'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
                            'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
                        )),
    CEP                 CHAR(10),                                             
    Cidade              NVARCHAR(100) NOT NULL,
    Logradouro          NVARCHAR(120),
    Numero              NVARCHAR(10),
    Complemento         NVARCHAR(50),
    Bairro              NVARCHAR(80),
    DataCadastro        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),   
    UltimaAtualizacao   DATETIME2 NOT NULL DEFAULT SYSDATETIME() 
);
GO

CREATE TABLE CLIENTES (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Nome            NVARCHAR(100) NOT NULL,
    CPF             CHAR(11) NOT NULL UNIQUE,
    DataNascimento  DATE,
    Email           NVARCHAR(150),
    Telefone        VARCHAR(17),
    Logradouro      NVARCHAR(120),
    Numero          NVARCHAR(10),
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

CREATE TABLE FORNECEDORES (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    NomeFantasia    NVARCHAR(150) NOT NULL,
    RazaoSocial     NVARCHAR(150),
    CNPJ            CHAR(14) UNIQUE NOT NULL,
    Email           NVARCHAR(120),
    Telefone        VARCHAR(17),
    Cidade          NVARCHAR(100),
    UF              CHAR(2) CHECK (UF IN (
                    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
                    'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
                    )),
    DataCadastro    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Ativo           BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE PRODUTOS (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Codigo          VARCHAR(5) UNIQUE NOT NULL,
    Nome            NVARCHAR(80) NOT NULL,
    Descricao       NVARCHAR(150),
    Preco           DECIMAL(10,2) NOT NULL CHECK (Preco >= 0),
    Estoque         INT NOT NULL DEFAULT 0 CHECK (Estoque >= 0),
    Unidade         CHAR(2) NOT NULL, 
    FornecedorId    INT NOT NULL FOREIGN KEY REFERENCES Fornecedores(Id),
    DataCadastro    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Ativo           BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE MOVIMENTACAOESTOQUE(
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    TipoMovimentacao    NVARCHAR(20) NOT NULL,
    CodigoProduto       NVARCHAR(5) NOT NULL,
    NomeProduto         NVARCHAR(80) NOT NULL,
    Quantidade,
    Preco,
    ValorVendido,
    ValorCompra,
    OV, 
    DataMovimentacao,
);
GO

CREATE TABLE SERVICOS (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Nome            NVARCHAR(150) NOT NULL,
    Descricao       NVARCHAR(500),
    Preco           DECIMAL(10,2) NOT NULL CHECK (Preco >= 0),
    DataCadastro    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Ativo           BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE VENDAS (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    ClienteId   INT NULL,
    DataVenda   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Total       DECIMAL(12,2) NOT NULL CHECK (Total >= 0),
    Estatus     NVARCHAR(50) NOT NULL DEFAULT 'Aberta'
);
GO

CREATE TABLE VendaItens (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    VendaId         INT NOT NULL,
    ProdutoId       INT NULL,
    ServicoId       INT NULL,
    Quantidade      DECIMAL(10,2) DEFAULT 1 CHECK (Quantidade > 0),
    PrecoUnitario   DECIMAL(12,2) NOT NULL CHECK (PrecoUnitario >= 0),
    Total           AS (PrecoUnitario * Quantidade) PERSISTED,
    CONSTRAINT FK_VendaItens_Vendas   FOREIGN KEY (VendaId)   REFERENCES Vendas(Id),
    CONSTRAINT FK_VendaItens_Produtos FOREIGN KEY (ProdutoId) REFERENCES Produtos(Id),
    CONSTRAINT FK_VendaItens_Servicos FOREIGN KEY (ServicoId) REFERENCES Servicos(Id)
);
GO

CREATE TABLE FORMASPAGAMENTO (
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Nome    NVARCHAR(50) NOT NULL UNIQUE,
    Tipo    NVARCHAR(20) NOT NULL,
    Ativo   BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE MOVIMENTACOESFINANCEIRAS (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    VendaId             INT NULL FOREIGN KEY REFERENCES Vendas(Id),
    TipoMovimentacacao  NVARCHAR(10) NOT NULL CHECK (TipoMovimentacacao IN ('Entrada', 'Saida')),
    Valor               DECIMAL(12,2) NOT NULL CHECK (Valor >= 0),
    FormaPagamentoId    INT NULL FOREIGN KEY REFERENCES FormasPagamento(Id),
    DataMovimento       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Observacao          NVARCHAR(500)
);
GO

-- Cria indices para tabelas
CREATE INDEX IX_Produtos_Nome ON Produtos(Nome);
CREATE INDEX IX_Produtos_FornecedorId ON Produtos(FornecedorId);
GO

CREATE INDEX IX_Servicos_Nome ON Servicos(Nome);
GO

CREATE INDEX IX_Vendas_DataVenda ON Vendas(DataVenda);
GO

CREATE INDEX IX_VendaItens_VendaId ON VendaItens(VendaId);
CREATE INDEX IX_VendaItens_ProdutoId ON VendaItens(ProdutoId);
CREATE INDEX IX_VendaItens_ServicoId ON VendaItens(ServicoId);
GO