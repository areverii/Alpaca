; ModuleID = 'Alpaca'
source_filename = "Alpaca"

%QueryResult = type { i64, i64*** }
%Stats = type { double, i64 }
%Name = type { i8* }

@stderr = external global i64*
@fmt = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@fmt.1 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.2 = private unnamed_addr constant [6 x i8] c"%hhd\0A\00", align 1
@fmt.3 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@strlit = private unnamed_addr constant [5 x i8] c"Nick\00", align 1
@fmt.4 = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@fmt.5 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.6 = private unnamed_addr constant [6 x i8] c"%hhd\0A\00", align 1
@fmt.7 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1

declare i32 @strcmp(i8*, i8*)

declare i32 @printf(i8*, ...)

declare i32 @fprintf(i64*, i8*, ...)

declare void @reg_init()

declare void @reg_add(i64**)

declare %QueryResult* @reg_query(i64*, i64)

declare void @exit(i32)

declare void @memcpy(i64*, i64*, i64)

define void @main({ i64, i8** } %args) {
entry:
  call void @reg_init()
  %args1 = alloca { i64, i8** }, align 8
  store { i64, i8** } %args, { i64, i8** }* %args1, align 8
  %malloccall = tail call i8* @malloc(i32 mul (i32 ptrtoint (i1** getelementptr (i1*, i1** null, i32 1) to i32), i32 3))
  %entity_ptr = bitcast i8* %malloccall to i64**
  %element_ptr = getelementptr i64*, i64** %entity_ptr, i32 0
  store i64* null, i64** %element_ptr, align 8
  %element_ptr2 = getelementptr i64*, i64** %entity_ptr, i32 1
  store i64* null, i64** %element_ptr2, align 8
  %element_ptr3 = getelementptr i64*, i64** %entity_ptr, i32 2
  store i64* null, i64** %element_ptr3, align 8
  %element_ptr4 = getelementptr i64*, i64** %entity_ptr, i32 3
  store i64* null, i64** %element_ptr4, align 8
  %printf = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 3)
  %mallocResult = alloca %Stats, align 8
  %printf5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 3)
  %field_ptr = getelementptr inbounds %Stats, %Stats* %mallocResult, i32 0, i32 0
  store double 6.100000e+00, double* %field_ptr, align 8
  %field_ptr6 = getelementptr inbounds %Stats, %Stats* %mallocResult, i32 0, i32 1
  store i64 21, i64* %field_ptr6, align 4
  %entity_ptr7 = getelementptr i64*, i64** %entity_ptr, i32 1
  %struct_void_ptr = bitcast %Stats* %mallocResult to i64*
  store i64* %struct_void_ptr, i64** %entity_ptr7, align 8
  %printf8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 3)
  %mallocResult9 = alloca %Name, align 8
  %printf10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 3)
  %field_ptr11 = getelementptr inbounds %Name, %Name* %mallocResult9, i32 0, i32 0
  store i8* getelementptr inbounds ([5 x i8], [5 x i8]* @strlit, i32 0, i32 0), i8** %field_ptr11, align 8
  %entity_ptr12 = getelementptr i64*, i64** %entity_ptr, i32 0
  %struct_void_ptr13 = bitcast %Name* %mallocResult9 to i64*
  store i64* %struct_void_ptr13, i64** %entity_ptr12, align 8
  call void @reg_add(i64** %entity_ptr)
  call void @run()
  ret void
}

define void @run() {
entry:
  %ent = alloca i64**, align 8
  store i64** null, i64*** %ent, align 8
  %age = alloca i64, align 8
  store i64 0, i64* %age, align 4
  %comp_arr_heap = alloca i64, i64 1, align 8
  %element_ptr = getelementptr i64, i64* %comp_arr_heap, i32 0
  store i64 1, i64* %element_ptr, align 4
  %registry_query = call %QueryResult* @reg_query(i64* %comp_arr_heap, i64 1)
  %field_ptr = getelementptr inbounds %QueryResult, %QueryResult* %registry_query, i32 0, i32 0
  %0 = load i64, i64* %field_ptr, align 4
  %field_ptr1 = getelementptr inbounds %QueryResult, %QueryResult* %registry_query, i32 0, i32 1
  %1 = load i64***, i64**** %field_ptr1, align 8
  %tmp_struct_var = alloca { i64, i64*** }, align 8
  store { i64, i64*** } { i64 34, i64*** null }, { i64, i64*** }* %tmp_struct_var, align 8
  %arr_field_ptr = getelementptr inbounds { i64, i64*** }, { i64, i64*** }* %tmp_struct_var, i32 0, i32 1
  store i64*** %1, i64**** %arr_field_ptr, align 8
  %arr_field_ptr2 = getelementptr inbounds { i64, i64*** }, { i64, i64*** }* %tmp_struct_var, i32 0, i32 1
  %arr_ptr = load i64***, i64**** %arr_field_ptr2, align 8
  %element_ptr3 = getelementptr i64**, i64*** %arr_ptr, i64 0
  %element = load i64**, i64*** %element_ptr3, align 8
  store i64** %element, i64*** %ent, align 8
  ret void
}

declare noalias i8* @malloc(i32)
