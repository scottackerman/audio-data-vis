import processing.opengl.*;
import krister.Ess.*;

AudioInput audioInput;
AudioChannel audioChannel;
FFT FFTProcessor;

PImage img;
int stageWidth = 1000;
int stageHeight = 400;
int sampleRate = 2048;
int imageScale = 2;
int[][] pixelValues;
int[][] redValues;
int[][] greenValues;
int[][] blueValues;
int[][] intensityValues;
color stageColor = #000000;
String imagePath = "darkSide.jpg";
String audioPath = "breathe.aif";
float posX;
float posY;
float lineWidth = 2;
float angleY;
float angleX;
float amplitudeMulitplier = 750;
float easing = 0.03;
float angle;
float lastMouseXPos;
float manualAngleIncrement = 4;
boolean mouseOverride;

void setup() {
  size(stageWidth, stageHeight, OPENGL);
  
  //AUDIO
  Ess.start(this);
  audioInput = new AudioInput();
  audioChannel = new AudioChannel(audioPath);
  FFTProcessor = new FFT(sampleRate);
  // EQUALIZE SPECTRUM DATA - FFT PARAMETER THAT WEIGHTS THE EQ FOR VISUALIZATION
  // TRUE = SINCE BASS NEEDS MUCH MORE AMPLITUDE FOR AUDIBILITY, THIS EVENS THINGS OUT
  // FALSE = MORE ACCURATE REPRESENTATION OF ACTUAL FREQUENCY WEIGHTS
  FFTProcessor.equalizer(true);
  audioChannel.play(Ess.FOREVER);
  audioInput.start();
  
  //IMAGE
  pixelValues = new int[width][height];
  redValues = new int[width][height];
  greenValues = new int[width][height];
  blueValues = new int[width][height];
  intensityValues = new int[width][height];
  img = loadImage(imagePath);
  for (int i=0; i<img.width; i++) {
    for (int j=0; j<img.height; j++) {
      pixelValues[i][j] = img.pixels[j*img.width + i];
      redValues[i][j] = int(red(pixelValues[i][j]));
      greenValues[i][j] = int(green(pixelValues[i][j]));
      blueValues[i][j] = int(blue(pixelValues[i][j]));
      // BEAR WITH ME, PART 1
      // THIS ADDS THE THREE COLOR VALUE INTENSITIES TOGETHER, THEN DEVIDES BY THREE
      // TO GET THE AVERAGE INTENSITY (DIFFERENT FROM BRIGHTNESS). SO WHITE (255,255,255)
      // WILL SHOW A HIGHER INTENSITY THAN BRIGHT GREEN (0,255,0).
      intensityValues[i][j] = (redValues[i][j]+greenValues[i][j]+blueValues[i][j])/3;
    }
  }
}

void draw() {
  background(stageColor);
  translate(width/2, height/2, 0);
  scale(imageScale);
  if(lastMouseXPos != mouseX){
    mouseOverride = false;
    posX = mouseX;
    posY = mouseY;
    //ROTATION IS BASED ON RADIANS, WHERE PI*2 = 1 FULL ROTATION (360 DEGREES), PI/2 = 90 DEGREES
  }
  lastMouseXPos = mouseX;
  angleY += (((PI*4)*(posX/width))-angleY)*easing;
  angleX += (((PI*4)*(posY/height))-angleX)*easing;
  rotateY(angleY);
  rotateX(angleX);
  FFTProcessor.getSpectrum(audioChannel);
  for (int i = 0; i < img.height; i += 2) {
    for (int j = 0; j < img.width; j += 2) {
      // DO NOT RENDER BLACK - ANYTING LESS THAN A VALUE OF 15 I'M CONSIDREING BLACK.
      if(intensityValues[j][i]>15){
        stroke(pixelValues[j][i], 200);
        strokeWeight(lineWidth);
        // BEAR WITH ME, PART 2
        // THIS GETS THE AUDIO AMPLITUDE AT THE FREQUNCY DEFINED BY THE INTENSITY VALUE OF THE CURRENT PIXEL, MULTIPLIED
        // BY SAMPLERATE/255. 255 REPRESENTS THE HIGHEST INTESITY VALUE, SO IF WHITE (255) IS MULTIPLIED BY SAMPLERATE/255,
        // IT WILL BE REPRESENTED BY THE AMPLITUDE OF THE FREQUENCY AT THE HIGHEST SAMPLE RATE. SO HIGHER INTENSITY COLORS
        // ARE DRAWN IN Z SPACE BY THE AMPLITUDES OF THE HIGHER FREQUNCIES.
        float lineAmplitude = (Math.abs(FFTProcessor.spectrum[intensityValues[j][i]]*(sampleRate/255)))*amplitudeMulitplier;
        line(j-img.width/2, i-img.height/2, lineAmplitude, j-img.width/2, i-img.height/2, -lineAmplitude);
      }
    }
  }
}

void keyPressed() {
  if (key == '1') {
    imageScale = 1;
    println("ZOOM OUT");
  }else if (key == '2') {
    imageScale = 2;
    println("ZOOM IN");
  }else if (key == '3') {
    lineWidth = 1;
    println("THIN BANDS");
  }else if (key == '4') {
    lineWidth = 2;
    println("MED BANDS");
  }else if (key == '5') {
    lineWidth = 5;
    println("WIDE BANDS");
  }else if (key == '6') {
    lineWidth = 10;
    println("MONSTER BANDS");
  }else if (key == '7') {
    lineWidth = 20;
    println("DEEP BANDS");
  }else if (key == CODED) {
    if (keyCode == UP) {
      mouseOverride = true;
      posY += manualAngleIncrement;
    }else if (keyCode == DOWN) {
      mouseOverride = true;
      posY -= manualAngleIncrement;
    }else if (keyCode == LEFT) {
      mouseOverride = true;
      posX -= manualAngleIncrement;
    }else if (keyCode == RIGHT) {
      mouseOverride = true;
      posX += manualAngleIncrement;
    }
  }
}
