#include "stdafx.h"
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <windows.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>
#include <thrust\sort.h>
#include <thrust\scan.h>
#include <thrust\host_vector.h>
#include <thrust\device_vector.h>
#include <thrust\fill.h> 
#include <thrust\sequence.h>
#include <thrust\copy.h>



template<typename Argument1, typename Argument2, typename Result> struct binary_function  : public std::binary_function<Argument1, Argument2, Result>{};



//timer stuff
double PCFreq = 0.0;
__int64 CounterStart = 0;

//yeah it's really 112 or 480 (for me), but for testing 512 is easier
#define numOfCudaCores = 512;

__global__ void merge_x(float3* dPoints, int size)
{	
	int sizeOfSubArray=size;
	int x = blockIdx.x*blockDim.x + threadIdx.x;
	int i = x * sizeOfSubArray;
	int n = i + sizeOfSubArray;
	int m = 1;
	//bottom-up merge sort
	while(m<=n)
	{
		i = x * sizeOfSubArray;
		while(i<(n-m))
		{
			int endPos = (i+2*m-1) > (n-1) ? (n-1) : (i+2*m-1);
			//the merging part aka insertion
			int lenSubArr = (i + (endPos - i));
			int w = i;
			while(w<lenSubArr)
			{
				w=i;
				for(int r = (i+1); r <= lenSubArr; r++)
				{
					if(dPoints[w].x<dPoints[r].x)
					{
						w=r;
					}
				}
				float temp1 = dPoints[w].x;
				float temp2 = dPoints[w].y;
				float temp3 = dPoints[w].z;
				dPoints[w].x=dPoints[lenSubArr].x;
				dPoints[w].y=dPoints[lenSubArr].y;
				dPoints[w].z=dPoints[lenSubArr].z;
				dPoints[lenSubArr].x=temp1;
				dPoints[lenSubArr].y=temp2;
				dPoints[lenSubArr].z=temp3;
				lenSubArr--;
			}
			i = i + 2 * m;
		}
		m = m * 2;
	}	
}

__global__ void merge_y(float3* dPoints, int size)
{	
	int sizeOfSubArray=size;
	int x = blockIdx.x*blockDim.x + threadIdx.x;
	int i = x * sizeOfSubArray;
	int n = i + sizeOfSubArray;
	int m = 1;
	//bottom-up merge sort
	while(m<=n)
	{
		i = x * sizeOfSubArray;
		while(i<(n-m))
		{
			int endPos = (i+2*m-1) > (n-1) ? (n-1) : (i+2*m-1);
			//the merging part aka insertion
			int lenSubArr = (i + (endPos - i));
			int w = i;
			while(w<lenSubArr)
			{
				w=i;
				for(int r = (i+1); r <= lenSubArr; r++)
				{
					if(dPoints[w].y<dPoints[r].y)
					{
						w=r;
					}
				}
				float temp1 = dPoints[w].x;
				float temp2 = dPoints[w].y;
				float temp3 = dPoints[w].z;
				dPoints[w].x=dPoints[lenSubArr].x;
				dPoints[w].y=dPoints[lenSubArr].y;
				dPoints[w].z=dPoints[lenSubArr].z;
				dPoints[lenSubArr].x=temp1;
				dPoints[lenSubArr].y=temp2;
				dPoints[lenSubArr].z=temp3;
				lenSubArr--;
			}
			i = i + 2 * m;
		}
		m = m * 2;
	}	
}

