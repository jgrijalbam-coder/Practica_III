/// Nivel de riesgo de una amenaza.
enum NivelRiesgo { informativo, preventivo, inminente }

/// Sector donde está el obstáculo respecto al usuario.
enum Sector { izquierda, frente, derecha, atras }

/// Convierte un ángulo (grados, 0 = frente, negativo = izquierda) en sector.
Sector sectorDesdeAngulo(double angulo) {
  if (angulo.abs() > 90) return Sector.atras;
  if (angulo < -30) return Sector.izquierda;
  if (angulo > 30) return Sector.derecha;
  return Sector.frente;
}

/// inminente < 1.2 m, preventivo < 2.5 m, informativo en otro caso.
NivelRiesgo nivelDesdeDistancia(double metros) {
  if (metros < 1.2) return NivelRiesgo.inminente;
  if (metros < 2.5) return NivelRiesgo.preventivo;
  return NivelRiesgo.informativo;
}
