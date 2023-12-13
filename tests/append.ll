; ModuleID = 'Alpaca'
source_filename = "Alpaca"

%QueryResult = type { i64, i64*** }

@stderr = external global i64*
@fmt = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@fmt.1 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.2 = private unnamed_addr constant [6 x i8] c"%hhd\0A\00", align 1
@fmt.3 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@strlit = private unnamed_addr constant [8 x i8] c"length:\00", align 1

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
  %0 = trunc i64 3 to i32
  %mallocsize = mul i32 %0, ptrtoint (i64* getelementptr (i64, i64* null, i32 1) to i32)
  %malloccall = tail call i8* @malloc(i32 %mallocsize)
  %list_heap_arr = bitcast i8* %malloccall to i64*
  %"list_arr init" = getelementptr i64, i64* %list_heap_arr, i64 0
  store i64 1, i64* %"list_arr init", align 4
  %"list_arr init2" = getelementptr i64, i64* %list_heap_arr, i64 1
  store i64 2, i64* %"list_arr init2", align 4
  %"list_arr init3" = getelementptr i64, i64* %list_heap_arr, i64 2
  store i64 3, i64* %"list_arr init3", align 4
  %tmp_struct_var = alloca { i64, i64* }, align 8
  store { i64, i64* } { i64 3, i64* null }, { i64, i64* }* %tmp_struct_var, align 8
  %arr_field_ptr = getelementptr inbounds { i64, i64* }, { i64, i64* }* %tmp_struct_var, i32 0, i32 1
  store i64* %list_heap_arr, i64** %arr_field_ptr, align 8
  %load_tmp_struct = load { i64, i64* }, { i64, i64* }* %tmp_struct_var, align 8
  store { i64, i64* } %load_tmp_struct, { i64, i64* }* %x, align 8
  %arr_field_ptr4 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %x, i32 0, i32 1
  %arr_ptr = load i64*, i64** %arr_field_ptr4, align 8
  %element_ptr = getelementptr i64, i64* %arr_ptr, i64 0
  %element = load i64, i64* %element_ptr, align 4
  %printf = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %element)
  %arr_field_ptr5 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %x, i32 0, i32 1
  %arr_ptr6 = load i64*, i64** %arr_field_ptr5, align 8
  %element_ptr7 = getelementptr i64, i64* %arr_ptr6, i64 1
  %element8 = load i64, i64* %element_ptr7, align 4
  %printf9 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %element8)
  %arr_field_ptr10 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %x, i32 0, i32 1
  %arr_ptr11 = load i64*, i64** %arr_field_ptr10, align 8
  %element_ptr12 = getelementptr i64, i64* %arr_ptr11, i64 2
  %element13 = load i64, i64* %element_ptr12, align 4
  %printf14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %element13)
  %x15 = load { i64, i64* }, { i64, i64* }* %x, align 8
  %list = alloca { i64, i64* }, align 8
  store { i64, i64* } %x15, { i64, i64* }* %list, align 8
  %length_field_ptr = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list, i32 0, i32 0
  %length = load i64, i64* %length_field_ptr, align 4
  %arr_field_ptr16 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list, i32 0, i32 1
  %arr_ptr17 = load i64*, i64** %arr_field_ptr16, align 8
  %new_len = add i64 %length, 1
  %1 = trunc i64 %new_len to i32
  %mallocsize18 = mul i32 %1, ptrtoint (i64* getelementptr (i64, i64* null, i32 1) to i32)
  %malloccall19 = tail call i8* @malloc(i32 %mallocsize18)
  %"2" = bitcast i8* %malloccall19 to i64*
  %tmp_struct_var20 = alloca { i64, i64* }, align 8
  %length_field_ptr21 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %tmp_struct_var20, i32 0, i32 0
  %arr_field_ptr22 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %tmp_struct_var20, i32 0, i32 1
  store i64* %"2", i64** %arr_field_ptr22, align 8
  store i64 %new_len, i64* %length_field_ptr21, align 4
  %new_list = load { i64, i64* }, { i64, i64* }* %tmp_struct_var20, align 8
  %copy_size = mul i64 %length, ptrtoint (i64* getelementptr (i64, i64* null, i32 1) to i64)
  call void @memcpy(i64* %"2", i64* %arr_ptr17, i64 %copy_size)
  %end_ptr = getelementptr i64, i64* %"2", i64 %new_len
  store i64 4, i64* %end_ptr, align 4
  %arr_field_ptr23 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %x, i32 0, i32 1
  %arr_ptr24 = load i64*, i64** %arr_field_ptr23, align 8
  %element_ptr25 = getelementptr i64, i64* %arr_ptr24, i64 3
  %element26 = load i64, i64* %element_ptr25, align 4
  %printf27 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %element26)
  %printf28 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt.3, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8], [8 x i8]* @strlit, i32 0, i32 0))
  %x29 = load { i64, i64* }, { i64, i64* }* %x, align 8
  %list30 = alloca { i64, i64* }, align 8
  store { i64, i64* } %x29, { i64, i64* }* %list30, align 8
  %length_field_ptr31 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list30, i32 0, i32 0
  %length32 = load i64, i64* %length_field_ptr31, align 4
  %arr_field_ptr33 = getelementptr inbounds { i64, i64* }, { i64, i64* }* %list30, i32 0, i32 1
  %arr_ptr34 = load i64*, i64** %arr_field_ptr33, align 8
  %printf35 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @fmt, i32 0, i32 0), i64 %length32)
  ret void
}

declare noalias i8* @malloc(i32)
