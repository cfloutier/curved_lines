import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

CurvedLinesData data;
DataGUI dataGui;

PGraphics current_graphics;
ControlP5 cp5;

CurvedLinesGenerator generator;

void setup()
{
  size(1200, 800);
  pixelDensity(1);
  surface.setResizable(true);

  data = new CurvedLinesData();
  dataGui = new DataGUI(data);

  generator = new CurvedLinesGenerator(data.curves);

  setupControls();

  file_ui.export_group = generator.group;

  data.LoadSettings("./Settings/default.json");
  dataGui.setGUIValues();
}

void setupControls()
{
  cp5 = new ControlP5(this);
  cp5.getTab("default").setLabel("Hide GUI");
  dataGui.Init();
}

void draw()
{
  start_draw();

  if (data.any_change())
  {
    generator.build();
    file_ui.updateExportScale(generator.group.getBoundingBox(
      data.page.clipping, data.page.clip_width, data.page.clip_height));
    data.reset_all_changes();
  }

  strokeWeight(data.style.lineWidth);
  stroke(data.style.lineColor.col);
  noFill();

  generator.group.draw(data.page.clipping, data.page.clip_width, data.page.clip_height);

  if (data.curves.draw_handles)
    generator.drawHandles();

  end_draw();

  dataGui.draw();
}
