/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtGui>
#include <QtOpenGL>

#include <math.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <string>
#include <sstream>
#include <time.h>

#include "glwidget.h"
#include "qtlogo.h"

#ifndef GL_MULTISAMPLE
#define GL_MULTISAMPLE  0x809D
#endif
const int myHeight = 800;
const int myWidth = 800;
int numOfTriangles = 3051;
int numOfVertexes = 0;
float triangleArr[3051];
float rootArr[21];
float colorX[7];
float colorY[7];
float colorZ[7];
int blockSize = 0;
int power = 0;
int numberOfPoints=0;


//! [0]
GLWidget::GLWidget(QWidget *parent)
    : QGLWidget(QGLFormat(QGL::SampleBuffers), parent)
{
	logo = 0;
    xRot = 0;
    yRot = 0;
    zRot = 0;
    qtGreen = QColor::fromCmykF(0.40, 0.0, 1.0, 0.0);
    qtPurple = QColor::fromCmykF(0.75, 0.75, 0.0, 0.20);

	std::string line;
	std::string line2;
	char* weep = "kdtree.will"; 
	std::ifstream myfileW (weep);
	size_t found;
	size_t found2;
	size_t found3;
	size_t found4;
	int current=0;
	int current2=0;
	if (myfileW.is_open())
	{
		while ( myfileW.good() )
		{
	      std::getline (myfileW,line);
		  found=line.find("$");
		  found2=line.find("&");
		  found3=line.find("#");
		  found4=line.find("!");
		  if (found!=std::string::npos)
		  {
			  found2=line.find_first_not_of(" ",1);
			  int temp = (int(found2));

			  std::string test = line.substr(temp);	
			  power = atoi((char*)test.c_str());
		  }
		  else if ((found2!=std::string::npos))
		  {
			  found2=line.find_first_not_of(" ",1);
			  int temp = (int(found2));

			  std::string test = line.substr(temp);	
			  blockSize = atoi((char*)test.c_str());
		  }
		  else if ((found3!=std::string::npos))
		  {
			  found2=line.find_first_not_of(" ",1);
			  int temp = (int(found2));
			  found2=line.find_first_of(" ",temp);
			  int tempEnd = (int(found2));
			  found2=line.find_first_not_of(" ",tempEnd);
			  int temp2 = (int(found2));
			  found2=line.find_first_of(" ",temp2);
			  int temp2End = (int(found2));
			  found2=line.find_first_not_of(" ",temp2End);
			  int temp3 = (int(found2));

			  std::string test = line.substr(temp,(tempEnd-temp));	
			  rootArr[current2]= atof((char*)test.c_str());
			  current2++;

			  std::string test2=line.substr(temp2,(temp2End-temp2));
			  rootArr[current2]=atof((char*)test2.c_str());
			  current2++;

			  std::string test3=line.substr(temp3);
			  rootArr[current2]=atof((char*)test3.c_str());
			  current2++;
		  }
		  else if ((found4!=std::string::npos))
		  {
			  found2=line.find_first_not_of(" ",1);
			  int temp = (int(found2));
			  found2=line.find_first_of(" ",temp);
			  int tempEnd = (int(found2));
			  found2=line.find_first_not_of(" ",tempEnd);
			  int temp2 = (int(found2));
			  found2=line.find_first_of(" ",temp2);
			  int temp2End = (int(found2));
			  found2=line.find_first_not_of(" ",temp2End);
			  int temp3 = (int(found2));

			  std::string test = line.substr(temp,(tempEnd-temp));	
			  triangleArr[current]= atof((char*)test.c_str());
			  current++;

			  std::string test2=line.substr(temp2,(temp2End-temp2));
			  triangleArr[current]=atof((char*)test2.c_str());
			  current++;

			  std::string test3=line.substr(temp3);
			  triangleArr[current]=atof((char*)test3.c_str());
			  current++;
		  }

	    }
		myfileW.close();
	}
    else std::cout << "Unable to open file";
	numberOfPoints=blockSize*power;

    srand ( time(NULL) );
	for(int color=0;color<7;color++)
	{
			 colorX[color] = ((float)rand()/RAND_MAX);
			 colorY[color] = ((float)rand()/RAND_MAX);
			 colorZ[color] = ((float)rand()/RAND_MAX);
	}
}
//! [0]

