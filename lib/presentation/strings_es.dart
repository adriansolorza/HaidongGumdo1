/// Textos de la interfaz en español (Principio IX, R15). Los términos coreanos
/// y los nombres de niveles y patrones salen del catálogo, no de aquí.
abstract final class StringsEs {
  static const appTitle = 'Haidong Gumdo';
  static const appHeader = 'HAIDONG GUMDO';
  static const appSubtitle = 'Entrenamiento de reacción · 해동검도';
  static const levelHeader = 'NIVEL';
  static const patternHeader = 'PATRÓN';
  static const start = 'INICIAR';
  static const stop = 'DETENER';
  static const repeat = 'REPETIR';
  static const back = 'VOLVER';
  static const loadingCatalog = 'Cargando catálogo…';
  static const catalogError = 'No se pudo cargar el catálogo de ejercicios.';

  // Configuración (Spec 005, contrato §5).
  static const settings = 'CONFIGURACIÓN';
  static const save = 'GUARDAR';
  static const cancel = 'CANCELAR';
  static const reset = 'RESTABLECER';
  static const durationLabel = 'Duración del ejercicio';
  static const durationHint = 'Tiempo total del ejercicio';
  static const durationRange = '30 s a 3 min';
  static const maxRepeatsLabel = 'Máximo de repeticiones seguidas';
  static const maxRepeatsHint = 'Ataques seguidos al mismo lado, como máximo';
  static const maxRepeatsRange = '1 a 5';
  static const warningTimeLabel = 'Tiempo de aviso';
  static const warningTimeHint = 'Desde la señal hasta el corte';
  static const warningTimeRange = '⅓ s a 1 s';
  static const warningTimeReference = '1 s: cinta blanca · ⅓ s: avanzado';
  static const cutSpeedLabel = 'Velocidad del corte';
  static const cutSpeedHint = 'Duración del corte del oponente';
  static const cutSpeedRange = '0.3 s a 1 s';
  static const attackIntervalLabel = 'Intervalo máximo entre ataques';
  static const attackIntervalHint =
      'Desde el inicio del corte hasta la siguiente señal';
  static const saveErrorTitle = 'No se pudo guardar';
  static const saveErrorBody = 'Tus cambios siguen aquí. Inténtalo de nuevo.';
}
