USE Treinamento;
GO

-- Gera movimentações de estoque conforme movimentações venda
CREATE OR ALTER TRIGGER trg_AtualizaEstoqueVendaItens
ON VendaItens
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Atualiza estoque após alteração na venda(UPDATE)
    IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS (SELECT 1 FROM Deleted)
    BEGIN
        -- Atualiza o estoque dos PRODUTOS para alteração de quantidade ou exclusão
        UPDATE P
        SET P.Estoque = 
            CASE
                WHEN D.ProdutoId = I.ProdutoId THEN P.Estoque + (ISNULL(D.Quantidade,0) - ISNULL(I.Quantidade,0))
                WHEN D.ProdutoId IS NULL AND I.ProdutoId IS NOT NULL THEN P.Estoque - ISNULL(I.Quantidade,0)
                WHEN D.ProdutoId IS NOT NULL AND I.ProdutoId IS NULL THEN P.Estoque + ISNULL(D.Quantidade,0)
                ELSE P.Estoque
            END
        FROM Produtos P
        FULL JOIN Inserted I ON P.Id = I.ProdutoId
        FULL JOIN Deleted D  ON P.Id = D.ProdutoId;
        
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                              PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
        SELECT 
            CASE 
                WHEN ISNULL(D.Quantidade,0) > ISNULL(I.Quantidade,0) THEN 'E'
                WHEN ISNULL(D.Quantidade,0) < ISNULL(I.Quantidade,0) THEN 'S'
            END AS TipoMovimentacao,
            P.Codigo,
            P.Nome,
            ABS(ISNULL(D.Quantidade,0) - ISNULL(I.Quantidade,0)) AS Quantidade,
            P.PrecoVenda,
            I.PrecoUnitario,
            P.Custo,
            I.VendaId,
            'Atualização do produto na venda nº ' + CAST(I.VendaId AS VARCHAR),
            1
        FROM 
            Deleted D
            FULL JOIN Inserted I ON I.Id = D.Id
            FULL JOIN PRODUTOS P ON D.ProdutoId = P.Id OR I.ProdutoId = P.Id
        WHERE D.Quantidade <> I.Quantidade OR D.PrecoUnitario <> I.PrecoUnitario;

        RETURN;
    END;

    -- Reduz estoque ao inserir um item de venda
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- Atualiza a tabela PRODUTOS
        UPDATE P
        SET P.Estoque = P.Estoque - I.Quantidade
        FROM Produtos P
        INNER JOIN inserted I ON P.Id = I.ProdutoId;

        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                              PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
        SELECT 
            'S',
            P.Codigo,
            P.Nome,
            I.Quantidade,
            P.PrecoVenda,
            I.PrecoUnitario,
            P.Custo,
            I.VendaId,
            'Inclusão do produto na venda nº ' + CAST(I.VendaId AS VARCHAR),
            1
        FROM 
            Inserted I
            INNER JOIN PRODUTOS P ON I.ProdutoId = P.Id;

        RETURN;
    END

    -- Retorna estoque ao deletar um item de venda (ex: cancelamento)
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Atualiza a tabela PRODUTOS
        UPDATE P
        SET P.Estoque = P.Estoque + D.Quantidade
        FROM Produtos P
        INNER JOIN deleted D ON P.Id = D.ProdutoId;

        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                              PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
        SELECT 
            'E',
            P.Codigo,
            P.Nome,
            D.Quantidade,
            P.PrecoVenda,
            D.PrecoUnitario,
            P.Custo,
            D.VendaId,
            'Exclusão do produto na venda nº ' + CAST(D.VendaId AS VARCHAR),
            1
        FROM 
            Deleted D
            INNER JOIN PRODUTOS P ON D.ProdutoId = P.Id;

        RETURN;
    END;
END;
GO

