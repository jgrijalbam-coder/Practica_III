/// Tipo A: consulta simple local. Tipo B: consulta compleja (LLM).
enum TipoConsulta { a, b }

class ComandoVoz {
  final String texto;
  final TipoConsulta tipo;
  ComandoVoz(this.texto, this.tipo);
}