__global__ void merge_z(float3* dPoints, int size)
{	
	int sizeOfSubArray=size;
	int x = blockIdx.x*blockDim.x + threadIdx.x;
	int i = x * sizeOfSubArray;
	int n = i + sizeOfSubArray;
	int m = 1;
	//bottom-up merge sort
	while(m<=n)
	{
		i = x * sizeOfSubArray;
		while(i<(n-m))
		{
			int endPos = (i+2*m-1) > (n-1) ? (n-1) : (i+2*m-1);
			//the merging part aka insertion
			int lenSubArr = (i + (endPos - i));
			int w = i;
			while(w<lenSubArr)
			{
				w=i;
				for(int r = (i+1); r <= lenSubArr; r++)
				{
					if(dPoints[w].z<dPoints[r].z)
					{
						w=r;
					}
				}
				float temp1 = dPoints[w].x;
				float temp2 = dPoints[w].y;
				float temp3 = dPoints[w].z;
				dPoints[w].x=dPoints[lenSubArr].x;
				dPoints[w].y=dPoints[lenSubArr].y;
				dPoints[w].z=dPoints[lenSubArr].z;
				dPoints[lenSubArr].x=temp1;
				dPoints[lenSubArr].y=temp2;
				dPoints[lenSubArr].z=temp3;
				lenSubArr--;
			}
			i = i + 2 * m;
		}
		m = m * 2;
	}	
}

struct float3Array
{
	float* x;
	float* y;
	float* z;
	int* index;
};

struct node
{
	 float3 point;
	 int index;
	 node *parent;
	 node *leftChild;
	 node *rightChild;
};

struct compare_float3_x
{
	__host__ __device__
	bool operator()(float3 a, float3 b)
	{
		return a.x < b.x;
	}
};
struct compare_float3_y
{
	__host__ __device__
	bool operator()(float3 a, float3 b)
	{
		return a.y < b.y;
	}
};
struct compare_float3_z
{
	__host__ __device__
	bool operator()(float3 a, float3 b)
	{
		return a.z < b.z;
	}
};

//specialMaximum retuns the maximum value between two integers
//unless if they are equal, then it will return the integer++
//this will be used to update our SubArray
template<typename T>
struct specialMaximum : public thrust::binary_function<T,T,T>
{
	__host__ __device__ 
	const T operator()(const T &lhs, const T &rhs) const
	{
	  if(lhs<rhs)
	  {
		 return (((int)rhs)+1);
	  }
	  if(lhs==rhs)
	  {
		  if(lhs==0)
		  {
			  return 0;
		  }
		  return (((int)rhs)+1);
	  }
	  return lhs < rhs ? rhs : lhs;
  }
};


float3 make_random_float3(void);
void StartCounter();
double GetCounter();
int constructKD(thrust::device_vector<float3>& dPoints, int whichDim, int begin, int end,	compare_float3_x& comp_x, compare_float3_y& comp_y ,compare_float3_z& comp_z, int numLevels);

