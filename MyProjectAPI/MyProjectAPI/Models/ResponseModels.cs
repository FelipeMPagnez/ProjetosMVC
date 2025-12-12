namespace MyProjectAPI.Models
{
    public class ResponseModels<T>
    {
        public T? Dados { get; set; }
        public string Mensagem { get; set; } = string.Empty;
        public bool Status { get; set; }
    }
}
