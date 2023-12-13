; ModuleID = 'Alpaca'
source_filename = "Alpaca"

%QueryResult = type { i64, i64*** }

@stderr = external global i64*
@fmt = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@fmt.1 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.2 = private unnamed_addr constant [6 x i8] c"%hhd\0A\00", align 1
@fmt.3 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1

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
  %x = alloca { i64, i64* }, align 8
  store { i64, i64* } zeroinitializer, { i64, i64* }* %x, align 8
  %x2 = load { i64, i64* }, { i64, i64* }* %x, align 8
  %list = alloca { i64, i64* }, align 8
  store { i64, i64* } %x2, { i64, i64* }* %list, align 8
  %length_field_ptr = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list, i32 0, i32 0
  %length = load i64, i64* %length_field_ptr, align 4
  %arr_field_ptr = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list, i32 0, i32 1
  %arr_ptr = load i64*, i64** %arr_field_ptr, align 8
  %new_len = add i64 %length, 1
  %0 = trunc i64 %new_len to i32
  %mallocsize = mul i32 %0, ptrtoint (i64* getelementptr (i64, i64* null, i32 1) to i32)
  %malloccall = tail call i8* @malloc(i32 %mallocsize)
  %list_heap_arr = bitcast i8* %malloccall to i64*
  %tmp_struct_var = alloca { i64, i64* }, align 8
  %length_field_ptr3 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %tmp_struct_var, i32 0, i32 0
  %arr_field_ptr4 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %tmp_struct_var, i32 0, i32 1
  store i64* %list_heap_arr, i64** %arr_field_ptr4, align 8
  store i64 %new_len, i64* %length_field_ptr3, align 4
  %new_list = load { i64, i64* }, { i64, i64* }* %tmp_struct_var, align 8
  %copy_size = mul i64 %length, ptrtoint (i64* getelementptr (i64, i64* null, i32 1) to i64)
  call void @memcpy(i64* %list_heap_arr, i64* %arr_ptr, i64 %copy_size)
  %end_ptr = getelementptr i64, i64* %list_heap_arr, i64 %new_len
  store i64 1, i64* %end_ptr, align 4
  %x5 = load { i64, i64* }, { i64, i64* }* %x, align 8
  %list6 = alloca { i64, i64* }, align 8
  store { i64, i64* } %x5, { i64, i64* }* %list6, align 8
  %length_field_ptr7 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list6, i32 0, i32 0
  %length8 = load i64, i64* %length_field_ptr7, align 4
  %arr_field_ptr9 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list6, i32 0, i32 1
  %arr_ptr10 = load i64*, i64** %arr_field_ptr9, align 8
  %printf = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %length8)
  %arr_field_ptr11 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %x, i32 0, i32 1
  %arr_ptr12 = load i64*, i64** %arr_field_ptr11, align 8
  %element_ptr = getelementptr i64, i64* %arr_ptr12, i64 0
  %element = load i64, i64* %element_ptr, align 4
  %printf13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %element)
  ret void
}

declare noalias i8* @malloc(i32)
