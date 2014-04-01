
#include <iostream>
#include <cuda.h>
#include <time.h>
#include <math.h>
using namespace std;

    // 테스트 용이므로 일단 자료 크기는 1000으로
    // 1D이니까 그냥 블럭사이즈는 512로
    // EP는 슬라이스의 사이즈

//10만개부터 에러났음. 아마 랜덤 숫자 만들어내는 데, 아니면 GPU메모리 상에서 문제가 발생한 것 같음.
// 만일 화면 데이터를 정렬한다고 하면, 2560x1600 = 4,096,000 픽셀이니까 GPU메모리 상에서의 문제가
// 아니라 랜덤 숫자 만들어내는 곳에서 문제가 발생한 것일 수도...
#define DATASIZE    100000
#define BLOCK_SIZE    512

__global__ void oddevensort ( int * input, unsigned int len, int i )
{
     //개별 블럭의 좌표
    unsigned int tx = threadIdx.x;

    //전체 이미지의 좌표
    unsigned int x = tx + blockDim.x * blockIdx.x;
    //이동에 쓸 임시 변수
    int temp;

    //자료의 길이만큼 돌리는데, 인덱스(i)가 짝수이면 데이터의 짝수자리와 그 다음 숫자를 비교.
    //인덱스가 홀수이면 데이터의 홀수자리와 그 다음 숫자를 비교해서 정렬한다.
    if( i % 2 == 0 )
    {
    		// 길이를 측정안해주면 블럭에 남아있던 자리에 있는 자료가 튀어나올 수 있으니 조심.
    	if( input[x] > input[x+1] && x < len && x % 2 == 0)
    	{
    		temp = input[x+1];
    		input[x+1] = input[x];
        	input[x] = temp;
        }
    }
    else
    {
    	if( input[x] > input[x+1] && x < len && x % 2 != 0)
        {
    		temp = input[x+1];
        	input[x+1] = input[x];
        	input[x] = temp;
        }
    }
    	__syncthreads();
}



int main()
{
    // 테스트에 쓸 숫자 생성
    int TestInput[DATASIZE], TestOutput[DATASIZE];

    srand(time(NULL));

    for( int i = 0; i < DATASIZE; i++ )
    {
        TestInput[i] = rand() % 500;
    }

    //device 설정
    int *devInput, *devOutput;
    //일단 크기는 아니까
    unsigned int MemDataSize = DATASIZE * sizeof(int);

    // device 자리 잡아주고
    cudaMalloc((void**)&devInput, MemDataSize );
    cudaMalloc((void**)&devOutput, MemDataSize );
    cudaMemset( devOutput, 0, MemDataSize );

    // 자리 잡았으면 복사
    cudaMemcpy( devInput, TestInput, MemDataSize, cudaMemcpyHostToDevice);

    // block 크기 설정
    // 1D 이니까, 그냥 간단하게...
    dim3    dimBlocksize( BLOCK_SIZE );
    dim3    dimGridsize( ceil((DATASIZE-1)/(float)BLOCK_SIZE) + 1 );
    // 일단 Max값과 min값을 알아내야됨.
    // 처음부터 끝까지 휙 둘러보면 되니 이건 CPU에게 맡김.

    for( int i=0; i<DATASIZE; i++)
    {
    	oddevensort<<< dimGridsize, dimBlocksize >>>( devInput, DATASIZE, i );
    }

    // 결과물 복사
    cudaMemcpy( TestOutput, devInput, MemDataSize, cudaMemcpyDeviceToHost);

    for( int i=0; i<DATASIZE; i++ )
    {
    	cout << TestOutput[i] << ", ";
    	if( (i+1)%10 == 0 )
    	{
    		cout << endl;
    	}
    }

    // 위에 GPU에 마련한 자리 해소. 그때 그때 해놓는 게 편할 듯
    cudaFree( devInput );
    cudaFree( devOutput );

    return 0;
}
