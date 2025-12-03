using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Perfil
{
    public int Id { get; set; }

    public string Nome { get; set; } = null!;

    public string? Descricao { get; set; }

    public virtual ICollection<Usuario> Usuarios { get; set; } = new List<Usuario>();
}