int main(int argc, char* argv[])
{	
	int deviceCount = 0;
    cudaGetDeviceCount(&deviceCount);
	cudaSetDevice(0);
	/*if(deviceCount>1)
	{
		//1=9800gt, 0=gtx480
		//we want to develop/debug on the non-primary device if possible (at least on Windows)
		//set value to 0 for release builds or comment this line out
		cudaSetDevice(1);
	}*/
		
	int numOfTriangles = 0;
	int numOfVertexes = 0;
	std::string line;
	char* file = "teapot.obj";
	std::ifstream myfile (file);
	size_t found;
	size_t found2;
	size_t found3;
	size_t found4;
	
	if (myfile.is_open())
	{
		while ( myfile.good() )
		{
	      std::getline (myfile,line);
		  found=line.find("f");
		  found4=line.find("#");
		  found2=line.find("v");
		  found3=line.find("n");
		  if (found!=std::string::npos && (!(found4!=std::string::npos)))
		  {
			  numOfTriangles++;
		  }
		  if ((found2!=std::string::npos) && (!(found3!=std::string::npos)))
		  {
			  numOfVertexes++;
		  }

	    }
		myfile.close();
	}
    else printf("Unable to open file");

	//how many Points we will have
	int numOfPoints=numOfTriangles;
	numOfTriangles=numOfTriangles*3;
	numOfVertexes=numOfVertexes*3;
	
	//creating the arrays on host
	thrust::host_vector<float> vertexArr(numOfVertexes);
	thrust::host_vector<float> triangleArr(numOfTriangles);
	thrust::host_vector<int> hSubArray(numOfPoints);
	thrust::host_vector<float3> hPoints(numOfPoints);

	//generating random numbers
	//thrust::generate(hPoints.begin(), hPoints.end(), make_random_float3);
	//fill index array
	thrust::fill(hSubArray.begin(), hSubArray.end(), 0);

	std::ifstream myfile2 (file);
	int current=0;
	if (myfile2.is_open())
	{
		while ( myfile2.good() )
		{
	      std::getline (myfile2,line);
		  found2=line.find("v");
		  found3=line.find("n");
		  if ((found2!=std::string::npos) && (!(found3!=std::string::npos)))
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
			  vertexArr[current]= atof((char*)test.c_str());
			  current++;

			  std::string test2=line.substr(temp2,(temp2End-temp2));
			  vertexArr[current]=atof((char*)test2.c_str());
			  current++;

			  std::string test3=line.substr(temp3);
			  vertexArr[current]=atof((char*)test3.c_str());
			  current++;

		  }

	    }
		myfile2.close();
	}
    else printf("Unable to open file");

	std::ifstream myfile3 (file);
	current=0;
	if (myfile3.is_open())
	{
		while ( myfile3.good() )
		{
	      std::getline (myfile3,line);

		  found=line.find("f");
		  found4=line.find("#");
		  if (found!=std::string::npos && (!(found4!=std::string::npos)))
		  {
			  found=line.find_first_not_of(" ",1);
			  int temp = (int(found));
			  found=line.find_first_of(" ",temp);
			  int tempEnd = (int(found));
			  found=line.find_first_not_of(" ",tempEnd);
			  int temp2 = (int(found));
			  found=line.find_first_of(" ",temp2);
			  int temp2End = (int(found));
			  found2=line.find_first_not_of(" ",temp2End);
			  int temp3 = (int(found));

			  std::string test = line.substr(temp,(tempEnd-temp));	
			  int firstTri = (((atoi((char*)test.c_str()))-1)*3);
			  std::string test2=line.substr(temp2,(temp2End-temp2));
			  int secondTri = (((atoi((char*)test2.c_str()))-1)*3);
			  std::string test3=line.substr(temp3);
			  int thirdTri = (((atoi((char*)test3.c_str()))-1)*3);
			  
			  float midX = (vertexArr[firstTri]+vertexArr[secondTri]+vertexArr[thirdTri])/3;
			  float midY = (vertexArr[firstTri+1]+vertexArr[secondTri+1]+vertexArr[thirdTri+1])/3;
			  float midZ = (vertexArr[firstTri+2]+vertexArr[secondTri+2]+vertexArr[thirdTri+2])/3;

			  triangleArr[current]= midX;
			  current++;
			  triangleArr[current]= midY;
			  current++;
			  triangleArr[current]= midZ;
			  current++;
		  }
		}
		myfile3.close();
	}
	else printf("Unable to open file");


	for(int w=0;w<numOfTriangles;w+=3)
	{
		int t = w/3;
		hPoints[t].x=triangleArr[w];
		hPoints[t].y=triangleArr[w+1];
		hPoints[t].z=triangleArr[w+2];
	}
	 
	//transfering values to device
	thrust::device_vector<float3> dPoints=hPoints;
	thrust::device_vector<int> dSubArray=hSubArray;
	double elapsed_time=0;
	compare_float3_x comp_x;
	compare_float3_y comp_y;
	compare_float3_z comp_z;

	int numLevels = 3;

	//Normally we would have the next three lines of code
	//int totalLevels = ((int) log2(numOfPoints+0.0f));
	//int numLevels = ((int) log2(512.0f));//this means keep going until we hit 512 subArrays
	//int * ptr = thrust::raw_pointer_cast(&dPoints[0]);

	cudaThreadSynchronize();
	StartCounter();


	int whichDim = constructKD(dPoints, 0, 0, numOfPoints, comp_x, comp_y, comp_z, numLevels);
	/*
	int currentLevel=numLevels;
	int numPartitions = 0;
	int nBlocks =0;
	while(currentLevel<=maxLevel)
	{
		numPartitions = ((int) pow(2.0f,currentLevel+0.0f));
		nBlocks = numPartitions/numOfCudaCores + (numPartitions%numOfCudaCores == 0?0:1);
		switch(whichDim)
		{
		case 0:
			merge_x <<< nBlocks, numPartitions,0 >>> (ptr,numPartitions);
			whichDim=1;
			break;
		case 1:
			merge_y <<< nBlocks, numPartitions,0 >>> (ptr,numPartitions);
			whichDim=2;
			break;
		case 2:
			merge_z <<< nBlocks, numPartitions,0 >>> (ptr,numPartitions);
			whichDim=0;
			break;
		default:
			printf("You shouldn't be here; i.e. wrong case number");
			break;
		}
		currentLevel++;
	}
	*/

	cudaThreadSynchronize();
	printf("Time elapsed: %G seconds\n", GetCounter());
	thrust::copy(dPoints.begin(), dPoints.end(), hPoints.begin());
	std::ofstream myOut ("kdtree.will");
	int blockNum = (pow(2.0f,numLevels));
	int blockSize = numOfPoints/blockNum;
	myOut << "$ " << blockNum << "\n";
	myOut << "& " << blockSize << "\n";
	for(int i=0; i<numOfPoints;i++)
	{
		if (myOut.is_open())
		{
			if( (!(i==0)) && i%blockSize==0)
			{
				myOut << "# " << hPoints[i].x << " " << hPoints[i].y << " " << hPoints[i].z << "\n";
			}
			else
			{
				myOut << "! " << hPoints[i].x << " " << hPoints[i].y << " " << hPoints[i].z << "\n";
			}
		}
		 else std::cout << "Unable to open file\n";
	}
	myOut<< "\n";
	myOut.close();
	//RAWR END
}

