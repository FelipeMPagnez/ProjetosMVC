using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Movimentacoesestoque
{
    public int Id { get; set; }

    public string TipoMovimentacao { get; set; } = null!;

    public string CodigoProduto { get; set; } = null!;

    public string NomeProduto { get; set; } = null!;

    public int Quantidade { get; set; }

    public decimal PrecoVenda { get; set; }

    public decimal? ValorVendido { get; set; }

    public decimal Custo { get; set; }

    public int? DocumentoId { get; set; }

    public string? Observacao { get; set; }

    public int UsuarioMovimentacao { get; set; }

    public DateTime DataMovimentacao { get; set; }

    public virtual Usuario UsuarioMovimentacaoNavigation { get; set; } = null!;
}