-- Gera movimentações de estoque ajuste manual
CREATE OR ALTER TRIGGER trg_AtualizaMovimentacoesEstoqueEntradaManual
ON PRODUTOS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Sai da trigger se foi acionado por outra trigger
    IF(TRIGGER_NESTLEVEL() > 1) RETURN;

    -- Alteração manual de um produto(UPDATE)
    IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS (SELECT 1 FROM Deleted)
    BEGIN
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                              PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
        SELECT 
            'A',
            I.Codigo,
            I.Nome,
            ABS(ISNULL(I.Estoque,0) - ISNULL(D.Estoque,0)) AS Quantidade,
            I.PrecoVenda,
            0,
            I.Custo,
            NULL,
            CASE
                WHEN i.Ativo = 0 AND I.Ativo <> D.Ativo THEN 'Ajuste manual do produto, produto inativado'
                WHEN i.Ativo = 1 AND I.Ativo <> D.Ativo THEN 'Ajuste manual do produto, produto ativado'
                WHEN ISNULL(I.Estoque,0) <> ISNULL(D.Estoque,0) THEN 'Ajuste manual do produto, ajuste de estoque'
                WHEN ISNULL(I.PrecoVenda,0) <> ISNULL(D.PrecoVenda,0) THEN 'Ajuste manual do produto, correção no preço de venda'
                WHEN ISNULL(I.PrecoCompra,0) <> ISNULL(D.PrecoCompra,0) THEN 'Ajuste manual do produto, correção no preço de compra'
                WHEN ISNULL(I.Custo,0) <> ISNULL(D.Custo,0) THEN 'Ajuste manual do produto, correção no valor do custo'
            END AS Observacao,
            1
        FROM Deleted D
        FULL JOIN Inserted I ON I.Id = D.Id
        WHERE 
        D.Estoque <> I.Estoque OR D.PrecoVenda <> I.PrecoVenda OR D.PrecoCompra <> I.PrecoCompra OR D.Custo <> I.Custo OR D.Ativo <> I.Ativo;
    END

    -- Inclusão manual de novo produto(INSERT)
    IF EXISTS (SELECT 1 FROM Inserted) AND NOT EXISTS (SELECT 1 FROM Deleted)
    BEGIN
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                              PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
        SELECT 
            'A',
            I.Codigo,
            I.Nome,
            I.Estoque,
            I.PrecoVenda,
            0,
            I.Custo,
            NULL,
            'Inclusão manual do produto',
            1
        FROM Inserted I
    END

END;
GO

