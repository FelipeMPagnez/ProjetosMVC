using System.ComponentModel.DataAnnotations;

namespace MyProjectAPI.Dto
{
    public class FornecedorCadastrarDTO
    {

        [Required(ErrorMessage = "O nome fantasia é obrigatório")]
        [StringLength(150, ErrorMessage = "O nome fantasia deve ter no máximo 150 caracteres")]
        public string NomeFantasia { get; set; } = null!;

        [StringLength(150, ErrorMessage = "A razão social deve ter no máximo 150 caracteres")]
        public string? RazaoSocial { get; set; }

        [Required(ErrorMessage ="O CNPJ é obrigatório")]
        [StringLength(14, ErrorMessage ="O CNPJ deve ter 14 caracteres")]
        [RegularExpression("^[0-9]*$", ErrorMessage ="O CNPJ deve conter apenas números")]
        public string CNPJ { get; set; } = null!;

        [EmailAddress(ErrorMessage = "Email em formato inválido")]
        [StringLength(150, ErrorMessage = "Email deve ter no máximo 150 caracteres")]
        public string? Email { get; set; }

        [StringLength(17, ErrorMessage = "Telefone deve ter no máximo 17 caracteres")]
        public string? Telefone { get; set; }

        [StringLength(100, ErrorMessage = "Cidade deve ter no máximo 100 caracteres")]
        public string? Cidade { get; set; }

        [Required(ErrorMessage = "A UF é obrigatória")]
        [StringLength(2, MinimumLength = 2, ErrorMessage = "UF deve ter 2 caracteres")]
        [RegularExpression("^(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)$",
            ErrorMessage = "UF inválida")]
        public string? UF { get; set; }

        public bool Ativo { get; set; }
    }
}
