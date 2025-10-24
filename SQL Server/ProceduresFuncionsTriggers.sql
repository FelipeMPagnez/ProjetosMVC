USE Treinamento;
GO

-- Alterar o estoque de produtos conforme movimentações
CREATE OR ALTER TRIGGER trg_AtualizaEstoqueVendaItens
ON VendaItens
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Atualiza estoque após alteração na venda(UPFATE)
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
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
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
            'Atualização do produto na venda nº ' + I.VendaId
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
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            'S',
            P.Codigo,
            P.Nome,
            I.Quantidade,
            P.PrecoVenda,
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
            P.PrecoVenda,
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

-- Inclui movimentação de estoque para interações de venda, ajuste manual ou entrada de produto
CREATE OR ALTER TRIGGER trg_AtualizaMovimentacoesEstoqueEntradaManual
ON PRODUTOS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Alteração manual de um produto(UPDATE)
    IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS (SELECT 1 FROM Deleted)
    BEGIN        
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            CASE 
                WHEN ISNULL(I.Estoque,0) > ISNULL(D.Estoque,0) THEN 'E'
                WHEN ISNULL(I.Estoque,0) < ISNULL(D.Estoque,0) THEN 'S'
                ELSE 'A'
            END AS TipoMovimentacao,
            I.Codigo,
            I.Nome,
            ABS(ISNULL(I.Estoque,0) - ISNULL(D.Estoque,0)) AS Quantidade,
            I.PrecoVenda,
            '',
            I.Custo,
            '',
            CASE
                WHEN I.Ativo = 0 THEN 'Atualização manual do produto, produto inativado'
                WHEN I.Ativo = 1 AND ISNULL(I.Estoque,0) <> ISNULL(D.Estoque,0) THEN 'Atualização manual do produto, ajuste de estoque'
                WHEN I.Ativo = 1 AND ISNULL(I.PrecoVenda,0) <> ISNULL(D.PrecoVenda,0) THEN 'Atualização manual do produto, correção preço venda'
                WHEN I.Ativo = 1 AND ISNULL(I.PrecoCompra,0) <> ISNULL(D.PrecoCompra,0) THEN 'Atualização manual do produto, correção preço compra'
                WHEN I.Ativo = 1 AND ISNULL(I.Custo,0) <> ISNULL(D.Custo,0) THEN 'Atualização manual do produto, correção custo'
            END AS Observacao
        FROM Deleted D
        FULL JOIN Inserted I ON I.Id = D.Id
        WHERE 
        D.Estoque <> I.Estoque OR D.PrecoVenda <> I.PrecoVenda OR D.PrecoCompra <> I.PrecoCompra OR D.Custo <> I.Custo;
        RETURN;
    END

    -- Inclusão manual de novo produto(INSERT)
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Inclui uma movimentação de estoque
        INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                              Quantidade,Preco,ValorVendido,Custo,DocumentoId,Observacao)
        SELECT 
            'E',
            I.Codigo,
            I.Nome,
            I.Estoque,
            I.PrecoVenda,
            '',
            I.Custo,
            '',
            'Inclusão manual do produto'
        FROM Inserted I

        RETURN;
    END