//! [1]
GLWidget::~GLWidget()
{
}
//! [1]

//! [2]
QSize GLWidget::minimumSizeHint() const
{
    return QSize(50, 50);
}
//! [2]

//! [3]
QSize GLWidget::sizeHint() const
//! [3] //! [4]
{
    return QSize(800, 800);
}
//! [4]

static void qNormalizeAngle(int &angle)
{
    while (angle < 0)
        angle += 360 * 16;
    while (angle > 360 * 16)
        angle -= 360 * 16;
}

//! [5]
void GLWidget::setXRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != xRot) {
        xRot = angle;
        emit xRotationChanged(angle);
        updateGL();
    }
}
//! [5]

void GLWidget::setYRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != yRot) {
        yRot = angle;
        emit yRotationChanged(angle);
        updateGL();
    }
}

void GLWidget::setZRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != zRot) {
        zRot = angle;
        emit zRotationChanged(angle);
        updateGL();
    }
}



//! [6]
void GLWidget::initializeGL()
{
	 //glDisable(GL_TEXTURE_2D);
     //glDisable(GL_DEPTH_TEST);
     //glDisable(GL_COLOR_MATERIAL);

     glEnable(GL_BLEND);
	 glEnable(GL_POINT_SMOOTH);
	
     //glEnable(GL_POLYGON_SMOOTH);
     glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     glClearColor(1.0, 1.0, 1.0, 1.0);
	 glClearDepth(1.0f);							// Depth Buffer Setup
	 glEnable(GL_DEPTH_TEST);						// Enables Depth Testing
	 glDepthFunc(GL_LEQUAL);	
	 glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	 glShadeModel(GL_FLAT);
 
}
//! [6]

//! [7]

float getMinX()
{
	 int current=1;
	 int minX = triangleArr[0];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle]<minX)
		 {
			 minX=triangleArr[currentTriangle];
		 }
		 current++;
	 }
	 return minX;
}

float getMaxX()
{
	 int current=1;
	 int maxX = triangleArr[0];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle]>maxX)
		 {
			 maxX=triangleArr[currentTriangle];
		 }
		 current++;
	 }
	 return maxX;
}

float getMinY()
{
	 int current=1;
	 int minY = triangleArr[1];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle+1]<minY)
		 {
			 minY=triangleArr[currentTriangle+1];
		 }
		 current++;
	 }
	 return minY;
}

float getMaxY()
{
	 int current=1;
	 int maxY = triangleArr[1];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle+1]>maxY)
		 {
			 maxY=triangleArr[currentTriangle+1];
		 }
		 current++;
	 }
	 return maxY;
}

float getMinZ()
{
	 int current=1;
	 int minZ = triangleArr[2];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle+2]<minZ)
		 {
			 minZ=triangleArr[currentTriangle+2];
		 }
		 current++;
	 }
	 return minZ;
}

float getMaxZ()
{
	 int current=1;
	 int maxZ = triangleArr[2];
	 while(current<numOfTriangles)
	 {
		 int currentTriangle = current*3;
		 if(triangleArr[currentTriangle+2]>maxZ)
		 {
			 maxZ=triangleArr[currentTriangle+2];
		 }
		 current++;
	 }
	 return maxZ;
}

void makePoint(float x, float y, float z, float colorX, float colorY, float colorZ, float size)
{
	glPointSize(size);
	
	glColor3f(colorX, colorY, colorZ);
	glBegin(GL_POINTS);
	
	glVertex3f(x, y, z); 

	glEnd();
}

