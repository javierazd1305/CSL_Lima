import processing.video.*;
import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.core.Mat;
import org.opencv.core.CvType;
import java.util.Collections;

PGraphics canvas;
PGraphics canvasOriginal;
PGraphics canvasColor;
PGraphics lengedColor;
PGraphics grayScale;


int sizeCanvas = 480; 
PImage colorImage;
PImage imageWrapped;
PImage capture;
float inc = 1;

Boolean refresh = false;
ArrayList<PVector> posibles = new ArrayList();
ArrayList<PVector> calibrationPoints = new ArrayList();

Capture cam;
OpenCV opencv;
Corners corners;
WrappedPerspective wrappedPerspective;
ColorRange colorRange;
Mesh mesh;
BloackReader blockReader;
Configuration config = new Configuration("data/calibrationParameters.json");


void settings(){
  size(sizeCanvas*2, sizeCanvas);
}


void setup() {
  colorMode(HSB,360,100,100);
  String[] cameras = Capture.list();
  print(cameras.length);
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    canvas = createGraphics(sizeCanvas,sizeCanvas);
    canvasOriginal = createGraphics(sizeCanvas, sizeCanvas);
    grayScale = createGraphics(sizeCanvas, sizeCanvas);
    colorImage = createImage(sizeCanvas, sizeCanvas, HSB);
    imageWrapped = createImage(sizeCanvas, sizeCanvas, HSB);
    
    corners = new Corners(grayScale);

    config.loadConfiguration();
    
    mesh = new Mesh(config.nblocks, canvas.width);

    wrappedPerspective = new WrappedPerspective(config.contour);
    
    cam = new Capture(this,canvas.width, canvas.height, cameras[0]);
    cam.start();

    String[] args = {"Animation"};
    String[] name = {"color"};
    blockReader = new BloackReader(sizeCanvas,sizeCanvas);
    colorRange = new ColorRange(config.colorLimits, 600, 100);
    PApplet.runSketch(name,colorRange);
    PApplet.runSketch(args, blockReader);
    
    opencv = new OpenCV(this, cam);
    opencv.useColor(HSB);
    frameRate(5);
  }
}


void draw() {
  
  corners.applyHCD(refresh, wrappedPerspective);
  
  canvasOriginal.beginDraw();
  config.flip(canvasOriginal, cam, true);
  wrappedPerspective.draw(canvasOriginal);
  config.SBCorrection(canvasOriginal,config.brightnessLevel,config.saturationLevel);
  corners.drawCalibrationPoints(canvasOriginal, refresh);

  canvasOriginal.endDraw();
  image(canvasOriginal, 0, 0);
  

  //Filter colors with specific ranges
  config.applyFilter(canvasOriginal,colorImage);
  
  //canvas with the color processing and wrapped image
  colorImage.updatePixels();
  opencv.loadImage(colorImage);
  opencv.toPImage(wrappedPerspective.warpPerspective(sizeCanvas - config.resizeCanvas.get(0), sizeCanvas - config.resizeCanvas.get(1)), imageWrapped);
  
  canvas.beginDraw();
  canvas.background(255);
  imageWrapped.resize(canvas.width - config.resizeCanvas.get(0), canvas.height - config.resizeCanvas.get(1));
  canvas.image(imageWrapped, 0, 0);
  mesh.getColors(canvas, config.colorLimits);
  mesh.draw(canvas, false);
  canvas.endDraw();
  image(canvas, canvas.width, 0);
}


void keyPressed(KeyEvent e) {
  switch(e.getKeyCode()){
    case UP:
    config.brightnessLevel += inc;
    println(config.brightnessLevel);
    break;
     
    case DOWN:
    config.brightnessLevel -= inc;
    println(config.brightnessLevel);
    break;
     
    case RIGHT:
    config.saturationLevel += inc;
    println(config.saturationLevel);
    break;
     
    case LEFT:
    config.saturationLevel -= inc;
    println(config.saturationLevel);
    break;
   }
   
   switch(key){
     case 's':
     config.safeConfiguration(colorRange.selectAll());
     break;
     

     case 'r':
     print(true);
     refresh = !refresh;

     case '+':
     config.nblocks ++;
     mesh.actualize(config.nblocks, canvas.width);
     config.actualizeSizeCanvas(canvas.width % config.nblocks,canvas.height % config.nblocks);
     break;
     
     case '-':
     config.nblocks--;
     mesh.actualize(config.nblocks, canvas.width);
     config.actualizeSizeCanvas(canvas.width % config.nblocks,canvas.height % config.nblocks);
     break;    
   }

}

void captureEvent(Capture cam){
  cam.read();
}

void mouseClicked(){
  //print("\n",hue(this.get(mouseX,mouseY)),saturation(this.get(mouseX,mouseY)),brightness(this.get(mouseX,mouseY)));
  print("\n", calibrationPoints);
  print("\n",mouseX,mouseY);
}
void mousePressed(){
  wrappedPerspective.selected(mouseX,mouseY,5);
}

void mouseReleased(){
  wrappedPerspective.unSelect();
}

void mouseDragged(){
  wrappedPerspective.move(mouseX,mouseY);
}