END;
GO

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
            @NumeroNotaFiscal   INT,
            @FornecedorId       INT;

        DECLARE @NovosProdutos TABLE(Id INT);

        -- Inclui produtos novos na tabela PRODUTOS
        DECLARE cur_ItensInseridos CURSOR FOR
            SELECT 
            I.CodigoProduto, I.Quantidade, I.PrecoUnitario, I.CustoUnitario, E.FornecedorId, I.EntradaId, E.NumeroNotaFiscal
            FROM Inserted I
            INNER JOIN dbo.ENTRADAS E ON I.EntradaId = E.Id
            WHERE
            I.Id NOT IN(SELECT I.Id FROM Inserted I INNER JOIN dbo.PRODUTOS P ON I.CodigoProduto = P.Codigo);

        OPEN cur_ItensInseridos;
        FETCH NEXT cur_ItensInseridos INTO 
            @CodigoProduto,@Quantidade,@PrecoUnitario,@CustoUnitario,@EntradaID,@NumeroNotaFiscal,@FornecedorId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO dbo.PRODUTOS (Codigo,Nome,Descricao,PrecoVenda,PrecoCompra,Custo,Estoque,Unidade,FornecedorId)
            VALUES (
                @CodigoProduto,
                CONCAT('Produto',@CodigoProduto),
                CONCAT('Descrição do Produto',@CodigoProduto),
                @CustoUnitario*1,75,
                @PrecoUnitario,
                @CustoUnitario,
                @Quantidade,
                'UN',
                @FornecedorId
            );

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, 
                                                  Quantidade,PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao)
            VALUES (
                'E',
                @CodigoProduto,
                CONCAT('Produto',@CodigoProduto),
                @Quantidade,
                @CustoUnitario*1.75,
                '',
                @CustoUnitario,
                @EntradaID,
                CONCAT('Entrada NF: ', @NumeroNotaFiscal));

            SET @ProdutoId = SCOPE_IDENTITY();
            INSERT INTO @NovosProdutos VALUES (@ProdutoId);

            FETCH NEXT cur_ItensInseridos INTO 
            @CodigoProduto,@Quantidade,@PrecoUnitario,@CustoUnitario,@EntradaID,@NumeroNotaFiscal,@FornecedorId;

        END;

        CLOSE cur_ItensInseridos;
        DEALLOCATE cur_ItensInseridos;

        -- Atualiza itens existentes(UPDATE)
        IF EXISTS (SELECT 1 FROM Inserted) AND EXISTS (SELECT 1 FROM Deleted)
        BEGIN
            PRINT '→ Atualizando estoque e custo dos produtos já existentes.';            

            UPDATE P
            SET 
            P.Estoque += (ISNULL(I.Quantidade,0) - ISNULL(D.Quantidade,0)),
            P.PrecoVenda = I.CustoUnitario * 1.75,
            P.Custo = I.CustoUnitario,
            P.PrecoCompra = I.PrecoUnitario
            FROM dbo.PRODUTOS P
            FULL JOIN Inserted I ON P.Nome = I.NomeProduto
            FULL JOIN Deleted D  ON P.Nome = D.NomeProduto
            WHERE  
            (ISNULL(I.Quantidade,0) <> ISNULL(D.Quantidade,0) OR 
             ISNULL(I.PrecoUnitario,0) <> ISNULL(D.PrecoUnitario,0) OR 
             ISNULL(I.CustoUnitario,0) <> ISNULL(D.CustoUnitario,0))
            AND P.Id NOT IN(SELECT Id FROM @NovosProdutos);

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao,CodigoProduto,NomeProduto,
                                                  Quantidade,PrecoVenda,ValorVendido,Custo,DocumentoId,Observacao)
            SELECT
                CASE 
                    WHEN ISNULL(I.Quantidade,0) > ISNULL(D.Quantidade,0) THEN 'E'
                    WHEN ISNULL(I.Quantidade,0) < ISNULL(D.Quantidade,0) THEN 'S'
                END,
                P.Codigo,
                P.Nome,
                ABS(ISNULL(I.Quantidade,0) - ISNULL(D.Quantidade,0)) AS Quantidade,
                I.CustoUnitario * 1.75,
                '',
                I.CustoUnitario,
                I.EntradaId,
                CONCAT('Ajuste NF: ', E.NumeroNotaFiscal)
            FROM dbo.PRODUTOS P
            FULL JOIN Inserted I ON P.Nome = I.NomeProduto
            FULL JOIN Deleted D  ON P.Nome = D.NomeProduto
            INNER JOIN dbo.ENTRADAS E ON I.EntradaId = E.Id
            WHERE 
            (ISNULL(I.Quantidade,0) <> ISNULL(D.Quantidade,0) OR 
             ISNULL(I.PrecoUnitario,0) <> ISNULL(D.PrecoUnitario,0) OR 
             ISNULL(I.CustoUnitario,0) <> ISNULL(D.CustoUnitario,0))
            AND P.Id NOT IN(SELECT Id FROM @NovosProdutos);

            PRINT '✓ Atualização de estoque e custo concluída.';
        END

        -- Entrada de novos itens via nota de entrada(INSERT)
        IF EXISTS (SELECT 1 FROM Inserted) AND NOT EXISTS (SELECT 1 FROM Deleted)
        BEGIN
            PRINT '→ Inserindo novos itens de entrada na movimentação e atualizando estoque.';

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, 
                                                  Quantidade,PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao)
            SELECT
                'E',
                P.Codigo,
                P.Nome,
                I.Quantidade,
                I.CustoUnitario*1.75,
                '',
                I.CustoUnitario,
                I.EntradaId,
                CONCAT('Entrada NF: ', E.NumeroNotaFiscal)
            FROM Inserted I
            INNER JOIN dbo.PRODUTOS P ON P.Nome = I.NomeProduto
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
            INNER JOIN inserted I ON P.Nome = I.NomeProduto
            WHERE
            (P.Custo <> I.CustoUnitario OR P.Estoque <> I.Quantidade OR P.PrecoCompra <> I.PrecoUnitario)
            AND P.Id NOT IN (SELECT Id FROM @NovosProdutos);

            PRINT '✓ Estoque atualizado com sucesso para novos produtos.';
        END
                
        -- Exclusão de itens via entrada de nota(DELETE)
        IF EXISTS (SELECT 1 FROM Deleted) AND NOT EXISTS (SELECT 1 FROM Inserted)
        BEGIN
            PRINT '→ Excluindo itens de entrada e revertendo estoque.';

            INSERT INTO dbo.MOVIMENTACOESESTOQUE (TipoMovimentacao, CodigoProduto, NomeProduto, 
                                                  Quantidade,PrecoVenda, ValorVendido, Custo, DocumentoId, Observacao)
            SELECT
                'S',
                P.Codigo,
                P.Nome,
                D.Quantidade,
                D.CustoUnitario*1.75,
                '',
                D.CustoUnitario,
                D.EntradaId,
                CONCAT('Cancelamento NF: ', E.NumeroNotaFiscal)
            FROM Deleted D
            INNER JOIN dbo.PRODUTOS P ON P.Nome = D.NomeProduto
            INNER JOIN dbo.ENTRADAS E ON E.Id = D.EntradaId;

            UPDATE P
            SET P.Estoque = P.Estoque - D.Quantidade
            FROM dbo.PRODUTOS P
            INNER JOIN Deleted D ON P.Nome = D.NomeProduto;

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
