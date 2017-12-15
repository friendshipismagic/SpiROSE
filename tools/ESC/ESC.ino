#include <Servo.h>

int value = 0; // set values you need to zero

Servo firstESC; //Create as much as Servoobject you want. You can controll 2 or more Servos at the same time

void setup() {

  firstESC.attach(9);    // attached to pin 9 I just do this with 1 Servo
  Serial.begin(9600);    // start serial at 9600 baud

}

void loop() {

//First connect your ESC WITHOUT Arming. Then Open Serial and follo Instructions
 
  firstESC.writeMicroseconds(value);
 
  if(Serial.available()) {
    int a = Serial.parseInt();    // Parse an Integer from Serial
    if(a == 0)
      value = 700;
    else if(a == 1)
      value = 2000;
    else
      value = a;
    Serial.println(value);
  }

}
