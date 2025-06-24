PROGRAM dens_3d_slicer
    implicit none
	real*8,parameter                        :: pi=3.14159265359d0
    integer                                 :: n,n1,n2,n3,num,i,j,k,m,l,ind,num_args,numnormed,stride,nwrite,nwrite2,outper
    real(4), dimension(:),allocatable       :: cur,dens
    real(4), dimension(:,:), allocatable    :: avrcur
	real(4), dimension(:,:,:),allocatable   :: dens3d
    real(4), dimension(:,:,:,:),allocatable :: cur_3d
	real*8,allocatable                      :: xgrid(:),ygrid(:),zgrid(:)
	real*4,allocatable                      :: crd_2d_sx(:,:,:),crd_2d_sy(:,:,:),crd_2d_sz(:,:,:)
    character(255)                          :: fname,fname1,dfname,chbuffer,path2grid,file_line, the_key,value_string
	character(300)                          :: fname2,fname3
	character(1)                            :: ch1
	character(2)                            :: ch2
    integer,parameter                :: currentfile=2,td_total_current_file=22,current_averagefile=8,densfile=33,bovfile=44,outfilep=14184
	real*4                                  :: curmax(3),cur_cutoff,curmag,min_curr,curxyz(3),curxyzmag
    logical  :: write_cur_out,file_exists
	real*8   :: grid_step,brick_origin(3),brick_size(3),dx(3),max_x=1.d16,max_y=1.d16,INTEGRATE_END,DENS_INT,R_INT1,R_INT0,rho_sum,rho_sumBox,bov_time
	integer  :: npts(3)
	
	real*8 :: X_pos,Y_pos,Z_pos,dr,d2x,d2y,d2z,grid_volume,r
	integer :: N_R_GRID,npts_range
	
	real*8,allocatable  :: R_GRID(:),rho_R(:)
	
	write_cur_out=.FALSE.
	cur_cutoff=9.d9
	min_curr=1e-6
    n1=0
    n2=0
    n3=0
	curmax(1)=0.d0
    curmax(2)=0.d0
    curmax(3)=0.d0
	path2grid=""
	stride=1
	outper=1
	INTEGRATE_END=-1.d0
	num_args=iargc()
  if(num_args==6) then
     call getarg(1,fname2)
     call getarg(2,fname3)
	 call getarg(3,chbuffer)
	 read(chbuffer,*) X_pos
     call getarg(4,chbuffer)
     read(chbuffer,*) Y_pos
     call getarg(5,chbuffer)
     read(chbuffer,*) Z_pos
     call getarg(6,chbuffer)
     read(chbuffer,*) dr

  else
     print *, "Uses .dat binary file viewable by visit."
     print *, "   Input: <.bov file> <output_file> <X position> <Y position> <Z position> <dr> "
	 stop
  end if
	
	open(bovfile,file=trim(adjustl(fname2)),form='formatted')
	! don't need first 2 lines
	read(bovfile,'(a)')file_line ! line 1 has the time
	 i=index(file_line,':')
     read(file_line(1:i-1),'(a)')the_key
     read(file_line(i+1:),'(a)')value_string
	 read(value_string,*) bov_time
	read(bovfile,'(a)')file_line  ! line 2 has the .dat filename
	 i=index(file_line,':')
     read(file_line(1:i-1),'(a)')the_key
     read(file_line(i+1:),'(a)')dfname
	 
	 write(*,*) "Use .dat file=",trim(adjustl(dfname))
	! read size
	read(bovfile,'(a)')file_line 
	i=index(file_line,':')
    read(file_line(1:i-1),'(a)')the_key
    read(file_line(i+1:),'(a)')value_string	
	read(value_string,*)n1,n2,n3
	
	npts(1)=n1; npts(2)=n2; npts(3)=n3
    !write(*,*) 'total number of grid points X Y Z:',n1,n2,n3
	n=n1*n2*n3
	!write(*,*) 'total number of data points:',n
	
	do i=1,4 ! don't need next 4 lines
	  read(bovfile,'(a)')file_line
	  !write(*,*) 'skip:',trim(adjustl(file_line))
	end do
	read(bovfile,'(a)')file_line
	i=index(file_line,':')
    read(file_line(1:i-1),'(a)')the_key
    read(file_line(i+1:),'(a)')value_string	
	read(value_string,*)brick_origin(1:3)
	!write(*,*) 'BRICK_ORIGIN:',brick_origin(1:3)
	read(bovfile,'(a)')file_line
	i=index(file_line,':')
    read(file_line(1:i-1),'(a)')the_key
    read(file_line(i+1:),'(a)')value_string	
	read(value_string,*)brick_size(1:3)
	!write(*,*) 'BRICK_SIZE:',brick_size(1:3)
	dx=brick_size/(npts-1)
	!write(*,*) 'DX:',dx(1:3)
	
	
	close(bovfile)
	
    !num=45
    allocate(dens(n1*n2*n3),dens3d(n1,n2,n3))
	allocate(xgrid(n1),ygrid(n2),zgrid(n3))
    allocate(R_GRID(N_R_GRID),rho_R(N_R_GRID))
  
    grid_volume=dx(1)*dx(2)*dx(3)
	
  call fd_axis_bov_grid(n1,dx(1),xgrid,brick_origin(1))
  call fd_axis_bov_grid(n2,dx(2),ygrid,brick_origin(2))
  call fd_axis_bov_grid(n3,dx(3),zgrid,brick_origin(3))
  
  write(*,'(a,f15.7,a,f15.7)') 'xgrid from ',xgrid(1),' to ',xgrid(n1)
  write(*,'(a,f15.7,a,f15.7)') 'ygrid from ',ygrid(1),' to ',ygrid(n2)
  write(*,'(a,f15.7,a,f15.7)') 'zgrid from ',zgrid(1),' to ',zgrid(n3)  
	
   numnormed=0
  !write(fname,'(a,i5.5,a)') 'current_dens',i,'.dat'

  open(densfile,file=dfname,form='unformatted')
  read(densfile) dens
  close(densfile)
       ind=0
       do j=1,n3
         do k=1,n2
           do m=1,n1
                 ind=ind+1
                 dens3d(m,k,j)=dens(ind) 
          enddo		  
         enddo
       enddo 

	inquire(file=trim(adjustl(fname3)), exist=file_exists)
	if(file_exists) then
	   open(outfilep,file=trim(adjustl(fname3)),form='formatted', status="old", position="append")
	else
	   open(outfilep,file=trim(adjustl(fname3)),form='formatted',status='replace')
	end if
	  rho_sum=0.d0
	  npts_range=0
       do j=1,n3
	     d2z=abs(zgrid(j)-Z_pos)
	     if(d2z<dr) then
           do k=1,n2
		     d2y=abs(ygrid(k)-Y_pos)
		     if(d2y<dr) then
               do m=1,n1
			     d2x=abs(xgrid(m)-X_pos)
			     r=sqrt(d2x**2 + d2y**2 + d2z**2)
                 if(r<dr) then
				   rho_sum=rho_sum+dens3d(m,k,j)*grid_volume
				   npts_range=npts_range+1
				 end if
               enddo
             end if			   
           enddo
		 end if
       enddo 
	   rho_sumBox=0.d0
	   do j=1,n3
	     do k=1,n2
		   do m=1,n1
		     rho_sumBox=rho_sumBox+dens3d(m,k,j)*grid_volume
		   end do
	     end do 
	   end do
	   write(outfilep,'(F12.5,2ES20.10E3)') bov_time,rho_sum,rho_sumBox
	
    deallocate(dens)
	deallocate(xgrid,ygrid,zgrid)
	 
	
END PROGRAM dens_3d_slicer

subroutine fd_axis_bov_grid(N,dx,grid,origin)
implicit none
  integer :: N
  real*8  :: dx,origin
  real*8  :: grid(N)
  integer :: i
  real*8  :: R_size,h
  

  do i=1,N
    grid(i)=origin+(i-1)*dx
	!write(1414,*) i,grid(i)
  end do
  
end subroutine
