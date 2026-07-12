/// Width breakpoints for adapting layouts to wider (desktop) browser windows.
///
/// Bands are sized around this app's own shell (a 4-item nav + card grids),
/// not copied wholesale from a generic framework:
/// - mobile: current phone-width layout, unchanged.
/// - tablet: collapsed icon-only nav rail, 2-column grids.
/// - desktop: expanded labeled nav rail, multi-column dashboards, master-detail splits.
/// - wide: same shell as desktop, content capped at [maxContentWidth] instead of stretching.
class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;

  /// Max width content is allowed to grow to on ultra-wide viewports.
  static const double maxContentWidth = 1240;

  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isAtLeastTablet(double width) => width >= tablet;
  static bool isAtLeastDesktop(double width) => width >= desktop;
  static bool isWide(double width) => width >= wide;
}
