using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Usuario
{
    public int Id { get; set; }

    public string Nome { get; set; } = null!;

    public string Email { get; set; } = null!;

    public byte[] SenhaHash { get; set; } = null!;

    public int PerfilId { get; set; }

    public bool Ativo { get; set; }

    public DateTime DataCadastro { get; set; }

    public virtual ICollection<Entrada> Entrada { get; set; } = new List<Entrada>();

    public virtual ICollection<Movimentacoesestoque> Movimentacoesestoques { get; set; } = new List<Movimentacoesestoque>();

    public virtual Perfil Perfil { get; set; } = null!;
}