void makeBox(float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3,
			 float x4, float y4, float z4, float x5, float y5, float z5, float x6, float y6, float z6,
			 float x7, float y7, float z7, float x8, float y8, float z8, float colorX, float colorY, float colorZ)
{
	glColor4f(colorX,colorY,colorZ,.1);

	glBegin(GL_QUADS);

	glVertex3f(x7,y7,z7);
	glVertex3f(x3,y3,z3);
	glVertex3f(x1,y1,z1);
	glVertex3f(x5,y5,z5);

	glVertex3f(x7,y7,z7);
	glVertex3f(x8,y8,z8);
	glVertex3f(x6,y6,z6);
	glVertex3f(x5,y5,z5);

	glVertex3f(x4,y4,z4);
	glVertex3f(x3,y3,z3);
	glVertex3f(x1,y1,z1);
	glVertex3f(x2,y2,z2);

	glVertex3f(x7,y7,z7);
	glVertex3f(x3,y3,z3);
	glVertex3f(x4,y4,z4);
	glVertex3f(x8,y8,z8);

	glVertex3f(x8,y8,z8);
	glVertex3f(x4,y4,z4);
	glVertex3f(x2,y2,z2);
	glVertex3f(x6,y6,z6);

	glVertex3f(x6,y6,z6);
	glVertex3f(x5,y5,z5);
	glVertex3f(x1,y1,z1);
	glVertex3f(x2,y2,z2);

	glEnd();
}

void GLWidget::paintGL()
{
	 glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	 glLoadIdentity();
	 gluLookAt(0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
	//glTranslatef(0,0,-100);
	//glRotatef(45.0,1,1,1);
	glTranslatef(0.0, 0.0, -10.0);
    glRotatef(xRot / 16.0, 1.0, 0.0, 0.0);
    glRotatef(yRot / 16.0, 0.0, 1.0, 0.0);
    glRotatef(zRot / 16.0, 0.0, 0.0, 1.0);
     int pointSize=3;
	 int current11=0;
	 int current22=0;
	 int current33=0;
	 while(current33<numberOfPoints)
	 {	 
		 int currentRoot = current22 * 3;
		 int currentTriangle = current11 * 3;
		 if( (!(current33==0)) && (current33%blockSize==0) )
		 {
			 makePoint(rootArr[currentRoot],rootArr[currentRoot+1],rootArr[currentRoot+2],0,0,0,pointSize);
			 current22++;
		 }
		 else
		 {
			makePoint(triangleArr[currentTriangle],triangleArr[currentTriangle+1],triangleArr[currentTriangle+2],colorX[current22],colorY[current22],colorZ[current22],pointSize);
			current11++;
		 }
		 current33++;
	 }

}
//! [7]

//! [8]
void GLWidget::resizeGL(int width, int height)
{
	 glViewport(0, 0, width, height);
     glMatrixMode(GL_PROJECTION);
     glLoadIdentity();
     //gluOrtho2D(0, width, 0, height); // set origin to bottom left corner
     //gluPerspective(90.0, 1, .1, 999.0);
	 gluPerspective(90.0, (width/height), .1, 250.0);
	 //glFrustum(-1.0, 1.0, -1.0, 1.0, 1.5, 20.0);
	 glMatrixMode(GL_MODELVIEW);
	 //glLoadIdentity();
}
//! [8]

//! [9]
void GLWidget::mousePressEvent(QMouseEvent *event)
{
	lastPos = event->pos();
}
//! [9]

//! [10]
void GLWidget::mouseMoveEvent(QMouseEvent *event)
{
    int dx = event->x() - lastPos.x();
    int dy = event->y() - lastPos.y();

    if (event->buttons() & Qt::LeftButton) {
        setXRotation(xRot + 8 * dy);
        setYRotation(yRot + 8 * dx);
    } else if (event->buttons() & Qt::RightButton) {
        setXRotation(xRot + 8 * dy);
        setZRotation(zRot + 8 * dx);
    }
    lastPos = event->pos();
}
//! [10]