//creates a float3 with three random numbers
float3 make_random_float3(void)
{
	return make_float3( rand()+(rand()/(RAND_MAX + 1.0f)), rand()+(rand()/(RAND_MAX + 1.0f)), rand()+(rand()/(RAND_MAX + 1.0f)));
}

//whichDim simply means which dimension we are sorting by, 0 = x, 1 = y, 2 = z
int constructKD(thrust::device_vector<float3>& dPoints, int whichDim, int begin, int end,	compare_float3_x& comp_x, compare_float3_y& comp_y ,compare_float3_z& comp_z, int numLevels)
{
	switch(whichDim)
	{
	case 0:
		thrust::sort(dPoints.begin()+begin, dPoints.begin()+end, comp_x);	
		break;
	case 1:
		thrust::sort(dPoints.begin()+begin, dPoints.begin()+end, comp_y);
		break;
	case 2:
		thrust::sort(dPoints.begin()+begin, dPoints.begin()+end, comp_z);
		break;
	default:
		printf("You shouldn't be here; i.e. wrong case number");
		break;
	}

	switch(whichDim)
	{
	case 0:
		whichDim=1;
		break;
	case 1:
		whichDim=2;
		break;
	case 2:
		whichDim=0;
		break;
	default:
		printf("You shouldn't be here; i.e. wrong case number");
		break;
	}
	
	numLevels--;
	int numOfPoints = end-begin;
	int lowerBound = ((int)numOfPoints/2)+begin;
	int upperBound = ((int)numOfPoints/2)+1+begin;
	int toReturn=0;
	if(numLevels>0)
	{		
		toReturn=constructKD(dPoints, whichDim, begin, lowerBound, comp_x, comp_y, comp_z, numLevels);
		toReturn=constructKD(dPoints, whichDim, upperBound, end, comp_x, comp_y, comp_z, numLevels);
	}
	toReturn=whichDim;
	return toReturn;
}

void StartCounter()
{
    LARGE_INTEGER li;
    if(!QueryPerformanceFrequency(&li))
	printf("QueryPerformanceFrequency failed!\n");

    //Below is for seconds
	PCFreq = double(li.QuadPart);
	//Below is for milliseconds
	//PCFreq = double(li.QuadPart)/1000.0;
	//Below is for microseconds
	//PCFreq = double(li.QuadPart)/1000000.0;

    QueryPerformanceCounter(&li);
    CounterStart = li.QuadPart;
}
double GetCounter()
{
    LARGE_INTEGER li;
    QueryPerformanceCounter(&li);
    return double(li.QuadPart-CounterStart)/PCFreq;
}