-- Gera movimentações de estoque para entrada de produto via NF
CREATE OR ALTER TRIGGER trg_AtualizaEstoqueEntradaNF
ON EntradaItens
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE 
            @ProdutoId          INT,
            @CodigoProduto      NVARCHAR(5),
            @Quantidade         INT,
            @PrecoUnitario      DECIMAL(10,2),
            @CustoUnitario      DECIMAL(10,2),
            @EntradaID          INT,
            @NumeroNotaFiscal   INT;

        DECLARE @NovosProdutos TABLE(Id INT);

        -- Inclui produtos novos na tabela PRODUTOS
        DECLARE cur_ItensInseridos CURSOR FOR
            SELECT 
            I.CodigoProduto, I.Quantidade, I.PrecoUnitario, I.CustoUnitario, 
            I.EntradaId, E.NumeroNotaFiscal
            FROM Inserted I
            INNER JOIN dbo.ENTRADAS E ON I.EntradaId = E.Id
            WHERE
            I.Id NOT IN(SELECT I.Id FROM Inserted I INNER JOIN dbo.PRODUTOS P ON I.CodigoProduto = P.Codigo);

        OPEN cur_ItensInseridos;
        FETCH NEXT FROM cur_ItensInseridos INTO 
            @CodigoProduto,@Quantidade,@PrecoUnitario,@CustoUnitario,@EntradaID,@NumeroNotaFiscal;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO dbo.PRODUTOS (Codigo,Nome,Descricao,PrecoVenda,PrecoCompra,Custo,Estoque,Unidade)
            VALUES (
                @CodigoProduto,
                CONCAT('Produto-',@CodigoProduto),
                CONCAT('Descrição do Produto-',@CodigoProduto),
                @CustoUnitario*1.75,
                @PrecoUnitario,
                @CustoUnitario,
                @Quantidade,
                'UN'
            );

            SET @ProdutoId = SCOPE_IDENTITY();
            INSERT INTO @NovosProdutos VALUES (@ProdutoId);

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                                  PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
            VALUES (
                'E',
                @CodigoProduto,
                CONCAT('Produto-',@CodigoProduto),
                @Quantidade,
                @CustoUnitario*1.75,
                0,
                @CustoUnitario,
                @EntradaID,
                CONCAT('Entrada NF: ', @NumeroNotaFiscal),
                1);

            FETCH NEXT FROM cur_ItensInseridos INTO 
                @CodigoProduto,@Quantidade,@PrecoUnitario,@CustoUnitario,@EntradaID,@NumeroNotaFiscal;

        END;

        CLOSE cur_ItensInseridos;
        DEALLOCATE cur_ItensInseridos;

        -- Atualiza itens existentes(UPDATE)
        IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS (SELECT 1 FROM Deleted)
        BEGIN
            -- Atualiza tabela PRODUTOS
            UPDATE P
            SET 
            P.Estoque += (ISNULL(I.Quantidade,0) - ISNULL(D.Quantidade,0)),
            P.PrecoVenda = I.CustoUnitario * 1.75,
            P.Custo = I.CustoUnitario,
            P.PrecoCompra = I.PrecoUnitario
            FROM dbo.PRODUTOS P
            FULL JOIN Inserted I ON P.Codigo = I.CodigoProduto
            FULL JOIN Deleted D  ON P.Codigo = D.CodigoProduto
            WHERE  
            (ISNULL(I.Quantidade,0) <> ISNULL(D.Quantidade,0) OR 
             ISNULL(I.PrecoUnitario,0) <> ISNULL(D.PrecoUnitario,0) OR 
             ISNULL(I.CustoUnitario,0) <> ISNULL(D.CustoUnitario,0))
            AND P.Id NOT IN(SELECT Id FROM @NovosProdutos);

            -- Insere registro de entrada de nota na MOVIMENTAÇÃO DE ESTOQUE
            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                                  PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
            SELECT
                CASE 
                    WHEN ISNULL(I.Quantidade,0) > ISNULL(D.Quantidade,0) THEN 'E'
                    WHEN ISNULL(I.Quantidade,0) < ISNULL(D.Quantidade,0) THEN 'S'
                END,
                P.Codigo,
                P.Nome,
                ABS(ISNULL(I.Quantidade,0) - ISNULL(D.Quantidade,0)) AS Quantidade,
                I.CustoUnitario * 1.75,
                0,
                I.CustoUnitario,
                I.EntradaId,
                CONCAT('Ajuste NF: ', E.NumeroNotaFiscal),
                1
            FROM dbo.PRODUTOS P
            FULL JOIN Inserted I ON P.Codigo = I.CodigoProduto
            FULL JOIN Deleted D  ON P.Codigo = D.CodigoProduto
            INNER JOIN dbo.ENTRADAS E ON I.EntradaId = E.Id
            WHERE 
            (ISNULL(I.Quantidade,0) <> ISNULL(D.Quantidade,0) OR 
             ISNULL(I.PrecoUnitario,0) <> ISNULL(D.PrecoUnitario,0) OR 
             ISNULL(I.CustoUnitario,0) <> ISNULL(D.CustoUnitario,0))
            AND I.Id NOT IN(SELECT Id FROM @NovosProdutos);

        END

        -- Entrada de novos itens via nota de entrada(INSERT)
        IF EXISTS (SELECT 1 FROM Inserted) AND NOT EXISTS (SELECT 1 FROM Deleted)
        BEGIN

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                                  PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
            SELECT
                'E',
                P.Codigo,
                P.Nome,
                I.Quantidade,
                I.CustoUnitario*1.75,
                0,
                I.CustoUnitario,
                I.EntradaId,
                CONCAT('Entrada NF: ', E.NumeroNotaFiscal),
                1
            FROM Inserted I
            INNER JOIN dbo.PRODUTOS P ON P.Codigo = I.CodigoProduto
            INNER JOIN dbo.ENTRADAS E ON E.Id   = I.EntradaId
            WHERE
            P.Id NOT IN(SELECT Id FROM @NovosProdutos);

            UPDATE P
            SET 
            P.Estoque += I.Quantidade,
            P.PrecoVenda = I.CustoUnitario*1.75,
            P.Custo = I.CustoUnitario,
            P.PrecoCompra = I.PrecoUnitario
            FROM dbo.PRODUTOS P
            INNER JOIN inserted I ON P.Codigo = I.CodigoProduto
            WHERE
            (P.Custo <> I.CustoUnitario OR P.Estoque <> I.Quantidade OR P.PrecoCompra <> I.PrecoUnitario)
            AND P.Id NOT IN (SELECT Id FROM @NovosProdutos);

        END
                
        -- Exclusão de itens via entrada de nota(DELETE)
        IF EXISTS (SELECT 1 FROM Deleted) AND NOT EXISTS (SELECT 1 FROM Inserted)
        BEGIN

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, Quantidade,
                                                  PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao, UsuarioMovimentacao)
            SELECT
                'S',
                P.Codigo,
                P.Nome,
                D.Quantidade,
                D.CustoUnitario*1.75,
                0,
                D.CustoUnitario,
                D.EntradaId,
                CONCAT('Cancelado/Retirado produto na NF: ', E.NumeroNotaFiscal),
                1
            FROM Deleted D
            INNER JOIN dbo.PRODUTOS P ON P.Codigo = D.CodigoProduto
            INNER JOIN dbo.ENTRADAS E ON E.Id = D.EntradaId;

            UPDATE P
            SET P.Estoque = P.Estoque - D.Quantidade
            FROM dbo.PRODUTOS P
            INNER JOIN Deleted D ON P.Codigo = D.CodigoProduto;

        END

        -- Finaliza a transação
        COMMIT TRAN;
        PRINT 'Trigger trg_AtualizaEstoqueEntrada executada com sucesso.';

    END TRY

    BEGIN CATCH
        -- Em caso de erro, reverte tudo
        ROLLBACK TRAN;

        DECLARE @ErroMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErroLine INT = ERROR_LINE();

        RAISERROR(
            '❌ Erro na trigger trg_AtualizaEstoqueEntrada (linha %d): %s',
            16, 1, @ErroLine, @ErroMsg
        );
    END CATCH
END;
GO

--DROP TRIGGER trg_AtualizaEstoqueVendaItens
--DROP TRIGGER trg_AtualizaMovimentacoesEstoqueEntradaManual
--DROP TRIGGER trg_AtualizaEstoqueEntradaNF
