using System.ComponentModel.DataAnnotations;

namespace MyProjectAPI.Dto
{
    public class ClienteUpdateDTO
    {
        [StringLength(100, ErrorMessage = "O nome deve ter no máximo 100 caracteres")]
        public string Nome { get; set; }

        [DataType(DataType.Date)]
        public DateOnly? DataNascimento { get; set; }

        [StringLength(150, ErrorMessage = "Email deve ter no máximo 150 caracteres")]
        public string Email { get; set; }

        [StringLength(17, ErrorMessage = "Telefone deve ter no máximo 17 caracteres")]
        public string Telefone { get; set; }

        [StringLength(120, ErrorMessage = "Logradouro deve ter no máximo 120 caracteres")]
        public string Logradouro { get; set; }

        [StringLength(4, ErrorMessage = "Número deve ter no máximo 4 caracteres")]
        public string Numero { get; set; }

        [StringLength(50, ErrorMessage = "Complemento deve ter no máximo 50 caracteres")]
        public string Complemento { get; set; }

        [StringLength(80, ErrorMessage = "Bairro deve ter no máximo 80 caracteres")]
        public string Bairro { get; set; }

        [StringLength(100, ErrorMessage = "Cidade deve ter no máximo 100 caracteres")]
        public string Cidade { get; set; }

        [StringLength(2, MinimumLength = 2, ErrorMessage = "UF deve ter 2 caracteres")]
        [RegularExpression("^(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)$",
            ErrorMessage = "UF inválida")]
        public string UF { get; set; }

        [StringLength(10, ErrorMessage = "CEP deve ter no máximo 10 caracteres")]
        public string CEP { get; set; }

        public string Historico { get; set; }

        public bool Ativo { get; set; }
    }
}
