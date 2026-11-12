import 'package:flutter/material.dart';

/// Paleta de la app por grupos (Spec 004, data-model §3, research R9).
///
/// Regla de color (FR-004): rojo, azul y amarillo solo en el sable, la punta
/// de frente y las señales. El dojang usa tonos cálidos apagados (lista
/// explícita en [dojangColors]); la figura y la interfaz, solo blancos, grises
/// y oscuros.
abstract final class AppColors {
  // ── Colores de señal: solo el sable, la punta de frente y las señales ──
  static const saberBlue = Color(0xFF1E6BFF);
  static const saberRed = Color(0xFFFF2D2D);
  static const saberYellow = Color(0xFFFFD400);
  static const saberWhite = Color(0xFFFFFFFF);

  /// Contorno del sable y de las señales.
  static const outline = Color(0xFF000000);

  // ── Dojang (excepciones cálidas nombradas, croma ≤ 0.45) ──
  static const wallTop = Color(0xFFAAA598);
  static const wallBottom = Color(0xFF8C887E);
  static const wood = Color(0xFF6A5644);
  static const woodShadow = Color(0xFF574536);
  static const beam = Color(0xFF5B4A3A);
  static const beamShadow = Color(0xFF3F3328);
  static const baseboard = Color(0xFF3D3027);
  static const floorBack = Color(0xFF694322);
  static const floorFront = Color(0xFF96622F);
  static const floorJoint = Color(0xB35A391C); // 70 %
  static const spotLight = Color(0x61FFE2B0); // 38 %
  static const floorShadow = Color(0x8C2E1D0D); // 55 %
  static const bannerCloth = Color(0xFF2A2B31);
  static const bannerText = Color(0xFFF2EFE6);
  static const selectionDim = Color(0x9E0C0E14); // 62 %
  static const skin = Color(0xFFF1C9A5);

  // ── Figura del oponente (croma ≤ 0.10) ──
  static const helmetLight = Color(0xFFFFFFFF);
  static const helmetShade = Color(0xFFCDD3DE);
  static const helmetGrille = Color(0xFF262833);
  static const helmetBars = Color(0xFFB7BDCB);
  static const petoLight = Color(0xFFF1F3F7);
  static const petoShade = Color(0xFFC2C8D4);
  static const petoLines = Color(0xFFAAB1BF);
  static const sleeveLight = Color(0xFFFFFFFF);
  static const sleeveShade = Color(0xFFD2D8E3);
  static const hakama = Color(0xFF2B2C31);
  static const hakamaFold = Color(0xFF1D1E22);
  static const belt = Color(0xFF15151A);
  static const glove = Color(0xFF1C1C22);
  static const figureOutline = Color(0xFF1A1D2B);
  static const rimLight = Color(0xB3D8D5CC); // 70 %
  static const grip = Color(0xFF26201B);
  static const gripWrap = Color(0xFF5C5046);
  static const tsuba = Color(0xFF8F8F96);

  // ── Interfaz (croma ≤ 0.10) ──
  static const panel = Color(0xBD12141C); // 74 %
  static const panelStrong = Color(0xC712141C); // 78 %
  static const panelBorder = Color(0x59FFFFFF); // 35 %
  static const panelBorderStrong = Color(0x66FFFFFF); // 40 %
  static const buttonBorder = Color(0x8CFFFFFF); // 55 %
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFD6D9E4);
  static const textTertiary = Color(0xFFAEB3C4);
  static const columnHeader = Color(0xFFC9CCD8);
  static const progressTrack = Color(0x38FFFFFF); // 22 %
  static const progressFill = Color(0xFFFFFFFF);
  static const cardIdle = Color(0x9912141C); // 60 %
  static const cardIdleBorder = Color(0x38FFFFFF); // 22 %
  static const cardSelected = Color(0x29FFFFFF); // 16 %
  static const cardSelectedBorder = Color(0xFFFFFFFF);
  static const cardSelectedRing = Color(0x1FFFFFFF); // 12 %
  static const iconTile = Color(0x1AFFFFFF); // 10 %
  static const primaryButton = Color(0xFFF4F5F8);
  static const onPrimaryButton = Color(0xFF12141C);

  /// Fondo de las pantallas bajo el dojang y de las superficies de Material.
  static const surface = Color(0xFF12141C);

  static const signalColors = [
    saberBlue,
    saberRed,
    saberYellow,
    saberWhite,
    outline,
  ];

  static const dojangColors = [
    wallTop,
    wallBottom,
    wood,
    woodShadow,
    beam,
    beamShadow,
    baseboard,
    floorBack,
    floorFront,
    floorJoint,
    spotLight,
    floorShadow,
    bannerCloth,
    bannerText,
    selectionDim,
    skin,
  ];

  static const figureColors = [
    helmetLight,
    helmetShade,
    helmetGrille,
    helmetBars,
    petoLight,
    petoShade,
    petoLines,
    sleeveLight,
    sleeveShade,
    hakama,
    hakamaFold,
    belt,
    glove,
    figureOutline,
    rimLight,
    grip,
    gripWrap,
    tsuba,
  ];

  static const interfaceColors = [
    panel,
    panelStrong,
    panelBorder,
    panelBorderStrong,
    buttonBorder,
    textPrimary,
    textSecondary,
    textTertiary,
    columnHeader,
    progressTrack,
    progressFill,
    cardIdle,
    cardIdleBorder,
    cardSelected,
    cardSelectedBorder,
    cardSelectedRing,
    iconTile,
    primaryButton,
    onPrimaryButton,
    surface,
  ];
}

/// Grosor mínimo del contorno del sable y las señales, en dp.
const double kOutlineWidth = 4.0;

/// Familia tipográfica de la interfaz (ADR 0005). El hangul y el hanja usan la
/// fuente del sistema por *fallback*.
const kFontFamily = 'Rajdhani';

ThemeData buildAppTheme() {
  // Esquema explícito en blancos y grises: sin semilla de color, para que los
  // widgets de Material no introduzcan amarillo ni tonos derivados (FR-005).
  const scheme = ColorScheme.dark(
    primary: AppColors.textPrimary,
    onPrimary: AppColors.onPrimaryButton,
    secondary: AppColors.textSecondary,
    onSecondary: AppColors.onPrimaryButton,
    tertiary: AppColors.textTertiary,
    onTertiary: AppColors.onPrimaryButton,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.textTertiary,
    error: AppColors.textPrimary,
    onError: AppColors.onPrimaryButton,
  );
  const pill = StadiumBorder();
  const buttonText = TextStyle(
    fontFamily: kFontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.surface,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // Número de la cuenta regresiva.
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: kFontFamily,
        fontSize: 200,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pill,
        backgroundColor: AppColors.primaryButton,
        foregroundColor: AppColors.onPrimaryButton,
        disabledBackgroundColor: AppColors.primaryButton.withValues(
          alpha: 0.38,
        ),
        disabledForegroundColor: AppColors.onPrimaryButton.withValues(
          alpha: 0.6,
        ),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        backgroundColor: AppColors.panelStrong,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.buttonBorder, width: 1.5),
        textStyle: buttonText,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.textPrimary,
    ),
  );
}
