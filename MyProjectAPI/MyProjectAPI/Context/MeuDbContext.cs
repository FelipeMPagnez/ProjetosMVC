using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Models;

namespace MyProjectAPI.Context;

public partial class MeuDbContext : DbContext
{
    public MeuDbContext()
    {
    }

    public MeuDbContext(DbContextOptions<MeuDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Cliente> Clientes { get; set; }

    public virtual DbSet<Entrada> Entradas { get; set; }

    public virtual DbSet<EntradaItem> EntradaItens { get; set; }

    public virtual DbSet<Fornecedor> Fornecedores { get; set; }

    public virtual DbSet<Funcionario> Funcionarios { get; set; }

    public virtual DbSet<Movimentacoesestoque> Movimentacoesestoques { get; set; }

    public virtual DbSet<Perfil> Perfis { get; set; }

    public virtual DbSet<Produto> Produtos { get; set; }

    public virtual DbSet<Servico> Servicos { get; set; }

    public virtual DbSet<Usuario> Usuarios { get; set; }

    public virtual DbSet<Venda> Vendas { get; set; }

    public virtual DbSet<VendaItem> VendaItens { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=localhost\\SQLEXPRESS;Database=Treinamento;Trusted_Connection=True;TrustServerCertificate=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Cliente>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__CLIENTES__3214EC079FFEC4F4");
            entity.ToTable("CLIENTES");
            entity.HasIndex(e => e.CPF, "UQ__CLIENTES__C1F89731093A9AC2").IsUnique();
            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.Bairro).HasMaxLength(80);
            entity.Property(e => e.CEP).HasMaxLength(10).IsUnicode(false).HasColumnName("CEP");
            entity.Property(e => e.Cidade).HasMaxLength(100);
            entity.Property(e => e.Complemento).HasMaxLength(50);
            entity.Property(e => e.CPF).HasMaxLength(11).IsUnicode(false).IsFixedLength().HasColumnName("CPF");
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.Logradouro).HasMaxLength(120);
            entity.Property(e => e.Nome).HasMaxLength(100);
            entity.Property(e => e.Numero).HasMaxLength(10);
            entity.Property(e => e.Telefone).HasMaxLength(17).IsUnicode(false);
            entity.Property(e => e.UF).HasMaxLength(2).IsUnicode(false).IsFixedLength().HasColumnName("UF");
        });

        modelBuilder.Entity<Entrada>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__ENTRADAS__3214EC07BBD46104");

            entity.ToTable("ENTRADAS");

            entity.HasIndex(e => e.ChaveAcesso, "UQ__ENTRADAS__B1545512295C5C47").IsUnique();

            entity.Property(e => e.ChaveAcesso)
                .HasMaxLength(44)
                .IsUnicode(false)
                .IsFixedLength();
            entity.Property(e => e.CofinsTotal)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("COFINS_Total");
            entity.Property(e => e.DataEntrada).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.IcmsTotal)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("ICMS_Total");
            entity.Property(e => e.IpiTotal)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("IPI_Total");
            entity.Property(e => e.Modelo).HasMaxLength(2);
            entity.Property(e => e.NumeroNotaFiscal).HasMaxLength(9);
            entity.Property(e => e.Observacoes).HasMaxLength(500);
            entity.Property(e => e.PisTotal)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("PIS_Total");
            entity.Property(e => e.Serie).HasMaxLength(3);
            entity.Property(e => e.ValorTotal).HasColumnType("decimal(12, 2)");

            entity.HasOne(d => d.Fornecedor).WithMany(p => p.Entrada)
                .HasForeignKey(d => d.FornecedorId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ENTRADAS__Fornec__6477ECF3");

            entity.HasOne(d => d.UsuarioCadastroNavigation).WithMany(p => p.Entrada)
                .HasForeignKey(d => d.UsuarioCadastro)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ENTRADAS__Usuari__6E01572D");
        });

        modelBuilder.Entity<EntradaItem>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__EntradaI__3214EC07F9312606");

            entity.ToTable(tb => tb.HasTrigger("trg_AtualizaEstoqueEntradaNF"));

            entity.Property(e => e.CodigoProduto).HasMaxLength(5);
            entity.Property(e => e.CofinsAliquota)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("COFINS_Aliquota");
            entity.Property(e => e.CofinsValor)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("COFINS_Valor");
            entity.Property(e => e.CustoUnitario).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.IcmsAliquota)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("ICMS_Aliquota");
            entity.Property(e => e.IcmsValor)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("ICMS_Valor");
            entity.Property(e => e.IpiAliquota)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("IPI_Aliquota");
            entity.Property(e => e.IpiValor)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("IPI_Valor");
            entity.Property(e => e.PisAliquota)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("PIS_Aliquota");
            entity.Property(e => e.PisValor)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("PIS_Valor");
            entity.Property(e => e.PrecoUnitario).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.ValorTotal)
                .HasComputedColumnSql("(((([Quantidade]*[PrecoUnitario]+[ICMS_Valor])+[IPI_Valor])+[PIS_Valor])+[COFINS_Valor])", true)
                .HasColumnType("decimal(25, 2)");

            entity.HasOne(d => d.Entrada).WithMany(p => p.EntradaItens)
                .HasForeignKey(d => d.EntradaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__EntradaIt__Entra__70DDC3D8");
        });

        modelBuilder.Entity<Fornecedor>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__FORNECED__3214EC073B3AA6C8");

            entity.ToTable("FORNECEDORES");

            entity.HasIndex(e => e.CNPJ, "UQ__FORNECED__AA57D6B46EBBBE4F").IsUnique();

            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.Cidade).HasMaxLength(100);
            entity.Property(e => e.CNPJ)
                .HasMaxLength(14)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("CNPJ");
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.NomeFantasia).HasMaxLength(150);
            entity.Property(e => e.RazaoSocial).HasMaxLength(150);
            entity.Property(e => e.Telefone)
                .HasMaxLength(17)
                .IsUnicode(false);
            entity.Property(e => e.UF)
                .HasMaxLength(2)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("UF");
        });

        modelBuilder.Entity<Funcionario>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__FUNCIONA__3214EC072850DCC6");

            entity.ToTable("FUNCIONARIOS");

            entity.HasIndex(e => e.CPF, "UQ__FUNCIONA__C1F89731478AF879").IsUnique();

            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.Bairro).HasMaxLength(80);
            entity.Property(e => e.Cargo).HasMaxLength(80);
            entity.Property(e => e.CEP)
                .HasMaxLength(10)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("CEP");
            entity.Property(e => e.Cidade).HasMaxLength(100);
            entity.Property(e => e.Complemento).HasMaxLength(50);
            entity.Property(e => e.CPF)
                .HasMaxLength(11)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("CPF");
            entity.Property(e => e.DataAdmissao).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Departamento).HasMaxLength(80);
            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.Logradouro).HasMaxLength(120);
            entity.Property(e => e.Nome).HasMaxLength(100);
            entity.Property(e => e.Numero).HasMaxLength(10);
            entity.Property(e => e.Observacoes).HasMaxLength(500);
            entity.Property(e => e.Salario).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.Telefone)
                .HasMaxLength(17)
                .IsUnicode(false);
            entity.Property(e => e.UF)
                .HasMaxLength(2)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("UF");
            entity.Property(e => e.UltimaAtualizacao).HasDefaultValueSql("(sysdatetime())");
        });

        modelBuilder.Entity<Movimentacoesestoque>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__MOVIMENT__3214EC0745DF9034");

            entity.ToTable("MOVIMENTACOESESTOQUE");

            entity.HasIndex(e => e.CodigoProduto, "IX_MovEstoque_Codigo");

            entity.HasIndex(e => e.NomeProduto, "IX_MovEstoque_Nome");

            entity.Property(e => e.CodigoProduto).HasMaxLength(5);
            entity.Property(e => e.Custo).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.DataMovimentacao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.NomeProduto).HasMaxLength(80);
            entity.Property(e => e.Observacao).HasMaxLength(80);
            entity.Property(e => e.PrecoVenda).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.TipoMovimentacao)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength();
            entity.Property(e => e.ValorVendido).HasColumnType("decimal(10, 2)");

            entity.HasOne(d => d.UsuarioMovimentacaoNavigation).WithMany(p => p.Movimentacoesestoques)
                .HasForeignKey(d => d.UsuarioMovimentacao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__MOVIMENTA__Usuar__5EBF139D");
        });

        modelBuilder.Entity<Perfil>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__PERFIS__3214EC07BF7B8503");

            entity.ToTable("PERFIS");

            entity.HasIndex(e => e.Nome, "UQ__PERFIS__7D8FE3B2BD16FEFA").IsUnique();

            entity.Property(e => e.Descricao).HasMaxLength(200);
            entity.Property(e => e.Nome).HasMaxLength(50);
        });

        modelBuilder.Entity<Produto>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__PRODUTOS__3214EC07DC0A4A86");

            entity.ToTable("PRODUTOS", tb => tb.HasTrigger("trg_AtualizaMovimentacoesEstoqueEntradaManual"));

            entity.HasIndex(e => e.Nome, "IX_Produtos_Nome");

            entity.HasIndex(e => e.Codigo, "UQ__PRODUTOS__06370DAC454E42A1").IsUnique();

            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.Codigo)
                .HasMaxLength(5)
                .IsUnicode(false);
            entity.Property(e => e.Custo).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Descricao).HasMaxLength(150);
            entity.Property(e => e.Nome).HasMaxLength(80);
            entity.Property(e => e.PrecoCompra).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.PrecoVenda).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.Unidade)
                .HasMaxLength(2)
                .IsUnicode(false)
                .IsFixedLength();
        });

        modelBuilder.Entity<Servico>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__SERVICOS__3214EC07826C68C6");

            entity.ToTable("SERVICOS");

            entity.HasIndex(e => e.Nome, "IX_Servicos_Nome");

            entity.HasIndex(e => e.Codigo, "UQ__SERVICOS__06370DACA8553EA8").IsUnique();

            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.Codigo).HasMaxLength(6);
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Descricao).HasMaxLength(250);
            entity.Property(e => e.Nome).HasMaxLength(80);
            entity.Property(e => e.Preco).HasColumnType("decimal(10, 2)");
        });

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__USUARIOS__3214EC07C1762563");

            entity.ToTable("USUARIOS");

            entity.HasIndex(e => e.Email, "UQ__USUARIOS__A9D10534B1A6DCC5").IsUnique();

            entity.Property(e => e.Ativo).HasDefaultValue(true);
            entity.Property(e => e.DataCadastro).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.Nome).HasMaxLength(100);
            entity.Property(e => e.SenhaHash).HasMaxLength(256);

            entity.HasOne(d => d.Perfil).WithMany(p => p.Usuarios)
                .HasForeignKey(d => d.PerfilId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__USUARIOS__Perfil__3B75D760");
        });

        modelBuilder.Entity<Venda>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__VENDAS__3214EC074C32A75E");

            entity.ToTable("VENDAS");

            entity.HasIndex(e => e.DataVenda, "IX_Vendas_DataVenda");

            entity.HasIndex(e => e.NumeroVenda, "UQ__VENDAS__EBD34DCD3B4568FC").IsUnique();

            entity.Property(e => e.DataVenda).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Estatus)
                .HasMaxLength(50)
                .HasDefaultValue("Aberta");
            entity.Property(e => e.Total).HasColumnType("decimal(10, 2)");
        });

        modelBuilder.Entity<VendaItem>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__VendaIte__3214EC07946E9489");

            entity.ToTable(tb => tb.HasTrigger("trg_AtualizaEstoqueVendaItens"));

            entity.HasIndex(e => e.ProdutoId, "IX_VendaItens_ProdutoId");

            entity.HasIndex(e => e.ServicoId, "IX_VendaItens_ServicoId");

            entity.HasIndex(e => e.VendaId, "IX_VendaItens_VendaId");

            entity.Property(e => e.PrecoUnitario).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.Quantidade).HasDefaultValue(1);
            entity.Property(e => e.Total)
                .HasComputedColumnSql("([PrecoUnitario]*[Quantidade])", true)
                .HasColumnType("decimal(21, 2)");

            entity.HasOne(d => d.Produto).WithMany(p => p.VendaItens)
                .HasForeignKey(d => d.ProdutoId)
                .HasConstraintName("FK_VendaItens_Produtos");

            entity.HasOne(d => d.Servico).WithMany(p => p.VendaItens)
                .HasForeignKey(d => d.ServicoId)
                .HasConstraintName("FK_VendaItens_Servicos");

            entity.HasOne(d => d.Venda).WithMany(p => p.VendaItens)
                .HasForeignKey(d => d.VendaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendaItens_Vendas");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
