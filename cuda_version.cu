#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>

float max_norm(float *matrix, int m, int n);
float frob_norm(float *matrix, int m, int n);
float one_norm(float *matrix, int m, int n);
float inf_norm(float *matrix, int m, int n);


// #threads
int block_size = 32;	

//================================================================ 
// One global function for each norm, which will
// be called by curly brackets within a function, say,
// 'calculate_norm_on_gpu'


__global__ void add_arrays_gpu(float *matrix, int m, int n){
	// idx is a unique ID for each thread
	//      ( block index * threads ) + thread index
	int idx = blockIdx.x*blockDim.x + threadIdx.x;
	int k;
	int max = 0;
	if(idx<m) // For each row
		for(k=0; k<n; k++){
			if( fabsf(matrix_d[idx*m + k]) > max ){
				max = fabsf(matrix_d[idx*m + k]);	
			}
		}
	// Store local max somewhere
	
}

//================================================================

double max_norm_gpu(int m, int n ){
	// On device
	float *matrix_d
	cudaMalloc ((void **) &matrix_d, sizeof(float)*m*n);
	// Copy data from host memory to device
	cudaMemcpy(matrix_d, matrix, sizeof(float)*n*m, cudaMemcpyHostToDevice);	

	// Configuring the grid
	dim3 dimBlock(block_size);	// One argument = 1D
	// N/32 blocks, or one extra with an uneven amount
	dim3 dimGrid ( (N/dimBlock.x) + (!(N%dimBlock.x)?0:1) );

	// Matrix for local results
	float max[m];

	// Error Checks

	// Call global function
	compute_maxnorm_gpu<<dimGrid,dimBlock>>(matrix_d,m,n);
	// Run through max[m]
	cudaMemcpy(max[idx],max,sizeof(float),cudaMemcpyDeviceToHost);

	// return norm
}
int main(int argc, char **argv ){
	
	int c,m,n,i,j;
	int tflag=0,mflag=0,nflag=0;
	m=n=10;

	srand48(123456);

	struct timeval start,end;
	long long time_elasped;

	while((c = getopt(argc,argv,"rtmn")) != -1)
		switch(c){
			case 'r':
				srand48(time(NULL));
				break;
			case 't':
				tflag = 1;
				break;
			case 'm':
				mflag=1;
				break;
			case 'n':
				nflag=1;
				break;
			case '?':
				if(isprint (optopt))
					fprintf(stderr, "Unknown option `-%c.\n",optopt);
				else
					fprintf(stderr,"Unknown option chacracter `\\x%x'.\n",optopt);
				return 1;
			default:
				abort();
		}
	if(mflag)
		m = atoi(argv[optind]);
	if(nflag)
		n = atoi(argv[optind+1]);
	
	printf("m = %d, n = %d\n",m,n);

	//====================================================
 	// Allocate memory 
	// On host
	float *matrix;
	matrix = malloc(n*m*sizeof(float));		
	//====================================================
	
	// Initialise matrix
	for(i=0;i<n*m;i++){
		matrix[i] = drand48();
	}



	float norm;
	// Testing time
	/*
	gettimeofday(&start, NULL);
	sleep(5);
	gettimeofday(&end, NULL);
	printf("%f\n", end.tv_sec - start.tv_sec);
	printf("%f\n", end.tv_usec - start.tv_usec);
	*/
	// Calculating norms
	// Measuring time in microseconds
	gettimeofday(&start, NULL);
	norm = max_norm(matrix,m,n);
	gettimeofday(&end, NULL);
	printf("Max norm %f\n",norm);
	if(tflag){
		time_elasped = (end.tv_sec-start.tv_sec)*1000000 + (end.tv_usec-start.tv_usec);
		printf("\t%lld microseconds \n",time_elasped);
	}
	gettimeofday(&start, NULL);
	norm = frob_norm(matrix,m,n);
	gettimeofday(&end, NULL);
	printf("Frobenius norm %f\n",norm);
	if(tflag){
		time_elasped = (end.tv_sec-start.tv_sec)*1000000 + (end.tv_usec-start.tv_usec);
		printf("\t%lld microseconds \n",time_elasped);
	}
	gettimeofday(&start, NULL);
	norm = one_norm(matrix,m,n);
	gettimeofday(&end, NULL);
	printf("One norm %f\n",norm);
	if(tflag){
		time_elasped = (end.tv_sec-start.tv_sec)*1000000 + (end.tv_usec-start.tv_usec);
		printf("\t%lld microseconds \n",time_elasped);
	}
	gettimeofday(&start, NULL);
	norm = inf_norm(matrix,m,n);
	gettimeofday(&end, NULL);
	printf("Infinity norm %f\n",norm);
	if(tflag){
		time_elasped = (end.tv_sec-start.tv_sec)*1000000 + (end.tv_usec-start.tv_usec);
		printf("\t%lld microseconds \n",time_elasped);
	}

	free(matrix);
	return 0;
}
float max_norm(float *matrix, int m, int n){
	int i, I;
	float max = 0.0;
	for(i=0;i<(n*m);i++){
		if( matrix[i]*matrix[i] > max ){
			max = matrix[i]*matrix[i];
			I = i;
		}
	}
	return fabsf(matrix[I]);
}
float frob_norm(float *matrix, int m, int n){
	int i;
	float sum;
	for(i=0;i<(m*n);i++)
		sum+=matrix[i]*matrix[i];
	return sqrt(sum);	
}
float one_norm(float *matrix, int m, int n){
	// m rows 
	// n columns
	// Access (i.j) entry by matrix[i*n + j]
	float sum,max=0;
	int i,j;
	// Loop over columns
	for(j=0;j<n;j++){
		sum=0;
		// Add all column entries
		for(i=0;i<m;i++){
			sum+=fabsf(matrix[i*n+j]);
		}
		if( sum > max )
			max = sum;
	}
	return max;
}
float inf_norm(float *matrix,int m, int n){
	float sum,max=0;
	int i,j;
	// Loop over rows
	for(i=0;i<m;i++){
		sum=0;
		// Add all entries in row
		for(j=0;j<n;j++){
			sum+=fabsf(matrix[i*n+j]);
		}
		if( sum > max )
			max = sum;
	}
	return max;
}





























