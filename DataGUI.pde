import controlP5.*;

class DataGUI extends MainPanel
{
  CurvedLinesData data;
  FileGUI   file_ui;
  StyleGUI  style_ui;
  CurvesGUI curves_ui;

  public DataGUI(CurvedLinesData data)
  {
    this.data  = data;
    file_ui    = new FileGUI(data, true);
    style_ui   = new StyleGUI(data.style);
    curves_ui  = new CurvesGUI(data.curves);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(curves_ui);
    addTab(style_ui);

    super.Init();

    cp5.getTab("Curves").bringToFront();
  }
}
