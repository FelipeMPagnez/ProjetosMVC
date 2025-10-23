USE Treinamento;
GO

-- Alterar o estoque de produtos conforme movimentações
CREATE OR ALTER TRIGGER trg_AtualizaEstoqueVendaItens
ON VendaItens
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Atualiza estoque após alteração na venda
    IF EXISTS (SELECT 1 FROM Inserted I INNER JOIN Deleted D ON I.Id = D.Id)
    BEGIN
        -- Atualiza o estoque dos PRODUTOS para alteração de quantidade ou exclusão
        UPDATE P
        SET P.Estoque = 
            CASE
                WHEN D.ProdutoId = I.ProdutoId THEN P.Estoque + (D.Quantidade - I.Quantidade)
                WHEN D.ProdutoId IS NULL AND I.ProdutoId IS NOT NULL THEN P.Estoque - I.Quantidade
                WHEN D.ProdutoId IS NOT NULL AND I.ProdutoId IS NULL THEN P.Estoque + D.Quantidade
                ELSE P.Estoque
            END
        FROM Produtos P
        FULL JOIN Inserted I ON P.Id = I.ProdutoId
        FULL JOIN Deleted D  ON P.Id = D.ProdutoId;
        
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            CASE 
                WHEN ISNULL(D.Quantidade,0) > ISNULL(I.Quantidade,0) THEN 'E'
                WHEN ISNULL(D.Quantidade,0) < ISNULL(I.Quantidade,0) THEN 'S'
            END AS TipoMovimentacao,
            P.Codigo,
            P.Nome,
            ABS(D.Quantidade - I.Quantidade) AS Quantidade,
            P.Preco,
            I.PrecoUnitario,
            P.Custo,
            I.VendaId,
            'Atualização do produto na venda nº ' + I.VendaId
        FROM 
            Deleted D
            INNER JOIN Inserted I ON I.Id = D.Id
            INNER JOIN PRODUTOS P ON D.ProdutoId = P.Id OR I.ProdutoId = P.Id
        WHERE D.Quantidade <> I.Quantidade;

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
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            'S',
            P.Codigo,
            P.Nome,
            I.Quantidade,
            P.Preco,
            I.PrecoUnitario,
            P.Custo,
            I.VendaId,
            'Inclusão do produto na venda nº ' + I.VendaId
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
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            'E',
            P.Codigo,
            P.Nome,
            D.Quantidade,
            P.Preco,
            D.PrecoUnitario,
            P.Custo,
            D.VendaId,
            'Exclusão do produto na venda nº ' + D.VendaId
        FROM 
            Deleted D
            INNER JOIN PRODUTOS P ON D.ProdutoId = P.Id;

        RETURN;
    END;
END;
GO

---- Inclui movimentação de estoque para interações de venda, ajuste manual ou entrada de produto
--CREATE OR ALTER TRIGGER trg_AtualizaEstoqueEntradaProduto
--ON PRODUTOS
--AFTER INSERT, DELETE, UPDATE
--AS
--BEGIN
--    SET NOCOUNT ON;
    
--    IF EXISTS (SELECT * FROM inserted)
--    BEGIN
--        UPDATE P
--        SET P.Estoque = P.Estoque - I.Quantidade
--        FROM Produtos P
--        INNER JOIN inserted I ON P.Id = I.ProdutoId;
--        RETURN;
--    END

--    -- Retorna estoque ao deletar um item de venda (ex: cancelamento)
--    IF EXISTS (SELECT * FROM deleted)
--    BEGIN
--        UPDATE P
--        SET P.Estoque = P.Estoque + D.Quantidade
--        FROM Produtos P
--        INNER JOIN deleted D ON P.Id = D.ProdutoId;
--        RETURN;
--    END



--END;
--GO

CREATE OR ALTER TRIGGER trg_AtualizaEstoqueEntrada
ON EntradaItens
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;
        -- Atualiza itens existentes
        IF EXISTS (SELECT 1 FROM Inserted I INNER JOIN Deleted D ON I.Id = D.Id)
        BEGIN
            PRINT '→ Atualizando estoque e custo dos produtos já existentes.';

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                                  Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
            SELECT
                CASE 
                    WHEN ISNULL(I.Quantidade,0) > ISNULL(D.Quantidade,0) THEN 'E'
                    WHEN ISNULL(I.Quantidade,0) < ISNULL(D.Quantidade,0) THEN 'S'
                END,
                P.Codigo,
                P.Nome,
                ABS(I.Quantidade - D.Quantidade) AS Quantidade,
                ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2)*1.75,
                '',
                ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2),
                I.EntradaId,
                CONCAT('Ajuste NF: ', E.NumeroNotaFiscal)
            FROM Inserted I
            INNER JOIN Deleted D  ON I.Id = D.Id
            INNER JOIN Produtos P ON P.Id = I.ProdutoId
            INNER JOIN Entradas E ON E.Id = I.EntradaId
            WHERE I.Quantidade <> D.Quantidade OR I.PrecoUnitario <> D.PrecoUnitario;

            UPDATE P
            SET 
            P.Estoque = P.Estoque + (I.Quantidade - D.Quantidade),
            P.Preco = ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2)*1.75,
            P.Custo = ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2),
            P.PrecoCompra = I.PrecoUnitario
            FROM Produtos P
            INNER JOIN inserted I ON P.Id = I.ProdutoId
            INNER JOIN deleted D  ON I.Id = D.Id;

            PRINT '✓ Atualização de estoque e custo concluída.';
        END

        -- Entrada de novos itens via nota de entrada
        IF EXISTS (SELECT 1 FROM Inserted WHERE Id NOT IN (SELECT Id FROM Deleted))
        BEGIN
            PRINT '→ Inserindo novos itens de entrada na movimentação e atualizando estoque.';

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, 
                                                  Quantidade,Preco, ValorVendido, Custo, DocumentoId, Observacao)
            SELECT
                'E',
                P.Codigo,
                P.Nome,
                I.Quantidade,
                ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2)*1.75,
                '',
                ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2),
                I.EntradaId,
                CONCAT('Entrada NF: ', E.NumeroNotaFiscal)
            FROM inserted I
            INNER JOIN Produtos P ON P.Id = I.ProdutoId
            INNER JOIN Entradas E ON E.Id = I.EntradaId;

            UPDATE P
            SET 
            P.Estoque = P.Estoque + I.Quantidade, 
            P.Preco = ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2)*1.75,
            P.Custo = ROUND(I.PrecoUnitario + ((I.ICMS_Valor + I.IPI_Valor + I.PIS_Valor + I.COFINS_Valor) / NULLIF(I.Quantidade,0)),2),
            P.PrecoCompra = I.PrecoUnitario
            FROM Produtos P
            INNER JOIN inserted I ON P.Id = I.ProdutoId;

            PRINT '✓ Estoque atualizado com sucesso para novos produtos.';
        END
                
        -- Exclusão de itens via entrada de nota
        IF EXISTS (SELECT 1 FROM Deleted WHERE Id NOT IN (SELECT Id FROM Inserted))
        BEGIN
            PRINT '→ Excluindo itens de entrada e revertendo estoque.';

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, 
                                                  Quantidade,Preco, ValorVendido, Custo, DocumentoId, Observacao)
            SELECT
                'S',
                P.Codigo,
                P.Nome,
                D.Quantidade,
                ROUND(D.PrecoUnitario + ((D.ICMS_Valor + D.IPI_Valor + D.PIS_Valor + D.COFINS_Valor) / NULLIF(D.Quantidade,0)),2)*1.75,
                '',
                ROUND(D.PrecoUnitario + ((D.ICMS_Valor + D.IPI_Valor + D.PIS_Valor + D.COFINS_Valor) / NULLIF(D.Quantidade,0)),2),
                D.EntradaId,
                CONCAT('Cancelamento NF: ', E.NumeroNotaFiscal)
            FROM Deleted D
            INNER JOIN Produtos P ON P.Id = D.ProdutoId
            INNER JOIN Entradas E ON E.Id = D.EntradaId;

            UPDATE P
            SET P.Estoque = P.Estoque - D.Quantidade
            FROM Produtos P
            INNER JOIN Deleted D ON P.Id = D.ProdutoId;

            PRINT '✓ Estoque revertido com sucesso após exclusão de nota.';
        END

        -- Finaliza a transação
        COMMIT TRAN;
        PRINT '✅ Trigger trg_AtualizaEstoqueEntrada executada com sucesso.';

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
