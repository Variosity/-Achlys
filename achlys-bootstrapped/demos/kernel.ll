; ModuleID = 'achlys_kernel'
target triple = "x86_64-pc-linux-gnu"
declare i32 @printf(i8*, ...)
declare i32 @sprintf(i8*, i8*, ...)
declare i32 @fflush(i8*)
declare i64 @malloc(i64)
declare i8* @realloc(i8*, i64)
declare i32 @getchar()
declare void @exit(i32)
declare i8* @fopen(i8*, i8*)
declare i32 @fseek(i8*, i64, i32)
declare i64 @ftell(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fclose(i8*)
declare i32 @system(i8*)
declare i32 @usleep(i32)
declare i64 @atol(i8*)
declare i8* @strtok(i8*, i8*)
@.fmt_int = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 8
@.fmt_str = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 8
@.fmt_raw_s = private unnamed_addr constant [3 x i8] c"%s\00", align 8
@.fmt_raw_i = private unnamed_addr constant [4 x i8] c"%ld\00", align 8
@.mode_r = private unnamed_addr constant [2 x i8] c"r\00", align 8
@.mode_w = private unnamed_addr constant [2 x i8] c"w\00", align 8
@.str_lst = private unnamed_addr constant [7 x i8] c"<list>\00", align 8
@.str_map = private unnamed_addr constant [6 x i8] c"<map>\00", align 8
@__sys_argv = global i8** null, align 8
@__sys_argc = global i32 0, align 8
@.m_brk_l = private unnamed_addr constant [2 x i8] c"[\00", align 8
@.m_brk_r = private unnamed_addr constant [3 x i8] c"]\0A\00", align 8
@.m_comma = private unnamed_addr constant [3 x i8] c", \00", align 8
define i64 @_str_cat(i64 %a, i64 %b) {
  %sa = inttoptr i64 %a to i8*
  %sb = inttoptr i64 %b to i8*
  %la = call i64 @strlen(i8* %sa)
  %lb = call i64 @strlen(i8* %sb)
  %sz = add i64 %la, %lb
  %sz1 = add i64 %sz, 1
  %mem = call i64 @malloc(i64 %sz1)
  %ptr = inttoptr i64 %mem to i8*
  call i8* @strcpy(i8* %ptr, i8* %sa)
  call i8* @strcat(i8* %ptr, i8* %sb)
  ret i64 %mem
}
define i64 @to_string(i64 %val) {
  %is_ptr = icmp sgt i64 %val, 4294967296
  br i1 %is_ptr, label %is_str, label %is_int
is_str: ret i64 %val
is_int:
  %mem = call i64 @malloc(i64 32)
  %p = inttoptr i64 %mem to i8*
  %fmt = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0
  call i32 (i8*, i8*, ...) @sprintf(i8* %p, i8* %fmt, i64 %val)
  ret i64 %mem
}
define i64 @_add(i64 %a, i64 %b) {
  %is_ptr_a = icmp sgt i64 %a, 4294967296
  %is_ptr_b = icmp sgt i64 %b, 4294967296
  %both_ptr = and i1 %is_ptr_a, %is_ptr_b
  %any_ptr = or i1 %is_ptr_a, %is_ptr_b
  br i1 %both_ptr, label %check_list, label %check_str
check_list:
  %ptr_a = inttoptr i64 %a to i8*
  %type_a = load i8, i8* %ptr_a
  %is_list = icmp eq i8 %type_a, 3
  br i1 %is_list, label %do_list, label %check_str
check_str:
  br i1 %any_ptr, label %do_str, label %int
do_str:
  %sa = call i64 @to_string(i64 %a)
  %sb = call i64 @to_string(i64 %b)
  %ret_str = call i64 @_str_cat(i64 %sa, i64 %sb)
  ret i64 %ret_str
do_list:
  %new_list = call i64 @_list_new()
  call void @_list_copy(i64 %new_list, i64 %a)
  call void @_list_copy(i64 %new_list, i64 %b)
  ret i64 %new_list
int:
  %ret_int = add i64 %a, %b
  ret i64 %ret_int
}
define void @_list_copy(i64 %dest, i64 %src) {
  %ptr = inttoptr i64 %src to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1
  %cnt = load i64, i64* %cnt_ptr
  %data_ptr = getelementptr i64, i64* %ptr, i64 2
  %base = load i64, i64* %data_ptr
  %base_ptr = inttoptr i64 %base to i64*
  br label %loop
loop:
  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]
  %cond = icmp slt i64 %i, %cnt
  br i1 %cond, label %body, label %done
body:
  %slot = getelementptr i64, i64* %base_ptr, i64 %i
  %val = load i64, i64* %slot
  call i64 @_list_push(i64 %dest, i64 %val)
  %next_i = add i64 %i, 1
  br label %loop
done:
  ret void
}
define i64 @_append_poly(i64 %list, i64 %val) {
  %is_ptr = icmp sgt i64 %val, 4294967296
  br i1 %is_ptr, label %check_list, label %push_one
check_list:
  %ptr = inttoptr i64 %val to i8*
  %type = load i8, i8* %ptr
  %is_list = icmp eq i8 %type, 3
  br i1 %is_list, label %merge, label %push_one
merge:
  call void @_list_copy(i64 %list, i64 %val)
  ret i64 0
push_one:
  call i64 @_list_push(i64 %list, i64 %val)
  ret i64 0
}
define i64 @_eq(i64 %a, i64 %b) {
  %a_is_ptr = icmp sgt i64 %a, 4294967296
  %b_is_ptr = icmp sgt i64 %b, 4294967296
  %both_ptr = and i1 %a_is_ptr, %b_is_ptr
  br i1 %both_ptr, label %check_null, label %cmp_int
check_null:
  %a_null = icmp eq i64 %a, 0
  %b_null = icmp eq i64 %b, 0
  %any_null = or i1 %a_null, %b_null
  br i1 %any_null, label %cmp_int, label %cmp_str
cmp_str:
  %sa = inttoptr i64 %a to i8*
  %sb = inttoptr i64 %b to i8*
  %res = call i32 @strcmp(i8* %sa, i8* %sb)
  %iseq = icmp eq i32 %res, 0
  %ret_str = zext i1 %iseq to i64
  ret i64 %ret_str
cmp_int:
  %iseq_int = icmp eq i64 %a, %b
  %ret_int = zext i1 %iseq_int to i64
  ret i64 %ret_int
}
define i64 @_list_new() {
  %mem = call i64 @malloc(i64 24)
  %ptr = inttoptr i64 %mem to i64*
  store i64 3, i64* %ptr
  %cnt = getelementptr i64, i64* %ptr, i64 1
  store i64 0, i64* %cnt
  %data = getelementptr i64, i64* %ptr, i64 2
  store i64 0, i64* %data
  ret i64 %mem
}
define i64 @_list_set(i64 %l, i64 %idx, i64 %v) {
  %ptr = inttoptr i64 %l to i64*
  %data_ptr = getelementptr i64, i64* %ptr, i64 2
  %base = load i64, i64* %data_ptr
  %base_ptr = inttoptr i64 %base to i64*
  %slot = getelementptr i64, i64* %base_ptr, i64 %idx
  store i64 %v, i64* %slot
  ret i64 0
}
define i64 @_list_push(i64 %l, i64 %v) {
  %ptr = inttoptr i64 %l to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1
  %cnt = load i64, i64* %cnt_ptr
  %new_cnt = add i64 %cnt, 1
  store i64 %new_cnt, i64* %cnt_ptr
  %data_ptr = getelementptr i64, i64* %ptr, i64 2
  %old_mem_i = load i64, i64* %data_ptr
  %req_bytes = mul i64 %new_cnt, 8
  %old_ptr = inttoptr i64 %old_mem_i to i8*
  %new_ptr = call i8* @realloc(i8* %old_ptr, i64 %req_bytes)
  %new_mem = ptrtoint i8* %new_ptr to i64
  store i64 %new_mem, i64* %data_ptr
  %base_ptr = inttoptr i64 %new_mem to i64*
  %idx = getelementptr i64, i64* %base_ptr, i64 %cnt
  store i64 %v, i64* %idx
  ret i64 0
}
define i64 @_map_new() {
  %m = call i64 @_list_new()
  %ptr = inttoptr i64 %m to i64*
  store i64 4, i64* %ptr
  ret i64 %m
}
define i64 @_map_set(i64 %m, i64 %k, i64 %v) {
  call i64 @_list_push(i64 %m, i64 %k)
  call i64 @_list_push(i64 %m, i64 %v)
  ret i64 0
}
define i64 @_set(i64 %col, i64 %idx, i64 %v) {
  %ptr = inttoptr i64 %col to i64*
  %type = load i64, i64* %ptr
  %is_map = icmp eq i64 %type, 4
  br i1 %is_map, label %do_map, label %do_list
do_list:
  call i64 @_list_set(i64 %col, i64 %idx, i64 %v)
  ret i64 0
do_map:
  call i64 @_map_set(i64 %col, i64 %idx, i64 %v)
  ret i64 0
}
define i64 @_map_get(i64 %m, i64 %key) {
  %ptr = inttoptr i64 %m to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1
  %cnt = load i64, i64* %cnt_ptr
  %data_ptr = getelementptr i64, i64* %ptr, i64 2
  %base = load i64, i64* %data_ptr
  %base_ptr = inttoptr i64 %base to i64*
  %key_s = inttoptr i64 %key to i8*
  %start_i = sub i64 %cnt, 2
  br label %loop
loop:
  %i = phi i64 [ %start_i, %0 ], [ %next_i, %next ]
  %cond = icmp sge i64 %i, 0
  br i1 %cond, label %check_key, label %not_found
check_key:
  %k_slot = getelementptr i64, i64* %base_ptr, i64 %i
  %k_val = load i64, i64* %k_slot
  %k_str = inttoptr i64 %k_val to i8*
  %cmp = call i32 @strcmp(i8* %k_str, i8* %key_s)
  %match = icmp eq i32 %cmp, 0
  br i1 %match, label %found, label %next
next:
  %next_i = sub i64 %i, 2
  br label %loop
found:
  %v_idx = add i64 %i, 1
  %v_slot = getelementptr i64, i64* %base_ptr, i64 %v_idx
  %ret = load i64, i64* %v_slot
  ret i64 %ret
not_found:
  ret i64 0
}
define i64 @_get(i64 %col, i64 %idx) {
  %is_null = icmp eq i64 %col, 0
  br i1 %is_null, label %err, label %check
check:
  %ptr8 = inttoptr i64 %col to i8*
  %tag = load i8, i8* %ptr8
  %is_list = icmp eq i8 %tag, 3
  br i1 %is_list, label %do_list, label %check_map
check_map:
  %is_map = icmp eq i8 %tag, 4
  br i1 %is_map, label %do_map, label %do_str
do_str:
  %str_base = inttoptr i64 %col to i8*
  %char_ptr = getelementptr i8, i8* %str_base, i64 %idx
  %char = load i8, i8* %char_ptr
  %new_mem = call i64 @malloc(i64 2)
  %new_ptr = inttoptr i64 %new_mem to i8*
  store i8 %char, i8* %new_ptr
  %term = getelementptr i8, i8* %new_ptr, i64 1
  store i8 0, i8* %term
  %ret_str = ptrtoint i8* %new_ptr to i64
  ret i64 %ret_str
do_map:
  %map_val = call i64 @_map_get(i64 %col, i64 %idx)
  ret i64 %map_val
do_list:
  %ptr64 = inttoptr i64 %col to i64*
  %data_ptr = getelementptr i64, i64* %ptr64, i64 2
  %base = load i64, i64* %data_ptr
  %arr = inttoptr i64 %base to i64*
  %slot = getelementptr i64, i64* %arr, i64 %idx
  %val = load i64, i64* %slot
  ret i64 %val
err: ret i64 0
}
define i64 @_get_argv(i64 %idx) {
  %argc = load i32, i32* @__sys_argc
  %argc64 = sext i32 %argc to i64
  %is_oob = icmp sge i64 %idx, %argc64
  br i1 %is_oob, label %err, label %ok
err:
  %emp = call i64 @malloc(i64 1)
  %emp_p = inttoptr i64 %emp to i8*
  store i8 0, i8* %emp_p
  ret i64 %emp
ok:
  %argv = load i8**, i8*** @__sys_argv
  %ptr = getelementptr i8*, i8** %argv, i64 %idx
  %str = load i8*, i8** %ptr
  %ret = ptrtoint i8* %str to i64
  ret i64 %ret
}
define i64 @revelare(i64 %path_i) {
  %path = inttoptr i64 %path_i to i8*
  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_r, i64 0, i64 0
  %f = call i8* @fopen(i8* %path, i8* %mode)
  %f_int = ptrtoint i8* %f to i64
  %valid = icmp ne i64 %f_int, 0
  br i1 %valid, label %read, label %err
read:
  call i32 @fseek(i8* %f, i64 0, i32 2)
  %len = call i64 @ftell(i8* %f)
  call i32 @fseek(i8* %f, i64 0, i32 0)
  %alloc_sz = add i64 %len, 1
  %buf = call i64 @malloc(i64 %alloc_sz)
  %buf_ptr = inttoptr i64 %buf to i8*
  call i64 @fread(i8* %buf_ptr, i64 1, i64 %len, i8* %f)
  %term = getelementptr i8, i8* %buf_ptr, i64 %len
  store i8 0, i8* %term
  call i32 @fclose(i8* %f)
  ret i64 %buf
err:
  ret i64 0
}
define i64 @inscribo(i64 %path_i, i64 %content_i) {
  %path = inttoptr i64 %path_i to i8*
  %content = inttoptr i64 %content_i to i8*
  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_w, i64 0, i64 0
  %f = call i8* @fopen(i8* %path, i8* %mode)
  %len = call i64 @strlen(i8* %content)
  call i64 @fwrite(i8* %content, i64 1, i64 %len, i8* %f)
  call i32 @fclose(i8* %f)
  ret i64 0
}
define i64 @print_any(i64 %val) {
entry:
  %is_ptr = icmp sgt i64 %val, 4294967296
  br i1 %is_ptr, label %check_obj, label %print_int
check_obj:
  %ptr8 = inttoptr i64 %val to i8*
  %tag = load i8, i8* %ptr8
  %is_list = icmp eq i8 %tag, 3
  br i1 %is_list, label %print_list, label %print_str
print_list:
  %f_s1 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0
  %b_l = getelementptr [2 x i8], [2 x i8]* @.m_brk_l, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %f_s1, i8* %b_l)
  call i32 @fflush(i8* null)
  %ptr64 = inttoptr i64 %val to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1
  %cnt = load i64, i64* %cnt_ptr
  %is_empty = icmp eq i64 %cnt, 0
  br i1 %is_empty, label %done, label %setup_loop
setup_loop:
  %data_ptr = getelementptr i64, i64* %ptr64, i64 2
  %base = load i64, i64* %data_ptr
  %base_ptr = inttoptr i64 %base to i64*
  br label %loop
loop:
  %i = phi i64 [ 0, %setup_loop ], [ %next_i, %loop_end ]
  %cond = icmp slt i64 %i, %cnt
  br i1 %cond, label %body, label %done
body:
  %not_first = icmp ne i64 %i, 0
  br i1 %not_first, label %comma, label %val_print
comma:
  %f_s2 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0
  %com = getelementptr [3 x i8], [3 x i8]* @.m_comma, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %f_s2, i8* %com)
  call i32 @fflush(i8* null)
  br label %val_print
val_print:
  %slot = getelementptr i64, i64* %base_ptr, i64 %i
  %v = load i64, i64* %slot
  %v_is_ptr = icmp sgt i64 %v, 4294967296
  br i1 %v_is_ptr, label %v_ptr_check, label %v_int
v_ptr_check:
  %vs_ptr8 = inttoptr i64 %v to i8*
  %in_tag = load i8, i8* %vs_ptr8
  %in_is_list = icmp eq i8 %in_tag, 3
  br i1 %in_is_list, label %v_nested, label %v_raw_str
v_nested:
  call i64 @print_any(i64 %v)
  br label %loop_end
v_raw_str:
  %f_s3 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0
  %vs_str = inttoptr i64 %v to i8*
  call i32 (i8*, ...) @printf(i8* %f_s3, i8* %vs_str)
  call i32 @fflush(i8* null)
  br label %loop_end
v_int:
  %f_i = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %f_i, i64 %v)
  call i32 @fflush(i8* null)
  br label %loop_end
loop_end:
  %next_i = add i64 %i, 1
  br label %loop
done:
  %f_s4 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0
  %b_r = getelementptr [3 x i8], [3 x i8]* @.m_brk_r, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %f_s4, i8* %b_r)
  call i32 @fflush(i8* null)
  ret i64 0
print_int:
  %f_i_end = getelementptr [5 x i8], [5 x i8]* @.fmt_int, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %f_i_end, i64 %val)
  call i32 @fflush(i8* null)
  ret i64 0
print_str:
  %f_s_end = getelementptr [4 x i8], [4 x i8]* @.fmt_str, i64 0, i64 0
  %str_p = inttoptr i64 %val to i8*
  call i32 (i8*, ...) @printf(i8* %f_s_end, i8* %str_p)
  call i32 @fflush(i8* null)
  ret i64 0
}
define i64 @codex(i64 %val) {
  %ptr = inttoptr i64 %val to i8*
  %c = load i8, i8* %ptr
  %ret = zext i8 %c to i64
  ret i64 %ret
}
define i64 @pars(i64 %str, i64 %start, i64 %len) {
  %src = inttoptr i64 %str to i8*
  %slen = call i64 @strlen(i8* %src)
  %is_oob = icmp sge i64 %start, %slen
  br i1 %is_oob, label %oob, label %ok
oob:
  %emp = call i64 @malloc(i64 1)
  %emp_p = inttoptr i64 %emp to i8*
  store i8 0, i8* %emp_p
  ret i64 %emp
ok:
  %rem = sub i64 %slen, %start
  %is_long = icmp sgt i64 %len, %rem
  %safe_len = select i1 %is_long, i64 %rem, i64 %len
  %src_off = getelementptr i8, i8* %src, i64 %start
  %alloc_sz = add i64 %safe_len, 1
  %dest = call i64 @malloc(i64 %alloc_sz)
  %dest_ptr = inttoptr i64 %dest to i8*
  call i8* @strncpy(i8* %dest_ptr, i8* %src_off, i64 %safe_len)
  %term = getelementptr i8, i8* %dest_ptr, i64 %safe_len
  store i8 0, i8* %term
  ret i64 %dest
}
define i64 @signum_ex(i64 %val) {
  %mem = call i64 @malloc(i64 2)
  %ptr = inttoptr i64 %mem to i8*
  %c = trunc i64 %val to i8
  store i8 %c, i8* %ptr
  %term = getelementptr i8, i8* %ptr, i64 1
  store i8 0, i8* %term
  ret i64 %mem
}
define i64 @mensura(i64 %val) {
  %is_null = icmp eq i64 %val, 0
  br i1 %is_null, label %ret_zero, label %read
ret_zero:
  ret i64 0
read:
  %ptr8 = inttoptr i64 %val to i8*
  %type = load i8, i8* %ptr8
  %is_list = icmp eq i8 %type, 3
  %is_map = icmp eq i8 %type, 4
  %is_col = or i1 %is_list, %is_map
  br i1 %is_col, label %get_cnt, label %get_str
get_cnt:
  %ptr64 = inttoptr i64 %val to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1
  %cnt = load i64, i64* %cnt_ptr
  ret i64 %cnt
get_str:
  %str_ptr = inttoptr i64 %val to i8*
  %len = call i64 @strlen(i8* %str_ptr)
  ret i64 %len
}
define i64 @capio() {
  %mem = call i64 @malloc(i64 256)
  %ptr = inttoptr i64 %mem to i8*
  br label %read
read:
  %i = phi i64 [ 0, %0 ], [ %next_i, %cont ]
  %c = call i32 @getchar()
  %is_eof = icmp eq i32 %c, -1
  %is_nl = icmp eq i32 %c, 10
  %stop = or i1 %is_eof, %is_nl
  br i1 %stop, label %done, label %cont
cont:
  %char = trunc i32 %c to i8
  %slot = getelementptr i8, i8* %ptr, i64 %i
  store i8 %char, i8* %slot
  %next_i = add i64 %i, 1
  %limit = icmp slt i64 %next_i, 255
  br i1 %limit, label %read, label %done
done:
  %term_slot = getelementptr i8, i8* %ptr, i64 %i
  store i8 0, i8* %term_slot
  ret i64 %mem
}
define i64 @imperium(i64 %cmd) {
  %p = inttoptr i64 %cmd to i8*
  %res = call i32 @system(i8* %p)
  %ext = sext i32 %res to i64
  ret i64 %ext
}
define i64 @dormire(i64 %ms) {
  %us = mul i64 %ms, 1000
  %us32 = trunc i64 %us to i32
  call i32 @usleep(i32 %us32)
  ret i64 0
}
define i64 @numerus(i64 %str) {
  %p = inttoptr i64 %str to i8*
  %res = call i64 @atol(i8* %p)
  ret i64 %res
}
define i64 @scindere(i64 %str, i64 %delim) {
  %list = call i64 @_list_new()
  %s_p = inttoptr i64 %str to i8*
  %d_p = inttoptr i64 %delim to i8*
  %len = call i64 @strlen(i8* %s_p)
  %sz = add i64 %len, 1
  %mem = call i64 @malloc(i64 %sz)
  %cp = inttoptr i64 %mem to i8*
  call i8* @strcpy(i8* %cp, i8* %s_p)
  %tok = call i8* @strtok(i8* %cp, i8* %d_p)
  br label %loop
loop:
  %curr = phi i8* [ %tok, %0 ], [ %nxt, %body ]
  %is_null = icmp eq i8* %curr, null
  br i1 %is_null, label %done, label %body
body:
  %t_val = ptrtoint i8* %curr to i64
  call i64 @_list_push(i64 %list, i64 %t_val)
  %nxt = call i8* @strtok(i8* null, i8* %d_p)
  br label %loop
done:
  ret i64 %list
}
define i64 @iunctura(i64 %list_ptr, i64 %delim) {
  %is_null = icmp eq i64 %list_ptr, 0
  br i1 %is_null, label %ret_empty, label %check
check:
  %ptr64 = inttoptr i64 %list_ptr to i64*
  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1
  %cnt = load i64, i64* %cnt_ptr
  %is_empty = icmp eq i64 %cnt, 0
  br i1 %is_empty, label %ret_empty, label %calc
ret_empty:
  %emp = call i64 @malloc(i64 1)
  %emp_p = inttoptr i64 %emp to i8*
  store i8 0, i8* %emp_p
  ret i64 %emp
calc:
  %data_ptr = getelementptr i64, i64* %ptr64, i64 2
  %base = load i64, i64* %data_ptr
  %base_ptr = inttoptr i64 %base to i64*
  %res_0 = call i64 @malloc(i64 1)
  %res_0_p = inttoptr i64 %res_0 to i8*
  store i8 0, i8* %res_0_p
  br label %loop
loop:
  %i = phi i64 [ 0, %calc ], [ %next_i, %merge ]
  %curr_str = phi i64 [ %res_0, %calc ], [ %next_str, %merge ]
  %cond = icmp slt i64 %i, %cnt
  br i1 %cond, label %body, label %done
body:
  %slot = getelementptr i64, i64* %base_ptr, i64 %i
  %item = load i64, i64* %slot
  %item_s = call i64 @to_string(i64 %item)
  %added = call i64 @_str_cat(i64 %curr_str, i64 %item_s)
  %last_idx = sub i64 %cnt, 1
  %is_last = icmp eq i64 %i, %last_idx
  br i1 %is_last, label %skip_delim, label %add_delim
add_delim:
  %with_delim = call i64 @_str_cat(i64 %added, i64 %delim)
  br label %merge
skip_delim:
  br label %merge
merge:
  %next_str = phi i64 [ %with_delim, %add_delim ], [ %added, %skip_delim ]
  %next_i = add i64 %i, 1
  br label %loop
done:
  ret i64 %curr_str
}
define i64 @syscall6(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) {
  %res = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11},~{memory}"(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6)
  ret i64 %res
}
define i64 @strlen(i8* %str) {
entry: br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]
  %ptr = getelementptr i8, i8* %str, i64 %i
  %c = load i8, i8* %ptr
  %is_null = icmp eq i8 %c, 0
  %nxt = add i64 %i, 1
  br i1 %is_null, label %done, label %loop
done: ret i64 %i
}
define i32 @strcmp(i8* %s1, i8* %s2) {
entry: br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]
  %p1 = getelementptr i8, i8* %s1, i64 %i
  %p2 = getelementptr i8, i8* %s2, i64 %i
  %c1 = load i8, i8* %p1
  %c2 = load i8, i8* %p2
  %not_eq = icmp ne i8 %c1, %c2
  %is_null = icmp eq i8 %c1, 0
  %stop = or i1 %not_eq, %is_null
  %nxt = add i64 %i, 1
  br i1 %stop, label %done, label %loop
done:
  %z1 = zext i8 %c1 to i32
  %z2 = zext i8 %c2 to i32
  %diff = sub i32 %z1, %z2
  ret i32 %diff
}
define i8* @strcpy(i8* %dest, i8* %src) {
entry: br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]
  %ps = getelementptr i8, i8* %src, i64 %i
  %pd = getelementptr i8, i8* %dest, i64 %i
  %c = load i8, i8* %ps
  store i8 %c, i8* %pd
  %is_null = icmp eq i8 %c, 0
  %nxt = add i64 %i, 1
  br i1 %is_null, label %done, label %loop
done: ret i8* %dest
}
define i8* @strncpy(i8* %dest, i8* %src, i64 %n) {
entry: br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %nxt, %body ]
  %cmp = icmp slt i64 %i, %n
  br i1 %cmp, label %body, label %done
body:
  %ps = getelementptr i8, i8* %src, i64 %i
  %pd = getelementptr i8, i8* %dest, i64 %i
  %c = load i8, i8* %ps
  store i8 %c, i8* %pd
  %nxt = add i64 %i, 1
  br label %loop
done: ret i8* %dest
}
define i8* @strcat(i8* %dest, i8* %src) {
  %len = call i64 @strlen(i8* %dest)
  %d_end = getelementptr i8, i8* %dest, i64 %len
  call i8* @strcpy(i8* %d_end, i8* %src)
  ret i8* %dest
}
@TOK_EOF = global i64 0
@TOK_INT = global i64 0
@TOK_FLOAT = global i64 0
@TOK_STRING = global i64 0
@TOK_IDENT = global i64 0
@TOK_LET = global i64 0
@TOK_PRINT = global i64 0
@TOK_IF = global i64 0
@TOK_ELSE = global i64 0
@TOK_WHILE = global i64 0
@TOK_OPUS = global i64 0
@TOK_REDDO = global i64 0
@TOK_BREAK = global i64 0
@TOK_CONTINUE = global i64 0
@TOK_IMPORT = global i64 0
@TOK_LPAREN = global i64 0
@TOK_RPAREN = global i64 0
@TOK_LBRACE = global i64 0
@TOK_RBRACE = global i64 0
@TOK_LBRACKET = global i64 0
@TOK_RBRACKET = global i64 0
@TOK_COLON = global i64 0
@TOK_ARROW = global i64 0
@TOK_CARET = global i64 0
@TOK_DOT = global i64 0
@TOK_APPEND = global i64 0
@TOK_EXTRACT = global i64 0
@TOK_AND = global i64 0
@TOK_OR = global i64 0
@TOK_CONST = global i64 0
@TOK_SHARED = global i64 0
@TOK_OP = global i64 0
@TOK_COMMA = global i64 0
@EXPR_INT = global i64 0
@EXPR_FLOAT = global i64 0
@EXPR_STRING = global i64 0
@EXPR_VAR = global i64 0
@EXPR_LIST = global i64 0
@EXPR_MAP = global i64 0
@EXPR_BINARY = global i64 0
@EXPR_INDEX = global i64 0
@EXPR_GET = global i64 0
@EXPR_CALL = global i64 0
@EXPR_INPUT = global i64 0
@EXPR_READ = global i64 0
@EXPR_MEASURE = global i64 0
@STMT_LET = global i64 0
@STMT_ASSIGN = global i64 0
@STMT_SET = global i64 0
@STMT_SET_INDEX = global i64 0
@STMT_APPEND = global i64 0
@STMT_EXTRACT = global i64 0
@STMT_PRINT = global i64 0
@STMT_IF = global i64 0
@STMT_WHILE = global i64 0
@STMT_FUNC = global i64 0
@STMT_RETURN = global i64 0
@STMT_IMPORT = global i64 0
@STMT_BREAK = global i64 0
@STMT_CONTINUE = global i64 0
@STMT_EXPR = global i64 0
@STMT_CONST = global i64 0
@STMT_SHARED = global i64 0
@VAL_INT = global i64 0
@VAL_FLOAT = global i64 0
@VAL_STRING = global i64 0
@VAL_LIST = global i64 0
@VAL_MAP = global i64 0
@VAL_FUNC = global i64 0
@VAL_VOID = global i64 0
@global_tokens = global i64 0
@p_pos = global i64 0
@has_error = global i64 0
@use_huge_lists = global i64 0
@str_table = global i64 0
@stack_map = global i64 0
@stack_offset = global i64 0
@lbl_counter = global i64 0
@asm_main = global i64 0
@asm_funcs = global i64 0
@in_func = global i64 0
@local_vars = global i64 0
@stack_depth = global i64 0
@.str.1 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.2 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.3 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.4 = private unnamed_addr constant [2 x i8] c"_\00", align 8
@.str.5 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.6 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.7 = private unnamed_addr constant [4 x i8] c"txt\00", align 8
@.str.8 = private unnamed_addr constant [4 x i8] c"lbl\00", align 8
@.str.9 = private unnamed_addr constant [5 x i8] c"str_\00", align 8
@.str.10 = private unnamed_addr constant [4 x i8] c"txt\00", align 8
@.str.11 = private unnamed_addr constant [4 x i8] c"lbl\00", align 8
@.str.12 = private unnamed_addr constant [20 x i8] c"💀 SYNTAX ERROR: \00", align 8
@.str.13 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.14 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.15 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.16 = private unnamed_addr constant [9 x i8] c"mate.nox\00", align 8
@.str.17 = private unnamed_addr constant [24 x i8] c"[DEBUG] Source Length: \00", align 8
@.str.18 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.19 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.20 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.21 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.22 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.23 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.24 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.25 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.26 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.27 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.28 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.29 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.30 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.31 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.32 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.33 = private unnamed_addr constant [2 x i8] c"n\00", align 8
@.str.34 = private unnamed_addr constant [2 x i8] c"t\00", align 8
@.str.35 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.36 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.37 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.38 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.39 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.40 = private unnamed_addr constant [2 x i8] c"x\00", align 8
@.str.41 = private unnamed_addr constant [2 x i8] c"X\00", align 8
@.str.42 = private unnamed_addr constant [2 x i8] c".\00", align 8
@.str.43 = private unnamed_addr constant [4 x i8] c"vas\00", align 8
@.str.44 = private unnamed_addr constant [5 x i8] c"idea\00", align 8
@.str.45 = private unnamed_addr constant [6 x i8] c"umbra\00", align 8
@.str.46 = private unnamed_addr constant [7 x i8] c"scribo\00", align 8
@.str.47 = private unnamed_addr constant [8 x i8] c"monstro\00", align 8
@.str.48 = private unnamed_addr constant [10 x i8] c"insusurro\00", align 8
@.str.49 = private unnamed_addr constant [3 x i8] c"si\00", align 8
@.str.50 = private unnamed_addr constant [7 x i8] c"aliter\00", align 8
@.str.51 = private unnamed_addr constant [4 x i8] c"dum\00", align 8
@.str.52 = private unnamed_addr constant [5 x i8] c"opus\00", align 8
@.str.53 = private unnamed_addr constant [6 x i8] c"reddo\00", align 8
@.str.54 = private unnamed_addr constant [10 x i8] c"abrumpere\00", align 8
@.str.55 = private unnamed_addr constant [8 x i8] c"pergere\00", align 8
@.str.56 = private unnamed_addr constant [10 x i8] c"importare\00", align 8
@.str.57 = private unnamed_addr constant [9 x i8] c"constans\00", align 8
@.str.58 = private unnamed_addr constant [9 x i8] c"communis\00", align 8
@.str.59 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.60 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.61 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.62 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.63 = private unnamed_addr constant [6 x i8] c"verum\00", align 8
@.str.64 = private unnamed_addr constant [2 x i8] c"1\00", align 8
@.str.65 = private unnamed_addr constant [7 x i8] c"falsum\00", align 8
@.str.66 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.67 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.68 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.69 = private unnamed_addr constant [2 x i8] c"{\00", align 8
@.str.70 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.71 = private unnamed_addr constant [2 x i8] c"[\00", align 8
@.str.72 = private unnamed_addr constant [2 x i8] c"]\00", align 8
@.str.73 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.74 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.75 = private unnamed_addr constant [2 x i8] c".\00", align 8
@.str.76 = private unnamed_addr constant [2 x i8] c",\00", align 8
@.str.77 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.78 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.79 = private unnamed_addr constant [3 x i8] c"->\00", align 8
@.str.80 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.81 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.82 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.83 = private unnamed_addr constant [2 x i8] c"!\00", align 8
@.str.84 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.85 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.86 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.87 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.88 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.89 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.90 = private unnamed_addr constant [3 x i8] c"<<\00", align 8
@.str.91 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.92 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.93 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.94 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.95 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.96 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.97 = private unnamed_addr constant [3 x i8] c">>\00", align 8
@.str.98 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.99 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.100 = private unnamed_addr constant [4 x i8] c"EOF\00", align 8
@.str.101 = private unnamed_addr constant [39 x i8] c"[DEBUG] Lexer finished. Total Tokens: \00", align 8
@.str.102 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.103 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.104 = private unnamed_addr constant [4 x i8] c"EOF\00", align 8
@.str.105 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.106 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.107 = private unnamed_addr constant [21 x i8] c"Expected token type \00", align 8
@.str.108 = private unnamed_addr constant [10 x i8] c" but got \00", align 8
@.str.109 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.110 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.111 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.112 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.113 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.114 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.115 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.116 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.117 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.118 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.119 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.120 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.121 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.122 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.123 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.124 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.125 = private unnamed_addr constant [6 x i8] c"items\00", align 8
@.str.126 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.127 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.128 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.129 = private unnamed_addr constant [5 x i8] c"keys\00", align 8
@.str.130 = private unnamed_addr constant [5 x i8] c"vals\00", align 8
@.str.131 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.132 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.133 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.134 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.135 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.136 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.137 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.138 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.139 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.140 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.141 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.142 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.143 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.144 = private unnamed_addr constant [2 x i8] c"!\00", align 8
@.str.145 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.146 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.147 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.148 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.149 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.150 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.151 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.152 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.153 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.154 = private unnamed_addr constant [19 x i8] c"Unexpected token: \00", align 8
@.str.155 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.156 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.157 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.158 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.159 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.160 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.161 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.162 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.163 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.164 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.165 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.166 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.167 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.168 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.169 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.170 = private unnamed_addr constant [2 x i8] c"%\00", align 8
@.str.171 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.172 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.173 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.174 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.175 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.176 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.177 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.178 = private unnamed_addr constant [2 x i8] c"+\00", align 8
@.str.179 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.180 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.181 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.182 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.183 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.184 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.185 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.186 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.187 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.188 = private unnamed_addr constant [2 x i8] c"&\00", align 8
@.str.189 = private unnamed_addr constant [2 x i8] c"|\00", align 8
@.str.190 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.191 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.192 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.193 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.194 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.195 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.196 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.197 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.198 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.199 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.200 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.201 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.202 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.203 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.204 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.205 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.206 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.207 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.208 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.209 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.210 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.211 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.212 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.213 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.214 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.215 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.216 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.217 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.218 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.219 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.220 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.221 = private unnamed_addr constant [24 x i8] c"[DEBUG] Parsing stmt...\00", align 8
@.str.222 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.223 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.224 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.225 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.226 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.227 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.228 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.229 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.230 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.231 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.232 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.233 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.234 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.235 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.236 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.237 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.238 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.239 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.240 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.241 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.242 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.243 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.244 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.245 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.246 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.247 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.248 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.249 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.250 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.251 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.252 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.253 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.254 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.255 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.256 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.257 = private unnamed_addr constant [15 x i8] c"Unexpected EOF\00", align 8
@.str.258 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.259 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.260 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.261 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.262 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.263 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.264 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.265 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.266 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.267 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.268 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.269 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.270 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.271 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.272 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.273 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.274 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.275 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.276 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.277 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.278 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.279 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.280 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.281 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.282 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@reg_count = global i64 0
@str_count = global i64 0
@label_count = global i64 0
@out_code = global i64 0
@out_data = global i64 0
@var_map = global i64 0
@global_map = global i64 0
@loop_cond_stack = global i64 0
@loop_end_stack = global i64 0
@.str.283 = private unnamed_addr constant [3 x i8] c"%r\00", align 8
@.str.284 = private unnamed_addr constant [2 x i8] c"L\00", align 8
@.str.285 = private unnamed_addr constant [3 x i8] c"  \00", align 8
@.str.286 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.287 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.288 = private unnamed_addr constant [4 x i8] c"\5C22\00", align 8
@.str.289 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.290 = private unnamed_addr constant [4 x i8] c"\5C5C\00", align 8
@.str.291 = private unnamed_addr constant [4 x i8] c"\5C0A\00", align 8
@.str.292 = private unnamed_addr constant [7 x i8] c"@.str.\00", align 8
@.str.293 = private unnamed_addr constant [35 x i8] c" = private unnamed_addr constant [\00", align 8
@.str.294 = private unnamed_addr constant [10 x i8] c" x i8] c\22\00", align 8
@.str.295 = private unnamed_addr constant [14 x i8] c"\5C00\22, align 8\00", align 8
@.str.296 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.297 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.298 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.299 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.300 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.301 = private unnamed_addr constant [33 x i8] c"💀 FATAL: Undefined variable '\00", align 8
@.str.302 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.303 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.304 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.305 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.306 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.307 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.308 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.309 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.310 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.311 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.312 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.313 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.314 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.315 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.316 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.317 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.318 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.319 = private unnamed_addr constant [2 x i8] c"+\00", align 8
@.str.320 = private unnamed_addr constant [23 x i8] c" = call i64 @_add(i64 \00", align 8
@.str.321 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.322 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.323 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.324 = private unnamed_addr constant [12 x i8] c" = sub i64 \00", align 8
@.str.325 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.326 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.327 = private unnamed_addr constant [12 x i8] c" = mul i64 \00", align 8
@.str.328 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.329 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.330 = private unnamed_addr constant [13 x i8] c" = sdiv i64 \00", align 8
@.str.331 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.332 = private unnamed_addr constant [2 x i8] c"%\00", align 8
@.str.333 = private unnamed_addr constant [13 x i8] c" = srem i64 \00", align 8
@.str.334 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.335 = private unnamed_addr constant [2 x i8] c"&\00", align 8
@.str.336 = private unnamed_addr constant [12 x i8] c" = and i64 \00", align 8
@.str.337 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.338 = private unnamed_addr constant [2 x i8] c"|\00", align 8
@.str.339 = private unnamed_addr constant [11 x i8] c" = or i64 \00", align 8
@.str.340 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.341 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.342 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.343 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.344 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.345 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.346 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.347 = private unnamed_addr constant [2 x i8] c"~\00", align 8
@.str.348 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.349 = private unnamed_addr constant [5 x i8] c", -1\00", align 8
@.str.350 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.351 = private unnamed_addr constant [12 x i8] c" = shl i64 \00", align 8
@.str.352 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.353 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.354 = private unnamed_addr constant [13 x i8] c" = lshr i64 \00", align 8
@.str.355 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.356 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.357 = private unnamed_addr constant [12 x i8] c" = and i64 \00", align 8
@.str.358 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.359 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.360 = private unnamed_addr constant [11 x i8] c" = or i64 \00", align 8
@.str.361 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.362 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.363 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.364 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.365 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.366 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.367 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.368 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.369 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.370 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.371 = private unnamed_addr constant [4 x i8] c", 1\00", align 8
@.str.372 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.373 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.374 = private unnamed_addr constant [4 x i8] c"slt\00", align 8
@.str.375 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.376 = private unnamed_addr constant [4 x i8] c"sgt\00", align 8
@.str.377 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.378 = private unnamed_addr constant [4 x i8] c"sle\00", align 8
@.str.379 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.380 = private unnamed_addr constant [4 x i8] c"sge\00", align 8
@.str.381 = private unnamed_addr constant [9 x i8] c" = icmp \00", align 8
@.str.382 = private unnamed_addr constant [6 x i8] c" i64 \00", align 8
@.str.383 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.384 = private unnamed_addr constant [12 x i8] c" = zext i1 \00", align 8
@.str.385 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.386 = private unnamed_addr constant [16 x i8] c" = add i64 0, 0\00", align 8
@.str.387 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.388 = private unnamed_addr constant [25 x i8] c" = call i64 @_list_new()\00", align 8
@.str.389 = private unnamed_addr constant [6 x i8] c"items\00", align 8
@.str.390 = private unnamed_addr constant [26 x i8] c"call i64 @_list_push(i64 \00", align 8
@.str.391 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.392 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.393 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.394 = private unnamed_addr constant [24 x i8] c" = call i64 @_map_new()\00", align 8
@.str.395 = private unnamed_addr constant [5 x i8] c"keys\00", align 8
@.str.396 = private unnamed_addr constant [5 x i8] c"vals\00", align 8
@.str.397 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.398 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.399 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.400 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.401 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.402 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.403 = private unnamed_addr constant [24 x i8] c"call i64 @_map_set(i64 \00", align 8
@.str.404 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.405 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.406 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.407 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.408 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.409 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.410 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.411 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.412 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.413 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.414 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.415 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.416 = private unnamed_addr constant [23 x i8] c" = call i64 @_get(i64 \00", align 8
@.str.417 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.418 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.419 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.420 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.421 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.422 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.423 = private unnamed_addr constant [4 x i8] c"sys\00", align 8
@.str.424 = private unnamed_addr constant [9 x i8] c"imperium\00", align 8
@.str.425 = private unnamed_addr constant [9 x i8] c"scrutari\00", align 8
@.str.426 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.427 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.428 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.429 = private unnamed_addr constant [17 x i8] c" = load i8, ptr \00", align 8
@.str.430 = private unnamed_addr constant [12 x i8] c" = zext i8 \00", align 8
@.str.431 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.432 = private unnamed_addr constant [11 x i8] c"mutare_mem\00", align 8
@.str.433 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.434 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.435 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.436 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.437 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.438 = private unnamed_addr constant [7 x i8] c" to i8\00", align 8
@.str.439 = private unnamed_addr constant [10 x i8] c"store i8 \00", align 8
@.str.440 = private unnamed_addr constant [7 x i8] c", ptr \00", align 8
@.str.441 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.442 = private unnamed_addr constant [16 x i8] c"imperium_kernel\00", align 8
@.str.443 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.444 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.445 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.446 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.447 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.448 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.449 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.450 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.451 = private unnamed_addr constant [27 x i8] c" = call i64 @syscall6(i64 \00", align 8
@.str.452 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.453 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.454 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.455 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.456 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.457 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.458 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.459 = private unnamed_addr constant [18 x i8] c"capere_argumentum\00", align 8
@.str.460 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.461 = private unnamed_addr constant [28 x i8] c" = call i64 @_get_argv(i64 \00", align 8
@.str.462 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.463 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.464 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.465 = private unnamed_addr constant [5 x i8] c"i64 \00", align 8
@.str.466 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.467 = private unnamed_addr constant [7 x i8] c"scribo\00", align 8
@.str.468 = private unnamed_addr constant [28 x i8] c" = call i64 @print_any(i64 \00", align 8
@.str.469 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.470 = private unnamed_addr constant [14 x i8] c" = call i64 @\00", align 8
@.str.471 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.472 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.473 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.474 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.475 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.476 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.477 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.478 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.479 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.480 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.481 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.482 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.483 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.484 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.485 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.486 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.487 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.488 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.489 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.490 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.491 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.492 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.493 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.494 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.495 = private unnamed_addr constant [46 x i8] c"💀 FATAL: Index set on undefined variable '\00", align 8
@.str.496 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.497 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.498 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.499 = private unnamed_addr constant [20 x i8] c"call i64 @_set(i64 \00", align 8
@.str.500 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.501 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.502 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.503 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.504 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.505 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.506 = private unnamed_addr constant [47 x i8] c"💀 FATAL: Assignment to undefined variable '\00", align 8
@.str.507 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.508 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.509 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.510 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.511 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.512 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.513 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.514 = private unnamed_addr constant [43 x i8] c"💀 FATAL: Append to undefined variable '\00", align 8
@.str.515 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.516 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.517 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.518 = private unnamed_addr constant [28 x i8] c"call i64 @_append_poly(i64 \00", align 8
@.str.519 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.520 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.521 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.522 = private unnamed_addr constant [29 x i8] c"[DEBUG] Compiling STMT_PRINT\00", align 8
@.str.523 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.524 = private unnamed_addr constant [25 x i8] c"call i64 @print_any(i64 \00", align 8
@.str.525 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.526 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.527 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.528 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.529 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.530 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.531 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.532 = private unnamed_addr constant [9 x i8] c"ret i64 \00", align 8
@.str.533 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.534 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.535 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.536 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.537 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.538 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.539 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.540 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.541 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.542 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.543 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.544 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.545 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.546 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.547 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.548 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.549 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.550 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.551 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.552 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.553 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.554 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.555 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.556 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.557 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.558 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.559 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.560 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.561 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.562 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.563 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.564 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.565 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.566 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.567 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.568 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.569 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.570 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.571 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.572 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.573 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.574 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.575 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.576 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.577 = private unnamed_addr constant [13 x i8] c"define i64 @\00", align 8
@.str.578 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.579 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.580 = private unnamed_addr constant [10 x i8] c"i64 %arg_\00", align 8
@.str.581 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.582 = private unnamed_addr constant [4 x i8] c") {\00", align 8
@.str.583 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.584 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.585 = private unnamed_addr constant [16 x i8] c"store i64 %arg_\00", align 8
@.str.586 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.587 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.588 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.589 = private unnamed_addr constant [10 x i8] c"ret i64 0\00", align 8
@.str.590 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.591 = private unnamed_addr constant [29 x i8] c"; ModuleID = 'achlys_kernel'\00", align 8
@.str.592 = private unnamed_addr constant [38 x i8] c"target triple = \22x86_64-pc-linux-gnu\22\00", align 8
@.str.593 = private unnamed_addr constant [30 x i8] c"declare i32 @printf(i8*, ...)\00", align 8
@.str.594 = private unnamed_addr constant [36 x i8] c"declare i32 @sprintf(i8*, i8*, ...)\00", align 8
@.str.595 = private unnamed_addr constant [25 x i8] c"declare i32 @fflush(i8*)\00", align 8
@.str.596 = private unnamed_addr constant [25 x i8] c"declare i64 @malloc(i64)\00", align 8
@.str.597 = private unnamed_addr constant [31 x i8] c"declare i8* @realloc(i8*, i64)\00", align 8
@.str.598 = private unnamed_addr constant [23 x i8] c"declare i32 @getchar()\00", align 8
@.str.599 = private unnamed_addr constant [24 x i8] c"declare void @exit(i32)\00", align 8
@.str.600 = private unnamed_addr constant [29 x i8] c"declare i8* @fopen(i8*, i8*)\00", align 8
@.str.601 = private unnamed_addr constant [34 x i8] c"declare i32 @fseek(i8*, i64, i32)\00", align 8
@.str.602 = private unnamed_addr constant [24 x i8] c"declare i64 @ftell(i8*)\00", align 8
@.str.603 = private unnamed_addr constant [39 x i8] c"declare i64 @fread(i8*, i64, i64, i8*)\00", align 8
@.str.604 = private unnamed_addr constant [40 x i8] c"declare i64 @fwrite(i8*, i64, i64, i8*)\00", align 8
@.str.605 = private unnamed_addr constant [25 x i8] c"declare i32 @fclose(i8*)\00", align 8
@.str.606 = private unnamed_addr constant [25 x i8] c"declare i32 @system(i8*)\00", align 8
@.str.607 = private unnamed_addr constant [25 x i8] c"declare i32 @usleep(i32)\00", align 8
@.str.608 = private unnamed_addr constant [23 x i8] c"declare i64 @atol(i8*)\00", align 8
@.str.609 = private unnamed_addr constant [30 x i8] c"declare i8* @strtok(i8*, i8*)\00", align 8
@.str.610 = private unnamed_addr constant [73 x i8] c"@.fmt_int = private unnamed_addr constant [5 x i8] c\22%ld\5C0A\5C00\22, align 8\00", align 8
@.str.611 = private unnamed_addr constant [72 x i8] c"@.fmt_str = private unnamed_addr constant [4 x i8] c\22%s\5C0A\5C00\22, align 8\00", align 8
@.str.612 = private unnamed_addr constant [71 x i8] c"@.fmt_raw_s = private unnamed_addr constant [3 x i8] c\22%s\5C00\22, align 8\00", align 8
@.str.613 = private unnamed_addr constant [72 x i8] c"@.fmt_raw_i = private unnamed_addr constant [4 x i8] c\22%ld\5C00\22, align 8\00", align 8
@.str.614 = private unnamed_addr constant [67 x i8] c"@.mode_r = private unnamed_addr constant [2 x i8] c\22r\5C00\22, align 8\00", align 8
@.str.615 = private unnamed_addr constant [67 x i8] c"@.mode_w = private unnamed_addr constant [2 x i8] c\22w\5C00\22, align 8\00", align 8
@.str.616 = private unnamed_addr constant [73 x i8] c"@.str_lst = private unnamed_addr constant [7 x i8] c\22<list>\5C00\22, align 8\00", align 8
@.str.617 = private unnamed_addr constant [72 x i8] c"@.str_map = private unnamed_addr constant [6 x i8] c\22<map>\5C00\22, align 8\00", align 8
@.str.618 = private unnamed_addr constant [40 x i8] c"@__sys_argv = global i8** null, align 8\00", align 8
@.str.619 = private unnamed_addr constant [36 x i8] c"@__sys_argc = global i32 0, align 8\00", align 8
@.str.620 = private unnamed_addr constant [68 x i8] c"@.m_brk_l = private unnamed_addr constant [2 x i8] c\22[\5C00\22, align 8\00", align 8
@.str.621 = private unnamed_addr constant [71 x i8] c"@.m_brk_r = private unnamed_addr constant [3 x i8] c\22]\5C0A\5C00\22, align 8\00", align 8
@.str.622 = private unnamed_addr constant [69 x i8] c"@.m_comma = private unnamed_addr constant [3 x i8] c\22, \5C00\22, align 8\00", align 8
@.str.623 = private unnamed_addr constant [39 x i8] c"define i64 @_str_cat(i64 %a, i64 %b) {\00", align 8
@.str.624 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.625 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.626 = private unnamed_addr constant [34 x i8] c"  %la = call i64 @strlen(i8* %sa)\00", align 8
@.str.627 = private unnamed_addr constant [34 x i8] c"  %lb = call i64 @strlen(i8* %sb)\00", align 8
@.str.628 = private unnamed_addr constant [25 x i8] c"  %sz = add i64 %la, %lb\00", align 8
@.str.629 = private unnamed_addr constant [24 x i8] c"  %sz1 = add i64 %sz, 1\00", align 8
@.str.630 = private unnamed_addr constant [36 x i8] c"  %mem = call i64 @malloc(i64 %sz1)\00", align 8
@.str.631 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.632 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %ptr, i8* %sa)\00", align 8
@.str.633 = private unnamed_addr constant [38 x i8] c"  call i8* @strcat(i8* %ptr, i8* %sb)\00", align 8
@.str.634 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.635 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.636 = private unnamed_addr constant [34 x i8] c"define i64 @to_string(i64 %val) {\00", align 8
@.str.637 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.638 = private unnamed_addr constant [46 x i8] c"  br i1 %is_ptr, label %is_str, label %is_int\00", align 8
@.str.639 = private unnamed_addr constant [21 x i8] c"is_str: ret i64 %val\00", align 8
@.str.640 = private unnamed_addr constant [8 x i8] c"is_int:\00", align 8
@.str.641 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 32)\00", align 8
@.str.642 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %mem to i8*\00", align 8
@.str.643 = private unnamed_addr constant [69 x i8] c"  %fmt = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0\00", align 8
@.str.644 = private unnamed_addr constant [64 x i8] c"  call i32 (i8*, i8*, ...) @sprintf(i8* %p, i8* %fmt, i64 %val)\00", align 8
@.str.645 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.646 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.647 = private unnamed_addr constant [35 x i8] c"define i64 @_add(i64 %a, i64 %b) {\00", align 8
@.str.648 = private unnamed_addr constant [42 x i8] c"  %is_ptr_a = icmp sgt i64 %a, 4294967296\00", align 8
@.str.649 = private unnamed_addr constant [42 x i8] c"  %is_ptr_b = icmp sgt i64 %b, 4294967296\00", align 8
@.str.650 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.651 = private unnamed_addr constant [40 x i8] c"  %any_ptr = or i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.652 = private unnamed_addr constant [55 x i8] c"  br i1 %both_ptr, label %check_list, label %check_str\00", align 8
@.str.653 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.654 = private unnamed_addr constant [34 x i8] c"  %ptr_a = inttoptr i64 %a to i8*\00", align 8
@.str.655 = private unnamed_addr constant [32 x i8] c"  %type_a = load i8, i8* %ptr_a\00", align 8
@.str.656 = private unnamed_addr constant [35 x i8] c"  %is_list = icmp eq i8 %type_a, 3\00", align 8
@.str.657 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_str\00", align 8
@.str.658 = private unnamed_addr constant [11 x i8] c"check_str:\00", align 8
@.str.659 = private unnamed_addr constant [44 x i8] c"  br i1 %any_ptr, label %do_str, label %int\00", align 8
@.str.660 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.661 = private unnamed_addr constant [36 x i8] c"  %sa = call i64 @to_string(i64 %a)\00", align 8
@.str.662 = private unnamed_addr constant [36 x i8] c"  %sb = call i64 @to_string(i64 %b)\00", align 8
@.str.663 = private unnamed_addr constant [50 x i8] c"  %ret_str = call i64 @_str_cat(i64 %sa, i64 %sb)\00", align 8
@.str.664 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.665 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.666 = private unnamed_addr constant [36 x i8] c"  %new_list = call i64 @_list_new()\00", align 8
@.str.667 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %a)\00", align 8
@.str.668 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %b)\00", align 8
@.str.669 = private unnamed_addr constant [20 x i8] c"  ret i64 %new_list\00", align 8
@.str.670 = private unnamed_addr constant [5 x i8] c"int:\00", align 8
@.str.671 = private unnamed_addr constant [28 x i8] c"  %ret_int = add i64 %a, %b\00", align 8
@.str.672 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.673 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.674 = private unnamed_addr constant [47 x i8] c"define void @_list_copy(i64 %dest, i64 %src) {\00", align 8
@.str.675 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %src to i64*\00", align 8
@.str.676 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.677 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.678 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.679 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.680 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.681 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.682 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.683 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]\00", align 8
@.str.684 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.685 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.686 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.687 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.688 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.689 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %dest, i64 %val)\00", align 8
@.str.690 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.691 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.692 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.693 = private unnamed_addr constant [11 x i8] c"  ret void\00", align 8
@.str.694 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.695 = private unnamed_addr constant [48 x i8] c"define i64 @_append_poly(i64 %list, i64 %val) {\00", align 8
@.str.696 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.697 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_list, label %push_one\00", align 8
@.str.698 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.699 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.700 = private unnamed_addr constant [28 x i8] c"  %type = load i8, i8* %ptr\00", align 8
@.str.701 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.702 = private unnamed_addr constant [48 x i8] c"  br i1 %is_list, label %merge, label %push_one\00", align 8
@.str.703 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.704 = private unnamed_addr constant [45 x i8] c"  call void @_list_copy(i64 %list, i64 %val)\00", align 8
@.str.705 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.706 = private unnamed_addr constant [10 x i8] c"push_one:\00", align 8
@.str.707 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %list, i64 %val)\00", align 8
@.str.708 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.709 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.710 = private unnamed_addr constant [34 x i8] c"define i64 @_eq(i64 %a, i64 %b) {\00", align 8
@.str.711 = private unnamed_addr constant [42 x i8] c"  %a_is_ptr = icmp sgt i64 %a, 4294967296\00", align 8
@.str.712 = private unnamed_addr constant [42 x i8] c"  %b_is_ptr = icmp sgt i64 %b, 4294967296\00", align 8
@.str.713 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %a_is_ptr, %b_is_ptr\00", align 8
@.str.714 = private unnamed_addr constant [53 x i8] c"  br i1 %both_ptr, label %check_null, label %cmp_int\00", align 8
@.str.715 = private unnamed_addr constant [12 x i8] c"check_null:\00", align 8
@.str.716 = private unnamed_addr constant [30 x i8] c"  %a_null = icmp eq i64 %a, 0\00", align 8
@.str.717 = private unnamed_addr constant [30 x i8] c"  %b_null = icmp eq i64 %b, 0\00", align 8
@.str.718 = private unnamed_addr constant [37 x i8] c"  %any_null = or i1 %a_null, %b_null\00", align 8
@.str.719 = private unnamed_addr constant [50 x i8] c"  br i1 %any_null, label %cmp_int, label %cmp_str\00", align 8
@.str.720 = private unnamed_addr constant [9 x i8] c"cmp_str:\00", align 8
@.str.721 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.722 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.723 = private unnamed_addr constant [44 x i8] c"  %res = call i32 @strcmp(i8* %sa, i8* %sb)\00", align 8
@.str.724 = private unnamed_addr constant [30 x i8] c"  %iseq = icmp eq i32 %res, 0\00", align 8
@.str.725 = private unnamed_addr constant [34 x i8] c"  %ret_str = zext i1 %iseq to i64\00", align 8
@.str.726 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.727 = private unnamed_addr constant [9 x i8] c"cmp_int:\00", align 8
@.str.728 = private unnamed_addr constant [33 x i8] c"  %iseq_int = icmp eq i64 %a, %b\00", align 8
@.str.729 = private unnamed_addr constant [38 x i8] c"  %ret_int = zext i1 %iseq_int to i64\00", align 8
@.str.730 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.731 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.732 = private unnamed_addr constant [26 x i8] c"define i64 @_list_new() {\00", align 8
@.str.733 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 24)\00", align 8
@.str.734 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %mem to i64*\00", align 8
@.str.735 = private unnamed_addr constant [25 x i8] c"  store i64 3, i64* %ptr\00", align 8
@.str.736 = private unnamed_addr constant [45 x i8] c"  %cnt = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.737 = private unnamed_addr constant [25 x i8] c"  store i64 0, i64* %cnt\00", align 8
@.str.738 = private unnamed_addr constant [46 x i8] c"  %data = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.739 = private unnamed_addr constant [26 x i8] c"  store i64 0, i64* %data\00", align 8
@.str.740 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.741 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.742 = private unnamed_addr constant [50 x i8] c"define i64 @_list_set(i64 %l, i64 %idx, i64 %v) {\00", align 8
@.str.743 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.744 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.745 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.746 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.747 = private unnamed_addr constant [54 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %idx\00", align 8
@.str.748 = private unnamed_addr constant [27 x i8] c"  store i64 %v, i64* %slot\00", align 8
@.str.749 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.750 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.751 = private unnamed_addr constant [41 x i8] c"define i64 @_list_push(i64 %l, i64 %v) {\00", align 8
@.str.752 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.753 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.754 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.755 = private unnamed_addr constant [29 x i8] c"  %new_cnt = add i64 %cnt, 1\00", align 8
@.str.756 = private unnamed_addr constant [36 x i8] c"  store i64 %new_cnt, i64* %cnt_ptr\00", align 8
@.str.757 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.758 = private unnamed_addr constant [40 x i8] c"  %old_mem_i = load i64, i64* %data_ptr\00", align 8
@.str.759 = private unnamed_addr constant [35 x i8] c"  %req_bytes = mul i64 %new_cnt, 8\00", align 8
@.str.760 = private unnamed_addr constant [44 x i8] c"  %old_ptr = inttoptr i64 %old_mem_i to i8*\00", align 8
@.str.761 = private unnamed_addr constant [61 x i8] c"  %new_ptr = call i8* @realloc(i8* %old_ptr, i64 %req_bytes)\00", align 8
@.str.762 = private unnamed_addr constant [42 x i8] c"  %new_mem = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.763 = private unnamed_addr constant [37 x i8] c"  store i64 %new_mem, i64* %data_ptr\00", align 8
@.str.764 = private unnamed_addr constant [44 x i8] c"  %base_ptr = inttoptr i64 %new_mem to i64*\00", align 8
@.str.765 = private unnamed_addr constant [53 x i8] c"  %idx = getelementptr i64, i64* %base_ptr, i64 %cnt\00", align 8
@.str.766 = private unnamed_addr constant [26 x i8] c"  store i64 %v, i64* %idx\00", align 8
@.str.767 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.768 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.769 = private unnamed_addr constant [25 x i8] c"define i64 @_map_new() {\00", align 8
@.str.770 = private unnamed_addr constant [29 x i8] c"  %m = call i64 @_list_new()\00", align 8
@.str.771 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.772 = private unnamed_addr constant [25 x i8] c"  store i64 4, i64* %ptr\00", align 8
@.str.773 = private unnamed_addr constant [13 x i8] c"  ret i64 %m\00", align 8
@.str.774 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.775 = private unnamed_addr constant [47 x i8] c"define i64 @_map_set(i64 %m, i64 %k, i64 %v) {\00", align 8
@.str.776 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %k)\00", align 8
@.str.777 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %v)\00", align 8
@.str.778 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.779 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.780 = private unnamed_addr constant [47 x i8] c"define i64 @_set(i64 %col, i64 %idx, i64 %v) {\00", align 8
@.str.781 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %col to i64*\00", align 8
@.str.782 = private unnamed_addr constant [30 x i8] c"  %type = load i64, i64* %ptr\00", align 8
@.str.783 = private unnamed_addr constant [33 x i8] c"  %is_map = icmp eq i64 %type, 4\00", align 8
@.str.784 = private unnamed_addr constant [47 x i8] c"  br i1 %is_map, label %do_map, label %do_list\00", align 8
@.str.785 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.786 = private unnamed_addr constant [50 x i8] c"  call i64 @_list_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.787 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.788 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.789 = private unnamed_addr constant [49 x i8] c"  call i64 @_map_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.790 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.791 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.792 = private unnamed_addr constant [41 x i8] c"define i64 @_map_get(i64 %m, i64 %key) {\00", align 8
@.str.793 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.794 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.795 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.796 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.797 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.798 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.799 = private unnamed_addr constant [36 x i8] c"  %key_s = inttoptr i64 %key to i8*\00", align 8
@.str.800 = private unnamed_addr constant [29 x i8] c"  %start_i = sub i64 %cnt, 2\00", align 8
@.str.801 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.802 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.803 = private unnamed_addr constant [52 x i8] c"  %i = phi i64 [ %start_i, %0 ], [ %next_i, %next ]\00", align 8
@.str.804 = private unnamed_addr constant [29 x i8] c"  %cond = icmp sge i64 %i, 0\00", align 8
@.str.805 = private unnamed_addr constant [50 x i8] c"  br i1 %cond, label %check_key, label %not_found\00", align 8
@.str.806 = private unnamed_addr constant [11 x i8] c"check_key:\00", align 8
@.str.807 = private unnamed_addr constant [54 x i8] c"  %k_slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.808 = private unnamed_addr constant [34 x i8] c"  %k_val = load i64, i64* %k_slot\00", align 8
@.str.809 = private unnamed_addr constant [38 x i8] c"  %k_str = inttoptr i64 %k_val to i8*\00", align 8
@.str.810 = private unnamed_addr constant [50 x i8] c"  %cmp = call i32 @strcmp(i8* %k_str, i8* %key_s)\00", align 8
@.str.811 = private unnamed_addr constant [31 x i8] c"  %match = icmp eq i32 %cmp, 0\00", align 8
@.str.812 = private unnamed_addr constant [42 x i8] c"  br i1 %match, label %found, label %next\00", align 8
@.str.813 = private unnamed_addr constant [6 x i8] c"next:\00", align 8
@.str.814 = private unnamed_addr constant [26 x i8] c"  %next_i = sub i64 %i, 2\00", align 8
@.str.815 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.816 = private unnamed_addr constant [7 x i8] c"found:\00", align 8
@.str.817 = private unnamed_addr constant [25 x i8] c"  %v_idx = add i64 %i, 1\00", align 8
@.str.818 = private unnamed_addr constant [58 x i8] c"  %v_slot = getelementptr i64, i64* %base_ptr, i64 %v_idx\00", align 8
@.str.819 = private unnamed_addr constant [32 x i8] c"  %ret = load i64, i64* %v_slot\00", align 8
@.str.820 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.821 = private unnamed_addr constant [11 x i8] c"not_found:\00", align 8
@.str.822 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.823 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.824 = private unnamed_addr constant [39 x i8] c"define i64 @_get(i64 %col, i64 %idx) {\00", align 8
@.str.825 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %col, 0\00", align 8
@.str.826 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %err, label %check\00", align 8
@.str.827 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.828 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %col to i8*\00", align 8
@.str.829 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.830 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.831 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_map\00", align 8
@.str.832 = private unnamed_addr constant [11 x i8] c"check_map:\00", align 8
@.str.833 = private unnamed_addr constant [31 x i8] c"  %is_map = icmp eq i8 %tag, 4\00", align 8
@.str.834 = private unnamed_addr constant [46 x i8] c"  br i1 %is_map, label %do_map, label %do_str\00", align 8
@.str.835 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.836 = private unnamed_addr constant [39 x i8] c"  %str_base = inttoptr i64 %col to i8*\00", align 8
@.str.837 = private unnamed_addr constant [56 x i8] c"  %char_ptr = getelementptr i8, i8* %str_base, i64 %idx\00", align 8
@.str.838 = private unnamed_addr constant [33 x i8] c"  %char = load i8, i8* %char_ptr\00", align 8
@.str.839 = private unnamed_addr constant [37 x i8] c"  %new_mem = call i64 @malloc(i64 2)\00", align 8
@.str.840 = private unnamed_addr constant [42 x i8] c"  %new_ptr = inttoptr i64 %new_mem to i8*\00", align 8
@.str.841 = private unnamed_addr constant [31 x i8] c"  store i8 %char, i8* %new_ptr\00", align 8
@.str.842 = private unnamed_addr constant [48 x i8] c"  %term = getelementptr i8, i8* %new_ptr, i64 1\00", align 8
@.str.843 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.844 = private unnamed_addr constant [42 x i8] c"  %ret_str = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.845 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.846 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.847 = private unnamed_addr constant [52 x i8] c"  %map_val = call i64 @_map_get(i64 %col, i64 %idx)\00", align 8
@.str.848 = private unnamed_addr constant [19 x i8] c"  ret i64 %map_val\00", align 8
@.str.849 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.850 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %col to i64*\00", align 8
@.str.851 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.852 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.853 = private unnamed_addr constant [36 x i8] c"  %arr = inttoptr i64 %base to i64*\00", align 8
@.str.854 = private unnamed_addr constant [49 x i8] c"  %slot = getelementptr i64, i64* %arr, i64 %idx\00", align 8
@.str.855 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.856 = private unnamed_addr constant [15 x i8] c"  ret i64 %val\00", align 8
@.str.857 = private unnamed_addr constant [15 x i8] c"err: ret i64 0\00", align 8
@.str.858 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.859 = private unnamed_addr constant [34 x i8] c"define i64 @_get_argv(i64 %idx) {\00", align 8
@.str.860 = private unnamed_addr constant [37 x i8] c"  %argc = load i32, i32* @__sys_argc\00", align 8
@.str.861 = private unnamed_addr constant [34 x i8] c"  %argc64 = sext i32 %argc to i64\00", align 8
@.str.862 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %idx, %argc64\00", align 8
@.str.863 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %err, label %ok\00", align 8
@.str.864 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.865 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.866 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.867 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.868 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.869 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.870 = private unnamed_addr constant [39 x i8] c"  %argv = load i8**, i8*** @__sys_argv\00", align 8
@.str.871 = private unnamed_addr constant [49 x i8] c"  %ptr = getelementptr i8*, i8** %argv, i64 %idx\00", align 8
@.str.872 = private unnamed_addr constant [29 x i8] c"  %str = load i8*, i8** %ptr\00", align 8
@.str.873 = private unnamed_addr constant [34 x i8] c"  %ret = ptrtoint i8* %str to i64\00", align 8
@.str.874 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.875 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.876 = private unnamed_addr constant [36 x i8] c"define i64 @revelare(i64 %path_i) {\00", align 8
@.str.877 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.878 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_r, i64 0, i64 0\00", align 8
@.str.879 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.880 = private unnamed_addr constant [34 x i8] c"  %f_int = ptrtoint i8* %f to i64\00", align 8
@.str.881 = private unnamed_addr constant [33 x i8] c"  %valid = icmp ne i64 %f_int, 0\00", align 8
@.str.882 = private unnamed_addr constant [40 x i8] c"  br i1 %valid, label %read, label %err\00", align 8
@.str.883 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.884 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 2)\00", align 8
@.str.885 = private unnamed_addr constant [33 x i8] c"  %len = call i64 @ftell(i8* %f)\00", align 8
@.str.886 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 0)\00", align 8
@.str.887 = private unnamed_addr constant [30 x i8] c"  %alloc_sz = add i64 %len, 1\00", align 8
@.str.888 = private unnamed_addr constant [41 x i8] c"  %buf = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.889 = private unnamed_addr constant [38 x i8] c"  %buf_ptr = inttoptr i64 %buf to i8*\00", align 8
@.str.890 = private unnamed_addr constant [57 x i8] c"  call i64 @fread(i8* %buf_ptr, i64 1, i64 %len, i8* %f)\00", align 8
@.str.891 = private unnamed_addr constant [51 x i8] c"  %term = getelementptr i8, i8* %buf_ptr, i64 %len\00", align 8
@.str.892 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.893 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.894 = private unnamed_addr constant [15 x i8] c"  ret i64 %buf\00", align 8
@.str.895 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.896 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.897 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.898 = private unnamed_addr constant [52 x i8] c"define i64 @inscribo(i64 %path_i, i64 %content_i) {\00", align 8
@.str.899 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.900 = private unnamed_addr constant [44 x i8] c"  %content = inttoptr i64 %content_i to i8*\00", align 8
@.str.901 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_w, i64 0, i64 0\00", align 8
@.str.902 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.903 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %content)\00", align 8
@.str.904 = private unnamed_addr constant [58 x i8] c"  call i64 @fwrite(i8* %content, i64 1, i64 %len, i8* %f)\00", align 8
@.str.905 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.906 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.907 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.908 = private unnamed_addr constant [34 x i8] c"define i64 @print_any(i64 %val) {\00", align 8
@.str.909 = private unnamed_addr constant [7 x i8] c"entry:\00", align 8
@.str.910 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.911 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_obj, label %print_int\00", align 8
@.str.912 = private unnamed_addr constant [11 x i8] c"check_obj:\00", align 8
@.str.913 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.914 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.915 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.916 = private unnamed_addr constant [54 x i8] c"  br i1 %is_list, label %print_list, label %print_str\00", align 8
@.str.917 = private unnamed_addr constant [12 x i8] c"print_list:\00", align 8
@.str.918 = private unnamed_addr constant [70 x i8] c"  %f_s1 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.919 = private unnamed_addr constant [67 x i8] c"  %b_l = getelementptr [2 x i8], [2 x i8]* @.m_brk_l, i64 0, i64 0\00", align 8
@.str.920 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s1, i8* %b_l)\00", align 8
@.str.921 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.922 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.923 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.924 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.925 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.926 = private unnamed_addr constant [50 x i8] c"  br i1 %is_empty, label %done, label %setup_loop\00", align 8
@.str.927 = private unnamed_addr constant [12 x i8] c"setup_loop:\00", align 8
@.str.928 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.929 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.930 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.931 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.932 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.933 = private unnamed_addr constant [58 x i8] c"  %i = phi i64 [ 0, %setup_loop ], [ %next_i, %loop_end ]\00", align 8
@.str.934 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.935 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.936 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.937 = private unnamed_addr constant [33 x i8] c"  %not_first = icmp ne i64 %i, 0\00", align 8
@.str.938 = private unnamed_addr constant [51 x i8] c"  br i1 %not_first, label %comma, label %val_print\00", align 8
@.str.939 = private unnamed_addr constant [7 x i8] c"comma:\00", align 8
@.str.940 = private unnamed_addr constant [70 x i8] c"  %f_s2 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.941 = private unnamed_addr constant [67 x i8] c"  %com = getelementptr [3 x i8], [3 x i8]* @.m_comma, i64 0, i64 0\00", align 8
@.str.942 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s2, i8* %com)\00", align 8
@.str.943 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.944 = private unnamed_addr constant [22 x i8] c"  br label %val_print\00", align 8
@.str.945 = private unnamed_addr constant [11 x i8] c"val_print:\00", align 8
@.str.946 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.947 = private unnamed_addr constant [28 x i8] c"  %v = load i64, i64* %slot\00", align 8
@.str.948 = private unnamed_addr constant [42 x i8] c"  %v_is_ptr = icmp sgt i64 %v, 4294967296\00", align 8
@.str.949 = private unnamed_addr constant [52 x i8] c"  br i1 %v_is_ptr, label %v_ptr_check, label %v_int\00", align 8
@.str.950 = private unnamed_addr constant [13 x i8] c"v_ptr_check:\00", align 8
@.str.951 = private unnamed_addr constant [36 x i8] c"  %vs_ptr8 = inttoptr i64 %v to i8*\00", align 8
@.str.952 = private unnamed_addr constant [34 x i8] c"  %in_tag = load i8, i8* %vs_ptr8\00", align 8
@.str.953 = private unnamed_addr constant [38 x i8] c"  %in_is_list = icmp eq i8 %in_tag, 3\00", align 8
@.str.954 = private unnamed_addr constant [55 x i8] c"  br i1 %in_is_list, label %v_nested, label %v_raw_str\00", align 8
@.str.955 = private unnamed_addr constant [10 x i8] c"v_nested:\00", align 8
@.str.956 = private unnamed_addr constant [30 x i8] c"  call i64 @print_any(i64 %v)\00", align 8
@.str.957 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.958 = private unnamed_addr constant [11 x i8] c"v_raw_str:\00", align 8
@.str.959 = private unnamed_addr constant [70 x i8] c"  %f_s3 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.960 = private unnamed_addr constant [35 x i8] c"  %vs_str = inttoptr i64 %v to i8*\00", align 8
@.str.961 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s3, i8* %vs_str)\00", align 8
@.str.962 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.963 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.964 = private unnamed_addr constant [7 x i8] c"v_int:\00", align 8
@.str.965 = private unnamed_addr constant [69 x i8] c"  %f_i = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0\00", align 8
@.str.966 = private unnamed_addr constant [48 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i, i64 %v)\00", align 8
@.str.967 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.968 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.969 = private unnamed_addr constant [10 x i8] c"loop_end:\00", align 8
@.str.970 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.971 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.972 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.973 = private unnamed_addr constant [70 x i8] c"  %f_s4 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.974 = private unnamed_addr constant [67 x i8] c"  %b_r = getelementptr [3 x i8], [3 x i8]* @.m_brk_r, i64 0, i64 0\00", align 8
@.str.975 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s4, i8* %b_r)\00", align 8
@.str.976 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.977 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.978 = private unnamed_addr constant [11 x i8] c"print_int:\00", align 8
@.str.979 = private unnamed_addr constant [71 x i8] c"  %f_i_end = getelementptr [5 x i8], [5 x i8]* @.fmt_int, i64 0, i64 0\00", align 8
@.str.980 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i_end, i64 %val)\00", align 8
@.str.981 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.982 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.983 = private unnamed_addr constant [11 x i8] c"print_str:\00", align 8
@.str.984 = private unnamed_addr constant [71 x i8] c"  %f_s_end = getelementptr [4 x i8], [4 x i8]* @.fmt_str, i64 0, i64 0\00", align 8
@.str.985 = private unnamed_addr constant [36 x i8] c"  %str_p = inttoptr i64 %val to i8*\00", align 8
@.str.986 = private unnamed_addr constant [56 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s_end, i8* %str_p)\00", align 8
@.str.987 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.988 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.989 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.990 = private unnamed_addr constant [30 x i8] c"define i64 @codex(i64 %val) {\00", align 8
@.str.991 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.992 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.993 = private unnamed_addr constant [27 x i8] c"  %ret = zext i8 %c to i64\00", align 8
@.str.994 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.995 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.996 = private unnamed_addr constant [51 x i8] c"define i64 @pars(i64 %str, i64 %start, i64 %len) {\00", align 8
@.str.997 = private unnamed_addr constant [34 x i8] c"  %src = inttoptr i64 %str to i8*\00", align 8
@.str.998 = private unnamed_addr constant [37 x i8] c"  %slen = call i64 @strlen(i8* %src)\00", align 8
@.str.999 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %start, %slen\00", align 8
@.str.1000 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %oob, label %ok\00", align 8
@.str.1001 = private unnamed_addr constant [5 x i8] c"oob:\00", align 8
@.str.1002 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1003 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1004 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1005 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1006 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.1007 = private unnamed_addr constant [31 x i8] c"  %rem = sub i64 %slen, %start\00", align 8
@.str.1008 = private unnamed_addr constant [37 x i8] c"  %is_long = icmp sgt i64 %len, %rem\00", align 8
@.str.1009 = private unnamed_addr constant [53 x i8] c"  %safe_len = select i1 %is_long, i64 %rem, i64 %len\00", align 8
@.str.1010 = private unnamed_addr constant [52 x i8] c"  %src_off = getelementptr i8, i8* %src, i64 %start\00", align 8
@.str.1011 = private unnamed_addr constant [35 x i8] c"  %alloc_sz = add i64 %safe_len, 1\00", align 8
@.str.1012 = private unnamed_addr constant [42 x i8] c"  %dest = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.1013 = private unnamed_addr constant [40 x i8] c"  %dest_ptr = inttoptr i64 %dest to i8*\00", align 8
@.str.1014 = private unnamed_addr constant [64 x i8] c"  call i8* @strncpy(i8* %dest_ptr, i8* %src_off, i64 %safe_len)\00", align 8
@.str.1015 = private unnamed_addr constant [57 x i8] c"  %term = getelementptr i8, i8* %dest_ptr, i64 %safe_len\00", align 8
@.str.1016 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1017 = private unnamed_addr constant [16 x i8] c"  ret i64 %dest\00", align 8
@.str.1018 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1019 = private unnamed_addr constant [34 x i8] c"define i64 @signum_ex(i64 %val) {\00", align 8
@.str.1020 = private unnamed_addr constant [33 x i8] c"  %mem = call i64 @malloc(i64 2)\00", align 8
@.str.1021 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1022 = private unnamed_addr constant [28 x i8] c"  %c = trunc i64 %val to i8\00", align 8
@.str.1023 = private unnamed_addr constant [24 x i8] c"  store i8 %c, i8* %ptr\00", align 8
@.str.1024 = private unnamed_addr constant [44 x i8] c"  %term = getelementptr i8, i8* %ptr, i64 1\00", align 8
@.str.1025 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1026 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1027 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1028 = private unnamed_addr constant [32 x i8] c"define i64 @mensura(i64 %val) {\00", align 8
@.str.1029 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %val, 0\00", align 8
@.str.1030 = private unnamed_addr constant [47 x i8] c"  br i1 %is_null, label %ret_zero, label %read\00", align 8
@.str.1031 = private unnamed_addr constant [10 x i8] c"ret_zero:\00", align 8
@.str.1032 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1033 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1034 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.1035 = private unnamed_addr constant [29 x i8] c"  %type = load i8, i8* %ptr8\00", align 8
@.str.1036 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.1037 = private unnamed_addr constant [32 x i8] c"  %is_map = icmp eq i8 %type, 4\00", align 8
@.str.1038 = private unnamed_addr constant [36 x i8] c"  %is_col = or i1 %is_list, %is_map\00", align 8
@.str.1039 = private unnamed_addr constant [48 x i8] c"  br i1 %is_col, label %get_cnt, label %get_str\00", align 8
@.str.1040 = private unnamed_addr constant [9 x i8] c"get_cnt:\00", align 8
@.str.1041 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.1042 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1043 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1044 = private unnamed_addr constant [15 x i8] c"  ret i64 %cnt\00", align 8
@.str.1045 = private unnamed_addr constant [9 x i8] c"get_str:\00", align 8
@.str.1046 = private unnamed_addr constant [38 x i8] c"  %str_ptr = inttoptr i64 %val to i8*\00", align 8
@.str.1047 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %str_ptr)\00", align 8
@.str.1048 = private unnamed_addr constant [15 x i8] c"  ret i64 %len\00", align 8
@.str.1049 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1050 = private unnamed_addr constant [22 x i8] c"define i64 @capio() {\00", align 8
@.str.1051 = private unnamed_addr constant [35 x i8] c"  %mem = call i64 @malloc(i64 256)\00", align 8
@.str.1052 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1053 = private unnamed_addr constant [17 x i8] c"  br label %read\00", align 8
@.str.1054 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1055 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %cont ]\00", align 8
@.str.1056 = private unnamed_addr constant [27 x i8] c"  %c = call i32 @getchar()\00", align 8
@.str.1057 = private unnamed_addr constant [31 x i8] c"  %is_eof = icmp eq i32 %c, -1\00", align 8
@.str.1058 = private unnamed_addr constant [30 x i8] c"  %is_nl = icmp eq i32 %c, 10\00", align 8
@.str.1059 = private unnamed_addr constant [32 x i8] c"  %stop = or i1 %is_eof, %is_nl\00", align 8
@.str.1060 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %cont\00", align 8
@.str.1061 = private unnamed_addr constant [6 x i8] c"cont:\00", align 8
@.str.1062 = private unnamed_addr constant [29 x i8] c"  %char = trunc i32 %c to i8\00", align 8
@.str.1063 = private unnamed_addr constant [45 x i8] c"  %slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1064 = private unnamed_addr constant [28 x i8] c"  store i8 %char, i8* %slot\00", align 8
@.str.1065 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1066 = private unnamed_addr constant [37 x i8] c"  %limit = icmp slt i64 %next_i, 255\00", align 8
@.str.1067 = private unnamed_addr constant [41 x i8] c"  br i1 %limit, label %read, label %done\00", align 8
@.str.1068 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1069 = private unnamed_addr constant [50 x i8] c"  %term_slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1070 = private unnamed_addr constant [29 x i8] c"  store i8 0, i8* %term_slot\00", align 8
@.str.1071 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1072 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1073 = private unnamed_addr constant [33 x i8] c"define i64 @imperium(i64 %cmd) {\00", align 8
@.str.1074 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %cmd to i8*\00", align 8
@.str.1075 = private unnamed_addr constant [34 x i8] c"  %res = call i32 @system(i8* %p)\00", align 8
@.str.1076 = private unnamed_addr constant [30 x i8] c"  %ext = sext i32 %res to i64\00", align 8
@.str.1077 = private unnamed_addr constant [15 x i8] c"  ret i64 %ext\00", align 8
@.str.1078 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1079 = private unnamed_addr constant [31 x i8] c"define i64 @dormire(i64 %ms) {\00", align 8
@.str.1080 = private unnamed_addr constant [26 x i8] c"  %us = mul i64 %ms, 1000\00", align 8
@.str.1081 = private unnamed_addr constant [31 x i8] c"  %us32 = trunc i64 %us to i32\00", align 8
@.str.1082 = private unnamed_addr constant [30 x i8] c"  call i32 @usleep(i32 %us32)\00", align 8
@.str.1083 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1084 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1085 = private unnamed_addr constant [32 x i8] c"define i64 @numerus(i64 %str) {\00", align 8
@.str.1086 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %str to i8*\00", align 8
@.str.1087 = private unnamed_addr constant [32 x i8] c"  %res = call i64 @atol(i8* %p)\00", align 8
@.str.1088 = private unnamed_addr constant [15 x i8] c"  ret i64 %res\00", align 8
@.str.1089 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1090 = private unnamed_addr constant [45 x i8] c"define i64 @scindere(i64 %str, i64 %delim) {\00", align 8
@.str.1091 = private unnamed_addr constant [32 x i8] c"  %list = call i64 @_list_new()\00", align 8
@.str.1092 = private unnamed_addr constant [34 x i8] c"  %s_p = inttoptr i64 %str to i8*\00", align 8
@.str.1093 = private unnamed_addr constant [36 x i8] c"  %d_p = inttoptr i64 %delim to i8*\00", align 8
@.str.1094 = private unnamed_addr constant [36 x i8] c"  %len = call i64 @strlen(i8* %s_p)\00", align 8
@.str.1095 = private unnamed_addr constant [24 x i8] c"  %sz = add i64 %len, 1\00", align 8
@.str.1096 = private unnamed_addr constant [35 x i8] c"  %mem = call i64 @malloc(i64 %sz)\00", align 8
@.str.1097 = private unnamed_addr constant [33 x i8] c"  %cp = inttoptr i64 %mem to i8*\00", align 8
@.str.1098 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %cp, i8* %s_p)\00", align 8
@.str.1099 = private unnamed_addr constant [45 x i8] c"  %tok = call i8* @strtok(i8* %cp, i8* %d_p)\00", align 8
@.str.1100 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1101 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1102 = private unnamed_addr constant [48 x i8] c"  %curr = phi i8* [ %tok, %0 ], [ %nxt, %body ]\00", align 8
@.str.1103 = private unnamed_addr constant [37 x i8] c"  %is_null = icmp eq i8* %curr, null\00", align 8
@.str.1104 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %body\00", align 8
@.str.1105 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1106 = private unnamed_addr constant [37 x i8] c"  %t_val = ptrtoint i8* %curr to i64\00", align 8
@.str.1107 = private unnamed_addr constant [46 x i8] c"  call i64 @_list_push(i64 %list, i64 %t_val)\00", align 8
@.str.1108 = private unnamed_addr constant [46 x i8] c"  %nxt = call i8* @strtok(i8* null, i8* %d_p)\00", align 8
@.str.1109 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1110 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1111 = private unnamed_addr constant [16 x i8] c"  ret i64 %list\00", align 8
@.str.1112 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1113 = private unnamed_addr constant [50 x i8] c"define i64 @iunctura(i64 %list_ptr, i64 %delim) {\00", align 8
@.str.1114 = private unnamed_addr constant [38 x i8] c"  %is_null = icmp eq i64 %list_ptr, 0\00", align 8
@.str.1115 = private unnamed_addr constant [49 x i8] c"  br i1 %is_null, label %ret_empty, label %check\00", align 8
@.str.1116 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.1117 = private unnamed_addr constant [42 x i8] c"  %ptr64 = inttoptr i64 %list_ptr to i64*\00", align 8
@.str.1118 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1119 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1120 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.1121 = private unnamed_addr constant [49 x i8] c"  br i1 %is_empty, label %ret_empty, label %calc\00", align 8
@.str.1122 = private unnamed_addr constant [11 x i8] c"ret_empty:\00", align 8
@.str.1123 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1124 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1125 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1126 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1127 = private unnamed_addr constant [6 x i8] c"calc:\00", align 8
@.str.1128 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.1129 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.1130 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.1131 = private unnamed_addr constant [35 x i8] c"  %res_0 = call i64 @malloc(i64 1)\00", align 8
@.str.1132 = private unnamed_addr constant [40 x i8] c"  %res_0_p = inttoptr i64 %res_0 to i8*\00", align 8
@.str.1133 = private unnamed_addr constant [27 x i8] c"  store i8 0, i8* %res_0_p\00", align 8
@.str.1134 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1135 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1136 = private unnamed_addr constant [49 x i8] c"  %i = phi i64 [ 0, %calc ], [ %next_i, %merge ]\00", align 8
@.str.1137 = private unnamed_addr constant [63 x i8] c"  %curr_str = phi i64 [ %res_0, %calc ], [ %next_str, %merge ]\00", align 8
@.str.1138 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.1139 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.1140 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1141 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.1142 = private unnamed_addr constant [31 x i8] c"  %item = load i64, i64* %slot\00", align 8
@.str.1143 = private unnamed_addr constant [43 x i8] c"  %item_s = call i64 @to_string(i64 %item)\00", align 8
@.str.1144 = private unnamed_addr constant [58 x i8] c"  %added = call i64 @_str_cat(i64 %curr_str, i64 %item_s)\00", align 8
@.str.1145 = private unnamed_addr constant [30 x i8] c"  %last_idx = sub i64 %cnt, 1\00", align 8
@.str.1146 = private unnamed_addr constant [39 x i8] c"  %is_last = icmp eq i64 %i, %last_idx\00", align 8
@.str.1147 = private unnamed_addr constant [54 x i8] c"  br i1 %is_last, label %skip_delim, label %add_delim\00", align 8
@.str.1148 = private unnamed_addr constant [11 x i8] c"add_delim:\00", align 8
@.str.1149 = private unnamed_addr constant [59 x i8] c"  %with_delim = call i64 @_str_cat(i64 %added, i64 %delim)\00", align 8
@.str.1150 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1151 = private unnamed_addr constant [12 x i8] c"skip_delim:\00", align 8
@.str.1152 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1153 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.1154 = private unnamed_addr constant [75 x i8] c"  %next_str = phi i64 [ %with_delim, %add_delim ], [ %added, %skip_delim ]\00", align 8
@.str.1155 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1156 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1157 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1158 = private unnamed_addr constant [20 x i8] c"  ret i64 %curr_str\00", align 8
@.str.1159 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1160 = private unnamed_addr constant [90 x i8] c"define i64 @syscall6(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) {\00", align 8
@.str.1161 = private unnamed_addr constant [184 x i8] c"  %res = call i64 asm sideeffect \22syscall\22, \22={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11},~{memory}\22(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6)\00", align 8
@.str.1162 = private unnamed_addr constant [15 x i8] c"  ret i64 %res\00", align 8
@.str.1163 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1164 = private unnamed_addr constant [31 x i8] c"define i64 @strlen(i8* %str) {\00", align 8
@.str.1165 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1166 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1167 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1168 = private unnamed_addr constant [44 x i8] c"  %ptr = getelementptr i8, i8* %str, i64 %i\00", align 8
@.str.1169 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.1170 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1171 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1172 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1173 = private unnamed_addr constant [17 x i8] c"done: ret i64 %i\00", align 8
@.str.1174 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1175 = private unnamed_addr constant [39 x i8] c"define i32 @strcmp(i8* %s1, i8* %s2) {\00", align 8
@.str.1176 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1177 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1178 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1179 = private unnamed_addr constant [42 x i8] c"  %p1 = getelementptr i8, i8* %s1, i64 %i\00", align 8
@.str.1180 = private unnamed_addr constant [42 x i8] c"  %p2 = getelementptr i8, i8* %s2, i64 %i\00", align 8
@.str.1181 = private unnamed_addr constant [25 x i8] c"  %c1 = load i8, i8* %p1\00", align 8
@.str.1182 = private unnamed_addr constant [25 x i8] c"  %c2 = load i8, i8* %p2\00", align 8
@.str.1183 = private unnamed_addr constant [32 x i8] c"  %not_eq = icmp ne i8 %c1, %c2\00", align 8
@.str.1184 = private unnamed_addr constant [31 x i8] c"  %is_null = icmp eq i8 %c1, 0\00", align 8
@.str.1185 = private unnamed_addr constant [34 x i8] c"  %stop = or i1 %not_eq, %is_null\00", align 8
@.str.1186 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1187 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %loop\00", align 8
@.str.1188 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1189 = private unnamed_addr constant [27 x i8] c"  %z1 = zext i8 %c1 to i32\00", align 8
@.str.1190 = private unnamed_addr constant [27 x i8] c"  %z2 = zext i8 %c2 to i32\00", align 8
@.str.1191 = private unnamed_addr constant [27 x i8] c"  %diff = sub i32 %z1, %z2\00", align 8
@.str.1192 = private unnamed_addr constant [16 x i8] c"  ret i32 %diff\00", align 8
@.str.1193 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1194 = private unnamed_addr constant [42 x i8] c"define i8* @strcpy(i8* %dest, i8* %src) {\00", align 8
@.str.1195 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1196 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1197 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1198 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1199 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1200 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1201 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1202 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1203 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1204 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1205 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1206 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1207 = private unnamed_addr constant [51 x i8] c"define i8* @strncpy(i8* %dest, i8* %src, i64 %n) {\00", align 8
@.str.1208 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1209 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1210 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %body ]\00", align 8
@.str.1211 = private unnamed_addr constant [29 x i8] c"  %cmp = icmp slt i64 %i, %n\00", align 8
@.str.1212 = private unnamed_addr constant [39 x i8] c"  br i1 %cmp, label %body, label %done\00", align 8
@.str.1213 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1214 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1215 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1216 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1217 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1218 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1219 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1220 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1221 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1222 = private unnamed_addr constant [42 x i8] c"define i8* @strcat(i8* %dest, i8* %src) {\00", align 8
@.str.1223 = private unnamed_addr constant [37 x i8] c"  %len = call i64 @strlen(i8* %dest)\00", align 8
@.str.1224 = private unnamed_addr constant [49 x i8] c"  %d_end = getelementptr i8, i8* %dest, i64 %len\00", align 8
@.str.1225 = private unnamed_addr constant [41 x i8] c"  call i8* @strcpy(i8* %d_end, i8* %src)\00", align 8
@.str.1226 = private unnamed_addr constant [16 x i8] c"  ret i8* %dest\00", align 8
@.str.1227 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1228 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1229 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1230 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1231 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1232 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1233 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.1234 = private unnamed_addr constant [44 x i8] c"⚔️  ACHLYS -> LLVM COMPILER (STAGE 3.5)\00", align 8
@.str.1235 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1236 = private unnamed_addr constant [27 x i8] c"Usage: ./achlys <file.nox>\00", align 8
@.str.1237 = private unnamed_addr constant [25 x i8] c"⚠️  File not found: \00", align 8
@.str.1238 = private unnamed_addr constant [16 x i8] c"[1/3] Lexing...\00", align 8
@.str.1239 = private unnamed_addr constant [19 x i8] c"[DEBUG] Main sees \00", align 8
@.str.1240 = private unnamed_addr constant [9 x i8] c" tokens.\00", align 8
@.str.1241 = private unnamed_addr constant [4 x i8] c" T[\00", align 8
@.str.1242 = private unnamed_addr constant [4 x i8] c"]: \00", align 8
@.str.1243 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.1244 = private unnamed_addr constant [3 x i8] c" (\00", align 8
@.str.1245 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1246 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.1247 = private unnamed_addr constant [17 x i8] c"[2/3] Parsing...\00", align 8
@.str.1248 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1249 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1250 = private unnamed_addr constant [24 x i8] c"❌ Compilation Failed.\00", align 8
@.str.1251 = private unnamed_addr constant [28 x i8] c"[3/3] Generating LLVM IR...\00", align 8
@.str.1252 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1253 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1254 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1255 = private unnamed_addr constant [2 x i8] c"@\00", align 8
@.str.1256 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1257 = private unnamed_addr constant [16 x i8] c" = global i64 0\00", align 8
@.str.1258 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1259 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1260 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1261 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1262 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1263 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1264 = private unnamed_addr constant [42 x i8] c"define i32 @main(i32 %argc, i8** %argv) {\00", align 8
@.str.1265 = private unnamed_addr constant [36 x i8] c"  store i32 %argc, i32* @__sys_argc\00", align 8
@.str.1266 = private unnamed_addr constant [38 x i8] c"  store i8** %argv, i8*** @__sys_argv\00", align 8
@.str.1267 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1268 = private unnamed_addr constant [55 x i8] c"  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* \00", align 8
@.str.1269 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.1270 = private unnamed_addr constant [52 x i8] c"  %boot_msg_int = ptrtoint i8* %boot_msg_ptr to i64\00", align 8
@.str.1271 = private unnamed_addr constant [41 x i8] c"  call i64 @print_any(i64 %boot_msg_int)\00", align 8
@.str.1272 = private unnamed_addr constant [31 x i8] c"[DEBUG] Top Level Statements: \00", align 8
@.str.1273 = private unnamed_addr constant [10 x i8] c"ret i32 0\00", align 8
@.str.1274 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1275 = private unnamed_addr constant [10 x i8] c"kernel.ll\00", align 8
@.str.1276 = private unnamed_addr constant [36 x i8] c"✅ SUCCESS. 'kernel.ll' generated.\00", align 8
@.str.1277 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1278 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1279 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1280 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1281 = private unnamed_addr constant [1 x i8] c"\00", align 8
define i64 @int_to_str(i64 %arg_n) {
  %ptr_n = alloca i64
  store i64 %arg_n, i64* %ptr_n
  %ptr_out = alloca i64
  %ptr_is_neg = alloca i64
  %ptr_digit = alloca i64
  %ptr_c = alloca i64
  %r1 = load i64, i64* %ptr_n
  %r2 = call i64 @_eq(i64 %r1, i64 0)
  %r3 = icmp ne i64 %r2, 0
  br i1 %r3, label %L1, label %L2
L1:
  %r4 = getelementptr [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  ret i64 %r5
  br label %L3
L2:
  br label %L3
L3:
  %r6 = getelementptr [1 x i8], [1 x i8]* @.str.2, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* %ptr_out
  store i64 0, i64* %ptr_is_neg
  %r8 = load i64, i64* %ptr_n
  %r10 = icmp slt i64 %r8, 0
  %r9 = zext i1 %r10 to i64
  %r11 = icmp ne i64 %r9, 0
  br i1 %r11, label %L4, label %L5
L4:
  store i64 1, i64* %ptr_is_neg
  %r12 = load i64, i64* %ptr_n
  %r13 = sub i64 0, %r12
  store i64 %r13, i64* %ptr_n
  br label %L6
L5:
  br label %L6
L6:
  br label %L7
L7:
  %r14 = load i64, i64* %ptr_n
  %r16 = icmp sgt i64 %r14, 0
  %r15 = zext i1 %r16 to i64
  %r17 = icmp ne i64 %r15, 0
  br i1 %r17, label %L8, label %L9
L8:
  %r18 = load i64, i64* %ptr_n
  %r19 = srem i64 %r18, 10
  store i64 %r19, i64* %ptr_digit
  %r20 = load i64, i64* %ptr_digit
  %r21 = call i64 @_add(i64 48, i64 %r20)
  store i64 %r21, i64* %ptr_c
  %r22 = load i64, i64* %ptr_c
  %r23 = call i64 @signum_ex(i64 %r22)
  %r24 = load i64, i64* %ptr_out
  %r25 = call i64 @_add(i64 %r23, i64 %r24)
  store i64 %r25, i64* %ptr_out
  %r26 = load i64, i64* %ptr_n
  %r27 = sdiv i64 %r26, 10
  store i64 %r27, i64* %ptr_n
  br label %L7
L9:
  %r28 = load i64, i64* %ptr_is_neg
  %r29 = icmp ne i64 %r28, 0
  br i1 %r29, label %L10, label %L11
L10:
  %r30 = getelementptr [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  %r31 = ptrtoint i8* %r30 to i64
  %r32 = load i64, i64* %ptr_out
  %r33 = call i64 @_add(i64 %r31, i64 %r32)
  store i64 %r33, i64* %ptr_out
  br label %L12
L11:
  br label %L12
L12:
  %r34 = load i64, i64* %ptr_out
  ret i64 %r34
  ret i64 0
}
define i64 @hex_to_dec(i64 %arg_h) {
  %ptr_h = alloca i64
  store i64 %arg_h, i64* %ptr_h
  %ptr_len = alloca i64
  %ptr_val = alloca i64
  %ptr_i = alloca i64
  %ptr_c = alloca i64
  %r1 = load i64, i64* %ptr_h
  %r2 = call i64 @mensura(i64 %r1)
  store i64 %r2, i64* %ptr_len
  store i64 0, i64* %ptr_val
  store i64 0, i64* %ptr_i
  br label %L13
L13:
  %r3 = load i64, i64* %ptr_i
  %r4 = load i64, i64* %ptr_len
  %r6 = icmp slt i64 %r3, %r4
  %r5 = zext i1 %r6 to i64
  %r7 = icmp ne i64 %r5, 0
  br i1 %r7, label %L14, label %L15
L14:
  %r8 = load i64, i64* %ptr_h
  %r9 = load i64, i64* %ptr_i
  %r10 = call i64 @pars(i64 %r8, i64 %r9, i64 1)
  %r11 = call i64 @codex(i64 %r10)
  store i64 %r11, i64* %ptr_c
  %r12 = load i64, i64* %ptr_val
  %r13 = mul i64 %r12, 16
  store i64 %r13, i64* %ptr_val
  %r14 = load i64, i64* %ptr_c
  %r16 = icmp sge i64 %r14, 48
  %r15 = zext i1 %r16 to i64
  %r17 = icmp ne i64 %r15, 0
  br i1 %r17, label %L16, label %L17
L16:
  %r18 = load i64, i64* %ptr_c
  %r20 = icmp sle i64 %r18, 57
  %r19 = zext i1 %r20 to i64
  %r21 = icmp ne i64 %r19, 0
  br i1 %r21, label %L19, label %L20
L19:
  %r22 = load i64, i64* %ptr_val
  %r23 = load i64, i64* %ptr_c
  %r24 = sub i64 %r23, 48
  %r25 = call i64 @_add(i64 %r22, i64 %r24)
  store i64 %r25, i64* %ptr_val
  br label %L21
L20:
  br label %L21
L21:
  br label %L18
L17:
  br label %L18
L18:
  %r26 = load i64, i64* %ptr_c
  %r28 = icmp sge i64 %r26, 65
  %r27 = zext i1 %r28 to i64
  %r29 = icmp ne i64 %r27, 0
  br i1 %r29, label %L22, label %L23
L22:
  %r30 = load i64, i64* %ptr_c
  %r32 = icmp sle i64 %r30, 70
  %r31 = zext i1 %r32 to i64
  %r33 = icmp ne i64 %r31, 0
  br i1 %r33, label %L25, label %L26
L25:
  %r34 = load i64, i64* %ptr_val
  %r35 = load i64, i64* %ptr_c
  %r36 = sub i64 %r35, 55
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  store i64 %r37, i64* %ptr_val
  br label %L27
L26:
  br label %L27
L27:
  br label %L24
L23:
  br label %L24
L24:
  %r38 = load i64, i64* %ptr_c
  %r40 = icmp sge i64 %r38, 97
  %r39 = zext i1 %r40 to i64
  %r41 = icmp ne i64 %r39, 0
  br i1 %r41, label %L28, label %L29
L28:
  %r42 = load i64, i64* %ptr_c
  %r44 = icmp sle i64 %r42, 102
  %r43 = zext i1 %r44 to i64
  %r45 = icmp ne i64 %r43, 0
  br i1 %r45, label %L31, label %L32
L31:
  %r46 = load i64, i64* %ptr_val
  %r47 = load i64, i64* %ptr_c
  %r48 = sub i64 %r47, 87
  %r49 = call i64 @_add(i64 %r46, i64 %r48)
  store i64 %r49, i64* %ptr_val
  br label %L33
L32:
  br label %L33
L33:
  br label %L30
L29:
  br label %L30
L30:
  %r50 = load i64, i64* %ptr_i
  %r51 = call i64 @_add(i64 %r50, i64 1)
  store i64 %r51, i64* %ptr_i
  br label %L13
L15:
  %r52 = load i64, i64* %ptr_val
  ret i64 %r52
  ret i64 0
}
define i64 @init_constants() {
  store i64 0, i64* @TOK_EOF
  store i64 1, i64* @TOK_INT
  store i64 2, i64* @TOK_FLOAT
  store i64 3, i64* @TOK_STRING
  store i64 4, i64* @TOK_IDENT
  store i64 5, i64* @TOK_LET
  store i64 6, i64* @TOK_PRINT
  store i64 7, i64* @TOK_IF
  store i64 8, i64* @TOK_ELSE
  store i64 9, i64* @TOK_WHILE
  store i64 10, i64* @TOK_OPUS
  store i64 11, i64* @TOK_REDDO
  store i64 12, i64* @TOK_BREAK
  store i64 13, i64* @TOK_CONTINUE
  store i64 20, i64* @TOK_IMPORT
  store i64 21, i64* @TOK_LPAREN
  store i64 22, i64* @TOK_RPAREN
  store i64 23, i64* @TOK_LBRACE
  store i64 24, i64* @TOK_RBRACE
  store i64 25, i64* @TOK_LBRACKET
  store i64 26, i64* @TOK_RBRACKET
  store i64 27, i64* @TOK_COLON
  store i64 28, i64* @TOK_ARROW
  store i64 29, i64* @TOK_CARET
  store i64 30, i64* @TOK_DOT
  store i64 31, i64* @TOK_APPEND
  store i64 32, i64* @TOK_EXTRACT
  store i64 33, i64* @TOK_AND
  store i64 34, i64* @TOK_OR
  store i64 35, i64* @TOK_CONST
  store i64 36, i64* @TOK_SHARED
  store i64 37, i64* @TOK_OP
  store i64 38, i64* @TOK_COMMA
  store i64 0, i64* @EXPR_INT
  store i64 1, i64* @EXPR_FLOAT
  store i64 2, i64* @EXPR_STRING
  store i64 3, i64* @EXPR_VAR
  store i64 4, i64* @EXPR_LIST
  store i64 5, i64* @EXPR_MAP
  store i64 6, i64* @EXPR_BINARY
  store i64 7, i64* @EXPR_INDEX
  store i64 8, i64* @EXPR_GET
  store i64 9, i64* @EXPR_CALL
  store i64 10, i64* @EXPR_INPUT
  store i64 11, i64* @EXPR_READ
  store i64 12, i64* @EXPR_MEASURE
  store i64 0, i64* @STMT_LET
  store i64 1, i64* @STMT_ASSIGN
  store i64 2, i64* @STMT_SET
  store i64 3, i64* @STMT_SET_INDEX
  store i64 4, i64* @STMT_APPEND
  store i64 5, i64* @STMT_EXTRACT
  store i64 6, i64* @STMT_PRINT
  store i64 7, i64* @STMT_IF
  store i64 8, i64* @STMT_WHILE
  store i64 9, i64* @STMT_FUNC
  store i64 10, i64* @STMT_RETURN
  store i64 11, i64* @STMT_IMPORT
  store i64 12, i64* @STMT_BREAK
  store i64 13, i64* @STMT_CONTINUE
  store i64 14, i64* @STMT_EXPR
  store i64 15, i64* @STMT_CONST
  store i64 16, i64* @STMT_SHARED
  store i64 0, i64* @VAL_INT
  store i64 1, i64* @VAL_FLOAT
  store i64 2, i64* @VAL_STRING
  store i64 3, i64* @VAL_LIST
  store i64 4, i64* @VAL_MAP
  store i64 5, i64* @VAL_FUNC
  store i64 6, i64* @VAL_VOID
  ret i64 0
}
define i64 @is_digit(i64 %arg_c) {
  %ptr_c = alloca i64
  store i64 %arg_c, i64* %ptr_c
  %ptr_code = alloca i64
  %r1 = load i64, i64* %ptr_c
  %r2 = call i64 @codex(i64 %r1)
  store i64 %r2, i64* %ptr_code
  %r3 = load i64, i64* %ptr_code
  %r5 = icmp sge i64 %r3, 48
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L34, label %L35
L34:
  %r7 = load i64, i64* %ptr_code
  %r9 = icmp sle i64 %r7, 57
  %r8 = zext i1 %r9 to i64
  %r10 = icmp ne i64 %r8, 0
  br i1 %r10, label %L37, label %L38
L37:
  ret i64 1
  br label %L39
L38:
  br label %L39
L39:
  br label %L36
L35:
  br label %L36
L36:
  ret i64 0
  ret i64 0
}
define i64 @is_alpha(i64 %arg_c) {
  %ptr_c = alloca i64
  store i64 %arg_c, i64* %ptr_c
  %ptr_code = alloca i64
  %r1 = load i64, i64* %ptr_c
  %r2 = call i64 @codex(i64 %r1)
  store i64 %r2, i64* %ptr_code
  %r3 = load i64, i64* %ptr_code
  %r5 = icmp sge i64 %r3, 65
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L40, label %L41
L40:
  %r7 = load i64, i64* %ptr_code
  %r9 = icmp sle i64 %r7, 90
  %r8 = zext i1 %r9 to i64
  %r10 = icmp ne i64 %r8, 0
  br i1 %r10, label %L43, label %L44
L43:
  ret i64 1
  br label %L45
L44:
  br label %L45
L45:
  br label %L42
L41:
  br label %L42
L42:
  %r11 = load i64, i64* %ptr_code
  %r13 = icmp sge i64 %r11, 97
  %r12 = zext i1 %r13 to i64
  %r14 = icmp ne i64 %r12, 0
  br i1 %r14, label %L46, label %L47
L46:
  %r15 = load i64, i64* %ptr_code
  %r17 = icmp sle i64 %r15, 122
  %r16 = zext i1 %r17 to i64
  %r18 = icmp ne i64 %r16, 0
  br i1 %r18, label %L49, label %L50
L49:
  ret i64 1
  br label %L51
L50:
  br label %L51
L51:
  br label %L48
L47:
  br label %L48
L48:
  %r19 = load i64, i64* %ptr_c
  %r20 = getelementptr [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_eq(i64 %r19, i64 %r21)
  %r23 = icmp ne i64 %r22, 0
  br i1 %r23, label %L52, label %L53
L52:
  ret i64 1
  br label %L54
L53:
  br label %L54
L54:
  ret i64 0
  ret i64 0
}
define i64 @is_alnum(i64 %arg_c) {
  %ptr_c = alloca i64
  store i64 %arg_c, i64* %ptr_c
  %ptr_code = alloca i64
  %ptr_res = alloca i64
  %r1 = load i64, i64* %ptr_c
  %r2 = call i64 @codex(i64 %r1)
  store i64 %r2, i64* %ptr_code
  store i64 0, i64* %ptr_res
  %r3 = load i64, i64* %ptr_c
  %r4 = call i64 @is_alpha(i64 %r3)
  %r5 = icmp ne i64 %r4, 0
  br i1 %r5, label %L55, label %L56
L55:
  store i64 1, i64* %ptr_res
  br label %L57
L56:
  br label %L57
L57:
  %r6 = load i64, i64* %ptr_res
  %r7 = call i64 @_eq(i64 %r6, i64 0)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L58, label %L59
L58:
  %r9 = load i64, i64* %ptr_c
  %r10 = call i64 @is_digit(i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L61, label %L62
L61:
  store i64 1, i64* %ptr_res
  br label %L63
L62:
  br label %L63
L63:
  br label %L60
L59:
  br label %L60
L60:
  %r12 = load i64, i64* %ptr_res
  ret i64 %r12
  ret i64 0
}
define i64 @is_space(i64 %arg_c) {
  %ptr_c = alloca i64
  store i64 %arg_c, i64* %ptr_c
  %ptr_code = alloca i64
  %r1 = load i64, i64* %ptr_c
  %r2 = call i64 @codex(i64 %r1)
  store i64 %r2, i64* %ptr_code
  %r3 = load i64, i64* %ptr_code
  %r4 = call i64 @_eq(i64 %r3, i64 32)
  %r5 = icmp ne i64 %r4, 0
  br i1 %r5, label %L64, label %L65
L64:
  ret i64 1
  br label %L66
L65:
  br label %L66
L66:
  %r6 = load i64, i64* %ptr_code
  %r7 = call i64 @_eq(i64 %r6, i64 9)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L67, label %L68
L67:
  ret i64 1
  br label %L69
L68:
  br label %L69
L69:
  %r9 = load i64, i64* %ptr_code
  %r10 = call i64 @_eq(i64 %r9, i64 10)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L70, label %L71
L70:
  ret i64 1
  br label %L72
L71:
  br label %L72
L72:
  %r12 = load i64, i64* %ptr_code
  %r13 = call i64 @_eq(i64 %r12, i64 13)
  %r14 = icmp ne i64 %r13, 0
  br i1 %r14, label %L73, label %L74
L73:
  ret i64 1
  br label %L75
L74:
  br label %L75
L75:
  ret i64 0
  ret i64 0
}
define i64 @make_token(i64 %arg_type, i64 %arg_text) {
  %ptr_type = alloca i64
  store i64 %arg_type, i64* %ptr_type
  %ptr_text = alloca i64
  store i64 %arg_text, i64* %ptr_text
  %r1 = call i64 @_map_new()
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = load i64, i64* %ptr_type
  call i64 @_map_set(i64 %r1, i64 %r3, i64 %r4)
  %r5 = getelementptr [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %r6 = ptrtoint i8* %r5 to i64
  %r7 = load i64, i64* %ptr_text
  call i64 @_map_set(i64 %r1, i64 %r6, i64 %r7)
  ret i64 %r1
  ret i64 0
}
define i64 @get_str_label(i64 %arg_txt) {
  %ptr_txt = alloca i64
  store i64 %arg_txt, i64* %ptr_txt
  %ptr_i = alloca i64
  %ptr_entry = alloca i64
  %ptr_lbl = alloca i64
  %ptr_new_entry = alloca i64
  store i64 0, i64* %ptr_i
  br label %L76
L76:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* @str_table
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L77, label %L78
L77:
  %r7 = load i64, i64* @str_table
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  store i64 %r9, i64* %ptr_entry
  %r10 = load i64, i64* %ptr_entry
  %r11 = getelementptr [4 x i8], [4 x i8]* @.str.7, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = call i64 @_get(i64 %r10, i64 %r12)
  %r14 = load i64, i64* %ptr_txt
  %r15 = call i64 @_eq(i64 %r13, i64 %r14)
  %r16 = icmp ne i64 %r15, 0
  br i1 %r16, label %L79, label %L80
L79:
  %r17 = load i64, i64* %ptr_entry
  %r18 = getelementptr [4 x i8], [4 x i8]* @.str.8, i64 0, i64 0
  %r19 = ptrtoint i8* %r18 to i64
  %r20 = call i64 @_get(i64 %r17, i64 %r19)
  ret i64 %r20
  br label %L81
L80:
  br label %L81
L81:
  %r21 = load i64, i64* %ptr_i
  %r22 = call i64 @_add(i64 %r21, i64 1)
  store i64 %r22, i64* %ptr_i
  br label %L76
L78:
  %r23 = getelementptr [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %r24 = ptrtoint i8* %r23 to i64
  %r25 = load i64, i64* @str_table
  %r26 = call i64 @mensura(i64 %r25)
  %r27 = call i64 @int_to_str(i64 %r26)
  %r28 = call i64 @_add(i64 %r24, i64 %r27)
  store i64 %r28, i64* %ptr_lbl
  %r29 = call i64 @_map_new()
  %r30 = getelementptr [4 x i8], [4 x i8]* @.str.10, i64 0, i64 0
  %r31 = ptrtoint i8* %r30 to i64
  %r32 = load i64, i64* %ptr_txt
  call i64 @_map_set(i64 %r29, i64 %r31, i64 %r32)
  %r33 = getelementptr [4 x i8], [4 x i8]* @.str.11, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = load i64, i64* %ptr_lbl
  call i64 @_map_set(i64 %r29, i64 %r34, i64 %r35)
  store i64 %r29, i64* %ptr_new_entry
  %r36 = load i64, i64* %ptr_new_entry
  %r37 = load i64, i64* @str_table
  call i64 @_append_poly(i64 %r37, i64 %r36)
  %r38 = load i64, i64* %ptr_lbl
  ret i64 %r38
  ret i64 0
}
define i64 @error_report(i64 %arg_msg) {
  %ptr_msg = alloca i64
  store i64 %arg_msg, i64* %ptr_msg
  %r1 = getelementptr [20 x i8], [20 x i8]* @.str.12, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  %r3 = load i64, i64* %ptr_msg
  %r4 = call i64 @_add(i64 %r2, i64 %r3)
  call i64 @print_any(i64 %r4)
  store i64 1, i64* @has_error
  ret i64 0
}
define i64 @nasm_bytes(i64 %arg_s) {
  %ptr_s = alloca i64
  store i64 %arg_s, i64* %ptr_s
  %ptr_out = alloca i64
  %ptr_len = alloca i64
  %ptr_i = alloca i64
  %ptr_c = alloca i64
  %ptr_code = alloca i64
  %r1 = getelementptr [1 x i8], [1 x i8]* @.str.13, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  store i64 %r2, i64* %ptr_out
  %r3 = load i64, i64* %ptr_s
  %r4 = call i64 @mensura(i64 %r3)
  store i64 %r4, i64* %ptr_len
  store i64 0, i64* %ptr_i
  br label %L82
L82:
  %r5 = load i64, i64* %ptr_i
  %r6 = load i64, i64* %ptr_len
  %r8 = icmp slt i64 %r5, %r6
  %r7 = zext i1 %r8 to i64
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L83, label %L84
L83:
  %r10 = load i64, i64* %ptr_s
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @pars(i64 %r10, i64 %r11, i64 1)
  store i64 %r12, i64* %ptr_c
  %r13 = load i64, i64* %ptr_c
  %r14 = call i64 @codex(i64 %r13)
  store i64 %r14, i64* %ptr_code
  %r15 = load i64, i64* %ptr_out
  %r16 = load i64, i64* %ptr_code
  %r17 = call i64 @int_to_str(i64 %r16)
  %r18 = call i64 @_add(i64 %r15, i64 %r17)
  %r19 = getelementptr [3 x i8], [3 x i8]* @.str.14, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  store i64 %r21, i64* %ptr_out
  %r22 = load i64, i64* %ptr_i
  %r23 = call i64 @_add(i64 %r22, i64 1)
  store i64 %r23, i64* %ptr_i
  br label %L82
L84:
  %r24 = load i64, i64* %ptr_out
  %r25 = getelementptr [2 x i8], [2 x i8]* @.str.15, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = call i64 @_add(i64 %r24, i64 %r26)
  ret i64 %r27
  ret i64 0
}
define i64 @is_local(i64 %arg_nm) {
  %ptr_nm = alloca i64
  store i64 %arg_nm, i64* %ptr_nm
  %ptr_i = alloca i64
  %ptr_v = alloca i64
  store i64 0, i64* %ptr_i
  br label %L85
L85:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* @local_vars
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L86, label %L87
L86:
  %r7 = load i64, i64* @local_vars
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  store i64 %r9, i64* %ptr_v
  %r10 = load i64, i64* %ptr_v
  %r11 = load i64, i64* %ptr_nm
  %r12 = call i64 @_eq(i64 %r10, i64 %r11)
  %r13 = icmp ne i64 %r12, 0
  br i1 %r13, label %L88, label %L89
L88:
  ret i64 1
  br label %L90
L89:
  br label %L90
L90:
  %r14 = load i64, i64* %ptr_i
  %r15 = call i64 @_add(i64 %r14, i64 1)
  store i64 %r15, i64* %ptr_i
  br label %L85
L87:
  ret i64 0
  ret i64 0
}
define i64 @capere_argumentum(i64 %arg_n) {
  %ptr_n = alloca i64
  store i64 %arg_n, i64* %ptr_n
  %r1 = getelementptr [9 x i8], [9 x i8]* @.str.16, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  ret i64 %r2
  ret i64 0
}
define i64 @lex_source(i64 %arg_src) {
  %ptr_src = alloca i64
  store i64 %arg_src, i64* %ptr_src
  %ptr_tokens = alloca i64
  %ptr_len = alloca i64
  %ptr_i = alloca i64
  %ptr_c = alloca i64
  %ptr_next = alloca i64
  %ptr_start = alloca i64
  %ptr_txt = alloca i64
  %ptr_type = alloca i64
  %ptr_loop_c = alloca i64
  %ptr_adv = alloca i64
  %ptr_run_cmt = alloca i64
  %ptr_run_blk = alloca i64
  %ptr_run_str = alloca i64
  %ptr_run_num = alloca i64
  %ptr_run_id = alloca i64
  %ptr_esc = alloca i64
  %ptr_lcode = alloca i64
  %ptr_ok = alloca i64
  %ptr_is_hex = alloca i64
  %ptr_next_char = alloca i64
  %ptr_run_hex = alloca i64
  %ptr_hex_str = alloca i64
  %ptr_keep = alloca i64
  %ptr_next2 = alloca i64
  store i64 1, i64* @use_huge_lists
  %r1 = call i64 @_list_new()
  store i64 %r1, i64* %ptr_tokens
  store i64 0, i64* @use_huge_lists
  %r2 = load i64, i64* %ptr_src
  %r3 = call i64 @mensura(i64 %r2)
  store i64 %r3, i64* %ptr_len
  %r4 = getelementptr [24 x i8], [24 x i8]* @.str.17, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  %r6 = load i64, i64* %ptr_len
  %r7 = call i64 @int_to_str(i64 %r6)
  %r8 = call i64 @_add(i64 %r5, i64 %r7)
  call i64 @print_any(i64 %r8)
  store i64 0, i64* %ptr_i
  %r9 = getelementptr [1 x i8], [1 x i8]* @.str.18, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  store i64 %r10, i64* %ptr_c
  %r11 = getelementptr [1 x i8], [1 x i8]* @.str.19, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  store i64 %r12, i64* %ptr_next
  store i64 0, i64* %ptr_start
  %r13 = getelementptr [1 x i8], [1 x i8]* @.str.20, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  store i64 %r14, i64* %ptr_txt
  store i64 0, i64* %ptr_type
  %r15 = getelementptr [1 x i8], [1 x i8]* @.str.21, i64 0, i64 0
  %r16 = ptrtoint i8* %r15 to i64
  store i64 %r16, i64* %ptr_loop_c
  store i64 0, i64* %ptr_adv
  store i64 0, i64* %ptr_run_cmt
  store i64 0, i64* %ptr_run_blk
  store i64 0, i64* %ptr_run_str
  store i64 0, i64* %ptr_run_num
  store i64 0, i64* %ptr_run_id
  %r17 = getelementptr [1 x i8], [1 x i8]* @.str.22, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  store i64 %r18, i64* %ptr_esc
  store i64 0, i64* %ptr_lcode
  store i64 0, i64* %ptr_ok
  br label %L91
L91:
  %r19 = load i64, i64* %ptr_i
  %r20 = load i64, i64* %ptr_len
  %r22 = icmp slt i64 %r19, %r20
  %r21 = zext i1 %r22 to i64
  %r23 = icmp ne i64 %r21, 0
  br i1 %r23, label %L92, label %L93
L92:
  %r24 = load i64, i64* %ptr_src
  %r25 = load i64, i64* %ptr_i
  %r26 = call i64 @pars(i64 %r24, i64 %r25, i64 1)
  store i64 %r26, i64* %ptr_c
  %r27 = load i64, i64* %ptr_c
  %r28 = call i64 @is_space(i64 %r27)
  %r29 = icmp ne i64 %r28, 0
  br i1 %r29, label %L94, label %L95
L94:
  %r30 = load i64, i64* %ptr_i
  %r31 = call i64 @_add(i64 %r30, i64 1)
  store i64 %r31, i64* %ptr_i
  br label %L96
L95:
  %r32 = load i64, i64* %ptr_c
  %r33 = getelementptr [2 x i8], [2 x i8]* @.str.23, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_eq(i64 %r32, i64 %r34)
  %r36 = icmp ne i64 %r35, 0
  br i1 %r36, label %L97, label %L98
L97:
  %r37 = load i64, i64* %ptr_src
  %r38 = load i64, i64* %ptr_i
  %r39 = call i64 @_add(i64 %r38, i64 1)
  %r40 = call i64 @pars(i64 %r37, i64 %r39, i64 1)
  store i64 %r40, i64* %ptr_next
  %r41 = load i64, i64* %ptr_next
  %r42 = getelementptr [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_eq(i64 %r41, i64 %r43)
  %r45 = icmp ne i64 %r44, 0
  br i1 %r45, label %L100, label %L101
L100:
  store i64 1, i64* %ptr_run_cmt
  br label %L103
L103:
  %r46 = load i64, i64* %ptr_run_cmt
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L104, label %L105
L104:
  %r48 = load i64, i64* %ptr_i
  %r49 = load i64, i64* %ptr_len
  %r51 = icmp sge i64 %r48, %r49
  %r50 = zext i1 %r51 to i64
  %r52 = icmp ne i64 %r50, 0
  br i1 %r52, label %L106, label %L107
L106:
  store i64 0, i64* %ptr_run_cmt
  br label %L108
L107:
  br label %L108
L108:
  %r53 = load i64, i64* %ptr_run_cmt
  %r54 = icmp ne i64 %r53, 0
  br i1 %r54, label %L109, label %L110
L109:
  %r55 = load i64, i64* %ptr_src
  %r56 = load i64, i64* %ptr_i
  %r57 = call i64 @pars(i64 %r55, i64 %r56, i64 1)
  store i64 %r57, i64* %ptr_loop_c
  %r58 = load i64, i64* %ptr_loop_c
  %r59 = call i64 @codex(i64 %r58)
  %r60 = call i64 @_eq(i64 %r59, i64 10)
  %r61 = icmp ne i64 %r60, 0
  br i1 %r61, label %L112, label %L113
L112:
  store i64 0, i64* %ptr_run_cmt
  br label %L114
L113:
  br label %L114
L114:
  %r62 = load i64, i64* %ptr_run_cmt
  %r63 = icmp ne i64 %r62, 0
  br i1 %r63, label %L115, label %L116
L115:
  %r64 = load i64, i64* %ptr_i
  %r65 = call i64 @_add(i64 %r64, i64 1)
  store i64 %r65, i64* %ptr_i
  br label %L117
L116:
  br label %L117
L117:
  br label %L111
L110:
  br label %L111
L111:
  br label %L103
L105:
  br label %L102
L101:
  %r66 = load i64, i64* %ptr_next
  %r67 = getelementptr [2 x i8], [2 x i8]* @.str.25, i64 0, i64 0
  %r68 = ptrtoint i8* %r67 to i64
  %r69 = call i64 @_eq(i64 %r66, i64 %r68)
  %r70 = icmp ne i64 %r69, 0
  br i1 %r70, label %L118, label %L119
L118:
  %r71 = load i64, i64* %ptr_i
  %r72 = call i64 @_add(i64 %r71, i64 2)
  store i64 %r72, i64* %ptr_i
  store i64 1, i64* %ptr_run_blk
  br label %L121
L121:
  %r73 = load i64, i64* %ptr_run_blk
  %r74 = icmp ne i64 %r73, 0
  br i1 %r74, label %L122, label %L123
L122:
  %r75 = load i64, i64* %ptr_i
  %r76 = load i64, i64* %ptr_len
  %r78 = icmp sge i64 %r75, %r76
  %r77 = zext i1 %r78 to i64
  %r79 = icmp ne i64 %r77, 0
  br i1 %r79, label %L124, label %L125
L124:
  store i64 0, i64* %ptr_run_blk
  br label %L126
L125:
  br label %L126
L126:
  %r80 = load i64, i64* %ptr_run_blk
  %r81 = icmp ne i64 %r80, 0
  br i1 %r81, label %L127, label %L128
L127:
  %r82 = load i64, i64* %ptr_src
  %r83 = load i64, i64* %ptr_i
  %r84 = call i64 @pars(i64 %r82, i64 %r83, i64 1)
  %r85 = getelementptr [2 x i8], [2 x i8]* @.str.26, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = call i64 @_eq(i64 %r84, i64 %r86)
  %r88 = load i64, i64* %ptr_src
  %r89 = load i64, i64* %ptr_i
  %r90 = call i64 @_add(i64 %r89, i64 1)
  %r91 = call i64 @pars(i64 %r88, i64 %r90, i64 1)
  %r92 = getelementptr [2 x i8], [2 x i8]* @.str.27, i64 0, i64 0
  %r93 = ptrtoint i8* %r92 to i64
  %r94 = call i64 @_eq(i64 %r91, i64 %r93)
  %r95 = and i64 %r87, %r94
  %r96 = icmp ne i64 %r95, 0
  br i1 %r96, label %L130, label %L131
L130:
  %r97 = load i64, i64* %ptr_i
  %r98 = call i64 @_add(i64 %r97, i64 2)
  store i64 %r98, i64* %ptr_i
  store i64 0, i64* %ptr_run_blk
  br label %L132
L131:
  br label %L132
L132:
  %r99 = load i64, i64* %ptr_run_blk
  %r100 = icmp ne i64 %r99, 0
  br i1 %r100, label %L133, label %L134
L133:
  %r101 = load i64, i64* %ptr_i
  %r102 = call i64 @_add(i64 %r101, i64 1)
  store i64 %r102, i64* %ptr_i
  br label %L135
L134:
  br label %L135
L135:
  br label %L129
L128:
  br label %L129
L129:
  br label %L121
L123:
  br label %L120
L119:
  %r103 = load i64, i64* @TOK_OP
  %r104 = getelementptr [2 x i8], [2 x i8]* @.str.28, i64 0, i64 0
  %r105 = ptrtoint i8* %r104 to i64
  %r106 = call i64 @make_token(i64 %r103, i64 %r105)
  %r107 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r107, i64 %r106)
  %r108 = load i64, i64* %ptr_i
  %r109 = call i64 @_add(i64 %r108, i64 1)
  store i64 %r109, i64* %ptr_i
  br label %L120
L120:
  br label %L102
L102:
  br label %L99
L98:
  %r110 = load i64, i64* %ptr_c
  %r111 = getelementptr [2 x i8], [2 x i8]* @.str.29, i64 0, i64 0
  %r112 = ptrtoint i8* %r111 to i64
  %r113 = call i64 @_eq(i64 %r110, i64 %r112)
  %r114 = icmp ne i64 %r113, 0
  br i1 %r114, label %L136, label %L137
L136:
  %r115 = load i64, i64* %ptr_i
  %r116 = call i64 @_add(i64 %r115, i64 1)
  store i64 %r116, i64* %ptr_i
  %r117 = getelementptr [1 x i8], [1 x i8]* @.str.30, i64 0, i64 0
  %r118 = ptrtoint i8* %r117 to i64
  store i64 %r118, i64* %ptr_txt
  store i64 1, i64* %ptr_run_str
  br label %L139
L139:
  %r119 = load i64, i64* %ptr_run_str
  %r120 = icmp ne i64 %r119, 0
  br i1 %r120, label %L140, label %L141
L140:
  %r121 = load i64, i64* %ptr_i
  %r122 = load i64, i64* %ptr_len
  %r124 = icmp sge i64 %r121, %r122
  %r123 = zext i1 %r124 to i64
  %r125 = icmp ne i64 %r123, 0
  br i1 %r125, label %L142, label %L143
L142:
  store i64 0, i64* %ptr_run_str
  br label %L144
L143:
  br label %L144
L144:
  %r126 = load i64, i64* %ptr_run_str
  %r127 = icmp ne i64 %r126, 0
  br i1 %r127, label %L145, label %L146
L145:
  %r128 = load i64, i64* %ptr_src
  %r129 = load i64, i64* %ptr_i
  %r130 = call i64 @pars(i64 %r128, i64 %r129, i64 1)
  store i64 %r130, i64* %ptr_loop_c
  %r131 = load i64, i64* %ptr_loop_c
  %r132 = getelementptr [2 x i8], [2 x i8]* @.str.31, i64 0, i64 0
  %r133 = ptrtoint i8* %r132 to i64
  %r134 = call i64 @_eq(i64 %r131, i64 %r133)
  %r135 = icmp ne i64 %r134, 0
  br i1 %r135, label %L148, label %L149
L148:
  store i64 0, i64* %ptr_run_str
  br label %L150
L149:
  br label %L150
L150:
  %r136 = load i64, i64* %ptr_run_str
  %r137 = icmp ne i64 %r136, 0
  br i1 %r137, label %L151, label %L152
L151:
  %r138 = load i64, i64* %ptr_loop_c
  %r139 = getelementptr [2 x i8], [2 x i8]* @.str.32, i64 0, i64 0
  %r140 = ptrtoint i8* %r139 to i64
  %r141 = call i64 @_eq(i64 %r138, i64 %r140)
  %r142 = icmp ne i64 %r141, 0
  br i1 %r142, label %L154, label %L155
L154:
  %r143 = load i64, i64* %ptr_i
  %r144 = call i64 @_add(i64 %r143, i64 1)
  store i64 %r144, i64* %ptr_i
  %r145 = load i64, i64* %ptr_src
  %r146 = load i64, i64* %ptr_i
  %r147 = call i64 @pars(i64 %r145, i64 %r146, i64 1)
  store i64 %r147, i64* %ptr_esc
  %r148 = load i64, i64* %ptr_esc
  %r149 = getelementptr [2 x i8], [2 x i8]* @.str.33, i64 0, i64 0
  %r150 = ptrtoint i8* %r149 to i64
  %r151 = call i64 @_eq(i64 %r148, i64 %r150)
  %r152 = icmp ne i64 %r151, 0
  br i1 %r152, label %L157, label %L158
L157:
  %r153 = load i64, i64* %ptr_txt
  %r154 = call i64 @signum_ex(i64 10)
  %r155 = call i64 @_add(i64 %r153, i64 %r154)
  store i64 %r155, i64* %ptr_txt
  br label %L159
L158:
  %r156 = load i64, i64* %ptr_esc
  %r157 = getelementptr [2 x i8], [2 x i8]* @.str.34, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = call i64 @_eq(i64 %r156, i64 %r158)
  %r160 = icmp ne i64 %r159, 0
  br i1 %r160, label %L160, label %L161
L160:
  %r161 = load i64, i64* %ptr_txt
  %r162 = call i64 @signum_ex(i64 9)
  %r163 = call i64 @_add(i64 %r161, i64 %r162)
  store i64 %r163, i64* %ptr_txt
  br label %L162
L161:
  %r164 = load i64, i64* %ptr_esc
  %r165 = getelementptr [2 x i8], [2 x i8]* @.str.35, i64 0, i64 0
  %r166 = ptrtoint i8* %r165 to i64
  %r167 = call i64 @_eq(i64 %r164, i64 %r166)
  %r168 = icmp ne i64 %r167, 0
  br i1 %r168, label %L163, label %L164
L163:
  %r169 = load i64, i64* %ptr_txt
  %r170 = getelementptr [2 x i8], [2 x i8]* @.str.36, i64 0, i64 0
  %r171 = ptrtoint i8* %r170 to i64
  %r172 = call i64 @_add(i64 %r169, i64 %r171)
  store i64 %r172, i64* %ptr_txt
  br label %L165
L164:
  %r173 = load i64, i64* %ptr_esc
  %r174 = getelementptr [2 x i8], [2 x i8]* @.str.37, i64 0, i64 0
  %r175 = ptrtoint i8* %r174 to i64
  %r176 = call i64 @_eq(i64 %r173, i64 %r175)
  %r177 = icmp ne i64 %r176, 0
  br i1 %r177, label %L166, label %L167
L166:
  %r178 = load i64, i64* %ptr_txt
  %r179 = getelementptr [2 x i8], [2 x i8]* @.str.38, i64 0, i64 0
  %r180 = ptrtoint i8* %r179 to i64
  %r181 = call i64 @_add(i64 %r178, i64 %r180)
  store i64 %r181, i64* %ptr_txt
  br label %L168
L167:
  %r182 = load i64, i64* %ptr_txt
  %r183 = load i64, i64* %ptr_esc
  %r184 = call i64 @_add(i64 %r182, i64 %r183)
  store i64 %r184, i64* %ptr_txt
  br label %L168
L168:
  br label %L165
L165:
  br label %L162
L162:
  br label %L159
L159:
  br label %L156
L155:
  %r185 = load i64, i64* %ptr_txt
  %r186 = load i64, i64* %ptr_loop_c
  %r187 = call i64 @_add(i64 %r185, i64 %r186)
  store i64 %r187, i64* %ptr_txt
  br label %L156
L156:
  %r188 = load i64, i64* %ptr_i
  %r189 = call i64 @_add(i64 %r188, i64 1)
  store i64 %r189, i64* %ptr_i
  br label %L153
L152:
  br label %L153
L153:
  br label %L147
L146:
  br label %L147
L147:
  br label %L139
L141:
  %r190 = load i64, i64* @TOK_STRING
  %r191 = load i64, i64* %ptr_txt
  %r192 = call i64 @make_token(i64 %r190, i64 %r191)
  %r193 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r193, i64 %r192)
  %r194 = load i64, i64* %ptr_i
  %r195 = call i64 @_add(i64 %r194, i64 1)
  store i64 %r195, i64* %ptr_i
  br label %L138
L137:
  %r196 = load i64, i64* %ptr_c
  %r197 = call i64 @is_digit(i64 %r196)
  %r198 = icmp ne i64 %r197, 0
  br i1 %r198, label %L169, label %L170
L169:
  %r199 = load i64, i64* %ptr_i
  store i64 %r199, i64* %ptr_start
  store i64 0, i64* %ptr_is_hex
  %r200 = load i64, i64* %ptr_c
  %r201 = getelementptr [2 x i8], [2 x i8]* @.str.39, i64 0, i64 0
  %r202 = ptrtoint i8* %r201 to i64
  %r203 = call i64 @_eq(i64 %r200, i64 %r202)
  %r204 = icmp ne i64 %r203, 0
  br i1 %r204, label %L172, label %L173
L172:
  %r205 = load i64, i64* %ptr_src
  %r206 = load i64, i64* %ptr_i
  %r207 = call i64 @_add(i64 %r206, i64 1)
  %r208 = call i64 @pars(i64 %r205, i64 %r207, i64 1)
  store i64 %r208, i64* %ptr_next_char
  %r209 = load i64, i64* %ptr_next_char
  %r210 = getelementptr [2 x i8], [2 x i8]* @.str.40, i64 0, i64 0
  %r211 = ptrtoint i8* %r210 to i64
  %r212 = call i64 @_eq(i64 %r209, i64 %r211)
  %r213 = icmp ne i64 %r212, 0
  br i1 %r213, label %L175, label %L176
L175:
  store i64 1, i64* %ptr_is_hex
  br label %L177
L176:
  br label %L177
L177:
  %r214 = load i64, i64* %ptr_next_char
  %r215 = getelementptr [2 x i8], [2 x i8]* @.str.41, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = call i64 @_eq(i64 %r214, i64 %r216)
  %r218 = icmp ne i64 %r217, 0
  br i1 %r218, label %L178, label %L179
L178:
  store i64 1, i64* %ptr_is_hex
  br label %L180
L179:
  br label %L180
L180:
  br label %L174
L173:
  br label %L174
L174:
  %r219 = load i64, i64* %ptr_is_hex
  %r220 = icmp ne i64 %r219, 0
  br i1 %r220, label %L181, label %L182
L181:
  %r221 = load i64, i64* %ptr_i
  %r222 = call i64 @_add(i64 %r221, i64 2)
  store i64 %r222, i64* %ptr_i
  %r223 = load i64, i64* %ptr_i
  store i64 %r223, i64* %ptr_start
  store i64 1, i64* %ptr_run_hex
  br label %L184
L184:
  %r224 = load i64, i64* %ptr_run_hex
  %r225 = icmp ne i64 %r224, 0
  br i1 %r225, label %L185, label %L186
L185:
  %r226 = load i64, i64* %ptr_i
  %r227 = load i64, i64* %ptr_len
  %r229 = icmp sge i64 %r226, %r227
  %r228 = zext i1 %r229 to i64
  %r230 = icmp ne i64 %r228, 0
  br i1 %r230, label %L187, label %L188
L187:
  store i64 0, i64* %ptr_run_hex
  br label %L189
L188:
  br label %L189
L189:
  %r231 = load i64, i64* %ptr_run_hex
  %r232 = icmp ne i64 %r231, 0
  br i1 %r232, label %L190, label %L191
L190:
  %r233 = load i64, i64* %ptr_src
  %r234 = load i64, i64* %ptr_i
  %r235 = call i64 @pars(i64 %r233, i64 %r234, i64 1)
  store i64 %r235, i64* %ptr_loop_c
  %r236 = load i64, i64* %ptr_loop_c
  %r237 = call i64 @is_alnum(i64 %r236)
  %r238 = call i64 @_eq(i64 %r237, i64 0)
  %r239 = icmp ne i64 %r238, 0
  br i1 %r239, label %L193, label %L194
L193:
  store i64 0, i64* %ptr_run_hex
  br label %L195
L194:
  br label %L195
L195:
  %r240 = load i64, i64* %ptr_run_hex
  %r241 = icmp ne i64 %r240, 0
  br i1 %r241, label %L196, label %L197
L196:
  %r242 = load i64, i64* %ptr_i
  %r243 = call i64 @_add(i64 %r242, i64 1)
  store i64 %r243, i64* %ptr_i
  br label %L198
L197:
  br label %L198
L198:
  br label %L192
L191:
  br label %L192
L192:
  br label %L184
L186:
  %r244 = load i64, i64* %ptr_src
  %r245 = load i64, i64* %ptr_start
  %r246 = load i64, i64* %ptr_i
  %r247 = load i64, i64* %ptr_start
  %r248 = sub i64 %r246, %r247
  %r249 = call i64 @pars(i64 %r244, i64 %r245, i64 %r248)
  store i64 %r249, i64* %ptr_hex_str
  %r250 = load i64, i64* @TOK_INT
  %r251 = load i64, i64* %ptr_hex_str
  %r252 = call i64 @hex_to_dec(i64 %r251)
  %r253 = call i64 @int_to_str(i64 %r252)
  %r254 = call i64 @make_token(i64 %r250, i64 %r253)
  %r255 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r255, i64 %r254)
  br label %L183
L182:
  store i64 1, i64* %ptr_run_num
  br label %L199
L199:
  %r256 = load i64, i64* %ptr_run_num
  %r257 = icmp ne i64 %r256, 0
  br i1 %r257, label %L200, label %L201
L200:
  %r258 = load i64, i64* %ptr_i
  %r259 = load i64, i64* %ptr_len
  %r261 = icmp sge i64 %r258, %r259
  %r260 = zext i1 %r261 to i64
  %r262 = icmp ne i64 %r260, 0
  br i1 %r262, label %L202, label %L203
L202:
  store i64 0, i64* %ptr_run_num
  br label %L204
L203:
  br label %L204
L204:
  %r263 = load i64, i64* %ptr_run_num
  %r264 = icmp ne i64 %r263, 0
  br i1 %r264, label %L205, label %L206
L205:
  %r265 = load i64, i64* %ptr_src
  %r266 = load i64, i64* %ptr_i
  %r267 = call i64 @pars(i64 %r265, i64 %r266, i64 1)
  store i64 %r267, i64* %ptr_loop_c
  store i64 0, i64* %ptr_keep
  %r268 = load i64, i64* %ptr_loop_c
  %r269 = call i64 @is_digit(i64 %r268)
  %r270 = icmp ne i64 %r269, 0
  br i1 %r270, label %L208, label %L209
L208:
  store i64 1, i64* %ptr_keep
  br label %L210
L209:
  br label %L210
L210:
  %r271 = load i64, i64* %ptr_loop_c
  %r272 = getelementptr [2 x i8], [2 x i8]* @.str.42, i64 0, i64 0
  %r273 = ptrtoint i8* %r272 to i64
  %r274 = call i64 @_eq(i64 %r271, i64 %r273)
  %r275 = icmp ne i64 %r274, 0
  br i1 %r275, label %L211, label %L212
L211:
  store i64 1, i64* %ptr_keep
  br label %L213
L212:
  br label %L213
L213:
  %r276 = load i64, i64* %ptr_keep
  %r277 = call i64 @_eq(i64 %r276, i64 0)
  %r278 = icmp ne i64 %r277, 0
  br i1 %r278, label %L214, label %L215
L214:
  store i64 0, i64* %ptr_run_num
  br label %L216
L215:
  br label %L216
L216:
  %r279 = load i64, i64* %ptr_run_num
  %r280 = icmp ne i64 %r279, 0
  br i1 %r280, label %L217, label %L218
L217:
  %r281 = load i64, i64* %ptr_i
  %r282 = call i64 @_add(i64 %r281, i64 1)
  store i64 %r282, i64* %ptr_i
  br label %L219
L218:
  br label %L219
L219:
  br label %L207
L206:
  br label %L207
L207:
  br label %L199
L201:
  %r283 = load i64, i64* %ptr_src
  %r284 = load i64, i64* %ptr_start
  %r285 = load i64, i64* %ptr_i
  %r286 = load i64, i64* %ptr_start
  %r287 = sub i64 %r285, %r286
  %r288 = call i64 @pars(i64 %r283, i64 %r284, i64 %r287)
  store i64 %r288, i64* %ptr_txt
  %r289 = load i64, i64* @TOK_INT
  %r290 = load i64, i64* %ptr_txt
  %r291 = call i64 @make_token(i64 %r289, i64 %r290)
  %r292 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r292, i64 %r291)
  br label %L183
L183:
  br label %L171
L170:
  %r293 = load i64, i64* %ptr_c
  %r294 = call i64 @is_alpha(i64 %r293)
  %r295 = icmp ne i64 %r294, 0
  br i1 %r295, label %L220, label %L221
L220:
  %r296 = load i64, i64* %ptr_i
  store i64 %r296, i64* %ptr_start
  store i64 1, i64* %ptr_run_id
  br label %L223
L223:
  %r297 = load i64, i64* %ptr_run_id
  %r298 = icmp ne i64 %r297, 0
  br i1 %r298, label %L224, label %L225
L224:
  %r299 = load i64, i64* %ptr_i
  %r300 = load i64, i64* %ptr_len
  %r302 = icmp sge i64 %r299, %r300
  %r301 = zext i1 %r302 to i64
  %r303 = icmp ne i64 %r301, 0
  br i1 %r303, label %L226, label %L227
L226:
  store i64 0, i64* %ptr_run_id
  br label %L228
L227:
  br label %L228
L228:
  %r304 = load i64, i64* %ptr_run_id
  %r305 = icmp ne i64 %r304, 0
  br i1 %r305, label %L229, label %L230
L229:
  %r306 = load i64, i64* %ptr_src
  %r307 = load i64, i64* %ptr_i
  %r308 = call i64 @pars(i64 %r306, i64 %r307, i64 1)
  store i64 %r308, i64* %ptr_loop_c
  %r309 = load i64, i64* %ptr_loop_c
  %r310 = call i64 @codex(i64 %r309)
  store i64 %r310, i64* %ptr_lcode
  store i64 0, i64* %ptr_ok
  %r311 = load i64, i64* %ptr_lcode
  %r313 = icmp sge i64 %r311, 48
  %r312 = zext i1 %r313 to i64
  %r314 = icmp ne i64 %r312, 0
  br i1 %r314, label %L232, label %L233
L232:
  %r315 = load i64, i64* %ptr_lcode
  %r317 = icmp sle i64 %r315, 57
  %r316 = zext i1 %r317 to i64
  %r318 = icmp ne i64 %r316, 0
  br i1 %r318, label %L235, label %L236
L235:
  store i64 1, i64* %ptr_ok
  br label %L237
L236:
  br label %L237
L237:
  br label %L234
L233:
  br label %L234
L234:
  %r319 = load i64, i64* %ptr_lcode
  %r321 = icmp sge i64 %r319, 65
  %r320 = zext i1 %r321 to i64
  %r322 = icmp ne i64 %r320, 0
  br i1 %r322, label %L238, label %L239
L238:
  %r323 = load i64, i64* %ptr_lcode
  %r325 = icmp sle i64 %r323, 90
  %r324 = zext i1 %r325 to i64
  %r326 = icmp ne i64 %r324, 0
  br i1 %r326, label %L241, label %L242
L241:
  store i64 1, i64* %ptr_ok
  br label %L243
L242:
  br label %L243
L243:
  br label %L240
L239:
  br label %L240
L240:
  %r327 = load i64, i64* %ptr_lcode
  %r329 = icmp sge i64 %r327, 97
  %r328 = zext i1 %r329 to i64
  %r330 = icmp ne i64 %r328, 0
  br i1 %r330, label %L244, label %L245
L244:
  %r331 = load i64, i64* %ptr_lcode
  %r333 = icmp sle i64 %r331, 122
  %r332 = zext i1 %r333 to i64
  %r334 = icmp ne i64 %r332, 0
  br i1 %r334, label %L247, label %L248
L247:
  store i64 1, i64* %ptr_ok
  br label %L249
L248:
  br label %L249
L249:
  br label %L246
L245:
  br label %L246
L246:
  %r335 = load i64, i64* %ptr_lcode
  %r336 = call i64 @_eq(i64 %r335, i64 95)
  %r337 = icmp ne i64 %r336, 0
  br i1 %r337, label %L250, label %L251
L250:
  store i64 1, i64* %ptr_ok
  br label %L252
L251:
  br label %L252
L252:
  %r338 = load i64, i64* %ptr_ok
  %r339 = call i64 @_eq(i64 %r338, i64 0)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L253, label %L254
L253:
  store i64 0, i64* %ptr_run_id
  br label %L255
L254:
  br label %L255
L255:
  %r341 = load i64, i64* %ptr_run_id
  %r342 = icmp ne i64 %r341, 0
  br i1 %r342, label %L256, label %L257
L256:
  %r343 = load i64, i64* %ptr_i
  %r344 = call i64 @_add(i64 %r343, i64 1)
  store i64 %r344, i64* %ptr_i
  br label %L258
L257:
  br label %L258
L258:
  br label %L231
L230:
  br label %L231
L231:
  br label %L223
L225:
  %r345 = load i64, i64* %ptr_src
  %r346 = load i64, i64* %ptr_start
  %r347 = load i64, i64* %ptr_i
  %r348 = load i64, i64* %ptr_start
  %r349 = sub i64 %r347, %r348
  %r350 = call i64 @pars(i64 %r345, i64 %r346, i64 %r349)
  store i64 %r350, i64* %ptr_txt
  store i64 4, i64* %ptr_type
  %r351 = load i64, i64* %ptr_txt
  %r352 = getelementptr [4 x i8], [4 x i8]* @.str.43, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_eq(i64 %r351, i64 %r353)
  %r355 = icmp ne i64 %r354, 0
  br i1 %r355, label %L259, label %L260
L259:
  store i64 5, i64* %ptr_type
  br label %L261
L260:
  br label %L261
L261:
  %r356 = load i64, i64* %ptr_txt
  %r357 = getelementptr [5 x i8], [5 x i8]* @.str.44, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_eq(i64 %r356, i64 %r358)
  %r360 = icmp ne i64 %r359, 0
  br i1 %r360, label %L262, label %L263
L262:
  store i64 5, i64* %ptr_type
  br label %L264
L263:
  br label %L264
L264:
  %r361 = load i64, i64* %ptr_txt
  %r362 = getelementptr [6 x i8], [6 x i8]* @.str.45, i64 0, i64 0
  %r363 = ptrtoint i8* %r362 to i64
  %r364 = call i64 @_eq(i64 %r361, i64 %r363)
  %r365 = icmp ne i64 %r364, 0
  br i1 %r365, label %L265, label %L266
L265:
  store i64 5, i64* %ptr_type
  br label %L267
L266:
  br label %L267
L267:
  %r366 = load i64, i64* %ptr_txt
  %r367 = getelementptr [7 x i8], [7 x i8]* @.str.46, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_eq(i64 %r366, i64 %r368)
  %r370 = icmp ne i64 %r369, 0
  br i1 %r370, label %L268, label %L269
L268:
  store i64 6, i64* %ptr_type
  br label %L270
L269:
  br label %L270
L270:
  %r371 = load i64, i64* %ptr_txt
  %r372 = getelementptr [8 x i8], [8 x i8]* @.str.47, i64 0, i64 0
  %r373 = ptrtoint i8* %r372 to i64
  %r374 = call i64 @_eq(i64 %r371, i64 %r373)
  %r375 = icmp ne i64 %r374, 0
  br i1 %r375, label %L271, label %L272
L271:
  store i64 6, i64* %ptr_type
  br label %L273
L272:
  br label %L273
L273:
  %r376 = load i64, i64* %ptr_txt
  %r377 = getelementptr [10 x i8], [10 x i8]* @.str.48, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_eq(i64 %r376, i64 %r378)
  %r380 = icmp ne i64 %r379, 0
  br i1 %r380, label %L274, label %L275
L274:
  store i64 6, i64* %ptr_type
  br label %L276
L275:
  br label %L276
L276:
  %r381 = load i64, i64* %ptr_txt
  %r382 = getelementptr [3 x i8], [3 x i8]* @.str.49, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_eq(i64 %r381, i64 %r383)
  %r385 = icmp ne i64 %r384, 0
  br i1 %r385, label %L277, label %L278
L277:
  store i64 7, i64* %ptr_type
  br label %L279
L278:
  br label %L279
L279:
  %r386 = load i64, i64* %ptr_txt
  %r387 = getelementptr [7 x i8], [7 x i8]* @.str.50, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = call i64 @_eq(i64 %r386, i64 %r388)
  %r390 = icmp ne i64 %r389, 0
  br i1 %r390, label %L280, label %L281
L280:
  store i64 8, i64* %ptr_type
  br label %L282
L281:
  br label %L282
L282:
  %r391 = load i64, i64* %ptr_txt
  %r392 = getelementptr [4 x i8], [4 x i8]* @.str.51, i64 0, i64 0
  %r393 = ptrtoint i8* %r392 to i64
  %r394 = call i64 @_eq(i64 %r391, i64 %r393)
  %r395 = icmp ne i64 %r394, 0
  br i1 %r395, label %L283, label %L284
L283:
  store i64 9, i64* %ptr_type
  br label %L285
L284:
  br label %L285
L285:
  %r396 = load i64, i64* %ptr_txt
  %r397 = getelementptr [5 x i8], [5 x i8]* @.str.52, i64 0, i64 0
  %r398 = ptrtoint i8* %r397 to i64
  %r399 = call i64 @_eq(i64 %r396, i64 %r398)
  %r400 = icmp ne i64 %r399, 0
  br i1 %r400, label %L286, label %L287
L286:
  store i64 10, i64* %ptr_type
  br label %L288
L287:
  br label %L288
L288:
  %r401 = load i64, i64* %ptr_txt
  %r402 = getelementptr [6 x i8], [6 x i8]* @.str.53, i64 0, i64 0
  %r403 = ptrtoint i8* %r402 to i64
  %r404 = call i64 @_eq(i64 %r401, i64 %r403)
  %r405 = icmp ne i64 %r404, 0
  br i1 %r405, label %L289, label %L290
L289:
  store i64 11, i64* %ptr_type
  br label %L291
L290:
  br label %L291
L291:
  %r406 = load i64, i64* %ptr_txt
  %r407 = getelementptr [10 x i8], [10 x i8]* @.str.54, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = call i64 @_eq(i64 %r406, i64 %r408)
  %r410 = icmp ne i64 %r409, 0
  br i1 %r410, label %L292, label %L293
L292:
  store i64 12, i64* %ptr_type
  br label %L294
L293:
  br label %L294
L294:
  %r411 = load i64, i64* %ptr_txt
  %r412 = getelementptr [8 x i8], [8 x i8]* @.str.55, i64 0, i64 0
  %r413 = ptrtoint i8* %r412 to i64
  %r414 = call i64 @_eq(i64 %r411, i64 %r413)
  %r415 = icmp ne i64 %r414, 0
  br i1 %r415, label %L295, label %L296
L295:
  store i64 13, i64* %ptr_type
  br label %L297
L296:
  br label %L297
L297:
  %r416 = load i64, i64* %ptr_txt
  %r417 = getelementptr [10 x i8], [10 x i8]* @.str.56, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  %r419 = call i64 @_eq(i64 %r416, i64 %r418)
  %r420 = icmp ne i64 %r419, 0
  br i1 %r420, label %L298, label %L299
L298:
  store i64 20, i64* %ptr_type
  br label %L300
L299:
  br label %L300
L300:
  %r421 = load i64, i64* %ptr_txt
  %r422 = getelementptr [9 x i8], [9 x i8]* @.str.57, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_eq(i64 %r421, i64 %r423)
  %r425 = icmp ne i64 %r424, 0
  br i1 %r425, label %L301, label %L302
L301:
  store i64 35, i64* %ptr_type
  br label %L303
L302:
  br label %L303
L303:
  %r426 = load i64, i64* %ptr_txt
  %r427 = getelementptr [9 x i8], [9 x i8]* @.str.58, i64 0, i64 0
  %r428 = ptrtoint i8* %r427 to i64
  %r429 = call i64 @_eq(i64 %r426, i64 %r428)
  %r430 = icmp ne i64 %r429, 0
  br i1 %r430, label %L304, label %L305
L304:
  store i64 36, i64* %ptr_type
  br label %L306
L305:
  br label %L306
L306:
  %r431 = load i64, i64* %ptr_txt
  %r432 = getelementptr [4 x i8], [4 x i8]* @.str.59, i64 0, i64 0
  %r433 = ptrtoint i8* %r432 to i64
  %r434 = call i64 @_eq(i64 %r431, i64 %r433)
  %r435 = icmp ne i64 %r434, 0
  br i1 %r435, label %L307, label %L308
L307:
  store i64 37, i64* %ptr_type
  %r436 = getelementptr [2 x i8], [2 x i8]* @.str.60, i64 0, i64 0
  %r437 = ptrtoint i8* %r436 to i64
  store i64 %r437, i64* %ptr_txt
  br label %L309
L308:
  br label %L309
L309:
  %r438 = load i64, i64* %ptr_txt
  %r439 = getelementptr [3 x i8], [3 x i8]* @.str.61, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  %r441 = call i64 @_eq(i64 %r438, i64 %r440)
  %r442 = icmp ne i64 %r441, 0
  br i1 %r442, label %L310, label %L311
L310:
  store i64 33, i64* %ptr_type
  br label %L312
L311:
  br label %L312
L312:
  %r443 = load i64, i64* %ptr_txt
  %r444 = getelementptr [4 x i8], [4 x i8]* @.str.62, i64 0, i64 0
  %r445 = ptrtoint i8* %r444 to i64
  %r446 = call i64 @_eq(i64 %r443, i64 %r445)
  %r447 = icmp ne i64 %r446, 0
  br i1 %r447, label %L313, label %L314
L313:
  store i64 34, i64* %ptr_type
  br label %L315
L314:
  br label %L315
L315:
  %r448 = load i64, i64* %ptr_txt
  %r449 = getelementptr [6 x i8], [6 x i8]* @.str.63, i64 0, i64 0
  %r450 = ptrtoint i8* %r449 to i64
  %r451 = call i64 @_eq(i64 %r448, i64 %r450)
  %r452 = icmp ne i64 %r451, 0
  br i1 %r452, label %L316, label %L317
L316:
  store i64 1, i64* %ptr_type
  %r453 = getelementptr [2 x i8], [2 x i8]* @.str.64, i64 0, i64 0
  %r454 = ptrtoint i8* %r453 to i64
  store i64 %r454, i64* %ptr_txt
  br label %L318
L317:
  br label %L318
L318:
  %r455 = load i64, i64* %ptr_txt
  %r456 = getelementptr [7 x i8], [7 x i8]* @.str.65, i64 0, i64 0
  %r457 = ptrtoint i8* %r456 to i64
  %r458 = call i64 @_eq(i64 %r455, i64 %r457)
  %r459 = icmp ne i64 %r458, 0
  br i1 %r459, label %L319, label %L320
L319:
  store i64 1, i64* %ptr_type
  %r460 = getelementptr [2 x i8], [2 x i8]* @.str.66, i64 0, i64 0
  %r461 = ptrtoint i8* %r460 to i64
  store i64 %r461, i64* %ptr_txt
  br label %L321
L320:
  br label %L321
L321:
  %r462 = load i64, i64* %ptr_type
  %r463 = load i64, i64* %ptr_txt
  %r464 = call i64 @make_token(i64 %r462, i64 %r463)
  %r465 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r465, i64 %r464)
  br label %L222
L221:
  store i64 0, i64* %ptr_type
  store i64 1, i64* %ptr_adv
  %r466 = load i64, i64* %ptr_c
  %r467 = getelementptr [2 x i8], [2 x i8]* @.str.67, i64 0, i64 0
  %r468 = ptrtoint i8* %r467 to i64
  %r469 = call i64 @_eq(i64 %r466, i64 %r468)
  %r470 = icmp ne i64 %r469, 0
  br i1 %r470, label %L322, label %L323
L322:
  %r471 = load i64, i64* @TOK_LPAREN
  store i64 %r471, i64* %ptr_type
  br label %L324
L323:
  br label %L324
L324:
  %r472 = load i64, i64* %ptr_c
  %r473 = getelementptr [2 x i8], [2 x i8]* @.str.68, i64 0, i64 0
  %r474 = ptrtoint i8* %r473 to i64
  %r475 = call i64 @_eq(i64 %r472, i64 %r474)
  %r476 = icmp ne i64 %r475, 0
  br i1 %r476, label %L325, label %L326
L325:
  %r477 = load i64, i64* @TOK_RPAREN
  store i64 %r477, i64* %ptr_type
  br label %L327
L326:
  br label %L327
L327:
  %r478 = load i64, i64* %ptr_c
  %r479 = getelementptr [2 x i8], [2 x i8]* @.str.69, i64 0, i64 0
  %r480 = ptrtoint i8* %r479 to i64
  %r481 = call i64 @_eq(i64 %r478, i64 %r480)
  %r482 = icmp ne i64 %r481, 0
  br i1 %r482, label %L328, label %L329
L328:
  %r483 = load i64, i64* @TOK_LBRACE
  store i64 %r483, i64* %ptr_type
  br label %L330
L329:
  br label %L330
L330:
  %r484 = load i64, i64* %ptr_c
  %r485 = getelementptr [2 x i8], [2 x i8]* @.str.70, i64 0, i64 0
  %r486 = ptrtoint i8* %r485 to i64
  %r487 = call i64 @_eq(i64 %r484, i64 %r486)
  %r488 = icmp ne i64 %r487, 0
  br i1 %r488, label %L331, label %L332
L331:
  %r489 = load i64, i64* @TOK_RBRACE
  store i64 %r489, i64* %ptr_type
  br label %L333
L332:
  br label %L333
L333:
  %r490 = load i64, i64* %ptr_c
  %r491 = getelementptr [2 x i8], [2 x i8]* @.str.71, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_eq(i64 %r490, i64 %r492)
  %r494 = icmp ne i64 %r493, 0
  br i1 %r494, label %L334, label %L335
L334:
  %r495 = load i64, i64* @TOK_LBRACKET
  store i64 %r495, i64* %ptr_type
  br label %L336
L335:
  br label %L336
L336:
  %r496 = load i64, i64* %ptr_c
  %r497 = getelementptr [2 x i8], [2 x i8]* @.str.72, i64 0, i64 0
  %r498 = ptrtoint i8* %r497 to i64
  %r499 = call i64 @_eq(i64 %r496, i64 %r498)
  %r500 = icmp ne i64 %r499, 0
  br i1 %r500, label %L337, label %L338
L337:
  %r501 = load i64, i64* @TOK_RBRACKET
  store i64 %r501, i64* %ptr_type
  br label %L339
L338:
  br label %L339
L339:
  %r502 = load i64, i64* %ptr_c
  %r503 = getelementptr [2 x i8], [2 x i8]* @.str.73, i64 0, i64 0
  %r504 = ptrtoint i8* %r503 to i64
  %r505 = call i64 @_eq(i64 %r502, i64 %r504)
  %r506 = icmp ne i64 %r505, 0
  br i1 %r506, label %L340, label %L341
L340:
  %r507 = load i64, i64* @TOK_COLON
  store i64 %r507, i64* %ptr_type
  br label %L342
L341:
  br label %L342
L342:
  %r508 = load i64, i64* %ptr_c
  %r509 = getelementptr [2 x i8], [2 x i8]* @.str.74, i64 0, i64 0
  %r510 = ptrtoint i8* %r509 to i64
  %r511 = call i64 @_eq(i64 %r508, i64 %r510)
  %r512 = icmp ne i64 %r511, 0
  br i1 %r512, label %L343, label %L344
L343:
  %r513 = load i64, i64* @TOK_CARET
  store i64 %r513, i64* %ptr_type
  br label %L345
L344:
  br label %L345
L345:
  %r514 = load i64, i64* %ptr_c
  %r515 = getelementptr [2 x i8], [2 x i8]* @.str.75, i64 0, i64 0
  %r516 = ptrtoint i8* %r515 to i64
  %r517 = call i64 @_eq(i64 %r514, i64 %r516)
  %r518 = icmp ne i64 %r517, 0
  br i1 %r518, label %L346, label %L347
L346:
  %r519 = load i64, i64* @TOK_DOT
  store i64 %r519, i64* %ptr_type
  br label %L348
L347:
  br label %L348
L348:
  %r520 = load i64, i64* %ptr_c
  %r521 = getelementptr [2 x i8], [2 x i8]* @.str.76, i64 0, i64 0
  %r522 = ptrtoint i8* %r521 to i64
  %r523 = call i64 @_eq(i64 %r520, i64 %r522)
  %r524 = icmp ne i64 %r523, 0
  br i1 %r524, label %L349, label %L350
L349:
  %r525 = load i64, i64* @TOK_COMMA
  store i64 %r525, i64* %ptr_type
  br label %L351
L350:
  br label %L351
L351:
  %r526 = load i64, i64* %ptr_type
  %r527 = call i64 @_eq(i64 %r526, i64 0)
  %r528 = icmp ne i64 %r527, 0
  br i1 %r528, label %L352, label %L353
L352:
  %r529 = load i64, i64* @TOK_OP
  store i64 %r529, i64* %ptr_type
  %r530 = load i64, i64* %ptr_src
  %r531 = load i64, i64* %ptr_i
  %r532 = call i64 @_add(i64 %r531, i64 1)
  %r533 = call i64 @pars(i64 %r530, i64 %r532, i64 1)
  store i64 %r533, i64* %ptr_next
  %r534 = load i64, i64* %ptr_c
  %r535 = getelementptr [2 x i8], [2 x i8]* @.str.77, i64 0, i64 0
  %r536 = ptrtoint i8* %r535 to i64
  %r537 = call i64 @_eq(i64 %r534, i64 %r536)
  %r538 = icmp ne i64 %r537, 0
  br i1 %r538, label %L355, label %L356
L355:
  %r539 = load i64, i64* %ptr_next
  %r540 = getelementptr [2 x i8], [2 x i8]* @.str.78, i64 0, i64 0
  %r541 = ptrtoint i8* %r540 to i64
  %r542 = call i64 @_eq(i64 %r539, i64 %r541)
  %r543 = icmp ne i64 %r542, 0
  br i1 %r543, label %L358, label %L359
L358:
  %r544 = load i64, i64* @TOK_ARROW
  store i64 %r544, i64* %ptr_type
  %r545 = getelementptr [3 x i8], [3 x i8]* @.str.79, i64 0, i64 0
  %r546 = ptrtoint i8* %r545 to i64
  store i64 %r546, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L360
L359:
  br label %L360
L360:
  br label %L357
L356:
  br label %L357
L357:
  %r547 = load i64, i64* %ptr_c
  %r548 = getelementptr [2 x i8], [2 x i8]* @.str.80, i64 0, i64 0
  %r549 = ptrtoint i8* %r548 to i64
  %r550 = call i64 @_eq(i64 %r547, i64 %r549)
  %r551 = icmp ne i64 %r550, 0
  br i1 %r551, label %L361, label %L362
L361:
  %r552 = load i64, i64* %ptr_next
  %r553 = getelementptr [2 x i8], [2 x i8]* @.str.81, i64 0, i64 0
  %r554 = ptrtoint i8* %r553 to i64
  %r555 = call i64 @_eq(i64 %r552, i64 %r554)
  %r556 = icmp ne i64 %r555, 0
  br i1 %r556, label %L364, label %L365
L364:
  %r557 = getelementptr [3 x i8], [3 x i8]* @.str.82, i64 0, i64 0
  %r558 = ptrtoint i8* %r557 to i64
  store i64 %r558, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L366
L365:
  br label %L366
L366:
  br label %L363
L362:
  br label %L363
L363:
  %r559 = load i64, i64* %ptr_c
  %r560 = getelementptr [2 x i8], [2 x i8]* @.str.83, i64 0, i64 0
  %r561 = ptrtoint i8* %r560 to i64
  %r562 = call i64 @_eq(i64 %r559, i64 %r561)
  %r563 = icmp ne i64 %r562, 0
  br i1 %r563, label %L367, label %L368
L367:
  %r564 = load i64, i64* %ptr_next
  %r565 = getelementptr [2 x i8], [2 x i8]* @.str.84, i64 0, i64 0
  %r566 = ptrtoint i8* %r565 to i64
  %r567 = call i64 @_eq(i64 %r564, i64 %r566)
  %r568 = icmp ne i64 %r567, 0
  br i1 %r568, label %L370, label %L371
L370:
  %r569 = getelementptr [3 x i8], [3 x i8]* @.str.85, i64 0, i64 0
  %r570 = ptrtoint i8* %r569 to i64
  store i64 %r570, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L372
L371:
  br label %L372
L372:
  br label %L369
L368:
  br label %L369
L369:
  %r571 = load i64, i64* %ptr_c
  %r572 = getelementptr [2 x i8], [2 x i8]* @.str.86, i64 0, i64 0
  %r573 = ptrtoint i8* %r572 to i64
  %r574 = call i64 @_eq(i64 %r571, i64 %r573)
  %r575 = icmp ne i64 %r574, 0
  br i1 %r575, label %L373, label %L374
L373:
  %r576 = load i64, i64* %ptr_src
  %r577 = load i64, i64* %ptr_i
  %r578 = call i64 @_add(i64 %r577, i64 2)
  %r579 = call i64 @pars(i64 %r576, i64 %r578, i64 1)
  store i64 %r579, i64* %ptr_next2
  %r580 = load i64, i64* %ptr_next
  %r581 = getelementptr [2 x i8], [2 x i8]* @.str.87, i64 0, i64 0
  %r582 = ptrtoint i8* %r581 to i64
  %r583 = call i64 @_eq(i64 %r580, i64 %r582)
  %r584 = icmp ne i64 %r583, 0
  br i1 %r584, label %L376, label %L377
L376:
  %r585 = load i64, i64* %ptr_next2
  %r586 = getelementptr [2 x i8], [2 x i8]* @.str.88, i64 0, i64 0
  %r587 = ptrtoint i8* %r586 to i64
  %r588 = call i64 @_eq(i64 %r585, i64 %r587)
  %r589 = icmp ne i64 %r588, 0
  br i1 %r589, label %L379, label %L380
L379:
  store i64 37, i64* %ptr_type
  %r590 = getelementptr [4 x i8], [4 x i8]* @.str.89, i64 0, i64 0
  %r591 = ptrtoint i8* %r590 to i64
  store i64 %r591, i64* %ptr_c
  store i64 3, i64* %ptr_adv
  br label %L381
L380:
  %r592 = load i64, i64* @TOK_APPEND
  store i64 %r592, i64* %ptr_type
  %r593 = getelementptr [3 x i8], [3 x i8]* @.str.90, i64 0, i64 0
  %r594 = ptrtoint i8* %r593 to i64
  store i64 %r594, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L381
L381:
  br label %L378
L377:
  %r595 = load i64, i64* %ptr_next
  %r596 = getelementptr [2 x i8], [2 x i8]* @.str.91, i64 0, i64 0
  %r597 = ptrtoint i8* %r596 to i64
  %r598 = call i64 @_eq(i64 %r595, i64 %r597)
  %r599 = icmp ne i64 %r598, 0
  br i1 %r599, label %L382, label %L383
L382:
  %r600 = load i64, i64* @TOK_OP
  store i64 %r600, i64* %ptr_type
  %r601 = getelementptr [3 x i8], [3 x i8]* @.str.92, i64 0, i64 0
  %r602 = ptrtoint i8* %r601 to i64
  store i64 %r602, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L384
L383:
  br label %L384
L384:
  br label %L378
L378:
  br label %L375
L374:
  br label %L375
L375:
  %r603 = load i64, i64* %ptr_c
  %r604 = getelementptr [2 x i8], [2 x i8]* @.str.93, i64 0, i64 0
  %r605 = ptrtoint i8* %r604 to i64
  %r606 = call i64 @_eq(i64 %r603, i64 %r605)
  %r607 = icmp ne i64 %r606, 0
  br i1 %r607, label %L385, label %L386
L385:
  %r608 = load i64, i64* %ptr_src
  %r609 = load i64, i64* %ptr_i
  %r610 = call i64 @_add(i64 %r609, i64 2)
  %r611 = call i64 @pars(i64 %r608, i64 %r610, i64 1)
  store i64 %r611, i64* %ptr_next2
  %r612 = load i64, i64* %ptr_next
  %r613 = getelementptr [2 x i8], [2 x i8]* @.str.94, i64 0, i64 0
  %r614 = ptrtoint i8* %r613 to i64
  %r615 = call i64 @_eq(i64 %r612, i64 %r614)
  %r616 = icmp ne i64 %r615, 0
  br i1 %r616, label %L388, label %L389
L388:
  %r617 = load i64, i64* %ptr_next2
  %r618 = getelementptr [2 x i8], [2 x i8]* @.str.95, i64 0, i64 0
  %r619 = ptrtoint i8* %r618 to i64
  %r620 = call i64 @_eq(i64 %r617, i64 %r619)
  %r621 = icmp ne i64 %r620, 0
  br i1 %r621, label %L391, label %L392
L391:
  store i64 37, i64* %ptr_type
  %r622 = getelementptr [4 x i8], [4 x i8]* @.str.96, i64 0, i64 0
  %r623 = ptrtoint i8* %r622 to i64
  store i64 %r623, i64* %ptr_c
  store i64 3, i64* %ptr_adv
  br label %L393
L392:
  %r624 = load i64, i64* @TOK_EXTRACT
  store i64 %r624, i64* %ptr_type
  %r625 = getelementptr [3 x i8], [3 x i8]* @.str.97, i64 0, i64 0
  %r626 = ptrtoint i8* %r625 to i64
  store i64 %r626, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L393
L393:
  br label %L390
L389:
  %r627 = load i64, i64* %ptr_next
  %r628 = getelementptr [2 x i8], [2 x i8]* @.str.98, i64 0, i64 0
  %r629 = ptrtoint i8* %r628 to i64
  %r630 = call i64 @_eq(i64 %r627, i64 %r629)
  %r631 = icmp ne i64 %r630, 0
  br i1 %r631, label %L394, label %L395
L394:
  %r632 = load i64, i64* @TOK_OP
  store i64 %r632, i64* %ptr_type
  %r633 = getelementptr [3 x i8], [3 x i8]* @.str.99, i64 0, i64 0
  %r634 = ptrtoint i8* %r633 to i64
  store i64 %r634, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L396
L395:
  br label %L396
L396:
  br label %L390
L390:
  br label %L387
L386:
  br label %L387
L387:
  br label %L354
L353:
  br label %L354
L354:
  %r635 = load i64, i64* %ptr_type
  %r636 = load i64, i64* %ptr_c
  %r637 = call i64 @make_token(i64 %r635, i64 %r636)
  %r638 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r638, i64 %r637)
  %r639 = load i64, i64* %ptr_i
  %r640 = load i64, i64* %ptr_adv
  %r641 = call i64 @_add(i64 %r639, i64 %r640)
  store i64 %r641, i64* %ptr_i
  br label %L222
L222:
  br label %L171
L171:
  br label %L138
L138:
  br label %L99
L99:
  br label %L96
L96:
  br label %L91
L93:
  %r642 = load i64, i64* @TOK_EOF
  %r643 = getelementptr [4 x i8], [4 x i8]* @.str.100, i64 0, i64 0
  %r644 = ptrtoint i8* %r643 to i64
  %r645 = call i64 @make_token(i64 %r642, i64 %r644)
  %r646 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r646, i64 %r645)
  %r647 = getelementptr [39 x i8], [39 x i8]* @.str.101, i64 0, i64 0
  %r648 = ptrtoint i8* %r647 to i64
  %r649 = load i64, i64* %ptr_tokens
  %r650 = call i64 @mensura(i64 %r649)
  %r651 = call i64 @int_to_str(i64 %r650)
  %r652 = call i64 @_add(i64 %r648, i64 %r651)
  call i64 @print_any(i64 %r652)
  %r653 = load i64, i64* %ptr_tokens
  ret i64 %r653
  ret i64 0
}
define i64 @peek() {
  %r1 = load i64, i64* @p_pos
  %r2 = load i64, i64* @global_tokens
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp sge i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L397, label %L398
L397:
  %r7 = call i64 @_map_new()
  %r8 = getelementptr [5 x i8], [5 x i8]* @.str.102, i64 0, i64 0
  %r9 = ptrtoint i8* %r8 to i64
  %r10 = load i64, i64* @TOK_EOF
  call i64 @_map_set(i64 %r7, i64 %r9, i64 %r10)
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.103, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = getelementptr [4 x i8], [4 x i8]* @.str.104, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  call i64 @_map_set(i64 %r7, i64 %r12, i64 %r14)
  ret i64 %r7
  br label %L399
L398:
  br label %L399
L399:
  %r15 = load i64, i64* @global_tokens
  %r16 = load i64, i64* @p_pos
  %r17 = call i64 @_get(i64 %r15, i64 %r16)
  ret i64 %r17
  ret i64 0
}
define i64 @advance() {
  %ptr_t = alloca i64
  %r1 = call i64 @peek()
  store i64 %r1, i64* %ptr_t
  %r2 = load i64, i64* %ptr_t
  %r3 = getelementptr [5 x i8], [5 x i8]* @.str.105, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = call i64 @_get(i64 %r2, i64 %r4)
  %r6 = load i64, i64* @TOK_EOF
  %r8 = call i64 @_eq(i64 %r5, i64 %r6)
  %r7 = xor i64 %r8, 1
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L400, label %L401
L400:
  %r10 = load i64, i64* @p_pos
  %r11 = call i64 @_add(i64 %r10, i64 1)
  store i64 %r11, i64* @p_pos
  br label %L402
L401:
  br label %L402
L402:
  %r12 = load i64, i64* %ptr_t
  ret i64 %r12
  ret i64 0
}
define i64 @consume(i64 %arg_type) {
  %ptr_type = alloca i64
  store i64 %arg_type, i64* %ptr_type
  %ptr_t = alloca i64
  %r1 = call i64 @peek()
  store i64 %r1, i64* %ptr_t
  %r2 = load i64, i64* %ptr_t
  %r3 = getelementptr [5 x i8], [5 x i8]* @.str.106, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = call i64 @_get(i64 %r2, i64 %r4)
  %r6 = load i64, i64* %ptr_type
  %r7 = call i64 @_eq(i64 %r5, i64 %r6)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L403, label %L404
L403:
  %r9 = call i64 @advance()
  ret i64 1
  br label %L405
L404:
  br label %L405
L405:
  ret i64 0
  ret i64 0
}
define i64 @expect(i64 %arg_type) {
  %ptr_type = alloca i64
  store i64 %arg_type, i64* %ptr_type
  %ptr_t = alloca i64
  %r1 = load i64, i64* %ptr_type
  %r2 = call i64 @consume(i64 %r1)
  %r3 = icmp ne i64 %r2, 0
  br i1 %r3, label %L406, label %L407
L406:
  ret i64 1
  br label %L408
L407:
  br label %L408
L408:
  %r4 = call i64 @peek()
  store i64 %r4, i64* %ptr_t
  %r5 = getelementptr [21 x i8], [21 x i8]* @.str.107, i64 0, i64 0
  %r6 = ptrtoint i8* %r5 to i64
  %r7 = load i64, i64* %ptr_type
  %r8 = call i64 @int_to_str(i64 %r7)
  %r9 = call i64 @_add(i64 %r6, i64 %r8)
  %r10 = getelementptr [10 x i8], [10 x i8]* @.str.108, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  %r12 = call i64 @_add(i64 %r9, i64 %r11)
  %r13 = load i64, i64* %ptr_t
  %r14 = getelementptr [5 x i8], [5 x i8]* @.str.109, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_get(i64 %r13, i64 %r15)
  %r17 = call i64 @_add(i64 %r12, i64 %r16)
  %r18 = call i64 @error_report(i64 %r17)
  ret i64 0
  ret i64 0
}
define i64 @parse_primary() {
  %ptr_t = alloca i64
  %ptr_name = alloca i64
  %ptr_args = alloca i64
  %ptr_expr = alloca i64
  %ptr_items = alloca i64
  %ptr_keys = alloca i64
  %ptr_vals = alloca i64
  %ptr_k = alloca i64
  %ptr_v = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @peek()
  store i64 %r1, i64* %ptr_t
  %r2 = load i64, i64* @TOK_INT
  %r3 = call i64 @consume(i64 %r2)
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L409, label %L410
L409:
  %r5 = call i64 @_map_new()
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.110, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r5, i64 %r7, i64 %r8)
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.111, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = load i64, i64* %ptr_t
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.112, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  call i64 @_map_set(i64 %r5, i64 %r10, i64 %r14)
  ret i64 %r5
  br label %L411
L410:
  br label %L411
L411:
  %r15 = load i64, i64* @TOK_STRING
  %r16 = call i64 @consume(i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L412, label %L413
L412:
  %r18 = call i64 @_map_new()
  %r19 = getelementptr [5 x i8], [5 x i8]* @.str.113, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = load i64, i64* @EXPR_STRING
  call i64 @_map_set(i64 %r18, i64 %r20, i64 %r21)
  %r22 = getelementptr [4 x i8], [4 x i8]* @.str.114, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = load i64, i64* %ptr_t
  %r25 = getelementptr [5 x i8], [5 x i8]* @.str.115, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = call i64 @_get(i64 %r24, i64 %r26)
  call i64 @_map_set(i64 %r18, i64 %r23, i64 %r27)
  ret i64 %r18
  br label %L414
L413:
  br label %L414
L414:
  %r28 = load i64, i64* @TOK_IDENT
  %r29 = call i64 @consume(i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L415, label %L416
L415:
  %r31 = load i64, i64* %ptr_t
  %r32 = getelementptr [5 x i8], [5 x i8]* @.str.116, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_get(i64 %r31, i64 %r33)
  store i64 %r34, i64* %ptr_name
  %r35 = load i64, i64* @TOK_LPAREN
  %r36 = call i64 @consume(i64 %r35)
  %r37 = icmp ne i64 %r36, 0
  br i1 %r37, label %L418, label %L419
L418:
  %r38 = call i64 @_list_new()
  store i64 %r38, i64* %ptr_args
  %r39 = call i64 @peek()
  %r40 = getelementptr [5 x i8], [5 x i8]* @.str.117, i64 0, i64 0
  %r41 = ptrtoint i8* %r40 to i64
  %r42 = call i64 @_get(i64 %r39, i64 %r41)
  %r43 = load i64, i64* @TOK_RPAREN
  %r45 = call i64 @_eq(i64 %r42, i64 %r43)
  %r44 = xor i64 %r45, 1
  %r46 = icmp ne i64 %r44, 0
  br i1 %r46, label %L421, label %L422
L421:
  %r47 = call i64 @parse_expr()
  %r48 = load i64, i64* %ptr_args
  call i64 @_append_poly(i64 %r48, i64 %r47)
  br label %L424
L424:
  %r49 = load i64, i64* @TOK_COMMA
  %r50 = call i64 @consume(i64 %r49)
  %r51 = icmp ne i64 %r50, 0
  br i1 %r51, label %L425, label %L426
L425:
  %r52 = call i64 @parse_expr()
  %r53 = load i64, i64* %ptr_args
  call i64 @_append_poly(i64 %r53, i64 %r52)
  br label %L424
L426:
  br label %L423
L422:
  br label %L423
L423:
  %r54 = load i64, i64* @TOK_RPAREN
  %r55 = call i64 @expect(i64 %r54)
  %r56 = call i64 @_map_new()
  %r57 = getelementptr [5 x i8], [5 x i8]* @.str.118, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = load i64, i64* @EXPR_CALL
  call i64 @_map_set(i64 %r56, i64 %r58, i64 %r59)
  %r60 = getelementptr [5 x i8], [5 x i8]* @.str.119, i64 0, i64 0
  %r61 = ptrtoint i8* %r60 to i64
  %r62 = load i64, i64* %ptr_name
  call i64 @_map_set(i64 %r56, i64 %r61, i64 %r62)
  %r63 = getelementptr [5 x i8], [5 x i8]* @.str.120, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = load i64, i64* %ptr_args
  call i64 @_map_set(i64 %r56, i64 %r64, i64 %r65)
  ret i64 %r56
  br label %L420
L419:
  br label %L420
L420:
  %r66 = call i64 @_map_new()
  %r67 = getelementptr [5 x i8], [5 x i8]* @.str.121, i64 0, i64 0
  %r68 = ptrtoint i8* %r67 to i64
  %r69 = load i64, i64* @EXPR_VAR
  call i64 @_map_set(i64 %r66, i64 %r68, i64 %r69)
  %r70 = getelementptr [5 x i8], [5 x i8]* @.str.122, i64 0, i64 0
  %r71 = ptrtoint i8* %r70 to i64
  %r72 = load i64, i64* %ptr_name
  call i64 @_map_set(i64 %r66, i64 %r71, i64 %r72)
  ret i64 %r66
  br label %L417
L416:
  br label %L417
L417:
  %r73 = load i64, i64* @TOK_LPAREN
  %r74 = call i64 @consume(i64 %r73)
  %r75 = icmp ne i64 %r74, 0
  br i1 %r75, label %L427, label %L428
L427:
  %r76 = call i64 @parse_expr()
  store i64 %r76, i64* %ptr_expr
  %r77 = load i64, i64* @TOK_RPAREN
  %r78 = call i64 @expect(i64 %r77)
  %r79 = load i64, i64* %ptr_expr
  ret i64 %r79
  br label %L429
L428:
  br label %L429
L429:
  %r80 = load i64, i64* @TOK_LBRACKET
  %r81 = call i64 @consume(i64 %r80)
  %r82 = icmp ne i64 %r81, 0
  br i1 %r82, label %L430, label %L431
L430:
  %r83 = call i64 @_list_new()
  store i64 %r83, i64* %ptr_items
  %r84 = call i64 @peek()
  %r85 = getelementptr [5 x i8], [5 x i8]* @.str.123, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = call i64 @_get(i64 %r84, i64 %r86)
  %r88 = load i64, i64* @TOK_RBRACKET
  %r90 = call i64 @_eq(i64 %r87, i64 %r88)
  %r89 = xor i64 %r90, 1
  %r91 = icmp ne i64 %r89, 0
  br i1 %r91, label %L433, label %L434
L433:
  %r92 = call i64 @parse_expr()
  %r93 = load i64, i64* %ptr_items
  call i64 @_append_poly(i64 %r93, i64 %r92)
  br label %L436
L436:
  %r94 = load i64, i64* @TOK_COMMA
  %r95 = call i64 @consume(i64 %r94)
  %r96 = icmp ne i64 %r95, 0
  br i1 %r96, label %L437, label %L438
L437:
  %r97 = call i64 @parse_expr()
  %r98 = load i64, i64* %ptr_items
  call i64 @_append_poly(i64 %r98, i64 %r97)
  br label %L436
L438:
  br label %L435
L434:
  br label %L435
L435:
  %r99 = load i64, i64* @TOK_RBRACKET
  %r100 = call i64 @expect(i64 %r99)
  %r101 = call i64 @_map_new()
  %r102 = getelementptr [5 x i8], [5 x i8]* @.str.124, i64 0, i64 0
  %r103 = ptrtoint i8* %r102 to i64
  %r104 = load i64, i64* @EXPR_LIST
  call i64 @_map_set(i64 %r101, i64 %r103, i64 %r104)
  %r105 = getelementptr [6 x i8], [6 x i8]* @.str.125, i64 0, i64 0
  %r106 = ptrtoint i8* %r105 to i64
  %r107 = load i64, i64* %ptr_items
  call i64 @_map_set(i64 %r101, i64 %r106, i64 %r107)
  ret i64 %r101
  br label %L432
L431:
  br label %L432
L432:
  %r108 = load i64, i64* @TOK_LBRACE
  %r109 = call i64 @consume(i64 %r108)
  %r110 = icmp ne i64 %r109, 0
  br i1 %r110, label %L439, label %L440
L439:
  %r111 = call i64 @_list_new()
  store i64 %r111, i64* %ptr_keys
  %r112 = call i64 @_list_new()
  store i64 %r112, i64* %ptr_vals
  br label %L442
L442:
  %r113 = call i64 @peek()
  %r114 = getelementptr [5 x i8], [5 x i8]* @.str.126, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_get(i64 %r113, i64 %r115)
  %r117 = load i64, i64* @TOK_RBRACE
  %r119 = call i64 @_eq(i64 %r116, i64 %r117)
  %r118 = xor i64 %r119, 1
  %r120 = icmp ne i64 %r118, 0
  br i1 %r120, label %L443, label %L444
L443:
  %r121 = call i64 @advance()
  store i64 %r121, i64* %ptr_k
  %r122 = load i64, i64* @TOK_COLON
  %r123 = call i64 @expect(i64 %r122)
  %r124 = call i64 @parse_expr()
  store i64 %r124, i64* %ptr_v
  %r125 = load i64, i64* %ptr_k
  %r126 = getelementptr [5 x i8], [5 x i8]* @.str.127, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = load i64, i64* %ptr_keys
  call i64 @_append_poly(i64 %r129, i64 %r128)
  %r130 = load i64, i64* %ptr_v
  %r131 = load i64, i64* %ptr_vals
  call i64 @_append_poly(i64 %r131, i64 %r130)
  %r132 = load i64, i64* @TOK_COMMA
  %r133 = call i64 @consume(i64 %r132)
  br label %L442
L444:
  %r134 = load i64, i64* @TOK_RBRACE
  %r135 = call i64 @expect(i64 %r134)
  %r136 = call i64 @_map_new()
  %r137 = getelementptr [5 x i8], [5 x i8]* @.str.128, i64 0, i64 0
  %r138 = ptrtoint i8* %r137 to i64
  %r139 = load i64, i64* @EXPR_MAP
  call i64 @_map_set(i64 %r136, i64 %r138, i64 %r139)
  %r140 = getelementptr [5 x i8], [5 x i8]* @.str.129, i64 0, i64 0
  %r141 = ptrtoint i8* %r140 to i64
  %r142 = load i64, i64* %ptr_keys
  call i64 @_map_set(i64 %r136, i64 %r141, i64 %r142)
  %r143 = getelementptr [5 x i8], [5 x i8]* @.str.130, i64 0, i64 0
  %r144 = ptrtoint i8* %r143 to i64
  %r145 = load i64, i64* %ptr_vals
  call i64 @_map_set(i64 %r136, i64 %r144, i64 %r145)
  ret i64 %r136
  br label %L441
L440:
  br label %L441
L441:
  %r146 = load i64, i64* %ptr_t
  %r147 = getelementptr [5 x i8], [5 x i8]* @.str.131, i64 0, i64 0
  %r148 = ptrtoint i8* %r147 to i64
  %r149 = call i64 @_get(i64 %r146, i64 %r148)
  %r150 = load i64, i64* @TOK_OP
  %r151 = call i64 @_eq(i64 %r149, i64 %r150)
  %r152 = load i64, i64* %ptr_t
  %r153 = getelementptr [5 x i8], [5 x i8]* @.str.132, i64 0, i64 0
  %r154 = ptrtoint i8* %r153 to i64
  %r155 = call i64 @_get(i64 %r152, i64 %r154)
  %r156 = getelementptr [2 x i8], [2 x i8]* @.str.133, i64 0, i64 0
  %r157 = ptrtoint i8* %r156 to i64
  %r158 = call i64 @_eq(i64 %r155, i64 %r157)
  %r159 = and i64 %r151, %r158
  %r160 = icmp ne i64 %r159, 0
  br i1 %r160, label %L445, label %L446
L445:
  %r161 = call i64 @advance()
  %r162 = call i64 @parse_primary()
  store i64 %r162, i64* %ptr_right
  %r163 = call i64 @_map_new()
  %r164 = getelementptr [5 x i8], [5 x i8]* @.str.134, i64 0, i64 0
  %r165 = ptrtoint i8* %r164 to i64
  %r166 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r163, i64 %r165, i64 %r166)
  %r167 = getelementptr [3 x i8], [3 x i8]* @.str.135, i64 0, i64 0
  %r168 = ptrtoint i8* %r167 to i64
  %r169 = getelementptr [2 x i8], [2 x i8]* @.str.136, i64 0, i64 0
  %r170 = ptrtoint i8* %r169 to i64
  call i64 @_map_set(i64 %r163, i64 %r168, i64 %r170)
  %r171 = getelementptr [5 x i8], [5 x i8]* @.str.137, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_map_new()
  %r174 = getelementptr [5 x i8], [5 x i8]* @.str.138, i64 0, i64 0
  %r175 = ptrtoint i8* %r174 to i64
  %r176 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r173, i64 %r175, i64 %r176)
  %r177 = getelementptr [4 x i8], [4 x i8]* @.str.139, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = getelementptr [2 x i8], [2 x i8]* @.str.140, i64 0, i64 0
  %r180 = ptrtoint i8* %r179 to i64
  call i64 @_map_set(i64 %r173, i64 %r178, i64 %r180)
  call i64 @_map_set(i64 %r163, i64 %r172, i64 %r173)
  %r181 = getelementptr [6 x i8], [6 x i8]* @.str.141, i64 0, i64 0
  %r182 = ptrtoint i8* %r181 to i64
  %r183 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r163, i64 %r182, i64 %r183)
  ret i64 %r163
  br label %L447
L446:
  br label %L447
L447:
  %r184 = load i64, i64* %ptr_t
  %r185 = getelementptr [5 x i8], [5 x i8]* @.str.142, i64 0, i64 0
  %r186 = ptrtoint i8* %r185 to i64
  %r187 = call i64 @_get(i64 %r184, i64 %r186)
  %r188 = load i64, i64* @TOK_OP
  %r189 = call i64 @_eq(i64 %r187, i64 %r188)
  %r190 = load i64, i64* %ptr_t
  %r191 = getelementptr [5 x i8], [5 x i8]* @.str.143, i64 0, i64 0
  %r192 = ptrtoint i8* %r191 to i64
  %r193 = call i64 @_get(i64 %r190, i64 %r192)
  %r194 = getelementptr [2 x i8], [2 x i8]* @.str.144, i64 0, i64 0
  %r195 = ptrtoint i8* %r194 to i64
  %r196 = call i64 @_eq(i64 %r193, i64 %r195)
  %r197 = and i64 %r189, %r196
  %r198 = icmp ne i64 %r197, 0
  br i1 %r198, label %L448, label %L449
L448:
  %r199 = call i64 @advance()
  %r200 = call i64 @parse_primary()
  store i64 %r200, i64* %ptr_right
  %r201 = call i64 @_map_new()
  %r202 = getelementptr [5 x i8], [5 x i8]* @.str.145, i64 0, i64 0
  %r203 = ptrtoint i8* %r202 to i64
  %r204 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r201, i64 %r203, i64 %r204)
  %r205 = getelementptr [3 x i8], [3 x i8]* @.str.146, i64 0, i64 0
  %r206 = ptrtoint i8* %r205 to i64
  %r207 = getelementptr [3 x i8], [3 x i8]* @.str.147, i64 0, i64 0
  %r208 = ptrtoint i8* %r207 to i64
  call i64 @_map_set(i64 %r201, i64 %r206, i64 %r208)
  %r209 = getelementptr [5 x i8], [5 x i8]* @.str.148, i64 0, i64 0
  %r210 = ptrtoint i8* %r209 to i64
  %r211 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r201, i64 %r210, i64 %r211)
  %r212 = getelementptr [6 x i8], [6 x i8]* @.str.149, i64 0, i64 0
  %r213 = ptrtoint i8* %r212 to i64
  %r214 = call i64 @_map_new()
  %r215 = getelementptr [5 x i8], [5 x i8]* @.str.150, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r214, i64 %r216, i64 %r217)
  %r218 = getelementptr [4 x i8], [4 x i8]* @.str.151, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = getelementptr [2 x i8], [2 x i8]* @.str.152, i64 0, i64 0
  %r221 = ptrtoint i8* %r220 to i64
  call i64 @_map_set(i64 %r214, i64 %r219, i64 %r221)
  call i64 @_map_set(i64 %r201, i64 %r213, i64 %r214)
  ret i64 %r201
  br label %L450
L449:
  br label %L450
L450:
  %r222 = load i64, i64* %ptr_t
  %r223 = getelementptr [5 x i8], [5 x i8]* @.str.153, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = call i64 @_get(i64 %r222, i64 %r224)
  %r226 = load i64, i64* @TOK_EOF
  %r228 = call i64 @_eq(i64 %r225, i64 %r226)
  %r227 = xor i64 %r228, 1
  %r229 = icmp ne i64 %r227, 0
  br i1 %r229, label %L451, label %L452
L451:
  %r230 = call i64 @advance()
  br label %L453
L452:
  br label %L453
L453:
  %r231 = getelementptr [19 x i8], [19 x i8]* @.str.154, i64 0, i64 0
  %r232 = ptrtoint i8* %r231 to i64
  %r233 = load i64, i64* %ptr_t
  %r234 = getelementptr [5 x i8], [5 x i8]* @.str.155, i64 0, i64 0
  %r235 = ptrtoint i8* %r234 to i64
  %r236 = call i64 @_get(i64 %r233, i64 %r235)
  %r237 = call i64 @_add(i64 %r232, i64 %r236)
  %r238 = call i64 @error_report(i64 %r237)
  %r239 = call i64 @_map_new()
  %r240 = getelementptr [5 x i8], [5 x i8]* @.str.156, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r239, i64 %r241, i64 %r242)
  %r243 = getelementptr [4 x i8], [4 x i8]* @.str.157, i64 0, i64 0
  %r244 = ptrtoint i8* %r243 to i64
  %r245 = getelementptr [2 x i8], [2 x i8]* @.str.158, i64 0, i64 0
  %r246 = ptrtoint i8* %r245 to i64
  call i64 @_map_set(i64 %r239, i64 %r244, i64 %r246)
  ret i64 %r239
  ret i64 0
}
define i64 @parse_postfix() {
  %ptr_expr = alloca i64
  %ptr_running = alloca i64
  %ptr_idx = alloca i64
  %ptr_t = alloca i64
  %r1 = call i64 @parse_primary()
  store i64 %r1, i64* %ptr_expr
  store i64 1, i64* %ptr_running
  br label %L454
L454:
  %r2 = load i64, i64* %ptr_running
  %r3 = icmp ne i64 %r2, 0
  br i1 %r3, label %L455, label %L456
L455:
  %r4 = load i64, i64* @TOK_LBRACKET
  %r5 = call i64 @consume(i64 %r4)
  %r6 = icmp ne i64 %r5, 0
  br i1 %r6, label %L457, label %L458
L457:
  %r7 = call i64 @parse_expr()
  store i64 %r7, i64* %ptr_idx
  %r8 = load i64, i64* @TOK_RBRACKET
  %r9 = call i64 @expect(i64 %r8)
  %r10 = call i64 @_map_new()
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.159, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = load i64, i64* @EXPR_INDEX
  call i64 @_map_set(i64 %r10, i64 %r12, i64 %r13)
  %r14 = getelementptr [4 x i8], [4 x i8]* @.str.160, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r10, i64 %r15, i64 %r16)
  %r17 = getelementptr [4 x i8], [4 x i8]* @.str.161, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = load i64, i64* %ptr_idx
  call i64 @_map_set(i64 %r10, i64 %r18, i64 %r19)
  store i64 %r10, i64* %ptr_expr
  br label %L459
L458:
  %r20 = load i64, i64* @TOK_DOT
  %r21 = call i64 @consume(i64 %r20)
  %r22 = icmp ne i64 %r21, 0
  br i1 %r22, label %L460, label %L461
L460:
  %r23 = call i64 @advance()
  store i64 %r23, i64* %ptr_t
  %r24 = call i64 @_map_new()
  %r25 = getelementptr [5 x i8], [5 x i8]* @.str.162, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = load i64, i64* @EXPR_GET
  call i64 @_map_set(i64 %r24, i64 %r26, i64 %r27)
  %r28 = getelementptr [4 x i8], [4 x i8]* @.str.163, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r24, i64 %r29, i64 %r30)
  %r31 = getelementptr [5 x i8], [5 x i8]* @.str.164, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = load i64, i64* %ptr_t
  %r34 = getelementptr [5 x i8], [5 x i8]* @.str.165, i64 0, i64 0
  %r35 = ptrtoint i8* %r34 to i64
  %r36 = call i64 @_get(i64 %r33, i64 %r35)
  call i64 @_map_set(i64 %r24, i64 %r32, i64 %r36)
  store i64 %r24, i64* %ptr_expr
  br label %L462
L461:
  store i64 0, i64* %ptr_running
  br label %L462
L462:
  br label %L459
L459:
  br label %L454
L456:
  %r37 = load i64, i64* %ptr_expr
  ret i64 %r37
  ret i64 0
}
define i64 @parse_term() {
  %ptr_left = alloca i64
  %ptr_t = alloca i64
  %ptr_running = alloca i64
  %ptr_is_op = alloca i64
  %ptr_op = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @parse_postfix()
  store i64 %r1, i64* %ptr_left
  %r2 = call i64 @peek()
  store i64 %r2, i64* %ptr_t
  store i64 1, i64* %ptr_running
  br label %L463
L463:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L464, label %L465
L464:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.166, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L466, label %L467
L466:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.167, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.168, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L469, label %L470
L469:
  store i64 1, i64* %ptr_is_op
  br label %L471
L470:
  br label %L471
L471:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.169, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L472, label %L473
L472:
  store i64 1, i64* %ptr_is_op
  br label %L474
L473:
  br label %L474
L474:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.170, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L475, label %L476
L475:
  store i64 1, i64* %ptr_is_op
  br label %L477
L476:
  br label %L477
L477:
  br label %L468
L467:
  br label %L468
L468:
  %r31 = load i64, i64* %ptr_is_op
  %r32 = icmp ne i64 %r31, 0
  br i1 %r32, label %L478, label %L479
L478:
  %r33 = load i64, i64* %ptr_t
  %r34 = getelementptr [5 x i8], [5 x i8]* @.str.171, i64 0, i64 0
  %r35 = ptrtoint i8* %r34 to i64
  %r36 = call i64 @_get(i64 %r33, i64 %r35)
  store i64 %r36, i64* %ptr_op
  %r37 = call i64 @advance()
  %r38 = call i64 @parse_postfix()
  store i64 %r38, i64* %ptr_right
  %r39 = call i64 @_map_new()
  %r40 = getelementptr [5 x i8], [5 x i8]* @.str.172, i64 0, i64 0
  %r41 = ptrtoint i8* %r40 to i64
  %r42 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r39, i64 %r41, i64 %r42)
  %r43 = getelementptr [3 x i8], [3 x i8]* @.str.173, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r39, i64 %r44, i64 %r45)
  %r46 = getelementptr [5 x i8], [5 x i8]* @.str.174, i64 0, i64 0
  %r47 = ptrtoint i8* %r46 to i64
  %r48 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r39, i64 %r47, i64 %r48)
  %r49 = getelementptr [6 x i8], [6 x i8]* @.str.175, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r39, i64 %r50, i64 %r51)
  store i64 %r39, i64* %ptr_left
  %r52 = call i64 @peek()
  store i64 %r52, i64* %ptr_t
  br label %L480
L479:
  store i64 0, i64* %ptr_running
  br label %L480
L480:
  br label %L463
L465:
  %r53 = load i64, i64* %ptr_left
  ret i64 %r53
  ret i64 0
}
define i64 @parse_math() {
  %ptr_left = alloca i64
  %ptr_t = alloca i64
  %ptr_running = alloca i64
  %ptr_is_op = alloca i64
  %ptr_op = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @parse_term()
  store i64 %r1, i64* %ptr_left
  %r2 = call i64 @peek()
  store i64 %r2, i64* %ptr_t
  store i64 1, i64* %ptr_running
  br label %L481
L481:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L482, label %L483
L482:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.176, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L484, label %L485
L484:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.177, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.178, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L487, label %L488
L487:
  store i64 1, i64* %ptr_is_op
  br label %L489
L488:
  br label %L489
L489:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.179, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L490, label %L491
L490:
  store i64 1, i64* %ptr_is_op
  br label %L492
L491:
  br label %L492
L492:
  br label %L486
L485:
  br label %L486
L486:
  %r26 = load i64, i64* %ptr_is_op
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L493, label %L494
L493:
  %r28 = load i64, i64* %ptr_t
  %r29 = getelementptr [5 x i8], [5 x i8]* @.str.180, i64 0, i64 0
  %r30 = ptrtoint i8* %r29 to i64
  %r31 = call i64 @_get(i64 %r28, i64 %r30)
  store i64 %r31, i64* %ptr_op
  %r32 = call i64 @advance()
  %r33 = call i64 @parse_term()
  store i64 %r33, i64* %ptr_right
  %r34 = call i64 @_map_new()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.181, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r34, i64 %r36, i64 %r37)
  %r38 = getelementptr [3 x i8], [3 x i8]* @.str.182, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r34, i64 %r39, i64 %r40)
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.183, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r34, i64 %r42, i64 %r43)
  %r44 = getelementptr [6 x i8], [6 x i8]* @.str.184, i64 0, i64 0
  %r45 = ptrtoint i8* %r44 to i64
  %r46 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r34, i64 %r45, i64 %r46)
  store i64 %r34, i64* %ptr_left
  %r47 = call i64 @peek()
  store i64 %r47, i64* %ptr_t
  br label %L495
L494:
  store i64 0, i64* %ptr_running
  br label %L495
L495:
  br label %L481
L483:
  %r48 = load i64, i64* %ptr_left
  ret i64 %r48
  ret i64 0
}
define i64 @parse_bitwise() {
  %ptr_left = alloca i64
  %ptr_t = alloca i64
  %ptr_running = alloca i64
  %ptr_is_op = alloca i64
  %ptr_op = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @parse_math()
  store i64 %r1, i64* %ptr_left
  %r2 = call i64 @peek()
  store i64 %r2, i64* %ptr_t
  store i64 1, i64* %ptr_running
  br label %L496
L496:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L497, label %L498
L497:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.185, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  store i64 %r8, i64* %ptr_op
  %r9 = load i64, i64* %ptr_t
  %r10 = getelementptr [5 x i8], [5 x i8]* @.str.186, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  %r12 = call i64 @_get(i64 %r9, i64 %r11)
  %r13 = load i64, i64* @TOK_OP
  %r14 = call i64 @_eq(i64 %r12, i64 %r13)
  %r15 = icmp ne i64 %r14, 0
  br i1 %r15, label %L499, label %L500
L499:
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.187, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L502, label %L503
L502:
  store i64 1, i64* %ptr_is_op
  br label %L504
L503:
  br label %L504
L504:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.188, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L505, label %L506
L505:
  store i64 1, i64* %ptr_is_op
  br label %L507
L506:
  br label %L507
L507:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.189, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L508, label %L509
L508:
  store i64 1, i64* %ptr_is_op
  br label %L510
L509:
  br label %L510
L510:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [4 x i8], [4 x i8]* @.str.190, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L511, label %L512
L511:
  store i64 1, i64* %ptr_is_op
  br label %L513
L512:
  br label %L513
L513:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [4 x i8], [4 x i8]* @.str.191, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L514, label %L515
L514:
  store i64 1, i64* %ptr_is_op
  br label %L516
L515:
  br label %L516
L516:
  br label %L501
L500:
  br label %L501
L501:
  %r41 = load i64, i64* %ptr_t
  %r42 = getelementptr [5 x i8], [5 x i8]* @.str.192, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_get(i64 %r41, i64 %r43)
  %r45 = load i64, i64* @TOK_IDENT
  %r46 = call i64 @_eq(i64 %r44, i64 %r45)
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L517, label %L518
L517:
  %r48 = load i64, i64* %ptr_op
  %r49 = getelementptr [4 x i8], [4 x i8]* @.str.193, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_eq(i64 %r48, i64 %r50)
  %r52 = icmp ne i64 %r51, 0
  br i1 %r52, label %L520, label %L521
L520:
  store i64 1, i64* %ptr_is_op
  %r53 = getelementptr [2 x i8], [2 x i8]* @.str.194, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  store i64 %r54, i64* %ptr_op
  br label %L522
L521:
  br label %L522
L522:
  br label %L519
L518:
  br label %L519
L519:
  %r55 = load i64, i64* %ptr_is_op
  %r56 = icmp ne i64 %r55, 0
  br i1 %r56, label %L523, label %L524
L523:
  %r57 = call i64 @advance()
  %r58 = call i64 @parse_math()
  store i64 %r58, i64* %ptr_right
  %r59 = call i64 @_map_new()
  %r60 = getelementptr [5 x i8], [5 x i8]* @.str.195, i64 0, i64 0
  %r61 = ptrtoint i8* %r60 to i64
  %r62 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r59, i64 %r61, i64 %r62)
  %r63 = getelementptr [3 x i8], [3 x i8]* @.str.196, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r59, i64 %r64, i64 %r65)
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.197, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r59, i64 %r67, i64 %r68)
  %r69 = getelementptr [6 x i8], [6 x i8]* @.str.198, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r59, i64 %r70, i64 %r71)
  store i64 %r59, i64* %ptr_left
  %r72 = call i64 @peek()
  store i64 %r72, i64* %ptr_t
  br label %L525
L524:
  store i64 0, i64* %ptr_running
  br label %L525
L525:
  br label %L496
L498:
  %r73 = load i64, i64* %ptr_left
  ret i64 %r73
  ret i64 0
}
define i64 @parse_cmp() {
  %ptr_left = alloca i64
  %ptr_t = alloca i64
  %ptr_running = alloca i64
  %ptr_is_op = alloca i64
  %ptr_op = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @parse_bitwise()
  store i64 %r1, i64* %ptr_left
  %r2 = call i64 @peek()
  store i64 %r2, i64* %ptr_t
  store i64 1, i64* %ptr_running
  br label %L526
L526:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L527, label %L528
L527:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.199, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L529, label %L530
L529:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.200, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [3 x i8], [3 x i8]* @.str.201, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L532, label %L533
L532:
  store i64 1, i64* %ptr_is_op
  br label %L534
L533:
  br label %L534
L534:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [3 x i8], [3 x i8]* @.str.202, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L535, label %L536
L535:
  store i64 1, i64* %ptr_is_op
  br label %L537
L536:
  br label %L537
L537:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.203, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L538, label %L539
L538:
  store i64 1, i64* %ptr_is_op
  br label %L540
L539:
  br label %L540
L540:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [2 x i8], [2 x i8]* @.str.204, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L541, label %L542
L541:
  store i64 1, i64* %ptr_is_op
  br label %L543
L542:
  br label %L543
L543:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [3 x i8], [3 x i8]* @.str.205, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L544, label %L545
L544:
  store i64 1, i64* %ptr_is_op
  br label %L546
L545:
  br label %L546
L546:
  %r41 = load i64, i64* %ptr_op
  %r42 = getelementptr [3 x i8], [3 x i8]* @.str.206, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_eq(i64 %r41, i64 %r43)
  %r45 = icmp ne i64 %r44, 0
  br i1 %r45, label %L547, label %L548
L547:
  store i64 1, i64* %ptr_is_op
  br label %L549
L548:
  br label %L549
L549:
  br label %L531
L530:
  br label %L531
L531:
  %r46 = load i64, i64* %ptr_is_op
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L550, label %L551
L550:
  %r48 = load i64, i64* %ptr_t
  %r49 = getelementptr [5 x i8], [5 x i8]* @.str.207, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_get(i64 %r48, i64 %r50)
  store i64 %r51, i64* %ptr_op
  %r52 = call i64 @advance()
  %r53 = call i64 @parse_bitwise()
  store i64 %r53, i64* %ptr_right
  %r54 = call i64 @_map_new()
  %r55 = getelementptr [5 x i8], [5 x i8]* @.str.208, i64 0, i64 0
  %r56 = ptrtoint i8* %r55 to i64
  %r57 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r54, i64 %r56, i64 %r57)
  %r58 = getelementptr [3 x i8], [3 x i8]* @.str.209, i64 0, i64 0
  %r59 = ptrtoint i8* %r58 to i64
  %r60 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r54, i64 %r59, i64 %r60)
  %r61 = getelementptr [5 x i8], [5 x i8]* @.str.210, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r54, i64 %r62, i64 %r63)
  %r64 = getelementptr [6 x i8], [6 x i8]* @.str.211, i64 0, i64 0
  %r65 = ptrtoint i8* %r64 to i64
  %r66 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r54, i64 %r65, i64 %r66)
  store i64 %r54, i64* %ptr_left
  %r67 = call i64 @peek()
  store i64 %r67, i64* %ptr_t
  br label %L552
L551:
  store i64 0, i64* %ptr_running
  br label %L552
L552:
  br label %L526
L528:
  %r68 = load i64, i64* %ptr_left
  ret i64 %r68
  ret i64 0
}
define i64 @parse_expr() {
  %ptr_left = alloca i64
  %ptr_t = alloca i64
  %ptr_running = alloca i64
  %ptr_is_op = alloca i64
  %ptr_op = alloca i64
  %ptr_right = alloca i64
  %r1 = call i64 @parse_cmp()
  store i64 %r1, i64* %ptr_left
  %r2 = call i64 @peek()
  store i64 %r2, i64* %ptr_t
  store i64 1, i64* %ptr_running
  br label %L553
L553:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L554, label %L555
L554:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.212, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_AND
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = load i64, i64* %ptr_t
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.213, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  %r15 = load i64, i64* @TOK_OR
  %r16 = call i64 @_eq(i64 %r14, i64 %r15)
  %r17 = or i64 %r10, %r16
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L556, label %L557
L556:
  store i64 1, i64* %ptr_is_op
  br label %L558
L557:
  br label %L558
L558:
  %r19 = load i64, i64* %ptr_is_op
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L559, label %L560
L559:
  %r21 = getelementptr [3 x i8], [3 x i8]* @.str.214, i64 0, i64 0
  %r22 = ptrtoint i8* %r21 to i64
  store i64 %r22, i64* %ptr_op
  %r23 = load i64, i64* %ptr_t
  %r24 = getelementptr [5 x i8], [5 x i8]* @.str.215, i64 0, i64 0
  %r25 = ptrtoint i8* %r24 to i64
  %r26 = call i64 @_get(i64 %r23, i64 %r25)
  %r27 = load i64, i64* @TOK_OR
  %r28 = call i64 @_eq(i64 %r26, i64 %r27)
  %r29 = icmp ne i64 %r28, 0
  br i1 %r29, label %L562, label %L563
L562:
  %r30 = getelementptr [4 x i8], [4 x i8]* @.str.216, i64 0, i64 0
  %r31 = ptrtoint i8* %r30 to i64
  store i64 %r31, i64* %ptr_op
  br label %L564
L563:
  br label %L564
L564:
  %r32 = call i64 @advance()
  %r33 = call i64 @parse_cmp()
  store i64 %r33, i64* %ptr_right
  %r34 = call i64 @_map_new()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.217, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r34, i64 %r36, i64 %r37)
  %r38 = getelementptr [3 x i8], [3 x i8]* @.str.218, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r34, i64 %r39, i64 %r40)
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.219, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r34, i64 %r42, i64 %r43)
  %r44 = getelementptr [6 x i8], [6 x i8]* @.str.220, i64 0, i64 0
  %r45 = ptrtoint i8* %r44 to i64
  %r46 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r34, i64 %r45, i64 %r46)
  store i64 %r34, i64* %ptr_left
  %r47 = call i64 @peek()
  store i64 %r47, i64* %ptr_t
  br label %L561
L560:
  store i64 0, i64* %ptr_running
  br label %L561
L561:
  br label %L553
L555:
  %r48 = load i64, i64* %ptr_left
  ret i64 %r48
  ret i64 0
}
define i64 @parse_stmt() {
  %ptr_t = alloca i64
  %ptr_stmt_type = alloca i64
  %ptr_name = alloca i64
  %ptr_val = alloca i64
  %ptr_cond = alloca i64
  %ptr_body = alloca i64
  %ptr_else_body = alloca i64
  %ptr_params = alloca i64
  %ptr_p = alloca i64
  %ptr_path = alloca i64
  %ptr_next_idx = alloca i64
  %ptr_next = alloca i64
  %ptr_lhs = alloca i64
  %ptr_arr_nm = alloca i64
  %ptr_expr = alloca i64
  %r1 = getelementptr [24 x i8], [24 x i8]* @.str.221, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  call i64 @print_any(i64 %r2)
  %r3 = call i64 @peek()
  store i64 %r3, i64* %ptr_t
  %r4 = sub i64 0, 1
  store i64 %r4, i64* %ptr_stmt_type
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.222, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_LET
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L565, label %L566
L565:
  %r12 = load i64, i64* @STMT_LET
  store i64 %r12, i64* %ptr_stmt_type
  %r13 = load i64, i64* @TOK_LET
  %r14 = call i64 @consume(i64 %r13)
  br label %L567
L566:
  %r15 = load i64, i64* %ptr_t
  %r16 = getelementptr [5 x i8], [5 x i8]* @.str.223, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  %r18 = call i64 @_get(i64 %r15, i64 %r17)
  %r19 = load i64, i64* @TOK_SHARED
  %r20 = call i64 @_eq(i64 %r18, i64 %r19)
  %r21 = icmp ne i64 %r20, 0
  br i1 %r21, label %L568, label %L569
L568:
  %r22 = load i64, i64* @STMT_SHARED
  store i64 %r22, i64* %ptr_stmt_type
  %r23 = load i64, i64* @TOK_SHARED
  %r24 = call i64 @consume(i64 %r23)
  br label %L570
L569:
  %r25 = load i64, i64* %ptr_t
  %r26 = getelementptr [5 x i8], [5 x i8]* @.str.224, i64 0, i64 0
  %r27 = ptrtoint i8* %r26 to i64
  %r28 = call i64 @_get(i64 %r25, i64 %r27)
  %r29 = load i64, i64* @TOK_CONST
  %r30 = call i64 @_eq(i64 %r28, i64 %r29)
  %r31 = icmp ne i64 %r30, 0
  br i1 %r31, label %L571, label %L572
L571:
  %r32 = load i64, i64* @STMT_CONST
  store i64 %r32, i64* %ptr_stmt_type
  %r33 = load i64, i64* @TOK_CONST
  %r34 = call i64 @consume(i64 %r33)
  br label %L573
L572:
  br label %L573
L573:
  br label %L570
L570:
  br label %L567
L567:
  %r35 = load i64, i64* %ptr_stmt_type
  %r36 = sub i64 0, 1
  %r38 = call i64 @_eq(i64 %r35, i64 %r36)
  %r37 = xor i64 %r38, 1
  %r39 = icmp ne i64 %r37, 0
  br i1 %r39, label %L574, label %L575
L574:
  %r40 = call i64 @advance()
  store i64 %r40, i64* %ptr_name
  %r41 = load i64, i64* @TOK_COLON
  %r42 = call i64 @expect(i64 %r41)
  %r43 = call i64 @advance()
  %r44 = load i64, i64* @TOK_ARROW
  %r45 = call i64 @expect(i64 %r44)
  %r46 = call i64 @parse_expr()
  store i64 %r46, i64* %ptr_val
  %r47 = load i64, i64* @TOK_CARET
  %r48 = call i64 @expect(i64 %r47)
  %r49 = call i64 @_map_new()
  %r50 = getelementptr [5 x i8], [5 x i8]* @.str.225, i64 0, i64 0
  %r51 = ptrtoint i8* %r50 to i64
  %r52 = load i64, i64* %ptr_stmt_type
  call i64 @_map_set(i64 %r49, i64 %r51, i64 %r52)
  %r53 = getelementptr [5 x i8], [5 x i8]* @.str.226, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = load i64, i64* %ptr_name
  %r56 = getelementptr [5 x i8], [5 x i8]* @.str.227, i64 0, i64 0
  %r57 = ptrtoint i8* %r56 to i64
  %r58 = call i64 @_get(i64 %r55, i64 %r57)
  call i64 @_map_set(i64 %r49, i64 %r54, i64 %r58)
  %r59 = getelementptr [4 x i8], [4 x i8]* @.str.228, i64 0, i64 0
  %r60 = ptrtoint i8* %r59 to i64
  %r61 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r49, i64 %r60, i64 %r61)
  ret i64 %r49
  br label %L576
L575:
  br label %L576
L576:
  %r62 = load i64, i64* @TOK_PRINT
  %r63 = call i64 @consume(i64 %r62)
  %r64 = icmp ne i64 %r63, 0
  br i1 %r64, label %L577, label %L578
L577:
  %r65 = load i64, i64* @TOK_LPAREN
  %r66 = call i64 @expect(i64 %r65)
  %r67 = call i64 @parse_expr()
  store i64 %r67, i64* %ptr_val
  %r68 = load i64, i64* @TOK_RPAREN
  %r69 = call i64 @expect(i64 %r68)
  %r70 = load i64, i64* @TOK_CARET
  %r71 = call i64 @expect(i64 %r70)
  %r72 = call i64 @_map_new()
  %r73 = getelementptr [5 x i8], [5 x i8]* @.str.229, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = load i64, i64* @STMT_PRINT
  call i64 @_map_set(i64 %r72, i64 %r74, i64 %r75)
  %r76 = getelementptr [4 x i8], [4 x i8]* @.str.230, i64 0, i64 0
  %r77 = ptrtoint i8* %r76 to i64
  %r78 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r72, i64 %r77, i64 %r78)
  ret i64 %r72
  br label %L579
L578:
  br label %L579
L579:
  %r79 = load i64, i64* @TOK_IF
  %r80 = call i64 @consume(i64 %r79)
  %r81 = icmp ne i64 %r80, 0
  br i1 %r81, label %L580, label %L581
L580:
  %r82 = load i64, i64* @TOK_LPAREN
  %r83 = call i64 @expect(i64 %r82)
  %r84 = call i64 @parse_expr()
  store i64 %r84, i64* %ptr_cond
  %r85 = load i64, i64* @TOK_RPAREN
  %r86 = call i64 @expect(i64 %r85)
  %r87 = load i64, i64* @TOK_LBRACE
  %r88 = call i64 @expect(i64 %r87)
  %r89 = call i64 @_list_new()
  store i64 %r89, i64* %ptr_body
  br label %L583
L583:
  %r90 = call i64 @peek()
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.231, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = load i64, i64* @TOK_RBRACE
  %r96 = call i64 @_eq(i64 %r93, i64 %r94)
  %r95 = xor i64 %r96, 1
  %r97 = icmp ne i64 %r95, 0
  br i1 %r97, label %L584, label %L585
L584:
  %r98 = call i64 @parse_stmt()
  %r99 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r99, i64 %r98)
  br label %L583
L585:
  %r100 = load i64, i64* @TOK_RBRACE
  %r101 = call i64 @expect(i64 %r100)
  %r102 = call i64 @_list_new()
  store i64 %r102, i64* %ptr_else_body
  %r103 = load i64, i64* @TOK_ELSE
  %r104 = call i64 @consume(i64 %r103)
  %r105 = icmp ne i64 %r104, 0
  br i1 %r105, label %L586, label %L587
L586:
  %r106 = load i64, i64* @TOK_LBRACE
  %r107 = call i64 @expect(i64 %r106)
  br label %L589
L589:
  %r108 = call i64 @peek()
  %r109 = getelementptr [5 x i8], [5 x i8]* @.str.232, i64 0, i64 0
  %r110 = ptrtoint i8* %r109 to i64
  %r111 = call i64 @_get(i64 %r108, i64 %r110)
  %r112 = load i64, i64* @TOK_RBRACE
  %r114 = call i64 @_eq(i64 %r111, i64 %r112)
  %r113 = xor i64 %r114, 1
  %r115 = icmp ne i64 %r113, 0
  br i1 %r115, label %L590, label %L591
L590:
  %r116 = call i64 @parse_stmt()
  %r117 = load i64, i64* %ptr_else_body
  call i64 @_append_poly(i64 %r117, i64 %r116)
  br label %L589
L591:
  %r118 = load i64, i64* @TOK_RBRACE
  %r119 = call i64 @expect(i64 %r118)
  br label %L588
L587:
  br label %L588
L588:
  %r120 = call i64 @_map_new()
  %r121 = getelementptr [5 x i8], [5 x i8]* @.str.233, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = load i64, i64* @STMT_IF
  call i64 @_map_set(i64 %r120, i64 %r122, i64 %r123)
  %r124 = getelementptr [5 x i8], [5 x i8]* @.str.234, i64 0, i64 0
  %r125 = ptrtoint i8* %r124 to i64
  %r126 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r120, i64 %r125, i64 %r126)
  %r127 = getelementptr [5 x i8], [5 x i8]* @.str.235, i64 0, i64 0
  %r128 = ptrtoint i8* %r127 to i64
  %r129 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r120, i64 %r128, i64 %r129)
  %r130 = getelementptr [5 x i8], [5 x i8]* @.str.236, i64 0, i64 0
  %r131 = ptrtoint i8* %r130 to i64
  %r132 = load i64, i64* %ptr_else_body
  call i64 @_map_set(i64 %r120, i64 %r131, i64 %r132)
  ret i64 %r120
  br label %L582
L581:
  br label %L582
L582:
  %r133 = load i64, i64* @TOK_WHILE
  %r134 = call i64 @consume(i64 %r133)
  %r135 = icmp ne i64 %r134, 0
  br i1 %r135, label %L592, label %L593
L592:
  %r136 = load i64, i64* @TOK_LPAREN
  %r137 = call i64 @expect(i64 %r136)
  %r138 = call i64 @parse_expr()
  store i64 %r138, i64* %ptr_cond
  %r139 = load i64, i64* @TOK_RPAREN
  %r140 = call i64 @expect(i64 %r139)
  %r141 = load i64, i64* @TOK_LBRACE
  %r142 = call i64 @expect(i64 %r141)
  %r143 = call i64 @_list_new()
  store i64 %r143, i64* %ptr_body
  br label %L595
L595:
  %r144 = call i64 @peek()
  %r145 = getelementptr [5 x i8], [5 x i8]* @.str.237, i64 0, i64 0
  %r146 = ptrtoint i8* %r145 to i64
  %r147 = call i64 @_get(i64 %r144, i64 %r146)
  %r148 = load i64, i64* @TOK_RBRACE
  %r150 = call i64 @_eq(i64 %r147, i64 %r148)
  %r149 = xor i64 %r150, 1
  %r151 = icmp ne i64 %r149, 0
  br i1 %r151, label %L596, label %L597
L596:
  %r152 = call i64 @parse_stmt()
  %r153 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r153, i64 %r152)
  br label %L595
L597:
  %r154 = load i64, i64* @TOK_RBRACE
  %r155 = call i64 @expect(i64 %r154)
  %r156 = call i64 @_map_new()
  %r157 = getelementptr [5 x i8], [5 x i8]* @.str.238, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = load i64, i64* @STMT_WHILE
  call i64 @_map_set(i64 %r156, i64 %r158, i64 %r159)
  %r160 = getelementptr [5 x i8], [5 x i8]* @.str.239, i64 0, i64 0
  %r161 = ptrtoint i8* %r160 to i64
  %r162 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r156, i64 %r161, i64 %r162)
  %r163 = getelementptr [5 x i8], [5 x i8]* @.str.240, i64 0, i64 0
  %r164 = ptrtoint i8* %r163 to i64
  %r165 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r156, i64 %r164, i64 %r165)
  ret i64 %r156
  br label %L594
L593:
  br label %L594
L594:
  %r166 = load i64, i64* @TOK_OPUS
  %r167 = call i64 @consume(i64 %r166)
  %r168 = icmp ne i64 %r167, 0
  br i1 %r168, label %L598, label %L599
L598:
  %r169 = call i64 @advance()
  store i64 %r169, i64* %ptr_name
  %r170 = load i64, i64* @TOK_LPAREN
  %r171 = call i64 @expect(i64 %r170)
  %r172 = call i64 @_list_new()
  store i64 %r172, i64* %ptr_params
  %r173 = call i64 @peek()
  %r174 = getelementptr [5 x i8], [5 x i8]* @.str.241, i64 0, i64 0
  %r175 = ptrtoint i8* %r174 to i64
  %r176 = call i64 @_get(i64 %r173, i64 %r175)
  %r177 = load i64, i64* @TOK_RPAREN
  %r179 = call i64 @_eq(i64 %r176, i64 %r177)
  %r178 = xor i64 %r179, 1
  %r180 = icmp ne i64 %r178, 0
  br i1 %r180, label %L601, label %L602
L601:
  %r181 = call i64 @advance()
  store i64 %r181, i64* %ptr_p
  %r182 = load i64, i64* %ptr_p
  %r183 = getelementptr [5 x i8], [5 x i8]* @.str.242, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_get(i64 %r182, i64 %r184)
  %r186 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r186, i64 %r185)
  br label %L604
L604:
  %r187 = load i64, i64* @TOK_COMMA
  %r188 = call i64 @consume(i64 %r187)
  %r189 = icmp ne i64 %r188, 0
  br i1 %r189, label %L605, label %L606
L605:
  %r190 = call i64 @advance()
  store i64 %r190, i64* %ptr_p
  %r191 = load i64, i64* %ptr_p
  %r192 = getelementptr [5 x i8], [5 x i8]* @.str.243, i64 0, i64 0
  %r193 = ptrtoint i8* %r192 to i64
  %r194 = call i64 @_get(i64 %r191, i64 %r193)
  %r195 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r195, i64 %r194)
  br label %L604
L606:
  br label %L603
L602:
  br label %L603
L603:
  %r196 = load i64, i64* @TOK_RPAREN
  %r197 = call i64 @expect(i64 %r196)
  %r198 = load i64, i64* @TOK_LBRACE
  %r199 = call i64 @expect(i64 %r198)
  %r200 = call i64 @_list_new()
  store i64 %r200, i64* %ptr_body
  br label %L607
L607:
  %r201 = call i64 @peek()
  %r202 = getelementptr [5 x i8], [5 x i8]* @.str.244, i64 0, i64 0
  %r203 = ptrtoint i8* %r202 to i64
  %r204 = call i64 @_get(i64 %r201, i64 %r203)
  %r205 = load i64, i64* @TOK_RBRACE
  %r207 = call i64 @_eq(i64 %r204, i64 %r205)
  %r206 = xor i64 %r207, 1
  %r208 = icmp ne i64 %r206, 0
  br i1 %r208, label %L608, label %L609
L608:
  %r209 = call i64 @parse_stmt()
  %r210 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r210, i64 %r209)
  br label %L607
L609:
  %r211 = load i64, i64* @TOK_RBRACE
  %r212 = call i64 @expect(i64 %r211)
  %r213 = call i64 @_map_new()
  %r214 = getelementptr [5 x i8], [5 x i8]* @.str.245, i64 0, i64 0
  %r215 = ptrtoint i8* %r214 to i64
  %r216 = load i64, i64* @STMT_FUNC
  call i64 @_map_set(i64 %r213, i64 %r215, i64 %r216)
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.246, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = load i64, i64* %ptr_name
  %r220 = getelementptr [5 x i8], [5 x i8]* @.str.247, i64 0, i64 0
  %r221 = ptrtoint i8* %r220 to i64
  %r222 = call i64 @_get(i64 %r219, i64 %r221)
  call i64 @_map_set(i64 %r213, i64 %r218, i64 %r222)
  %r223 = getelementptr [7 x i8], [7 x i8]* @.str.248, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = load i64, i64* %ptr_params
  call i64 @_map_set(i64 %r213, i64 %r224, i64 %r225)
  %r226 = getelementptr [5 x i8], [5 x i8]* @.str.249, i64 0, i64 0
  %r227 = ptrtoint i8* %r226 to i64
  %r228 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r213, i64 %r227, i64 %r228)
  ret i64 %r213
  br label %L600
L599:
  br label %L600
L600:
  %r229 = load i64, i64* @TOK_REDDO
  %r230 = call i64 @consume(i64 %r229)
  %r231 = icmp ne i64 %r230, 0
  br i1 %r231, label %L610, label %L611
L610:
  %r232 = call i64 @parse_expr()
  store i64 %r232, i64* %ptr_val
  %r233 = load i64, i64* @TOK_CARET
  %r234 = call i64 @expect(i64 %r233)
  %r235 = call i64 @_map_new()
  %r236 = getelementptr [5 x i8], [5 x i8]* @.str.250, i64 0, i64 0
  %r237 = ptrtoint i8* %r236 to i64
  %r238 = load i64, i64* @STMT_RETURN
  call i64 @_map_set(i64 %r235, i64 %r237, i64 %r238)
  %r239 = getelementptr [4 x i8], [4 x i8]* @.str.251, i64 0, i64 0
  %r240 = ptrtoint i8* %r239 to i64
  %r241 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r235, i64 %r240, i64 %r241)
  ret i64 %r235
  br label %L612
L611:
  br label %L612
L612:
  %r242 = load i64, i64* @TOK_BREAK
  %r243 = call i64 @consume(i64 %r242)
  %r244 = icmp ne i64 %r243, 0
  br i1 %r244, label %L613, label %L614
L613:
  %r245 = load i64, i64* @TOK_CARET
  %r246 = call i64 @expect(i64 %r245)
  %r247 = call i64 @_map_new()
  %r248 = getelementptr [5 x i8], [5 x i8]* @.str.252, i64 0, i64 0
  %r249 = ptrtoint i8* %r248 to i64
  %r250 = load i64, i64* @STMT_BREAK
  call i64 @_map_set(i64 %r247, i64 %r249, i64 %r250)
  ret i64 %r247
  br label %L615
L614:
  br label %L615
L615:
  %r251 = load i64, i64* @TOK_CONTINUE
  %r252 = call i64 @consume(i64 %r251)
  %r253 = icmp ne i64 %r252, 0
  br i1 %r253, label %L616, label %L617
L616:
  %r254 = load i64, i64* @TOK_CARET
  %r255 = call i64 @expect(i64 %r254)
  %r256 = call i64 @_map_new()
  %r257 = getelementptr [5 x i8], [5 x i8]* @.str.253, i64 0, i64 0
  %r258 = ptrtoint i8* %r257 to i64
  %r259 = load i64, i64* @STMT_CONTINUE
  call i64 @_map_set(i64 %r256, i64 %r258, i64 %r259)
  ret i64 %r256
  br label %L618
L617:
  br label %L618
L618:
  %r260 = load i64, i64* @TOK_IMPORT
  %r261 = call i64 @consume(i64 %r260)
  %r262 = icmp ne i64 %r261, 0
  br i1 %r262, label %L619, label %L620
L619:
  %r263 = load i64, i64* @TOK_LPAREN
  %r264 = call i64 @expect(i64 %r263)
  %r265 = call i64 @parse_expr()
  store i64 %r265, i64* %ptr_path
  %r266 = load i64, i64* @TOK_RPAREN
  %r267 = call i64 @expect(i64 %r266)
  %r268 = load i64, i64* @TOK_CARET
  %r269 = call i64 @expect(i64 %r268)
  %r270 = call i64 @_map_new()
  %r271 = getelementptr [5 x i8], [5 x i8]* @.str.254, i64 0, i64 0
  %r272 = ptrtoint i8* %r271 to i64
  %r273 = load i64, i64* @STMT_IMPORT
  call i64 @_map_set(i64 %r270, i64 %r272, i64 %r273)
  %r274 = getelementptr [4 x i8], [4 x i8]* @.str.255, i64 0, i64 0
  %r275 = ptrtoint i8* %r274 to i64
  %r276 = load i64, i64* %ptr_path
  call i64 @_map_set(i64 %r270, i64 %r275, i64 %r276)
  ret i64 %r270
  br label %L621
L620:
  br label %L621
L621:
  %r277 = load i64, i64* %ptr_t
  %r278 = getelementptr [5 x i8], [5 x i8]* @.str.256, i64 0, i64 0
  %r279 = ptrtoint i8* %r278 to i64
  %r280 = call i64 @_get(i64 %r277, i64 %r279)
  %r281 = load i64, i64* @TOK_IDENT
  %r282 = call i64 @_eq(i64 %r280, i64 %r281)
  %r283 = icmp ne i64 %r282, 0
  br i1 %r283, label %L622, label %L623
L622:
  %r284 = load i64, i64* @p_pos
  %r285 = call i64 @_add(i64 %r284, i64 1)
  store i64 %r285, i64* %ptr_next_idx
  %r286 = load i64, i64* %ptr_next_idx
  %r287 = load i64, i64* @global_tokens
  %r288 = call i64 @mensura(i64 %r287)
  %r290 = icmp sge i64 %r286, %r288
  %r289 = zext i1 %r290 to i64
  %r291 = icmp ne i64 %r289, 0
  br i1 %r291, label %L625, label %L626
L625:
  %r292 = getelementptr [15 x i8], [15 x i8]* @.str.257, i64 0, i64 0
  %r293 = ptrtoint i8* %r292 to i64
  %r294 = call i64 @error_report(i64 %r293)
  %r295 = call i64 @_map_new()
  %r296 = getelementptr [5 x i8], [5 x i8]* @.str.258, i64 0, i64 0
  %r297 = ptrtoint i8* %r296 to i64
  %r298 = sub i64 0, 1
  call i64 @_map_set(i64 %r295, i64 %r297, i64 %r298)
  ret i64 %r295
  br label %L627
L626:
  br label %L627
L627:
  %r299 = load i64, i64* @global_tokens
  %r300 = load i64, i64* %ptr_next_idx
  %r301 = call i64 @_get(i64 %r299, i64 %r300)
  store i64 %r301, i64* %ptr_next
  %r302 = load i64, i64* %ptr_next
  %r303 = getelementptr [5 x i8], [5 x i8]* @.str.259, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_get(i64 %r302, i64 %r304)
  %r306 = load i64, i64* @TOK_ARROW
  %r307 = call i64 @_eq(i64 %r305, i64 %r306)
  %r308 = icmp ne i64 %r307, 0
  br i1 %r308, label %L628, label %L629
L628:
  %r309 = call i64 @advance()
  store i64 %r309, i64* %ptr_name
  %r310 = call i64 @advance()
  %r311 = call i64 @parse_expr()
  store i64 %r311, i64* %ptr_val
  %r312 = load i64, i64* @TOK_CARET
  %r313 = call i64 @expect(i64 %r312)
  %r314 = call i64 @_map_new()
  %r315 = getelementptr [5 x i8], [5 x i8]* @.str.260, i64 0, i64 0
  %r316 = ptrtoint i8* %r315 to i64
  %r317 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r314, i64 %r316, i64 %r317)
  %r318 = getelementptr [5 x i8], [5 x i8]* @.str.261, i64 0, i64 0
  %r319 = ptrtoint i8* %r318 to i64
  %r320 = load i64, i64* %ptr_name
  %r321 = getelementptr [5 x i8], [5 x i8]* @.str.262, i64 0, i64 0
  %r322 = ptrtoint i8* %r321 to i64
  %r323 = call i64 @_get(i64 %r320, i64 %r322)
  call i64 @_map_set(i64 %r314, i64 %r319, i64 %r323)
  %r324 = getelementptr [4 x i8], [4 x i8]* @.str.263, i64 0, i64 0
  %r325 = ptrtoint i8* %r324 to i64
  %r326 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r314, i64 %r325, i64 %r326)
  ret i64 %r314
  br label %L630
L629:
  br label %L630
L630:
  %r327 = load i64, i64* %ptr_next
  %r328 = getelementptr [5 x i8], [5 x i8]* @.str.264, i64 0, i64 0
  %r329 = ptrtoint i8* %r328 to i64
  %r330 = call i64 @_get(i64 %r327, i64 %r329)
  %r331 = load i64, i64* @TOK_APPEND
  %r332 = call i64 @_eq(i64 %r330, i64 %r331)
  %r333 = icmp ne i64 %r332, 0
  br i1 %r333, label %L631, label %L632
L631:
  %r334 = call i64 @advance()
  store i64 %r334, i64* %ptr_name
  %r335 = call i64 @advance()
  %r336 = call i64 @parse_expr()
  store i64 %r336, i64* %ptr_val
  %r337 = load i64, i64* @TOK_CARET
  %r338 = call i64 @expect(i64 %r337)
  %r339 = call i64 @_map_new()
  %r340 = getelementptr [5 x i8], [5 x i8]* @.str.265, i64 0, i64 0
  %r341 = ptrtoint i8* %r340 to i64
  %r342 = load i64, i64* @STMT_APPEND
  call i64 @_map_set(i64 %r339, i64 %r341, i64 %r342)
  %r343 = getelementptr [5 x i8], [5 x i8]* @.str.266, i64 0, i64 0
  %r344 = ptrtoint i8* %r343 to i64
  %r345 = load i64, i64* %ptr_name
  %r346 = getelementptr [5 x i8], [5 x i8]* @.str.267, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = call i64 @_get(i64 %r345, i64 %r347)
  call i64 @_map_set(i64 %r339, i64 %r344, i64 %r348)
  %r349 = getelementptr [4 x i8], [4 x i8]* @.str.268, i64 0, i64 0
  %r350 = ptrtoint i8* %r349 to i64
  %r351 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r339, i64 %r350, i64 %r351)
  ret i64 %r339
  br label %L633
L632:
  br label %L633
L633:
  %r352 = load i64, i64* %ptr_next
  %r353 = getelementptr [5 x i8], [5 x i8]* @.str.269, i64 0, i64 0
  %r354 = ptrtoint i8* %r353 to i64
  %r355 = call i64 @_get(i64 %r352, i64 %r354)
  %r356 = load i64, i64* @TOK_LBRACKET
  %r357 = call i64 @_eq(i64 %r355, i64 %r356)
  %r358 = icmp ne i64 %r357, 0
  br i1 %r358, label %L634, label %L635
L634:
  %r359 = call i64 @parse_expr()
  store i64 %r359, i64* %ptr_lhs
  %r360 = load i64, i64* @TOK_ARROW
  %r361 = call i64 @consume(i64 %r360)
  %r362 = icmp ne i64 %r361, 0
  br i1 %r362, label %L637, label %L638
L637:
  %r363 = call i64 @parse_expr()
  store i64 %r363, i64* %ptr_val
  %r364 = load i64, i64* @TOK_CARET
  %r365 = call i64 @expect(i64 %r364)
  %r366 = load i64, i64* %ptr_lhs
  %r367 = getelementptr [5 x i8], [5 x i8]* @.str.270, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_get(i64 %r366, i64 %r368)
  %r370 = load i64, i64* @EXPR_INDEX
  %r371 = call i64 @_eq(i64 %r369, i64 %r370)
  %r372 = icmp ne i64 %r371, 0
  br i1 %r372, label %L640, label %L641
L640:
  %r373 = load i64, i64* %ptr_lhs
  %r374 = getelementptr [4 x i8], [4 x i8]* @.str.271, i64 0, i64 0
  %r375 = ptrtoint i8* %r374 to i64
  %r376 = call i64 @_get(i64 %r373, i64 %r375)
  store i64 %r376, i64* %ptr_arr_nm
  %r377 = call i64 @_map_new()
  %r378 = getelementptr [5 x i8], [5 x i8]* @.str.272, i64 0, i64 0
  %r379 = ptrtoint i8* %r378 to i64
  %r380 = load i64, i64* @STMT_SET_INDEX
  call i64 @_map_set(i64 %r377, i64 %r379, i64 %r380)
  %r381 = getelementptr [5 x i8], [5 x i8]* @.str.273, i64 0, i64 0
  %r382 = ptrtoint i8* %r381 to i64
  %r383 = load i64, i64* %ptr_arr_nm
  %r384 = getelementptr [5 x i8], [5 x i8]* @.str.274, i64 0, i64 0
  %r385 = ptrtoint i8* %r384 to i64
  %r386 = call i64 @_get(i64 %r383, i64 %r385)
  call i64 @_map_set(i64 %r377, i64 %r382, i64 %r386)
  %r387 = getelementptr [4 x i8], [4 x i8]* @.str.275, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = load i64, i64* %ptr_lhs
  %r390 = getelementptr [4 x i8], [4 x i8]* @.str.276, i64 0, i64 0
  %r391 = ptrtoint i8* %r390 to i64
  %r392 = call i64 @_get(i64 %r389, i64 %r391)
  call i64 @_map_set(i64 %r377, i64 %r388, i64 %r392)
  %r393 = getelementptr [4 x i8], [4 x i8]* @.str.277, i64 0, i64 0
  %r394 = ptrtoint i8* %r393 to i64
  %r395 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r377, i64 %r394, i64 %r395)
  ret i64 %r377
  br label %L642
L641:
  br label %L642
L642:
  br label %L639
L638:
  br label %L639
L639:
  br label %L636
L635:
  br label %L636
L636:
  %r396 = load i64, i64* %ptr_next
  %r397 = getelementptr [5 x i8], [5 x i8]* @.str.278, i64 0, i64 0
  %r398 = ptrtoint i8* %r397 to i64
  %r399 = call i64 @_get(i64 %r396, i64 %r398)
  %r400 = load i64, i64* @TOK_LPAREN
  %r401 = call i64 @_eq(i64 %r399, i64 %r400)
  %r402 = icmp ne i64 %r401, 0
  br i1 %r402, label %L643, label %L644
L643:
  %r403 = call i64 @parse_expr()
  store i64 %r403, i64* %ptr_expr
  %r404 = load i64, i64* @TOK_CARET
  %r405 = call i64 @expect(i64 %r404)
  %r406 = call i64 @_map_new()
  %r407 = getelementptr [5 x i8], [5 x i8]* @.str.279, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = load i64, i64* @STMT_EXPR
  call i64 @_map_set(i64 %r406, i64 %r408, i64 %r409)
  %r410 = getelementptr [5 x i8], [5 x i8]* @.str.280, i64 0, i64 0
  %r411 = ptrtoint i8* %r410 to i64
  %r412 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r406, i64 %r411, i64 %r412)
  ret i64 %r406
  br label %L645
L644:
  br label %L645
L645:
  br label %L624
L623:
  br label %L624
L624:
  %r413 = load i64, i64* %ptr_t
  %r414 = getelementptr [5 x i8], [5 x i8]* @.str.281, i64 0, i64 0
  %r415 = ptrtoint i8* %r414 to i64
  %r416 = call i64 @_get(i64 %r413, i64 %r415)
  %r417 = load i64, i64* @TOK_EOF
  %r419 = call i64 @_eq(i64 %r416, i64 %r417)
  %r418 = xor i64 %r419, 1
  %r420 = icmp ne i64 %r418, 0
  br i1 %r420, label %L646, label %L647
L646:
  %r421 = call i64 @advance()
  br label %L648
L647:
  br label %L648
L648:
  %r422 = call i64 @_map_new()
  %r423 = getelementptr [5 x i8], [5 x i8]* @.str.282, i64 0, i64 0
  %r424 = ptrtoint i8* %r423 to i64
  %r425 = sub i64 0, 1
  call i64 @_map_set(i64 %r422, i64 %r424, i64 %r425)
  ret i64 %r422
  ret i64 0
}
define i64 @next_reg() {
  %r1 = load i64, i64* @reg_count
  %r2 = call i64 @_add(i64 %r1, i64 1)
  store i64 %r2, i64* @reg_count
  %r3 = getelementptr [3 x i8], [3 x i8]* @.str.283, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = load i64, i64* @reg_count
  %r6 = call i64 @int_to_str(i64 %r5)
  %r7 = call i64 @_add(i64 %r4, i64 %r6)
  ret i64 %r7
  ret i64 0
}
define i64 @next_label() {
  %r1 = load i64, i64* @label_count
  %r2 = call i64 @_add(i64 %r1, i64 1)
  store i64 %r2, i64* @label_count
  %r3 = getelementptr [2 x i8], [2 x i8]* @.str.284, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = load i64, i64* @label_count
  %r6 = call i64 @int_to_str(i64 %r5)
  %r7 = call i64 @_add(i64 %r4, i64 %r6)
  ret i64 %r7
  ret i64 0
}
define i64 @emit(i64 %arg_s) {
  %ptr_s = alloca i64
  store i64 %arg_s, i64* %ptr_s
  %r1 = load i64, i64* @out_code
  %r2 = getelementptr [3 x i8], [3 x i8]* @.str.285, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_add(i64 %r1, i64 %r3)
  %r5 = load i64, i64* %ptr_s
  %r6 = call i64 @_add(i64 %r4, i64 %r5)
  %r7 = call i64 @signum_ex(i64 10)
  %r8 = call i64 @_add(i64 %r6, i64 %r7)
  store i64 %r8, i64* @out_code
  ret i64 0
}
define i64 @emit_raw(i64 %arg_s) {
  %ptr_s = alloca i64
  store i64 %arg_s, i64* %ptr_s
  %r1 = load i64, i64* @out_code
  %r2 = load i64, i64* %ptr_s
  %r3 = call i64 @_add(i64 %r1, i64 %r2)
  %r4 = call i64 @signum_ex(i64 10)
  %r5 = call i64 @_add(i64 %r3, i64 %r4)
  store i64 %r5, i64* @out_code
  ret i64 0
}
define i64 @escape_llvm(i64 %arg_s) {
  %ptr_s = alloca i64
  store i64 %arg_s, i64* %ptr_s
  %ptr_out = alloca i64
  %ptr_len = alloca i64
  %ptr_i = alloca i64
  %ptr_c = alloca i64
  %r1 = getelementptr [1 x i8], [1 x i8]* @.str.286, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  store i64 %r2, i64* %ptr_out
  %r3 = load i64, i64* %ptr_s
  %r4 = call i64 @mensura(i64 %r3)
  store i64 %r4, i64* %ptr_len
  store i64 0, i64* %ptr_i
  br label %L649
L649:
  %r5 = load i64, i64* %ptr_i
  %r6 = load i64, i64* %ptr_len
  %r8 = icmp slt i64 %r5, %r6
  %r7 = zext i1 %r8 to i64
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L650, label %L651
L650:
  %r10 = load i64, i64* %ptr_s
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @pars(i64 %r10, i64 %r11, i64 1)
  store i64 %r12, i64* %ptr_c
  %r13 = load i64, i64* %ptr_c
  %r14 = getelementptr [2 x i8], [2 x i8]* @.str.287, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_eq(i64 %r13, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L652, label %L653
L652:
  %r18 = load i64, i64* %ptr_out
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.288, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  store i64 %r21, i64* %ptr_out
  br label %L654
L653:
  %r22 = load i64, i64* %ptr_c
  %r23 = getelementptr [2 x i8], [2 x i8]* @.str.289, i64 0, i64 0
  %r24 = ptrtoint i8* %r23 to i64
  %r25 = call i64 @_eq(i64 %r22, i64 %r24)
  %r26 = icmp ne i64 %r25, 0
  br i1 %r26, label %L655, label %L656
L655:
  %r27 = load i64, i64* %ptr_out
  %r28 = getelementptr [4 x i8], [4 x i8]* @.str.290, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = call i64 @_add(i64 %r27, i64 %r29)
  store i64 %r30, i64* %ptr_out
  br label %L657
L656:
  %r31 = load i64, i64* %ptr_c
  %r32 = call i64 @codex(i64 %r31)
  %r33 = call i64 @_eq(i64 %r32, i64 10)
  %r34 = icmp ne i64 %r33, 0
  br i1 %r34, label %L658, label %L659
L658:
  %r35 = load i64, i64* %ptr_out
  %r36 = getelementptr [4 x i8], [4 x i8]* @.str.291, i64 0, i64 0
  %r37 = ptrtoint i8* %r36 to i64
  %r38 = call i64 @_add(i64 %r35, i64 %r37)
  store i64 %r38, i64* %ptr_out
  br label %L660
L659:
  %r39 = load i64, i64* %ptr_out
  %r40 = load i64, i64* %ptr_c
  %r41 = call i64 @_add(i64 %r39, i64 %r40)
  store i64 %r41, i64* %ptr_out
  br label %L660
L660:
  br label %L657
L657:
  br label %L654
L654:
  %r42 = load i64, i64* %ptr_i
  %r43 = call i64 @_add(i64 %r42, i64 1)
  store i64 %r43, i64* %ptr_i
  br label %L649
L651:
  %r44 = load i64, i64* %ptr_out
  ret i64 %r44
  ret i64 0
}
define i64 @add_global_string(i64 %arg_txt) {
  %ptr_txt = alloca i64
  store i64 %arg_txt, i64* %ptr_txt
  %ptr_name = alloca i64
  %ptr_len = alloca i64
  %ptr_safe_txt = alloca i64
  %ptr_decl = alloca i64
  %r1 = load i64, i64* @str_count
  %r2 = call i64 @_add(i64 %r1, i64 1)
  store i64 %r2, i64* @str_count
  %r3 = getelementptr [7 x i8], [7 x i8]* @.str.292, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = load i64, i64* @str_count
  %r6 = call i64 @int_to_str(i64 %r5)
  %r7 = call i64 @_add(i64 %r4, i64 %r6)
  store i64 %r7, i64* %ptr_name
  %r8 = load i64, i64* %ptr_txt
  %r9 = call i64 @mensura(i64 %r8)
  %r10 = call i64 @_add(i64 %r9, i64 1)
  store i64 %r10, i64* %ptr_len
  %r11 = load i64, i64* %ptr_txt
  %r12 = call i64 @escape_llvm(i64 %r11)
  store i64 %r12, i64* %ptr_safe_txt
  %r13 = load i64, i64* %ptr_name
  %r14 = getelementptr [35 x i8], [35 x i8]* @.str.293, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_add(i64 %r13, i64 %r15)
  %r17 = load i64, i64* %ptr_len
  %r18 = call i64 @int_to_str(i64 %r17)
  %r19 = call i64 @_add(i64 %r16, i64 %r18)
  %r20 = getelementptr [10 x i8], [10 x i8]* @.str.294, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_add(i64 %r19, i64 %r21)
  %r23 = load i64, i64* %ptr_safe_txt
  %r24 = call i64 @_add(i64 %r22, i64 %r23)
  %r25 = getelementptr [14 x i8], [14 x i8]* @.str.295, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = call i64 @_add(i64 %r24, i64 %r26)
  %r28 = call i64 @signum_ex(i64 10)
  %r29 = call i64 @_add(i64 %r27, i64 %r28)
  store i64 %r29, i64* %ptr_decl
  %r30 = load i64, i64* @out_data
  %r31 = load i64, i64* %ptr_decl
  %r32 = call i64 @_add(i64 %r30, i64 %r31)
  store i64 %r32, i64* @out_data
  %r33 = load i64, i64* %ptr_name
  ret i64 %r33
  ret i64 0
}
define i64 @get_var_ptr(i64 %arg_name) {
  %ptr_name = alloca i64
  store i64 %arg_name, i64* %ptr_name
  %ptr_ptr = alloca i64
  %r1 = load i64, i64* @var_map
  %r2 = load i64, i64* %ptr_name
  %r3 = call i64 @_get(i64 %r1, i64 %r2)
  store i64 %r3, i64* %ptr_ptr
  %r4 = load i64, i64* %ptr_ptr
  %r5 = call i64 @mensura(i64 %r4)
  %r7 = icmp sgt i64 %r5, 0
  %r6 = zext i1 %r7 to i64
  %r8 = icmp ne i64 %r6, 0
  br i1 %r8, label %L661, label %L662
L661:
  %r9 = load i64, i64* %ptr_ptr
  ret i64 %r9
  br label %L663
L662:
  br label %L663
L663:
  %r10 = load i64, i64* @global_map
  %r11 = load i64, i64* %ptr_name
  %r12 = call i64 @_get(i64 %r10, i64 %r11)
  store i64 %r12, i64* %ptr_ptr
  %r13 = load i64, i64* %ptr_ptr
  %r14 = call i64 @mensura(i64 %r13)
  %r16 = icmp sgt i64 %r14, 0
  %r15 = zext i1 %r16 to i64
  %r17 = icmp ne i64 %r15, 0
  br i1 %r17, label %L664, label %L665
L664:
  %r18 = load i64, i64* %ptr_ptr
  ret i64 %r18
  br label %L666
L665:
  br label %L666
L666:
  %r19 = getelementptr [1 x i8], [1 x i8]* @.str.296, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  ret i64 %r20
  ret i64 0
}
define i64 @compile_expr(i64 %arg_node) {
  %ptr_node = alloca i64
  store i64 %arg_node, i64* %ptr_node
  %ptr_ptr = alloca i64
  %ptr_res = alloca i64
  %ptr_global_ptr = alloca i64
  %ptr_len = alloca i64
  %ptr_cast_res = alloca i64
  %ptr_lhs = alloca i64
  %ptr_rhs = alloca i64
  %ptr_op = alloca i64
  %ptr_defined = alloca i64
  %ptr_tmp = alloca i64
  %ptr_cmp = alloca i64
  %ptr_b = alloca i64
  %ptr_items = alloca i64
  %ptr_i = alloca i64
  %ptr_val = alloca i64
  %ptr_keys = alloca i64
  %ptr_vals = alloca i64
  %ptr_k = alloca i64
  %ptr_key_ptr = alloca i64
  %ptr_key_reg = alloca i64
  %ptr_key_int = alloca i64
  %ptr_v = alloca i64
  %ptr_val_reg = alloca i64
  %ptr_obj_node = alloca i64
  %ptr_idx_node = alloca i64
  %ptr_obj_reg = alloca i64
  %ptr_idx_reg = alloca i64
  %ptr_name = alloca i64
  %ptr_addr_reg = alloca i64
  %ptr_ptr_reg = alloca i64
  %ptr_mem_res = alloca i64
  %ptr_trunc_reg = alloca i64
  %ptr_args = alloca i64
  %ptr_a0 = alloca i64
  %ptr_a1 = alloca i64
  %ptr_a2 = alloca i64
  %ptr_a3 = alloca i64
  %ptr_a4 = alloca i64
  %ptr_a5 = alloca i64
  %ptr_a6 = alloca i64
  %ptr_arg_idx = alloca i64
  %ptr_arg_str = alloca i64
  %r1 = load i64, i64* %ptr_node
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.297, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @EXPR_INT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L667, label %L668
L667:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.298, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  ret i64 %r11
  br label %L669
L668:
  br label %L669
L669:
  %r12 = load i64, i64* %ptr_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.299, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_VAR
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L670, label %L671
L670:
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [5 x i8], [5 x i8]* @.str.300, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @get_var_ptr(i64 %r22)
  store i64 %r23, i64* %ptr_ptr
  %r24 = load i64, i64* %ptr_ptr
  %r25 = call i64 @mensura(i64 %r24)
  %r26 = call i64 @_eq(i64 %r25, i64 0)
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L673, label %L674
L673:
  %r28 = getelementptr [33 x i8], [33 x i8]* @.str.301, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_node
  %r31 = getelementptr [5 x i8], [5 x i8]* @.str.302, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = call i64 @_get(i64 %r30, i64 %r32)
  %r34 = call i64 @_add(i64 %r29, i64 %r33)
  %r35 = getelementptr [2 x i8], [2 x i8]* @.str.303, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  call i64 @print_any(i64 %r37)
  %r38 = getelementptr [2 x i8], [2 x i8]* @.str.304, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  ret i64 %r39
  br label %L675
L674:
  br label %L675
L675:
  %r40 = call i64 @next_reg()
  store i64 %r40, i64* %ptr_res
  %r41 = load i64, i64* %ptr_res
  %r42 = getelementptr [19 x i8], [19 x i8]* @.str.305, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_add(i64 %r41, i64 %r43)
  %r45 = load i64, i64* %ptr_ptr
  %r46 = call i64 @_add(i64 %r44, i64 %r45)
  %r47 = call i64 @emit(i64 %r46)
  %r48 = load i64, i64* %ptr_res
  ret i64 %r48
  br label %L672
L671:
  br label %L672
L672:
  %r49 = load i64, i64* %ptr_node
  %r50 = getelementptr [5 x i8], [5 x i8]* @.str.306, i64 0, i64 0
  %r51 = ptrtoint i8* %r50 to i64
  %r52 = call i64 @_get(i64 %r49, i64 %r51)
  %r53 = load i64, i64* @EXPR_STRING
  %r54 = call i64 @_eq(i64 %r52, i64 %r53)
  %r55 = icmp ne i64 %r54, 0
  br i1 %r55, label %L676, label %L677
L676:
  %r56 = load i64, i64* %ptr_node
  %r57 = getelementptr [4 x i8], [4 x i8]* @.str.307, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = call i64 @_get(i64 %r56, i64 %r58)
  %r60 = call i64 @add_global_string(i64 %r59)
  store i64 %r60, i64* %ptr_global_ptr
  %r61 = call i64 @next_reg()
  store i64 %r61, i64* %ptr_res
  %r62 = load i64, i64* %ptr_node
  %r63 = getelementptr [4 x i8], [4 x i8]* @.str.308, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = call i64 @_get(i64 %r62, i64 %r64)
  %r66 = call i64 @mensura(i64 %r65)
  %r67 = call i64 @_add(i64 %r66, i64 1)
  store i64 %r67, i64* %ptr_len
  %r68 = load i64, i64* %ptr_res
  %r69 = getelementptr [19 x i8], [19 x i8]* @.str.309, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = call i64 @_add(i64 %r68, i64 %r70)
  %r72 = load i64, i64* %ptr_len
  %r73 = call i64 @int_to_str(i64 %r72)
  %r74 = call i64 @_add(i64 %r71, i64 %r73)
  %r75 = getelementptr [10 x i8], [10 x i8]* @.str.310, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = call i64 @_add(i64 %r74, i64 %r76)
  %r78 = load i64, i64* %ptr_len
  %r79 = call i64 @int_to_str(i64 %r78)
  %r80 = call i64 @_add(i64 %r77, i64 %r79)
  %r81 = getelementptr [9 x i8], [9 x i8]* @.str.311, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_add(i64 %r80, i64 %r82)
  %r84 = load i64, i64* %ptr_global_ptr
  %r85 = call i64 @_add(i64 %r83, i64 %r84)
  %r86 = getelementptr [15 x i8], [15 x i8]* @.str.312, i64 0, i64 0
  %r87 = ptrtoint i8* %r86 to i64
  %r88 = call i64 @_add(i64 %r85, i64 %r87)
  %r89 = call i64 @emit(i64 %r88)
  %r90 = call i64 @next_reg()
  store i64 %r90, i64* %ptr_cast_res
  %r91 = load i64, i64* %ptr_cast_res
  %r92 = getelementptr [17 x i8], [17 x i8]* @.str.313, i64 0, i64 0
  %r93 = ptrtoint i8* %r92 to i64
  %r94 = call i64 @_add(i64 %r91, i64 %r93)
  %r95 = load i64, i64* %ptr_res
  %r96 = call i64 @_add(i64 %r94, i64 %r95)
  %r97 = getelementptr [8 x i8], [8 x i8]* @.str.314, i64 0, i64 0
  %r98 = ptrtoint i8* %r97 to i64
  %r99 = call i64 @_add(i64 %r96, i64 %r98)
  %r100 = call i64 @emit(i64 %r99)
  %r101 = load i64, i64* %ptr_cast_res
  ret i64 %r101
  br label %L678
L677:
  br label %L678
L678:
  %r102 = load i64, i64* %ptr_node
  %r103 = getelementptr [5 x i8], [5 x i8]* @.str.315, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @_get(i64 %r102, i64 %r104)
  %r106 = load i64, i64* @EXPR_BINARY
  %r107 = call i64 @_eq(i64 %r105, i64 %r106)
  %r108 = icmp ne i64 %r107, 0
  br i1 %r108, label %L679, label %L680
L679:
  %r109 = load i64, i64* %ptr_node
  %r110 = getelementptr [5 x i8], [5 x i8]* @.str.316, i64 0, i64 0
  %r111 = ptrtoint i8* %r110 to i64
  %r112 = call i64 @_get(i64 %r109, i64 %r111)
  %r113 = call i64 @compile_expr(i64 %r112)
  store i64 %r113, i64* %ptr_lhs
  %r114 = load i64, i64* %ptr_node
  %r115 = getelementptr [6 x i8], [6 x i8]* @.str.317, i64 0, i64 0
  %r116 = ptrtoint i8* %r115 to i64
  %r117 = call i64 @_get(i64 %r114, i64 %r116)
  %r118 = call i64 @compile_expr(i64 %r117)
  store i64 %r118, i64* %ptr_rhs
  %r119 = load i64, i64* %ptr_node
  %r120 = getelementptr [3 x i8], [3 x i8]* @.str.318, i64 0, i64 0
  %r121 = ptrtoint i8* %r120 to i64
  %r122 = call i64 @_get(i64 %r119, i64 %r121)
  store i64 %r122, i64* %ptr_op
  %r123 = call i64 @next_reg()
  store i64 %r123, i64* %ptr_res
  store i64 0, i64* %ptr_defined
  %r124 = load i64, i64* %ptr_op
  %r125 = getelementptr [2 x i8], [2 x i8]* @.str.319, i64 0, i64 0
  %r126 = ptrtoint i8* %r125 to i64
  %r127 = call i64 @_eq(i64 %r124, i64 %r126)
  %r128 = icmp ne i64 %r127, 0
  br i1 %r128, label %L682, label %L683
L682:
  %r129 = load i64, i64* %ptr_res
  %r130 = getelementptr [23 x i8], [23 x i8]* @.str.320, i64 0, i64 0
  %r131 = ptrtoint i8* %r130 to i64
  %r132 = call i64 @_add(i64 %r129, i64 %r131)
  %r133 = load i64, i64* %ptr_lhs
  %r134 = call i64 @_add(i64 %r132, i64 %r133)
  %r135 = getelementptr [7 x i8], [7 x i8]* @.str.321, i64 0, i64 0
  %r136 = ptrtoint i8* %r135 to i64
  %r137 = call i64 @_add(i64 %r134, i64 %r136)
  %r138 = load i64, i64* %ptr_rhs
  %r139 = call i64 @_add(i64 %r137, i64 %r138)
  %r140 = getelementptr [2 x i8], [2 x i8]* @.str.322, i64 0, i64 0
  %r141 = ptrtoint i8* %r140 to i64
  %r142 = call i64 @_add(i64 %r139, i64 %r141)
  %r143 = call i64 @emit(i64 %r142)
  store i64 1, i64* %ptr_defined
  br label %L684
L683:
  %r144 = load i64, i64* %ptr_op
  %r145 = getelementptr [2 x i8], [2 x i8]* @.str.323, i64 0, i64 0
  %r146 = ptrtoint i8* %r145 to i64
  %r147 = call i64 @_eq(i64 %r144, i64 %r146)
  %r148 = icmp ne i64 %r147, 0
  br i1 %r148, label %L685, label %L686
L685:
  %r149 = load i64, i64* %ptr_res
  %r150 = getelementptr [12 x i8], [12 x i8]* @.str.324, i64 0, i64 0
  %r151 = ptrtoint i8* %r150 to i64
  %r152 = call i64 @_add(i64 %r149, i64 %r151)
  %r153 = load i64, i64* %ptr_lhs
  %r154 = call i64 @_add(i64 %r152, i64 %r153)
  %r155 = getelementptr [3 x i8], [3 x i8]* @.str.325, i64 0, i64 0
  %r156 = ptrtoint i8* %r155 to i64
  %r157 = call i64 @_add(i64 %r154, i64 %r156)
  %r158 = load i64, i64* %ptr_rhs
  %r159 = call i64 @_add(i64 %r157, i64 %r158)
  %r160 = call i64 @emit(i64 %r159)
  store i64 1, i64* %ptr_defined
  br label %L687
L686:
  %r161 = load i64, i64* %ptr_op
  %r162 = getelementptr [2 x i8], [2 x i8]* @.str.326, i64 0, i64 0
  %r163 = ptrtoint i8* %r162 to i64
  %r164 = call i64 @_eq(i64 %r161, i64 %r163)
  %r165 = icmp ne i64 %r164, 0
  br i1 %r165, label %L688, label %L689
L688:
  %r166 = load i64, i64* %ptr_res
  %r167 = getelementptr [12 x i8], [12 x i8]* @.str.327, i64 0, i64 0
  %r168 = ptrtoint i8* %r167 to i64
  %r169 = call i64 @_add(i64 %r166, i64 %r168)
  %r170 = load i64, i64* %ptr_lhs
  %r171 = call i64 @_add(i64 %r169, i64 %r170)
  %r172 = getelementptr [3 x i8], [3 x i8]* @.str.328, i64 0, i64 0
  %r173 = ptrtoint i8* %r172 to i64
  %r174 = call i64 @_add(i64 %r171, i64 %r173)
  %r175 = load i64, i64* %ptr_rhs
  %r176 = call i64 @_add(i64 %r174, i64 %r175)
  %r177 = call i64 @emit(i64 %r176)
  store i64 1, i64* %ptr_defined
  br label %L690
L689:
  %r178 = load i64, i64* %ptr_op
  %r179 = getelementptr [2 x i8], [2 x i8]* @.str.329, i64 0, i64 0
  %r180 = ptrtoint i8* %r179 to i64
  %r181 = call i64 @_eq(i64 %r178, i64 %r180)
  %r182 = icmp ne i64 %r181, 0
  br i1 %r182, label %L691, label %L692
L691:
  %r183 = load i64, i64* %ptr_res
  %r184 = getelementptr [13 x i8], [13 x i8]* @.str.330, i64 0, i64 0
  %r185 = ptrtoint i8* %r184 to i64
  %r186 = call i64 @_add(i64 %r183, i64 %r185)
  %r187 = load i64, i64* %ptr_lhs
  %r188 = call i64 @_add(i64 %r186, i64 %r187)
  %r189 = getelementptr [3 x i8], [3 x i8]* @.str.331, i64 0, i64 0
  %r190 = ptrtoint i8* %r189 to i64
  %r191 = call i64 @_add(i64 %r188, i64 %r190)
  %r192 = load i64, i64* %ptr_rhs
  %r193 = call i64 @_add(i64 %r191, i64 %r192)
  %r194 = call i64 @emit(i64 %r193)
  store i64 1, i64* %ptr_defined
  br label %L693
L692:
  %r195 = load i64, i64* %ptr_op
  %r196 = getelementptr [2 x i8], [2 x i8]* @.str.332, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = call i64 @_eq(i64 %r195, i64 %r197)
  %r199 = icmp ne i64 %r198, 0
  br i1 %r199, label %L694, label %L695
L694:
  %r200 = load i64, i64* %ptr_res
  %r201 = getelementptr [13 x i8], [13 x i8]* @.str.333, i64 0, i64 0
  %r202 = ptrtoint i8* %r201 to i64
  %r203 = call i64 @_add(i64 %r200, i64 %r202)
  %r204 = load i64, i64* %ptr_lhs
  %r205 = call i64 @_add(i64 %r203, i64 %r204)
  %r206 = getelementptr [3 x i8], [3 x i8]* @.str.334, i64 0, i64 0
  %r207 = ptrtoint i8* %r206 to i64
  %r208 = call i64 @_add(i64 %r205, i64 %r207)
  %r209 = load i64, i64* %ptr_rhs
  %r210 = call i64 @_add(i64 %r208, i64 %r209)
  %r211 = call i64 @emit(i64 %r210)
  store i64 1, i64* %ptr_defined
  br label %L696
L695:
  %r212 = load i64, i64* %ptr_op
  %r213 = getelementptr [2 x i8], [2 x i8]* @.str.335, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  %r215 = call i64 @_eq(i64 %r212, i64 %r214)
  %r216 = icmp ne i64 %r215, 0
  br i1 %r216, label %L697, label %L698
L697:
  %r217 = load i64, i64* %ptr_res
  %r218 = getelementptr [12 x i8], [12 x i8]* @.str.336, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @_add(i64 %r217, i64 %r219)
  %r221 = load i64, i64* %ptr_lhs
  %r222 = call i64 @_add(i64 %r220, i64 %r221)
  %r223 = getelementptr [3 x i8], [3 x i8]* @.str.337, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = call i64 @_add(i64 %r222, i64 %r224)
  %r226 = load i64, i64* %ptr_rhs
  %r227 = call i64 @_add(i64 %r225, i64 %r226)
  %r228 = call i64 @emit(i64 %r227)
  store i64 1, i64* %ptr_defined
  br label %L699
L698:
  %r229 = load i64, i64* %ptr_op
  %r230 = getelementptr [2 x i8], [2 x i8]* @.str.338, i64 0, i64 0
  %r231 = ptrtoint i8* %r230 to i64
  %r232 = call i64 @_eq(i64 %r229, i64 %r231)
  %r233 = icmp ne i64 %r232, 0
  br i1 %r233, label %L700, label %L701
L700:
  %r234 = load i64, i64* %ptr_res
  %r235 = getelementptr [11 x i8], [11 x i8]* @.str.339, i64 0, i64 0
  %r236 = ptrtoint i8* %r235 to i64
  %r237 = call i64 @_add(i64 %r234, i64 %r236)
  %r238 = load i64, i64* %ptr_lhs
  %r239 = call i64 @_add(i64 %r237, i64 %r238)
  %r240 = getelementptr [3 x i8], [3 x i8]* @.str.340, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_add(i64 %r239, i64 %r241)
  %r243 = load i64, i64* %ptr_rhs
  %r244 = call i64 @_add(i64 %r242, i64 %r243)
  %r245 = call i64 @emit(i64 %r244)
  store i64 1, i64* %ptr_defined
  br label %L702
L701:
  %r246 = load i64, i64* %ptr_op
  %r247 = getelementptr [2 x i8], [2 x i8]* @.str.341, i64 0, i64 0
  %r248 = ptrtoint i8* %r247 to i64
  %r249 = call i64 @_eq(i64 %r246, i64 %r248)
  %r250 = icmp ne i64 %r249, 0
  br i1 %r250, label %L703, label %L704
L703:
  %r251 = load i64, i64* %ptr_res
  %r252 = getelementptr [12 x i8], [12 x i8]* @.str.342, i64 0, i64 0
  %r253 = ptrtoint i8* %r252 to i64
  %r254 = call i64 @_add(i64 %r251, i64 %r253)
  %r255 = load i64, i64* %ptr_lhs
  %r256 = call i64 @_add(i64 %r254, i64 %r255)
  %r257 = getelementptr [3 x i8], [3 x i8]* @.str.343, i64 0, i64 0
  %r258 = ptrtoint i8* %r257 to i64
  %r259 = call i64 @_add(i64 %r256, i64 %r258)
  %r260 = load i64, i64* %ptr_rhs
  %r261 = call i64 @_add(i64 %r259, i64 %r260)
  %r262 = call i64 @emit(i64 %r261)
  store i64 1, i64* %ptr_defined
  br label %L705
L704:
  %r263 = load i64, i64* %ptr_op
  %r264 = getelementptr [4 x i8], [4 x i8]* @.str.344, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = call i64 @_eq(i64 %r263, i64 %r265)
  %r267 = icmp ne i64 %r266, 0
  br i1 %r267, label %L706, label %L707
L706:
  %r268 = load i64, i64* %ptr_res
  %r269 = getelementptr [12 x i8], [12 x i8]* @.str.345, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @_add(i64 %r268, i64 %r270)
  %r272 = load i64, i64* %ptr_lhs
  %r273 = call i64 @_add(i64 %r271, i64 %r272)
  %r274 = getelementptr [3 x i8], [3 x i8]* @.str.346, i64 0, i64 0
  %r275 = ptrtoint i8* %r274 to i64
  %r276 = call i64 @_add(i64 %r273, i64 %r275)
  %r277 = load i64, i64* %ptr_rhs
  %r278 = call i64 @_add(i64 %r276, i64 %r277)
  %r279 = call i64 @emit(i64 %r278)
  store i64 1, i64* %ptr_defined
  br label %L708
L707:
  %r280 = load i64, i64* %ptr_op
  %r281 = getelementptr [2 x i8], [2 x i8]* @.str.347, i64 0, i64 0
  %r282 = ptrtoint i8* %r281 to i64
  %r283 = call i64 @_eq(i64 %r280, i64 %r282)
  %r284 = icmp ne i64 %r283, 0
  br i1 %r284, label %L709, label %L710
L709:
  %r285 = load i64, i64* %ptr_res
  %r286 = getelementptr [12 x i8], [12 x i8]* @.str.348, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = call i64 @_add(i64 %r285, i64 %r287)
  %r289 = load i64, i64* %ptr_lhs
  %r290 = call i64 @_add(i64 %r288, i64 %r289)
  %r291 = getelementptr [5 x i8], [5 x i8]* @.str.349, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_add(i64 %r290, i64 %r292)
  %r294 = call i64 @emit(i64 %r293)
  store i64 1, i64* %ptr_defined
  br label %L711
L710:
  %r295 = load i64, i64* %ptr_op
  %r296 = getelementptr [4 x i8], [4 x i8]* @.str.350, i64 0, i64 0
  %r297 = ptrtoint i8* %r296 to i64
  %r298 = call i64 @_eq(i64 %r295, i64 %r297)
  %r299 = icmp ne i64 %r298, 0
  br i1 %r299, label %L712, label %L713
L712:
  %r300 = load i64, i64* %ptr_res
  %r301 = getelementptr [12 x i8], [12 x i8]* @.str.351, i64 0, i64 0
  %r302 = ptrtoint i8* %r301 to i64
  %r303 = call i64 @_add(i64 %r300, i64 %r302)
  %r304 = load i64, i64* %ptr_lhs
  %r305 = call i64 @_add(i64 %r303, i64 %r304)
  %r306 = getelementptr [3 x i8], [3 x i8]* @.str.352, i64 0, i64 0
  %r307 = ptrtoint i8* %r306 to i64
  %r308 = call i64 @_add(i64 %r305, i64 %r307)
  %r309 = load i64, i64* %ptr_rhs
  %r310 = call i64 @_add(i64 %r308, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  store i64 1, i64* %ptr_defined
  br label %L714
L713:
  %r312 = load i64, i64* %ptr_op
  %r313 = getelementptr [4 x i8], [4 x i8]* @.str.353, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_eq(i64 %r312, i64 %r314)
  %r316 = icmp ne i64 %r315, 0
  br i1 %r316, label %L715, label %L716
L715:
  %r317 = load i64, i64* %ptr_res
  %r318 = getelementptr [13 x i8], [13 x i8]* @.str.354, i64 0, i64 0
  %r319 = ptrtoint i8* %r318 to i64
  %r320 = call i64 @_add(i64 %r317, i64 %r319)
  %r321 = load i64, i64* %ptr_lhs
  %r322 = call i64 @_add(i64 %r320, i64 %r321)
  %r323 = getelementptr [3 x i8], [3 x i8]* @.str.355, i64 0, i64 0
  %r324 = ptrtoint i8* %r323 to i64
  %r325 = call i64 @_add(i64 %r322, i64 %r324)
  %r326 = load i64, i64* %ptr_rhs
  %r327 = call i64 @_add(i64 %r325, i64 %r326)
  %r328 = call i64 @emit(i64 %r327)
  store i64 1, i64* %ptr_defined
  br label %L717
L716:
  %r329 = load i64, i64* %ptr_op
  %r330 = getelementptr [3 x i8], [3 x i8]* @.str.356, i64 0, i64 0
  %r331 = ptrtoint i8* %r330 to i64
  %r332 = call i64 @_eq(i64 %r329, i64 %r331)
  %r333 = icmp ne i64 %r332, 0
  br i1 %r333, label %L718, label %L719
L718:
  %r334 = load i64, i64* %ptr_res
  %r335 = getelementptr [12 x i8], [12 x i8]* @.str.357, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_add(i64 %r334, i64 %r336)
  %r338 = load i64, i64* %ptr_lhs
  %r339 = call i64 @_add(i64 %r337, i64 %r338)
  %r340 = getelementptr [3 x i8], [3 x i8]* @.str.358, i64 0, i64 0
  %r341 = ptrtoint i8* %r340 to i64
  %r342 = call i64 @_add(i64 %r339, i64 %r341)
  %r343 = load i64, i64* %ptr_rhs
  %r344 = call i64 @_add(i64 %r342, i64 %r343)
  %r345 = call i64 @emit(i64 %r344)
  store i64 1, i64* %ptr_defined
  br label %L720
L719:
  %r346 = load i64, i64* %ptr_op
  %r347 = getelementptr [4 x i8], [4 x i8]* @.str.359, i64 0, i64 0
  %r348 = ptrtoint i8* %r347 to i64
  %r349 = call i64 @_eq(i64 %r346, i64 %r348)
  %r350 = icmp ne i64 %r349, 0
  br i1 %r350, label %L721, label %L722
L721:
  %r351 = load i64, i64* %ptr_res
  %r352 = getelementptr [11 x i8], [11 x i8]* @.str.360, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_add(i64 %r351, i64 %r353)
  %r355 = load i64, i64* %ptr_lhs
  %r356 = call i64 @_add(i64 %r354, i64 %r355)
  %r357 = getelementptr [3 x i8], [3 x i8]* @.str.361, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_add(i64 %r356, i64 %r358)
  %r360 = load i64, i64* %ptr_rhs
  %r361 = call i64 @_add(i64 %r359, i64 %r360)
  %r362 = call i64 @emit(i64 %r361)
  store i64 1, i64* %ptr_defined
  br label %L723
L722:
  br label %L723
L723:
  br label %L720
L720:
  br label %L717
L717:
  br label %L714
L714:
  br label %L711
L711:
  br label %L708
L708:
  br label %L705
L705:
  br label %L702
L702:
  br label %L699
L699:
  br label %L696
L696:
  br label %L693
L693:
  br label %L690
L690:
  br label %L687
L687:
  br label %L684
L684:
  %r363 = load i64, i64* %ptr_defined
  %r364 = call i64 @_eq(i64 %r363, i64 0)
  %r365 = icmp ne i64 %r364, 0
  br i1 %r365, label %L724, label %L725
L724:
  %r366 = load i64, i64* %ptr_op
  %r367 = getelementptr [3 x i8], [3 x i8]* @.str.362, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_eq(i64 %r366, i64 %r368)
  %r370 = icmp ne i64 %r369, 0
  br i1 %r370, label %L727, label %L728
L727:
  %r371 = load i64, i64* %ptr_res
  %r372 = getelementptr [22 x i8], [22 x i8]* @.str.363, i64 0, i64 0
  %r373 = ptrtoint i8* %r372 to i64
  %r374 = call i64 @_add(i64 %r371, i64 %r373)
  %r375 = load i64, i64* %ptr_lhs
  %r376 = call i64 @_add(i64 %r374, i64 %r375)
  %r377 = getelementptr [7 x i8], [7 x i8]* @.str.364, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_rhs
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  %r382 = getelementptr [2 x i8], [2 x i8]* @.str.365, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_add(i64 %r381, i64 %r383)
  %r385 = call i64 @emit(i64 %r384)
  br label %L729
L728:
  %r386 = load i64, i64* %ptr_op
  %r387 = getelementptr [3 x i8], [3 x i8]* @.str.366, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = call i64 @_eq(i64 %r386, i64 %r388)
  %r390 = icmp ne i64 %r389, 0
  br i1 %r390, label %L730, label %L731
L730:
  %r391 = call i64 @next_reg()
  store i64 %r391, i64* %ptr_tmp
  %r392 = load i64, i64* %ptr_tmp
  %r393 = getelementptr [22 x i8], [22 x i8]* @.str.367, i64 0, i64 0
  %r394 = ptrtoint i8* %r393 to i64
  %r395 = call i64 @_add(i64 %r392, i64 %r394)
  %r396 = load i64, i64* %ptr_lhs
  %r397 = call i64 @_add(i64 %r395, i64 %r396)
  %r398 = getelementptr [7 x i8], [7 x i8]* @.str.368, i64 0, i64 0
  %r399 = ptrtoint i8* %r398 to i64
  %r400 = call i64 @_add(i64 %r397, i64 %r399)
  %r401 = load i64, i64* %ptr_rhs
  %r402 = call i64 @_add(i64 %r400, i64 %r401)
  %r403 = getelementptr [2 x i8], [2 x i8]* @.str.369, i64 0, i64 0
  %r404 = ptrtoint i8* %r403 to i64
  %r405 = call i64 @_add(i64 %r402, i64 %r404)
  %r406 = call i64 @emit(i64 %r405)
  %r407 = load i64, i64* %ptr_res
  %r408 = getelementptr [12 x i8], [12 x i8]* @.str.370, i64 0, i64 0
  %r409 = ptrtoint i8* %r408 to i64
  %r410 = call i64 @_add(i64 %r407, i64 %r409)
  %r411 = load i64, i64* %ptr_tmp
  %r412 = call i64 @_add(i64 %r410, i64 %r411)
  %r413 = getelementptr [4 x i8], [4 x i8]* @.str.371, i64 0, i64 0
  %r414 = ptrtoint i8* %r413 to i64
  %r415 = call i64 @_add(i64 %r412, i64 %r414)
  %r416 = call i64 @emit(i64 %r415)
  br label %L732
L731:
  %r417 = getelementptr [1 x i8], [1 x i8]* @.str.372, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  store i64 %r418, i64* %ptr_cmp
  %r419 = load i64, i64* %ptr_op
  %r420 = getelementptr [2 x i8], [2 x i8]* @.str.373, i64 0, i64 0
  %r421 = ptrtoint i8* %r420 to i64
  %r422 = call i64 @_eq(i64 %r419, i64 %r421)
  %r423 = icmp ne i64 %r422, 0
  br i1 %r423, label %L733, label %L734
L733:
  %r424 = getelementptr [4 x i8], [4 x i8]* @.str.374, i64 0, i64 0
  %r425 = ptrtoint i8* %r424 to i64
  store i64 %r425, i64* %ptr_cmp
  br label %L735
L734:
  %r426 = load i64, i64* %ptr_op
  %r427 = getelementptr [2 x i8], [2 x i8]* @.str.375, i64 0, i64 0
  %r428 = ptrtoint i8* %r427 to i64
  %r429 = call i64 @_eq(i64 %r426, i64 %r428)
  %r430 = icmp ne i64 %r429, 0
  br i1 %r430, label %L736, label %L737
L736:
  %r431 = getelementptr [4 x i8], [4 x i8]* @.str.376, i64 0, i64 0
  %r432 = ptrtoint i8* %r431 to i64
  store i64 %r432, i64* %ptr_cmp
  br label %L738
L737:
  %r433 = load i64, i64* %ptr_op
  %r434 = getelementptr [3 x i8], [3 x i8]* @.str.377, i64 0, i64 0
  %r435 = ptrtoint i8* %r434 to i64
  %r436 = call i64 @_eq(i64 %r433, i64 %r435)
  %r437 = icmp ne i64 %r436, 0
  br i1 %r437, label %L739, label %L740
L739:
  %r438 = getelementptr [4 x i8], [4 x i8]* @.str.378, i64 0, i64 0
  %r439 = ptrtoint i8* %r438 to i64
  store i64 %r439, i64* %ptr_cmp
  br label %L741
L740:
  %r440 = load i64, i64* %ptr_op
  %r441 = getelementptr [3 x i8], [3 x i8]* @.str.379, i64 0, i64 0
  %r442 = ptrtoint i8* %r441 to i64
  %r443 = call i64 @_eq(i64 %r440, i64 %r442)
  %r444 = icmp ne i64 %r443, 0
  br i1 %r444, label %L742, label %L743
L742:
  %r445 = getelementptr [4 x i8], [4 x i8]* @.str.380, i64 0, i64 0
  %r446 = ptrtoint i8* %r445 to i64
  store i64 %r446, i64* %ptr_cmp
  br label %L744
L743:
  br label %L744
L744:
  br label %L741
L741:
  br label %L738
L738:
  br label %L735
L735:
  %r447 = load i64, i64* %ptr_cmp
  %r448 = call i64 @mensura(i64 %r447)
  %r450 = icmp sgt i64 %r448, 0
  %r449 = zext i1 %r450 to i64
  %r451 = icmp ne i64 %r449, 0
  br i1 %r451, label %L745, label %L746
L745:
  %r452 = call i64 @next_reg()
  store i64 %r452, i64* %ptr_b
  %r453 = load i64, i64* %ptr_b
  %r454 = getelementptr [9 x i8], [9 x i8]* @.str.381, i64 0, i64 0
  %r455 = ptrtoint i8* %r454 to i64
  %r456 = call i64 @_add(i64 %r453, i64 %r455)
  %r457 = load i64, i64* %ptr_cmp
  %r458 = call i64 @_add(i64 %r456, i64 %r457)
  %r459 = getelementptr [6 x i8], [6 x i8]* @.str.382, i64 0, i64 0
  %r460 = ptrtoint i8* %r459 to i64
  %r461 = call i64 @_add(i64 %r458, i64 %r460)
  %r462 = load i64, i64* %ptr_lhs
  %r463 = call i64 @_add(i64 %r461, i64 %r462)
  %r464 = getelementptr [3 x i8], [3 x i8]* @.str.383, i64 0, i64 0
  %r465 = ptrtoint i8* %r464 to i64
  %r466 = call i64 @_add(i64 %r463, i64 %r465)
  %r467 = load i64, i64* %ptr_rhs
  %r468 = call i64 @_add(i64 %r466, i64 %r467)
  %r469 = call i64 @emit(i64 %r468)
  %r470 = load i64, i64* %ptr_res
  %r471 = getelementptr [12 x i8], [12 x i8]* @.str.384, i64 0, i64 0
  %r472 = ptrtoint i8* %r471 to i64
  %r473 = call i64 @_add(i64 %r470, i64 %r472)
  %r474 = load i64, i64* %ptr_b
  %r475 = call i64 @_add(i64 %r473, i64 %r474)
  %r476 = getelementptr [8 x i8], [8 x i8]* @.str.385, i64 0, i64 0
  %r477 = ptrtoint i8* %r476 to i64
  %r478 = call i64 @_add(i64 %r475, i64 %r477)
  %r479 = call i64 @emit(i64 %r478)
  br label %L747
L746:
  %r480 = load i64, i64* %ptr_res
  %r481 = getelementptr [16 x i8], [16 x i8]* @.str.386, i64 0, i64 0
  %r482 = ptrtoint i8* %r481 to i64
  %r483 = call i64 @_add(i64 %r480, i64 %r482)
  %r484 = call i64 @emit(i64 %r483)
  br label %L747
L747:
  br label %L732
L732:
  br label %L729
L729:
  br label %L726
L725:
  br label %L726
L726:
  %r485 = load i64, i64* %ptr_res
  ret i64 %r485
  br label %L681
L680:
  br label %L681
L681:
  %r486 = load i64, i64* %ptr_node
  %r487 = getelementptr [5 x i8], [5 x i8]* @.str.387, i64 0, i64 0
  %r488 = ptrtoint i8* %r487 to i64
  %r489 = call i64 @_get(i64 %r486, i64 %r488)
  %r490 = load i64, i64* @EXPR_LIST
  %r491 = call i64 @_eq(i64 %r489, i64 %r490)
  %r492 = icmp ne i64 %r491, 0
  br i1 %r492, label %L748, label %L749
L748:
  %r493 = call i64 @next_reg()
  store i64 %r493, i64* %ptr_res
  %r494 = load i64, i64* %ptr_res
  %r495 = getelementptr [25 x i8], [25 x i8]* @.str.388, i64 0, i64 0
  %r496 = ptrtoint i8* %r495 to i64
  %r497 = call i64 @_add(i64 %r494, i64 %r496)
  %r498 = call i64 @emit(i64 %r497)
  %r499 = load i64, i64* %ptr_node
  %r500 = getelementptr [6 x i8], [6 x i8]* @.str.389, i64 0, i64 0
  %r501 = ptrtoint i8* %r500 to i64
  %r502 = call i64 @_get(i64 %r499, i64 %r501)
  store i64 %r502, i64* %ptr_items
  store i64 0, i64* %ptr_i
  br label %L751
L751:
  %r503 = load i64, i64* %ptr_i
  %r504 = load i64, i64* %ptr_items
  %r505 = call i64 @mensura(i64 %r504)
  %r507 = icmp slt i64 %r503, %r505
  %r506 = zext i1 %r507 to i64
  %r508 = icmp ne i64 %r506, 0
  br i1 %r508, label %L752, label %L753
L752:
  %r509 = load i64, i64* %ptr_items
  %r510 = load i64, i64* %ptr_i
  %r511 = call i64 @_get(i64 %r509, i64 %r510)
  %r512 = call i64 @compile_expr(i64 %r511)
  store i64 %r512, i64* %ptr_val
  %r513 = getelementptr [26 x i8], [26 x i8]* @.str.390, i64 0, i64 0
  %r514 = ptrtoint i8* %r513 to i64
  %r515 = load i64, i64* %ptr_res
  %r516 = call i64 @_add(i64 %r514, i64 %r515)
  %r517 = getelementptr [7 x i8], [7 x i8]* @.str.391, i64 0, i64 0
  %r518 = ptrtoint i8* %r517 to i64
  %r519 = call i64 @_add(i64 %r516, i64 %r518)
  %r520 = load i64, i64* %ptr_val
  %r521 = call i64 @_add(i64 %r519, i64 %r520)
  %r522 = getelementptr [2 x i8], [2 x i8]* @.str.392, i64 0, i64 0
  %r523 = ptrtoint i8* %r522 to i64
  %r524 = call i64 @_add(i64 %r521, i64 %r523)
  %r525 = call i64 @emit(i64 %r524)
  %r526 = load i64, i64* %ptr_i
  %r527 = call i64 @_add(i64 %r526, i64 1)
  store i64 %r527, i64* %ptr_i
  br label %L751
L753:
  %r528 = load i64, i64* %ptr_res
  ret i64 %r528
  br label %L750
L749:
  br label %L750
L750:
  %r529 = load i64, i64* %ptr_node
  %r530 = getelementptr [5 x i8], [5 x i8]* @.str.393, i64 0, i64 0
  %r531 = ptrtoint i8* %r530 to i64
  %r532 = call i64 @_get(i64 %r529, i64 %r531)
  %r533 = load i64, i64* @EXPR_MAP
  %r534 = call i64 @_eq(i64 %r532, i64 %r533)
  %r535 = icmp ne i64 %r534, 0
  br i1 %r535, label %L754, label %L755
L754:
  %r536 = call i64 @next_reg()
  store i64 %r536, i64* %ptr_res
  %r537 = load i64, i64* %ptr_res
  %r538 = getelementptr [24 x i8], [24 x i8]* @.str.394, i64 0, i64 0
  %r539 = ptrtoint i8* %r538 to i64
  %r540 = call i64 @_add(i64 %r537, i64 %r539)
  %r541 = call i64 @emit(i64 %r540)
  %r542 = load i64, i64* %ptr_node
  %r543 = getelementptr [5 x i8], [5 x i8]* @.str.395, i64 0, i64 0
  %r544 = ptrtoint i8* %r543 to i64
  %r545 = call i64 @_get(i64 %r542, i64 %r544)
  store i64 %r545, i64* %ptr_keys
  %r546 = load i64, i64* %ptr_node
  %r547 = getelementptr [5 x i8], [5 x i8]* @.str.396, i64 0, i64 0
  %r548 = ptrtoint i8* %r547 to i64
  %r549 = call i64 @_get(i64 %r546, i64 %r548)
  store i64 %r549, i64* %ptr_vals
  store i64 0, i64* %ptr_i
  br label %L757
L757:
  %r550 = load i64, i64* %ptr_i
  %r551 = load i64, i64* %ptr_keys
  %r552 = call i64 @mensura(i64 %r551)
  %r554 = icmp slt i64 %r550, %r552
  %r553 = zext i1 %r554 to i64
  %r555 = icmp ne i64 %r553, 0
  br i1 %r555, label %L758, label %L759
L758:
  %r556 = load i64, i64* %ptr_keys
  %r557 = load i64, i64* %ptr_i
  %r558 = call i64 @_get(i64 %r556, i64 %r557)
  store i64 %r558, i64* %ptr_k
  %r559 = load i64, i64* %ptr_k
  %r560 = call i64 @add_global_string(i64 %r559)
  store i64 %r560, i64* %ptr_key_ptr
  %r561 = call i64 @next_reg()
  store i64 %r561, i64* %ptr_key_reg
  %r562 = load i64, i64* %ptr_k
  %r563 = call i64 @mensura(i64 %r562)
  %r564 = call i64 @_add(i64 %r563, i64 1)
  store i64 %r564, i64* %ptr_len
  %r565 = load i64, i64* %ptr_key_reg
  %r566 = getelementptr [19 x i8], [19 x i8]* @.str.397, i64 0, i64 0
  %r567 = ptrtoint i8* %r566 to i64
  %r568 = call i64 @_add(i64 %r565, i64 %r567)
  %r569 = load i64, i64* %ptr_len
  %r570 = call i64 @int_to_str(i64 %r569)
  %r571 = call i64 @_add(i64 %r568, i64 %r570)
  %r572 = getelementptr [10 x i8], [10 x i8]* @.str.398, i64 0, i64 0
  %r573 = ptrtoint i8* %r572 to i64
  %r574 = call i64 @_add(i64 %r571, i64 %r573)
  %r575 = load i64, i64* %ptr_len
  %r576 = call i64 @int_to_str(i64 %r575)
  %r577 = call i64 @_add(i64 %r574, i64 %r576)
  %r578 = getelementptr [9 x i8], [9 x i8]* @.str.399, i64 0, i64 0
  %r579 = ptrtoint i8* %r578 to i64
  %r580 = call i64 @_add(i64 %r577, i64 %r579)
  %r581 = load i64, i64* %ptr_key_ptr
  %r582 = call i64 @_add(i64 %r580, i64 %r581)
  %r583 = getelementptr [15 x i8], [15 x i8]* @.str.400, i64 0, i64 0
  %r584 = ptrtoint i8* %r583 to i64
  %r585 = call i64 @_add(i64 %r582, i64 %r584)
  %r586 = call i64 @emit(i64 %r585)
  %r587 = call i64 @next_reg()
  store i64 %r587, i64* %ptr_key_int
  %r588 = load i64, i64* %ptr_key_int
  %r589 = getelementptr [17 x i8], [17 x i8]* @.str.401, i64 0, i64 0
  %r590 = ptrtoint i8* %r589 to i64
  %r591 = call i64 @_add(i64 %r588, i64 %r590)
  %r592 = load i64, i64* %ptr_key_reg
  %r593 = call i64 @_add(i64 %r591, i64 %r592)
  %r594 = getelementptr [8 x i8], [8 x i8]* @.str.402, i64 0, i64 0
  %r595 = ptrtoint i8* %r594 to i64
  %r596 = call i64 @_add(i64 %r593, i64 %r595)
  %r597 = call i64 @emit(i64 %r596)
  %r598 = load i64, i64* %ptr_vals
  %r599 = load i64, i64* %ptr_i
  %r600 = call i64 @_get(i64 %r598, i64 %r599)
  store i64 %r600, i64* %ptr_v
  %r601 = load i64, i64* %ptr_v
  %r602 = call i64 @compile_expr(i64 %r601)
  store i64 %r602, i64* %ptr_val_reg
  %r603 = getelementptr [24 x i8], [24 x i8]* @.str.403, i64 0, i64 0
  %r604 = ptrtoint i8* %r603 to i64
  %r605 = load i64, i64* %ptr_res
  %r606 = call i64 @_add(i64 %r604, i64 %r605)
  %r607 = getelementptr [7 x i8], [7 x i8]* @.str.404, i64 0, i64 0
  %r608 = ptrtoint i8* %r607 to i64
  %r609 = call i64 @_add(i64 %r606, i64 %r608)
  %r610 = load i64, i64* %ptr_key_int
  %r611 = call i64 @_add(i64 %r609, i64 %r610)
  %r612 = getelementptr [7 x i8], [7 x i8]* @.str.405, i64 0, i64 0
  %r613 = ptrtoint i8* %r612 to i64
  %r614 = call i64 @_add(i64 %r611, i64 %r613)
  %r615 = load i64, i64* %ptr_val_reg
  %r616 = call i64 @_add(i64 %r614, i64 %r615)
  %r617 = getelementptr [2 x i8], [2 x i8]* @.str.406, i64 0, i64 0
  %r618 = ptrtoint i8* %r617 to i64
  %r619 = call i64 @_add(i64 %r616, i64 %r618)
  %r620 = call i64 @emit(i64 %r619)
  %r621 = load i64, i64* %ptr_i
  %r622 = call i64 @_add(i64 %r621, i64 1)
  store i64 %r622, i64* %ptr_i
  br label %L757
L759:
  %r623 = load i64, i64* %ptr_res
  ret i64 %r623
  br label %L756
L755:
  br label %L756
L756:
  %r624 = load i64, i64* %ptr_node
  %r625 = getelementptr [5 x i8], [5 x i8]* @.str.407, i64 0, i64 0
  %r626 = ptrtoint i8* %r625 to i64
  %r627 = call i64 @_get(i64 %r624, i64 %r626)
  %r628 = load i64, i64* @EXPR_INDEX
  %r629 = call i64 @_eq(i64 %r627, i64 %r628)
  %r630 = load i64, i64* %ptr_node
  %r631 = getelementptr [5 x i8], [5 x i8]* @.str.408, i64 0, i64 0
  %r632 = ptrtoint i8* %r631 to i64
  %r633 = call i64 @_get(i64 %r630, i64 %r632)
  %r634 = load i64, i64* @EXPR_GET
  %r635 = call i64 @_eq(i64 %r633, i64 %r634)
  %r636 = or i64 %r629, %r635
  %r637 = icmp ne i64 %r636, 0
  br i1 %r637, label %L760, label %L761
L760:
  %r638 = call i64 @_map_new()
  store i64 %r638, i64* %ptr_obj_node
  %r639 = call i64 @_map_new()
  store i64 %r639, i64* %ptr_idx_node
  %r640 = load i64, i64* %ptr_node
  %r641 = getelementptr [5 x i8], [5 x i8]* @.str.409, i64 0, i64 0
  %r642 = ptrtoint i8* %r641 to i64
  %r643 = call i64 @_get(i64 %r640, i64 %r642)
  %r644 = load i64, i64* @EXPR_INDEX
  %r645 = call i64 @_eq(i64 %r643, i64 %r644)
  %r646 = icmp ne i64 %r645, 0
  br i1 %r646, label %L763, label %L764
L763:
  %r647 = load i64, i64* %ptr_node
  %r648 = getelementptr [4 x i8], [4 x i8]* @.str.410, i64 0, i64 0
  %r649 = ptrtoint i8* %r648 to i64
  %r650 = call i64 @_get(i64 %r647, i64 %r649)
  store i64 %r650, i64* %ptr_obj_node
  %r651 = load i64, i64* %ptr_node
  %r652 = getelementptr [4 x i8], [4 x i8]* @.str.411, i64 0, i64 0
  %r653 = ptrtoint i8* %r652 to i64
  %r654 = call i64 @_get(i64 %r651, i64 %r653)
  store i64 %r654, i64* %ptr_idx_node
  br label %L765
L764:
  %r655 = load i64, i64* %ptr_node
  %r656 = getelementptr [4 x i8], [4 x i8]* @.str.412, i64 0, i64 0
  %r657 = ptrtoint i8* %r656 to i64
  %r658 = call i64 @_get(i64 %r655, i64 %r657)
  store i64 %r658, i64* %ptr_obj_node
  %r659 = call i64 @_map_new()
  %r660 = getelementptr [5 x i8], [5 x i8]* @.str.413, i64 0, i64 0
  %r661 = ptrtoint i8* %r660 to i64
  %r662 = load i64, i64* @EXPR_STRING
  call i64 @_map_set(i64 %r659, i64 %r661, i64 %r662)
  %r663 = getelementptr [4 x i8], [4 x i8]* @.str.414, i64 0, i64 0
  %r664 = ptrtoint i8* %r663 to i64
  %r665 = load i64, i64* %ptr_node
  %r666 = getelementptr [5 x i8], [5 x i8]* @.str.415, i64 0, i64 0
  %r667 = ptrtoint i8* %r666 to i64
  %r668 = call i64 @_get(i64 %r665, i64 %r667)
  call i64 @_map_set(i64 %r659, i64 %r664, i64 %r668)
  store i64 %r659, i64* %ptr_idx_node
  br label %L765
L765:
  %r669 = load i64, i64* %ptr_obj_node
  %r670 = call i64 @compile_expr(i64 %r669)
  store i64 %r670, i64* %ptr_obj_reg
  %r671 = load i64, i64* %ptr_idx_node
  %r672 = call i64 @compile_expr(i64 %r671)
  store i64 %r672, i64* %ptr_idx_reg
  %r673 = call i64 @next_reg()
  store i64 %r673, i64* %ptr_res
  %r674 = load i64, i64* %ptr_res
  %r675 = getelementptr [23 x i8], [23 x i8]* @.str.416, i64 0, i64 0
  %r676 = ptrtoint i8* %r675 to i64
  %r677 = call i64 @_add(i64 %r674, i64 %r676)
  %r678 = load i64, i64* %ptr_obj_reg
  %r679 = call i64 @_add(i64 %r677, i64 %r678)
  %r680 = getelementptr [7 x i8], [7 x i8]* @.str.417, i64 0, i64 0
  %r681 = ptrtoint i8* %r680 to i64
  %r682 = call i64 @_add(i64 %r679, i64 %r681)
  %r683 = load i64, i64* %ptr_idx_reg
  %r684 = call i64 @_add(i64 %r682, i64 %r683)
  %r685 = getelementptr [2 x i8], [2 x i8]* @.str.418, i64 0, i64 0
  %r686 = ptrtoint i8* %r685 to i64
  %r687 = call i64 @_add(i64 %r684, i64 %r686)
  %r688 = call i64 @emit(i64 %r687)
  %r689 = load i64, i64* %ptr_res
  ret i64 %r689
  br label %L762
L761:
  br label %L762
L762:
  %r690 = load i64, i64* %ptr_node
  %r691 = getelementptr [5 x i8], [5 x i8]* @.str.419, i64 0, i64 0
  %r692 = ptrtoint i8* %r691 to i64
  %r693 = call i64 @_get(i64 %r690, i64 %r692)
  %r694 = load i64, i64* @EXPR_CALL
  %r695 = call i64 @_eq(i64 %r693, i64 %r694)
  %r696 = icmp ne i64 %r695, 0
  br i1 %r696, label %L766, label %L767
L766:
  %r697 = load i64, i64* %ptr_node
  %r698 = getelementptr [5 x i8], [5 x i8]* @.str.420, i64 0, i64 0
  %r699 = ptrtoint i8* %r698 to i64
  %r700 = call i64 @_get(i64 %r697, i64 %r699)
  store i64 %r700, i64* %ptr_name
  %r701 = load i64, i64* %ptr_name
  %r702 = getelementptr [5 x i8], [5 x i8]* @.str.421, i64 0, i64 0
  %r703 = ptrtoint i8* %r702 to i64
  %r704 = call i64 @_eq(i64 %r701, i64 %r703)
  %r705 = icmp ne i64 %r704, 0
  br i1 %r705, label %L769, label %L770
L769:
  %r706 = getelementptr [12 x i8], [12 x i8]* @.str.422, i64 0, i64 0
  %r707 = ptrtoint i8* %r706 to i64
  store i64 %r707, i64* %ptr_name
  br label %L771
L770:
  br label %L771
L771:
  %r708 = load i64, i64* %ptr_name
  %r709 = getelementptr [4 x i8], [4 x i8]* @.str.423, i64 0, i64 0
  %r710 = ptrtoint i8* %r709 to i64
  %r711 = call i64 @_eq(i64 %r708, i64 %r710)
  %r712 = icmp ne i64 %r711, 0
  br i1 %r712, label %L772, label %L773
L772:
  %r713 = getelementptr [9 x i8], [9 x i8]* @.str.424, i64 0, i64 0
  %r714 = ptrtoint i8* %r713 to i64
  store i64 %r714, i64* %ptr_name
  br label %L774
L773:
  br label %L774
L774:
  %r715 = load i64, i64* %ptr_name
  %r716 = getelementptr [9 x i8], [9 x i8]* @.str.425, i64 0, i64 0
  %r717 = ptrtoint i8* %r716 to i64
  %r718 = call i64 @_eq(i64 %r715, i64 %r717)
  %r719 = icmp ne i64 %r718, 0
  br i1 %r719, label %L775, label %L776
L775:
  %r720 = load i64, i64* %ptr_node
  %r721 = getelementptr [5 x i8], [5 x i8]* @.str.426, i64 0, i64 0
  %r722 = ptrtoint i8* %r721 to i64
  %r723 = call i64 @_get(i64 %r720, i64 %r722)
  %r724 = call i64 @_get(i64 %r723, i64 0)
  %r725 = call i64 @compile_expr(i64 %r724)
  store i64 %r725, i64* %ptr_addr_reg
  %r726 = call i64 @next_reg()
  store i64 %r726, i64* %ptr_ptr_reg
  %r727 = load i64, i64* %ptr_ptr_reg
  %r728 = getelementptr [17 x i8], [17 x i8]* @.str.427, i64 0, i64 0
  %r729 = ptrtoint i8* %r728 to i64
  %r730 = call i64 @_add(i64 %r727, i64 %r729)
  %r731 = load i64, i64* %ptr_addr_reg
  %r732 = call i64 @_add(i64 %r730, i64 %r731)
  %r733 = getelementptr [8 x i8], [8 x i8]* @.str.428, i64 0, i64 0
  %r734 = ptrtoint i8* %r733 to i64
  %r735 = call i64 @_add(i64 %r732, i64 %r734)
  %r736 = call i64 @emit(i64 %r735)
  %r737 = call i64 @next_reg()
  store i64 %r737, i64* %ptr_val_reg
  %r738 = load i64, i64* %ptr_val_reg
  %r739 = getelementptr [17 x i8], [17 x i8]* @.str.429, i64 0, i64 0
  %r740 = ptrtoint i8* %r739 to i64
  %r741 = call i64 @_add(i64 %r738, i64 %r740)
  %r742 = load i64, i64* %ptr_ptr_reg
  %r743 = call i64 @_add(i64 %r741, i64 %r742)
  %r744 = call i64 @emit(i64 %r743)
  %r745 = call i64 @next_reg()
  store i64 %r745, i64* %ptr_mem_res
  %r746 = load i64, i64* %ptr_mem_res
  %r747 = getelementptr [12 x i8], [12 x i8]* @.str.430, i64 0, i64 0
  %r748 = ptrtoint i8* %r747 to i64
  %r749 = call i64 @_add(i64 %r746, i64 %r748)
  %r750 = load i64, i64* %ptr_val_reg
  %r751 = call i64 @_add(i64 %r749, i64 %r750)
  %r752 = getelementptr [8 x i8], [8 x i8]* @.str.431, i64 0, i64 0
  %r753 = ptrtoint i8* %r752 to i64
  %r754 = call i64 @_add(i64 %r751, i64 %r753)
  %r755 = call i64 @emit(i64 %r754)
  %r756 = load i64, i64* %ptr_mem_res
  ret i64 %r756
  br label %L777
L776:
  br label %L777
L777:
  %r757 = load i64, i64* %ptr_name
  %r758 = getelementptr [11 x i8], [11 x i8]* @.str.432, i64 0, i64 0
  %r759 = ptrtoint i8* %r758 to i64
  %r760 = call i64 @_eq(i64 %r757, i64 %r759)
  %r761 = icmp ne i64 %r760, 0
  br i1 %r761, label %L778, label %L779
L778:
  %r762 = load i64, i64* %ptr_node
  %r763 = getelementptr [5 x i8], [5 x i8]* @.str.433, i64 0, i64 0
  %r764 = ptrtoint i8* %r763 to i64
  %r765 = call i64 @_get(i64 %r762, i64 %r764)
  %r766 = call i64 @_get(i64 %r765, i64 0)
  %r767 = call i64 @compile_expr(i64 %r766)
  store i64 %r767, i64* %ptr_addr_reg
  %r768 = load i64, i64* %ptr_node
  %r769 = getelementptr [5 x i8], [5 x i8]* @.str.434, i64 0, i64 0
  %r770 = ptrtoint i8* %r769 to i64
  %r771 = call i64 @_get(i64 %r768, i64 %r770)
  %r772 = call i64 @_get(i64 %r771, i64 1)
  %r773 = call i64 @compile_expr(i64 %r772)
  store i64 %r773, i64* %ptr_val_reg
  %r774 = call i64 @next_reg()
  store i64 %r774, i64* %ptr_ptr_reg
  %r775 = load i64, i64* %ptr_ptr_reg
  %r776 = getelementptr [17 x i8], [17 x i8]* @.str.435, i64 0, i64 0
  %r777 = ptrtoint i8* %r776 to i64
  %r778 = call i64 @_add(i64 %r775, i64 %r777)
  %r779 = load i64, i64* %ptr_addr_reg
  %r780 = call i64 @_add(i64 %r778, i64 %r779)
  %r781 = getelementptr [8 x i8], [8 x i8]* @.str.436, i64 0, i64 0
  %r782 = ptrtoint i8* %r781 to i64
  %r783 = call i64 @_add(i64 %r780, i64 %r782)
  %r784 = call i64 @emit(i64 %r783)
  %r785 = call i64 @next_reg()
  store i64 %r785, i64* %ptr_trunc_reg
  %r786 = load i64, i64* %ptr_trunc_reg
  %r787 = getelementptr [14 x i8], [14 x i8]* @.str.437, i64 0, i64 0
  %r788 = ptrtoint i8* %r787 to i64
  %r789 = call i64 @_add(i64 %r786, i64 %r788)
  %r790 = load i64, i64* %ptr_val_reg
  %r791 = call i64 @_add(i64 %r789, i64 %r790)
  %r792 = getelementptr [7 x i8], [7 x i8]* @.str.438, i64 0, i64 0
  %r793 = ptrtoint i8* %r792 to i64
  %r794 = call i64 @_add(i64 %r791, i64 %r793)
  %r795 = call i64 @emit(i64 %r794)
  %r796 = getelementptr [10 x i8], [10 x i8]* @.str.439, i64 0, i64 0
  %r797 = ptrtoint i8* %r796 to i64
  %r798 = load i64, i64* %ptr_trunc_reg
  %r799 = call i64 @_add(i64 %r797, i64 %r798)
  %r800 = getelementptr [7 x i8], [7 x i8]* @.str.440, i64 0, i64 0
  %r801 = ptrtoint i8* %r800 to i64
  %r802 = call i64 @_add(i64 %r799, i64 %r801)
  %r803 = load i64, i64* %ptr_ptr_reg
  %r804 = call i64 @_add(i64 %r802, i64 %r803)
  %r805 = call i64 @emit(i64 %r804)
  %r806 = getelementptr [2 x i8], [2 x i8]* @.str.441, i64 0, i64 0
  %r807 = ptrtoint i8* %r806 to i64
  ret i64 %r807
  br label %L780
L779:
  br label %L780
L780:
  %r808 = load i64, i64* %ptr_name
  %r809 = getelementptr [16 x i8], [16 x i8]* @.str.442, i64 0, i64 0
  %r810 = ptrtoint i8* %r809 to i64
  %r811 = call i64 @_eq(i64 %r808, i64 %r810)
  %r812 = icmp ne i64 %r811, 0
  br i1 %r812, label %L781, label %L782
L781:
  %r813 = load i64, i64* %ptr_node
  %r814 = getelementptr [5 x i8], [5 x i8]* @.str.443, i64 0, i64 0
  %r815 = ptrtoint i8* %r814 to i64
  %r816 = call i64 @_get(i64 %r813, i64 %r815)
  store i64 %r816, i64* %ptr_args
  %r817 = getelementptr [2 x i8], [2 x i8]* @.str.444, i64 0, i64 0
  %r818 = ptrtoint i8* %r817 to i64
  store i64 %r818, i64* %ptr_a0
  %r819 = load i64, i64* %ptr_args
  %r820 = call i64 @mensura(i64 %r819)
  %r822 = icmp sgt i64 %r820, 0
  %r821 = zext i1 %r822 to i64
  %r823 = icmp ne i64 %r821, 0
  br i1 %r823, label %L784, label %L785
L784:
  %r824 = load i64, i64* %ptr_args
  %r825 = call i64 @_get(i64 %r824, i64 0)
  %r826 = call i64 @compile_expr(i64 %r825)
  store i64 %r826, i64* %ptr_a0
  br label %L786
L785:
  br label %L786
L786:
  %r827 = getelementptr [2 x i8], [2 x i8]* @.str.445, i64 0, i64 0
  %r828 = ptrtoint i8* %r827 to i64
  store i64 %r828, i64* %ptr_a1
  %r829 = load i64, i64* %ptr_args
  %r830 = call i64 @mensura(i64 %r829)
  %r832 = icmp sgt i64 %r830, 1
  %r831 = zext i1 %r832 to i64
  %r833 = icmp ne i64 %r831, 0
  br i1 %r833, label %L787, label %L788
L787:
  %r834 = load i64, i64* %ptr_args
  %r835 = call i64 @_get(i64 %r834, i64 1)
  %r836 = call i64 @compile_expr(i64 %r835)
  store i64 %r836, i64* %ptr_a1
  br label %L789
L788:
  br label %L789
L789:
  %r837 = getelementptr [2 x i8], [2 x i8]* @.str.446, i64 0, i64 0
  %r838 = ptrtoint i8* %r837 to i64
  store i64 %r838, i64* %ptr_a2
  %r839 = load i64, i64* %ptr_args
  %r840 = call i64 @mensura(i64 %r839)
  %r842 = icmp sgt i64 %r840, 2
  %r841 = zext i1 %r842 to i64
  %r843 = icmp ne i64 %r841, 0
  br i1 %r843, label %L790, label %L791
L790:
  %r844 = load i64, i64* %ptr_args
  %r845 = call i64 @_get(i64 %r844, i64 2)
  %r846 = call i64 @compile_expr(i64 %r845)
  store i64 %r846, i64* %ptr_a2
  br label %L792
L791:
  br label %L792
L792:
  %r847 = getelementptr [2 x i8], [2 x i8]* @.str.447, i64 0, i64 0
  %r848 = ptrtoint i8* %r847 to i64
  store i64 %r848, i64* %ptr_a3
  %r849 = load i64, i64* %ptr_args
  %r850 = call i64 @mensura(i64 %r849)
  %r852 = icmp sgt i64 %r850, 3
  %r851 = zext i1 %r852 to i64
  %r853 = icmp ne i64 %r851, 0
  br i1 %r853, label %L793, label %L794
L793:
  %r854 = load i64, i64* %ptr_args
  %r855 = call i64 @_get(i64 %r854, i64 3)
  %r856 = call i64 @compile_expr(i64 %r855)
  store i64 %r856, i64* %ptr_a3
  br label %L795
L794:
  br label %L795
L795:
  %r857 = getelementptr [2 x i8], [2 x i8]* @.str.448, i64 0, i64 0
  %r858 = ptrtoint i8* %r857 to i64
  store i64 %r858, i64* %ptr_a4
  %r859 = load i64, i64* %ptr_args
  %r860 = call i64 @mensura(i64 %r859)
  %r862 = icmp sgt i64 %r860, 4
  %r861 = zext i1 %r862 to i64
  %r863 = icmp ne i64 %r861, 0
  br i1 %r863, label %L796, label %L797
L796:
  %r864 = load i64, i64* %ptr_args
  %r865 = call i64 @_get(i64 %r864, i64 4)
  %r866 = call i64 @compile_expr(i64 %r865)
  store i64 %r866, i64* %ptr_a4
  br label %L798
L797:
  br label %L798
L798:
  %r867 = getelementptr [2 x i8], [2 x i8]* @.str.449, i64 0, i64 0
  %r868 = ptrtoint i8* %r867 to i64
  store i64 %r868, i64* %ptr_a5
  %r869 = load i64, i64* %ptr_args
  %r870 = call i64 @mensura(i64 %r869)
  %r872 = icmp sgt i64 %r870, 5
  %r871 = zext i1 %r872 to i64
  %r873 = icmp ne i64 %r871, 0
  br i1 %r873, label %L799, label %L800
L799:
  %r874 = load i64, i64* %ptr_args
  %r875 = call i64 @_get(i64 %r874, i64 5)
  %r876 = call i64 @compile_expr(i64 %r875)
  store i64 %r876, i64* %ptr_a5
  br label %L801
L800:
  br label %L801
L801:
  %r877 = getelementptr [2 x i8], [2 x i8]* @.str.450, i64 0, i64 0
  %r878 = ptrtoint i8* %r877 to i64
  store i64 %r878, i64* %ptr_a6
  %r879 = load i64, i64* %ptr_args
  %r880 = call i64 @mensura(i64 %r879)
  %r882 = icmp sgt i64 %r880, 6
  %r881 = zext i1 %r882 to i64
  %r883 = icmp ne i64 %r881, 0
  br i1 %r883, label %L802, label %L803
L802:
  %r884 = load i64, i64* %ptr_args
  %r885 = call i64 @_get(i64 %r884, i64 6)
  %r886 = call i64 @compile_expr(i64 %r885)
  store i64 %r886, i64* %ptr_a6
  br label %L804
L803:
  br label %L804
L804:
  %r887 = call i64 @next_reg()
  store i64 %r887, i64* %ptr_res
  %r888 = load i64, i64* %ptr_res
  %r889 = getelementptr [27 x i8], [27 x i8]* @.str.451, i64 0, i64 0
  %r890 = ptrtoint i8* %r889 to i64
  %r891 = call i64 @_add(i64 %r888, i64 %r890)
  %r892 = load i64, i64* %ptr_a0
  %r893 = call i64 @_add(i64 %r891, i64 %r892)
  %r894 = getelementptr [7 x i8], [7 x i8]* @.str.452, i64 0, i64 0
  %r895 = ptrtoint i8* %r894 to i64
  %r896 = call i64 @_add(i64 %r893, i64 %r895)
  %r897 = load i64, i64* %ptr_a1
  %r898 = call i64 @_add(i64 %r896, i64 %r897)
  %r899 = getelementptr [7 x i8], [7 x i8]* @.str.453, i64 0, i64 0
  %r900 = ptrtoint i8* %r899 to i64
  %r901 = call i64 @_add(i64 %r898, i64 %r900)
  %r902 = load i64, i64* %ptr_a2
  %r903 = call i64 @_add(i64 %r901, i64 %r902)
  %r904 = getelementptr [7 x i8], [7 x i8]* @.str.454, i64 0, i64 0
  %r905 = ptrtoint i8* %r904 to i64
  %r906 = call i64 @_add(i64 %r903, i64 %r905)
  %r907 = load i64, i64* %ptr_a3
  %r908 = call i64 @_add(i64 %r906, i64 %r907)
  %r909 = getelementptr [7 x i8], [7 x i8]* @.str.455, i64 0, i64 0
  %r910 = ptrtoint i8* %r909 to i64
  %r911 = call i64 @_add(i64 %r908, i64 %r910)
  %r912 = load i64, i64* %ptr_a4
  %r913 = call i64 @_add(i64 %r911, i64 %r912)
  %r914 = getelementptr [7 x i8], [7 x i8]* @.str.456, i64 0, i64 0
  %r915 = ptrtoint i8* %r914 to i64
  %r916 = call i64 @_add(i64 %r913, i64 %r915)
  %r917 = load i64, i64* %ptr_a5
  %r918 = call i64 @_add(i64 %r916, i64 %r917)
  %r919 = getelementptr [7 x i8], [7 x i8]* @.str.457, i64 0, i64 0
  %r920 = ptrtoint i8* %r919 to i64
  %r921 = call i64 @_add(i64 %r918, i64 %r920)
  %r922 = load i64, i64* %ptr_a6
  %r923 = call i64 @_add(i64 %r921, i64 %r922)
  %r924 = getelementptr [2 x i8], [2 x i8]* @.str.458, i64 0, i64 0
  %r925 = ptrtoint i8* %r924 to i64
  %r926 = call i64 @_add(i64 %r923, i64 %r925)
  %r927 = call i64 @emit(i64 %r926)
  %r928 = load i64, i64* %ptr_res
  ret i64 %r928
  br label %L783
L782:
  br label %L783
L783:
  %r929 = load i64, i64* %ptr_name
  %r930 = getelementptr [18 x i8], [18 x i8]* @.str.459, i64 0, i64 0
  %r931 = ptrtoint i8* %r930 to i64
  %r932 = call i64 @_eq(i64 %r929, i64 %r931)
  %r933 = icmp ne i64 %r932, 0
  br i1 %r933, label %L805, label %L806
L805:
  %r934 = load i64, i64* %ptr_node
  %r935 = getelementptr [5 x i8], [5 x i8]* @.str.460, i64 0, i64 0
  %r936 = ptrtoint i8* %r935 to i64
  %r937 = call i64 @_get(i64 %r934, i64 %r936)
  %r938 = call i64 @_get(i64 %r937, i64 0)
  %r939 = call i64 @compile_expr(i64 %r938)
  store i64 %r939, i64* %ptr_arg_idx
  %r940 = call i64 @next_reg()
  store i64 %r940, i64* %ptr_res
  %r941 = load i64, i64* %ptr_res
  %r942 = getelementptr [28 x i8], [28 x i8]* @.str.461, i64 0, i64 0
  %r943 = ptrtoint i8* %r942 to i64
  %r944 = call i64 @_add(i64 %r941, i64 %r943)
  %r945 = load i64, i64* %ptr_arg_idx
  %r946 = call i64 @_add(i64 %r944, i64 %r945)
  %r947 = getelementptr [2 x i8], [2 x i8]* @.str.462, i64 0, i64 0
  %r948 = ptrtoint i8* %r947 to i64
  %r949 = call i64 @_add(i64 %r946, i64 %r948)
  %r950 = call i64 @emit(i64 %r949)
  %r951 = load i64, i64* %ptr_res
  ret i64 %r951
  br label %L807
L806:
  br label %L807
L807:
  %r952 = load i64, i64* %ptr_node
  %r953 = getelementptr [5 x i8], [5 x i8]* @.str.463, i64 0, i64 0
  %r954 = ptrtoint i8* %r953 to i64
  %r955 = call i64 @_get(i64 %r952, i64 %r954)
  store i64 %r955, i64* %ptr_args
  %r956 = getelementptr [1 x i8], [1 x i8]* @.str.464, i64 0, i64 0
  %r957 = ptrtoint i8* %r956 to i64
  store i64 %r957, i64* %ptr_arg_str
  store i64 0, i64* %ptr_i
  br label %L808
L808:
  %r958 = load i64, i64* %ptr_i
  %r959 = load i64, i64* %ptr_args
  %r960 = call i64 @mensura(i64 %r959)
  %r962 = icmp slt i64 %r958, %r960
  %r961 = zext i1 %r962 to i64
  %r963 = icmp ne i64 %r961, 0
  br i1 %r963, label %L809, label %L810
L809:
  %r964 = load i64, i64* %ptr_args
  %r965 = load i64, i64* %ptr_i
  %r966 = call i64 @_get(i64 %r964, i64 %r965)
  %r967 = call i64 @compile_expr(i64 %r966)
  store i64 %r967, i64* %ptr_val
  %r968 = load i64, i64* %ptr_arg_str
  %r969 = getelementptr [5 x i8], [5 x i8]* @.str.465, i64 0, i64 0
  %r970 = ptrtoint i8* %r969 to i64
  %r971 = call i64 @_add(i64 %r968, i64 %r970)
  %r972 = load i64, i64* %ptr_val
  %r973 = call i64 @_add(i64 %r971, i64 %r972)
  store i64 %r973, i64* %ptr_arg_str
  %r974 = load i64, i64* %ptr_i
  %r975 = load i64, i64* %ptr_args
  %r976 = call i64 @mensura(i64 %r975)
  %r977 = sub i64 %r976, 1
  %r979 = icmp slt i64 %r974, %r977
  %r978 = zext i1 %r979 to i64
  %r980 = icmp ne i64 %r978, 0
  br i1 %r980, label %L811, label %L812
L811:
  %r981 = load i64, i64* %ptr_arg_str
  %r982 = getelementptr [3 x i8], [3 x i8]* @.str.466, i64 0, i64 0
  %r983 = ptrtoint i8* %r982 to i64
  %r984 = call i64 @_add(i64 %r981, i64 %r983)
  store i64 %r984, i64* %ptr_arg_str
  br label %L813
L812:
  br label %L813
L813:
  %r985 = load i64, i64* %ptr_i
  %r986 = call i64 @_add(i64 %r985, i64 1)
  store i64 %r986, i64* %ptr_i
  br label %L808
L810:
  %r987 = call i64 @next_reg()
  store i64 %r987, i64* %ptr_res
  %r988 = load i64, i64* %ptr_name
  %r989 = getelementptr [7 x i8], [7 x i8]* @.str.467, i64 0, i64 0
  %r990 = ptrtoint i8* %r989 to i64
  %r991 = call i64 @_eq(i64 %r988, i64 %r990)
  %r992 = icmp ne i64 %r991, 0
  br i1 %r992, label %L814, label %L815
L814:
  %r993 = load i64, i64* %ptr_res
  %r994 = getelementptr [28 x i8], [28 x i8]* @.str.468, i64 0, i64 0
  %r995 = ptrtoint i8* %r994 to i64
  %r996 = call i64 @_add(i64 %r993, i64 %r995)
  %r997 = load i64, i64* %ptr_arg_str
  %r998 = call i64 @_add(i64 %r996, i64 %r997)
  %r999 = getelementptr [2 x i8], [2 x i8]* @.str.469, i64 0, i64 0
  %r1000 = ptrtoint i8* %r999 to i64
  %r1001 = call i64 @_add(i64 %r998, i64 %r1000)
  %r1002 = call i64 @emit(i64 %r1001)
  br label %L816
L815:
  %r1003 = load i64, i64* %ptr_res
  %r1004 = getelementptr [14 x i8], [14 x i8]* @.str.470, i64 0, i64 0
  %r1005 = ptrtoint i8* %r1004 to i64
  %r1006 = call i64 @_add(i64 %r1003, i64 %r1005)
  %r1007 = load i64, i64* %ptr_name
  %r1008 = call i64 @_add(i64 %r1006, i64 %r1007)
  %r1009 = getelementptr [2 x i8], [2 x i8]* @.str.471, i64 0, i64 0
  %r1010 = ptrtoint i8* %r1009 to i64
  %r1011 = call i64 @_add(i64 %r1008, i64 %r1010)
  %r1012 = load i64, i64* %ptr_arg_str
  %r1013 = call i64 @_add(i64 %r1011, i64 %r1012)
  %r1014 = getelementptr [2 x i8], [2 x i8]* @.str.472, i64 0, i64 0
  %r1015 = ptrtoint i8* %r1014 to i64
  %r1016 = call i64 @_add(i64 %r1013, i64 %r1015)
  %r1017 = call i64 @emit(i64 %r1016)
  br label %L816
L816:
  %r1018 = load i64, i64* %ptr_res
  ret i64 %r1018
  br label %L768
L767:
  br label %L768
L768:
  %r1019 = getelementptr [2 x i8], [2 x i8]* @.str.473, i64 0, i64 0
  %r1020 = ptrtoint i8* %r1019 to i64
  ret i64 %r1020
  ret i64 0
}
define i64 @compile_stmt(i64 %arg_node) {
  %ptr_node = alloca i64
  store i64 %arg_node, i64* %ptr_node
  %ptr_path_node = alloca i64
  %ptr_f_src = alloca i64
  %ptr_old_tokens = alloca i64
  %ptr_old_pos = alloca i64
  %ptr_link_stmts = alloca i64
  %ptr_val = alloca i64
  %ptr_ptr = alloca i64
  %ptr_idx = alloca i64
  %ptr_list_ptr = alloca i64
  %ptr_list_reg = alloca i64
  %ptr_len = alloca i64
  %ptr_lbl = alloca i64
  %ptr_cond = alloca i64
  %ptr_bool = alloca i64
  %ptr_l_then = alloca i64
  %ptr_l_else = alloca i64
  %ptr_l_end = alloca i64
  %ptr_l_cond = alloca i64
  %ptr_l_body = alloca i64
  %ptr_extract_dummy = alloca i64
  %ptr_popped_cond = alloca i64
  %ptr_i = alloca i64
  %ptr_popped_end = alloca i64
  %r1 = load i64, i64* %ptr_node
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.474, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @STMT_IMPORT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L817, label %L818
L817:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.475, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  store i64 %r11, i64* %ptr_path_node
  %r12 = load i64, i64* %ptr_path_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.476, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_STRING
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L820, label %L821
L820:
  %r19 = load i64, i64* %ptr_path_node
  %r20 = getelementptr [4 x i8], [4 x i8]* @.str.477, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @revelare(i64 %r22)
  store i64 %r23, i64* %ptr_f_src
  %r24 = load i64, i64* %ptr_f_src
  %r25 = call i64 @mensura(i64 %r24)
  %r27 = icmp sgt i64 %r25, 0
  %r26 = zext i1 %r27 to i64
  %r28 = icmp ne i64 %r26, 0
  br i1 %r28, label %L823, label %L824
L823:
  %r29 = load i64, i64* @global_tokens
  store i64 %r29, i64* %ptr_old_tokens
  %r30 = load i64, i64* @p_pos
  store i64 %r30, i64* %ptr_old_pos
  %r31 = load i64, i64* %ptr_f_src
  %r32 = call i64 @lex_source(i64 %r31)
  store i64 %r32, i64* @global_tokens
  store i64 0, i64* @p_pos
  %r33 = call i64 @_list_new()
  store i64 %r33, i64* %ptr_link_stmts
  br label %L826
L826:
  %r34 = call i64 @peek()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.478, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_get(i64 %r34, i64 %r36)
  %r38 = load i64, i64* @TOK_EOF
  %r40 = call i64 @_eq(i64 %r37, i64 %r38)
  %r39 = xor i64 %r40, 1
  %r41 = icmp ne i64 %r39, 0
  br i1 %r41, label %L827, label %L828
L827:
  %r42 = call i64 @peek()
  %r43 = getelementptr [5 x i8], [5 x i8]* @.str.479, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = call i64 @_get(i64 %r42, i64 %r44)
  %r46 = load i64, i64* @TOK_CARET
  %r47 = call i64 @_eq(i64 %r45, i64 %r46)
  %r48 = icmp ne i64 %r47, 0
  br i1 %r48, label %L829, label %L830
L829:
  %r49 = call i64 @advance()
  br label %L831
L830:
  %r50 = call i64 @parse_stmt()
  %r51 = load i64, i64* %ptr_link_stmts
  call i64 @_append_poly(i64 %r51, i64 %r50)
  br label %L831
L831:
  br label %L826
L828:
  %r52 = load i64, i64* %ptr_link_stmts
  %r53 = call i64 @compile_block(i64 %r52)
  %r54 = load i64, i64* %ptr_old_tokens
  store i64 %r54, i64* @global_tokens
  %r55 = load i64, i64* %ptr_old_pos
  store i64 %r55, i64* @p_pos
  br label %L825
L824:
  %r56 = getelementptr [41 x i8], [41 x i8]* @.str.480, i64 0, i64 0
  %r57 = ptrtoint i8* %r56 to i64
  %r58 = load i64, i64* %ptr_path_node
  %r59 = getelementptr [4 x i8], [4 x i8]* @.str.481, i64 0, i64 0
  %r60 = ptrtoint i8* %r59 to i64
  %r61 = call i64 @_get(i64 %r58, i64 %r60)
  %r62 = call i64 @_add(i64 %r57, i64 %r61)
  call i64 @print_any(i64 %r62)
  br label %L825
L825:
  br label %L822
L821:
  br label %L822
L822:
  br label %L819
L818:
  br label %L819
L819:
  %r63 = load i64, i64* %ptr_node
  %r64 = getelementptr [5 x i8], [5 x i8]* @.str.482, i64 0, i64 0
  %r65 = ptrtoint i8* %r64 to i64
  %r66 = call i64 @_get(i64 %r63, i64 %r65)
  %r67 = load i64, i64* @STMT_LET
  %r68 = call i64 @_eq(i64 %r66, i64 %r67)
  %r69 = icmp ne i64 %r68, 0
  br i1 %r69, label %L832, label %L833
L832:
  %r70 = load i64, i64* %ptr_node
  %r71 = getelementptr [4 x i8], [4 x i8]* @.str.483, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_get(i64 %r70, i64 %r72)
  %r74 = call i64 @compile_expr(i64 %r73)
  store i64 %r74, i64* %ptr_val
  %r75 = load i64, i64* @var_map
  %r76 = load i64, i64* %ptr_node
  %r77 = getelementptr [5 x i8], [5 x i8]* @.str.484, i64 0, i64 0
  %r78 = ptrtoint i8* %r77 to i64
  %r79 = call i64 @_get(i64 %r76, i64 %r78)
  %r80 = call i64 @_get(i64 %r75, i64 %r79)
  store i64 %r80, i64* %ptr_ptr
  %r81 = load i64, i64* %ptr_ptr
  %r82 = call i64 @mensura(i64 %r81)
  %r83 = call i64 @_eq(i64 %r82, i64 0)
  %r84 = icmp ne i64 %r83, 0
  br i1 %r84, label %L835, label %L836
L835:
  %r85 = getelementptr [6 x i8], [6 x i8]* @.str.485, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = load i64, i64* %ptr_node
  %r88 = getelementptr [5 x i8], [5 x i8]* @.str.486, i64 0, i64 0
  %r89 = ptrtoint i8* %r88 to i64
  %r90 = call i64 @_get(i64 %r87, i64 %r89)
  %r91 = call i64 @_add(i64 %r86, i64 %r90)
  store i64 %r91, i64* %ptr_ptr
  %r92 = load i64, i64* %ptr_ptr
  %r93 = getelementptr [14 x i8], [14 x i8]* @.str.487, i64 0, i64 0
  %r94 = ptrtoint i8* %r93 to i64
  %r95 = call i64 @_add(i64 %r92, i64 %r94)
  %r96 = call i64 @emit(i64 %r95)
  %r97 = load i64, i64* %ptr_ptr
  %r98 = load i64, i64* %ptr_node
  %r99 = getelementptr [5 x i8], [5 x i8]* @.str.488, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_get(i64 %r98, i64 %r100)
  %r102 = load i64, i64* @var_map
  call i64 @_set(i64 %r102, i64 %r101, i64 %r97)
  br label %L837
L836:
  br label %L837
L837:
  %r103 = getelementptr [11 x i8], [11 x i8]* @.str.489, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = load i64, i64* %ptr_val
  %r106 = call i64 @_add(i64 %r104, i64 %r105)
  %r107 = getelementptr [8 x i8], [8 x i8]* @.str.490, i64 0, i64 0
  %r108 = ptrtoint i8* %r107 to i64
  %r109 = call i64 @_add(i64 %r106, i64 %r108)
  %r110 = load i64, i64* %ptr_ptr
  %r111 = call i64 @_add(i64 %r109, i64 %r110)
  %r112 = call i64 @emit(i64 %r111)
  br label %L834
L833:
  br label %L834
L834:
  %r113 = load i64, i64* %ptr_node
  %r114 = getelementptr [5 x i8], [5 x i8]* @.str.491, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_get(i64 %r113, i64 %r115)
  %r117 = load i64, i64* @STMT_SET_INDEX
  %r118 = call i64 @_eq(i64 %r116, i64 %r117)
  %r119 = icmp ne i64 %r118, 0
  br i1 %r119, label %L838, label %L839
L838:
  %r120 = load i64, i64* %ptr_node
  %r121 = getelementptr [4 x i8], [4 x i8]* @.str.492, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = call i64 @_get(i64 %r120, i64 %r122)
  %r124 = call i64 @compile_expr(i64 %r123)
  store i64 %r124, i64* %ptr_val
  %r125 = load i64, i64* %ptr_node
  %r126 = getelementptr [4 x i8], [4 x i8]* @.str.493, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = call i64 @compile_expr(i64 %r128)
  store i64 %r129, i64* %ptr_idx
  %r130 = load i64, i64* %ptr_node
  %r131 = getelementptr [5 x i8], [5 x i8]* @.str.494, i64 0, i64 0
  %r132 = ptrtoint i8* %r131 to i64
  %r133 = call i64 @_get(i64 %r130, i64 %r132)
  %r134 = call i64 @get_var_ptr(i64 %r133)
  store i64 %r134, i64* %ptr_list_ptr
  %r135 = load i64, i64* %ptr_list_ptr
  %r136 = call i64 @mensura(i64 %r135)
  %r137 = call i64 @_eq(i64 %r136, i64 0)
  %r138 = icmp ne i64 %r137, 0
  br i1 %r138, label %L841, label %L842
L841:
  %r139 = getelementptr [46 x i8], [46 x i8]* @.str.495, i64 0, i64 0
  %r140 = ptrtoint i8* %r139 to i64
  %r141 = load i64, i64* %ptr_node
  %r142 = getelementptr [5 x i8], [5 x i8]* @.str.496, i64 0, i64 0
  %r143 = ptrtoint i8* %r142 to i64
  %r144 = call i64 @_get(i64 %r141, i64 %r143)
  %r145 = call i64 @_add(i64 %r140, i64 %r144)
  %r146 = getelementptr [2 x i8], [2 x i8]* @.str.497, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = call i64 @_add(i64 %r145, i64 %r147)
  call i64 @print_any(i64 %r148)
  br label %L843
L842:
  %r149 = call i64 @next_reg()
  store i64 %r149, i64* %ptr_list_reg
  %r150 = load i64, i64* %ptr_list_reg
  %r151 = getelementptr [19 x i8], [19 x i8]* @.str.498, i64 0, i64 0
  %r152 = ptrtoint i8* %r151 to i64
  %r153 = call i64 @_add(i64 %r150, i64 %r152)
  %r154 = load i64, i64* %ptr_list_ptr
  %r155 = call i64 @_add(i64 %r153, i64 %r154)
  %r156 = call i64 @emit(i64 %r155)
  %r157 = getelementptr [20 x i8], [20 x i8]* @.str.499, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = load i64, i64* %ptr_list_reg
  %r160 = call i64 @_add(i64 %r158, i64 %r159)
  %r161 = getelementptr [7 x i8], [7 x i8]* @.str.500, i64 0, i64 0
  %r162 = ptrtoint i8* %r161 to i64
  %r163 = call i64 @_add(i64 %r160, i64 %r162)
  %r164 = load i64, i64* %ptr_idx
  %r165 = call i64 @_add(i64 %r163, i64 %r164)
  %r166 = getelementptr [7 x i8], [7 x i8]* @.str.501, i64 0, i64 0
  %r167 = ptrtoint i8* %r166 to i64
  %r168 = call i64 @_add(i64 %r165, i64 %r167)
  %r169 = load i64, i64* %ptr_val
  %r170 = call i64 @_add(i64 %r168, i64 %r169)
  %r171 = getelementptr [2 x i8], [2 x i8]* @.str.502, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_add(i64 %r170, i64 %r172)
  %r174 = call i64 @emit(i64 %r173)
  br label %L843
L843:
  br label %L840
L839:
  br label %L840
L840:
  %r175 = load i64, i64* %ptr_node
  %r176 = getelementptr [5 x i8], [5 x i8]* @.str.503, i64 0, i64 0
  %r177 = ptrtoint i8* %r176 to i64
  %r178 = call i64 @_get(i64 %r175, i64 %r177)
  %r179 = load i64, i64* @STMT_ASSIGN
  %r180 = call i64 @_eq(i64 %r178, i64 %r179)
  %r181 = icmp ne i64 %r180, 0
  br i1 %r181, label %L844, label %L845
L844:
  %r182 = load i64, i64* %ptr_node
  %r183 = getelementptr [4 x i8], [4 x i8]* @.str.504, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_get(i64 %r182, i64 %r184)
  %r186 = call i64 @compile_expr(i64 %r185)
  store i64 %r186, i64* %ptr_val
  %r187 = load i64, i64* %ptr_node
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.505, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = call i64 @_get(i64 %r187, i64 %r189)
  %r191 = call i64 @get_var_ptr(i64 %r190)
  store i64 %r191, i64* %ptr_ptr
  %r192 = load i64, i64* %ptr_ptr
  %r193 = call i64 @mensura(i64 %r192)
  %r194 = call i64 @_eq(i64 %r193, i64 0)
  %r195 = icmp ne i64 %r194, 0
  br i1 %r195, label %L847, label %L848
L847:
  %r196 = getelementptr [47 x i8], [47 x i8]* @.str.506, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = load i64, i64* %ptr_node
  %r199 = getelementptr [5 x i8], [5 x i8]* @.str.507, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  %r202 = call i64 @_add(i64 %r197, i64 %r201)
  %r203 = getelementptr [2 x i8], [2 x i8]* @.str.508, i64 0, i64 0
  %r204 = ptrtoint i8* %r203 to i64
  %r205 = call i64 @_add(i64 %r202, i64 %r204)
  call i64 @print_any(i64 %r205)
  br label %L849
L848:
  %r206 = getelementptr [11 x i8], [11 x i8]* @.str.509, i64 0, i64 0
  %r207 = ptrtoint i8* %r206 to i64
  %r208 = load i64, i64* %ptr_val
  %r209 = call i64 @_add(i64 %r207, i64 %r208)
  %r210 = getelementptr [8 x i8], [8 x i8]* @.str.510, i64 0, i64 0
  %r211 = ptrtoint i8* %r210 to i64
  %r212 = call i64 @_add(i64 %r209, i64 %r211)
  %r213 = load i64, i64* %ptr_ptr
  %r214 = call i64 @_add(i64 %r212, i64 %r213)
  %r215 = call i64 @emit(i64 %r214)
  br label %L849
L849:
  br label %L846
L845:
  br label %L846
L846:
  %r216 = load i64, i64* %ptr_node
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.511, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_get(i64 %r216, i64 %r218)
  %r220 = load i64, i64* @STMT_APPEND
  %r221 = call i64 @_eq(i64 %r219, i64 %r220)
  %r222 = icmp ne i64 %r221, 0
  br i1 %r222, label %L850, label %L851
L850:
  %r223 = load i64, i64* %ptr_node
  %r224 = getelementptr [4 x i8], [4 x i8]* @.str.512, i64 0, i64 0
  %r225 = ptrtoint i8* %r224 to i64
  %r226 = call i64 @_get(i64 %r223, i64 %r225)
  %r227 = call i64 @compile_expr(i64 %r226)
  store i64 %r227, i64* %ptr_val
  %r228 = load i64, i64* %ptr_node
  %r229 = getelementptr [5 x i8], [5 x i8]* @.str.513, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @_get(i64 %r228, i64 %r230)
  %r232 = call i64 @get_var_ptr(i64 %r231)
  store i64 %r232, i64* %ptr_list_ptr
  %r233 = load i64, i64* %ptr_list_ptr
  %r234 = call i64 @mensura(i64 %r233)
  %r235 = call i64 @_eq(i64 %r234, i64 0)
  %r236 = icmp ne i64 %r235, 0
  br i1 %r236, label %L853, label %L854
L853:
  %r237 = getelementptr [43 x i8], [43 x i8]* @.str.514, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = load i64, i64* %ptr_node
  %r240 = getelementptr [5 x i8], [5 x i8]* @.str.515, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_get(i64 %r239, i64 %r241)
  %r243 = call i64 @_add(i64 %r238, i64 %r242)
  %r244 = getelementptr [2 x i8], [2 x i8]* @.str.516, i64 0, i64 0
  %r245 = ptrtoint i8* %r244 to i64
  %r246 = call i64 @_add(i64 %r243, i64 %r245)
  call i64 @print_any(i64 %r246)
  br label %L855
L854:
  %r247 = call i64 @next_reg()
  store i64 %r247, i64* %ptr_list_reg
  %r248 = load i64, i64* %ptr_list_reg
  %r249 = getelementptr [19 x i8], [19 x i8]* @.str.517, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = call i64 @_add(i64 %r248, i64 %r250)
  %r252 = load i64, i64* %ptr_list_ptr
  %r253 = call i64 @_add(i64 %r251, i64 %r252)
  %r254 = call i64 @emit(i64 %r253)
  %r255 = getelementptr [28 x i8], [28 x i8]* @.str.518, i64 0, i64 0
  %r256 = ptrtoint i8* %r255 to i64
  %r257 = load i64, i64* %ptr_list_reg
  %r258 = call i64 @_add(i64 %r256, i64 %r257)
  %r259 = getelementptr [7 x i8], [7 x i8]* @.str.519, i64 0, i64 0
  %r260 = ptrtoint i8* %r259 to i64
  %r261 = call i64 @_add(i64 %r258, i64 %r260)
  %r262 = load i64, i64* %ptr_val
  %r263 = call i64 @_add(i64 %r261, i64 %r262)
  %r264 = getelementptr [2 x i8], [2 x i8]* @.str.520, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = call i64 @_add(i64 %r263, i64 %r265)
  %r267 = call i64 @emit(i64 %r266)
  br label %L855
L855:
  br label %L852
L851:
  br label %L852
L852:
  %r268 = load i64, i64* %ptr_node
  %r269 = getelementptr [5 x i8], [5 x i8]* @.str.521, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @_get(i64 %r268, i64 %r270)
  %r272 = load i64, i64* @STMT_PRINT
  %r273 = call i64 @_eq(i64 %r271, i64 %r272)
  %r274 = icmp ne i64 %r273, 0
  br i1 %r274, label %L856, label %L857
L856:
  %r275 = getelementptr [29 x i8], [29 x i8]* @.str.522, i64 0, i64 0
  %r276 = ptrtoint i8* %r275 to i64
  call i64 @print_any(i64 %r276)
  %r277 = load i64, i64* %ptr_node
  %r278 = getelementptr [4 x i8], [4 x i8]* @.str.523, i64 0, i64 0
  %r279 = ptrtoint i8* %r278 to i64
  %r280 = call i64 @_get(i64 %r277, i64 %r279)
  %r281 = call i64 @compile_expr(i64 %r280)
  store i64 %r281, i64* %ptr_val
  %r282 = getelementptr [25 x i8], [25 x i8]* @.str.524, i64 0, i64 0
  %r283 = ptrtoint i8* %r282 to i64
  %r284 = load i64, i64* %ptr_val
  %r285 = call i64 @_add(i64 %r283, i64 %r284)
  %r286 = getelementptr [2 x i8], [2 x i8]* @.str.525, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = call i64 @_add(i64 %r285, i64 %r287)
  %r289 = call i64 @emit(i64 %r288)
  br label %L858
L857:
  br label %L858
L858:
  %r290 = load i64, i64* %ptr_node
  %r291 = getelementptr [5 x i8], [5 x i8]* @.str.526, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_get(i64 %r290, i64 %r292)
  %r294 = load i64, i64* @STMT_BREAK
  %r295 = call i64 @_eq(i64 %r293, i64 %r294)
  %r296 = icmp ne i64 %r295, 0
  br i1 %r296, label %L859, label %L860
L859:
  %r297 = load i64, i64* @loop_end_stack
  %r298 = call i64 @mensura(i64 %r297)
  store i64 %r298, i64* %ptr_len
  %r299 = load i64, i64* %ptr_len
  %r301 = icmp sgt i64 %r299, 0
  %r300 = zext i1 %r301 to i64
  %r302 = icmp ne i64 %r300, 0
  br i1 %r302, label %L862, label %L863
L862:
  %r303 = load i64, i64* @loop_end_stack
  %r304 = load i64, i64* %ptr_len
  %r305 = sub i64 %r304, 1
  %r306 = call i64 @_get(i64 %r303, i64 %r305)
  store i64 %r306, i64* %ptr_lbl
  %r307 = getelementptr [11 x i8], [11 x i8]* @.str.527, i64 0, i64 0
  %r308 = ptrtoint i8* %r307 to i64
  %r309 = load i64, i64* %ptr_lbl
  %r310 = call i64 @_add(i64 %r308, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  br label %L864
L863:
  br label %L864
L864:
  br label %L861
L860:
  br label %L861
L861:
  %r312 = load i64, i64* %ptr_node
  %r313 = getelementptr [5 x i8], [5 x i8]* @.str.528, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_get(i64 %r312, i64 %r314)
  %r316 = load i64, i64* @STMT_CONTINUE
  %r317 = call i64 @_eq(i64 %r315, i64 %r316)
  %r318 = icmp ne i64 %r317, 0
  br i1 %r318, label %L865, label %L866
L865:
  %r319 = load i64, i64* @loop_cond_stack
  %r320 = call i64 @mensura(i64 %r319)
  store i64 %r320, i64* %ptr_len
  %r321 = load i64, i64* %ptr_len
  %r323 = icmp sgt i64 %r321, 0
  %r322 = zext i1 %r323 to i64
  %r324 = icmp ne i64 %r322, 0
  br i1 %r324, label %L868, label %L869
L868:
  %r325 = load i64, i64* @loop_cond_stack
  %r326 = load i64, i64* %ptr_len
  %r327 = sub i64 %r326, 1
  %r328 = call i64 @_get(i64 %r325, i64 %r327)
  store i64 %r328, i64* %ptr_lbl
  %r329 = getelementptr [11 x i8], [11 x i8]* @.str.529, i64 0, i64 0
  %r330 = ptrtoint i8* %r329 to i64
  %r331 = load i64, i64* %ptr_lbl
  %r332 = call i64 @_add(i64 %r330, i64 %r331)
  %r333 = call i64 @emit(i64 %r332)
  br label %L870
L869:
  br label %L870
L870:
  br label %L867
L866:
  br label %L867
L867:
  %r334 = load i64, i64* %ptr_node
  %r335 = getelementptr [5 x i8], [5 x i8]* @.str.530, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_get(i64 %r334, i64 %r336)
  %r338 = load i64, i64* @STMT_RETURN
  %r339 = call i64 @_eq(i64 %r337, i64 %r338)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L871, label %L872
L871:
  %r341 = load i64, i64* %ptr_node
  %r342 = getelementptr [4 x i8], [4 x i8]* @.str.531, i64 0, i64 0
  %r343 = ptrtoint i8* %r342 to i64
  %r344 = call i64 @_get(i64 %r341, i64 %r343)
  %r345 = call i64 @compile_expr(i64 %r344)
  store i64 %r345, i64* %ptr_val
  %r346 = getelementptr [9 x i8], [9 x i8]* @.str.532, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = load i64, i64* %ptr_val
  %r349 = call i64 @_add(i64 %r347, i64 %r348)
  %r350 = call i64 @emit(i64 %r349)
  br label %L873
L872:
  br label %L873
L873:
  %r351 = load i64, i64* %ptr_node
  %r352 = getelementptr [5 x i8], [5 x i8]* @.str.533, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_get(i64 %r351, i64 %r353)
  %r355 = load i64, i64* @STMT_EXPR
  %r356 = call i64 @_eq(i64 %r354, i64 %r355)
  %r357 = icmp ne i64 %r356, 0
  br i1 %r357, label %L874, label %L875
L874:
  %r358 = load i64, i64* %ptr_node
  %r359 = getelementptr [5 x i8], [5 x i8]* @.str.534, i64 0, i64 0
  %r360 = ptrtoint i8* %r359 to i64
  %r361 = call i64 @_get(i64 %r358, i64 %r360)
  %r362 = call i64 @compile_expr(i64 %r361)
  br label %L876
L875:
  br label %L876
L876:
  %r363 = load i64, i64* %ptr_node
  %r364 = getelementptr [5 x i8], [5 x i8]* @.str.535, i64 0, i64 0
  %r365 = ptrtoint i8* %r364 to i64
  %r366 = call i64 @_get(i64 %r363, i64 %r365)
  %r367 = load i64, i64* @STMT_IF
  %r368 = call i64 @_eq(i64 %r366, i64 %r367)
  %r369 = icmp ne i64 %r368, 0
  br i1 %r369, label %L877, label %L878
L877:
  %r370 = load i64, i64* %ptr_node
  %r371 = getelementptr [5 x i8], [5 x i8]* @.str.536, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_get(i64 %r370, i64 %r372)
  %r374 = call i64 @compile_expr(i64 %r373)
  store i64 %r374, i64* %ptr_cond
  %r375 = call i64 @next_reg()
  store i64 %r375, i64* %ptr_bool
  %r376 = load i64, i64* %ptr_bool
  %r377 = getelementptr [16 x i8], [16 x i8]* @.str.537, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_cond
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  %r382 = getelementptr [4 x i8], [4 x i8]* @.str.538, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_add(i64 %r381, i64 %r383)
  %r385 = call i64 @emit(i64 %r384)
  %r386 = call i64 @next_label()
  store i64 %r386, i64* %ptr_l_then
  %r387 = call i64 @next_label()
  store i64 %r387, i64* %ptr_l_else
  %r388 = call i64 @next_label()
  store i64 %r388, i64* %ptr_l_end
  %r389 = getelementptr [7 x i8], [7 x i8]* @.str.539, i64 0, i64 0
  %r390 = ptrtoint i8* %r389 to i64
  %r391 = load i64, i64* %ptr_bool
  %r392 = call i64 @_add(i64 %r390, i64 %r391)
  %r393 = getelementptr [10 x i8], [10 x i8]* @.str.540, i64 0, i64 0
  %r394 = ptrtoint i8* %r393 to i64
  %r395 = call i64 @_add(i64 %r392, i64 %r394)
  %r396 = load i64, i64* %ptr_l_then
  %r397 = call i64 @_add(i64 %r395, i64 %r396)
  %r398 = getelementptr [10 x i8], [10 x i8]* @.str.541, i64 0, i64 0
  %r399 = ptrtoint i8* %r398 to i64
  %r400 = call i64 @_add(i64 %r397, i64 %r399)
  %r401 = load i64, i64* %ptr_l_else
  %r402 = call i64 @_add(i64 %r400, i64 %r401)
  %r403 = call i64 @emit(i64 %r402)
  %r404 = load i64, i64* %ptr_l_then
  %r405 = getelementptr [2 x i8], [2 x i8]* @.str.542, i64 0, i64 0
  %r406 = ptrtoint i8* %r405 to i64
  %r407 = call i64 @_add(i64 %r404, i64 %r406)
  %r408 = call i64 @emit_raw(i64 %r407)
  %r409 = load i64, i64* %ptr_node
  %r410 = getelementptr [5 x i8], [5 x i8]* @.str.543, i64 0, i64 0
  %r411 = ptrtoint i8* %r410 to i64
  %r412 = call i64 @_get(i64 %r409, i64 %r411)
  %r413 = call i64 @compile_block(i64 %r412)
  %r414 = getelementptr [11 x i8], [11 x i8]* @.str.544, i64 0, i64 0
  %r415 = ptrtoint i8* %r414 to i64
  %r416 = load i64, i64* %ptr_l_end
  %r417 = call i64 @_add(i64 %r415, i64 %r416)
  %r418 = call i64 @emit(i64 %r417)
  %r419 = load i64, i64* %ptr_l_else
  %r420 = getelementptr [2 x i8], [2 x i8]* @.str.545, i64 0, i64 0
  %r421 = ptrtoint i8* %r420 to i64
  %r422 = call i64 @_add(i64 %r419, i64 %r421)
  %r423 = call i64 @emit_raw(i64 %r422)
  %r424 = load i64, i64* %ptr_node
  %r425 = getelementptr [5 x i8], [5 x i8]* @.str.546, i64 0, i64 0
  %r426 = ptrtoint i8* %r425 to i64
  %r427 = call i64 @_get(i64 %r424, i64 %r426)
  %r428 = call i64 @mensura(i64 %r427)
  %r430 = icmp sgt i64 %r428, 0
  %r429 = zext i1 %r430 to i64
  %r431 = icmp ne i64 %r429, 0
  br i1 %r431, label %L880, label %L881
L880:
  %r432 = load i64, i64* %ptr_node
  %r433 = getelementptr [5 x i8], [5 x i8]* @.str.547, i64 0, i64 0
  %r434 = ptrtoint i8* %r433 to i64
  %r435 = call i64 @_get(i64 %r432, i64 %r434)
  %r436 = call i64 @compile_block(i64 %r435)
  br label %L882
L881:
  br label %L882
L882:
  %r437 = getelementptr [11 x i8], [11 x i8]* @.str.548, i64 0, i64 0
  %r438 = ptrtoint i8* %r437 to i64
  %r439 = load i64, i64* %ptr_l_end
  %r440 = call i64 @_add(i64 %r438, i64 %r439)
  %r441 = call i64 @emit(i64 %r440)
  %r442 = load i64, i64* %ptr_l_end
  %r443 = getelementptr [2 x i8], [2 x i8]* @.str.549, i64 0, i64 0
  %r444 = ptrtoint i8* %r443 to i64
  %r445 = call i64 @_add(i64 %r442, i64 %r444)
  %r446 = call i64 @emit_raw(i64 %r445)
  br label %L879
L878:
  br label %L879
L879:
  %r447 = load i64, i64* %ptr_node
  %r448 = getelementptr [5 x i8], [5 x i8]* @.str.550, i64 0, i64 0
  %r449 = ptrtoint i8* %r448 to i64
  %r450 = call i64 @_get(i64 %r447, i64 %r449)
  %r451 = load i64, i64* @STMT_WHILE
  %r452 = call i64 @_eq(i64 %r450, i64 %r451)
  %r453 = icmp ne i64 %r452, 0
  br i1 %r453, label %L883, label %L884
L883:
  %r454 = call i64 @next_label()
  store i64 %r454, i64* %ptr_l_cond
  %r455 = call i64 @next_label()
  store i64 %r455, i64* %ptr_l_body
  %r456 = call i64 @next_label()
  store i64 %r456, i64* %ptr_l_end
  %r457 = load i64, i64* %ptr_l_cond
  %r458 = load i64, i64* @loop_cond_stack
  call i64 @_append_poly(i64 %r458, i64 %r457)
  %r459 = load i64, i64* %ptr_l_end
  %r460 = load i64, i64* @loop_end_stack
  call i64 @_append_poly(i64 %r460, i64 %r459)
  %r461 = getelementptr [11 x i8], [11 x i8]* @.str.551, i64 0, i64 0
  %r462 = ptrtoint i8* %r461 to i64
  %r463 = load i64, i64* %ptr_l_cond
  %r464 = call i64 @_add(i64 %r462, i64 %r463)
  %r465 = call i64 @emit(i64 %r464)
  %r466 = load i64, i64* %ptr_l_cond
  %r467 = getelementptr [2 x i8], [2 x i8]* @.str.552, i64 0, i64 0
  %r468 = ptrtoint i8* %r467 to i64
  %r469 = call i64 @_add(i64 %r466, i64 %r468)
  %r470 = call i64 @emit_raw(i64 %r469)
  %r471 = load i64, i64* %ptr_node
  %r472 = getelementptr [5 x i8], [5 x i8]* @.str.553, i64 0, i64 0
  %r473 = ptrtoint i8* %r472 to i64
  %r474 = call i64 @_get(i64 %r471, i64 %r473)
  %r475 = call i64 @compile_expr(i64 %r474)
  store i64 %r475, i64* %ptr_cond
  %r476 = call i64 @next_reg()
  store i64 %r476, i64* %ptr_bool
  %r477 = load i64, i64* %ptr_bool
  %r478 = getelementptr [16 x i8], [16 x i8]* @.str.554, i64 0, i64 0
  %r479 = ptrtoint i8* %r478 to i64
  %r480 = call i64 @_add(i64 %r477, i64 %r479)
  %r481 = load i64, i64* %ptr_cond
  %r482 = call i64 @_add(i64 %r480, i64 %r481)
  %r483 = getelementptr [4 x i8], [4 x i8]* @.str.555, i64 0, i64 0
  %r484 = ptrtoint i8* %r483 to i64
  %r485 = call i64 @_add(i64 %r482, i64 %r484)
  %r486 = call i64 @emit(i64 %r485)
  %r487 = getelementptr [7 x i8], [7 x i8]* @.str.556, i64 0, i64 0
  %r488 = ptrtoint i8* %r487 to i64
  %r489 = load i64, i64* %ptr_bool
  %r490 = call i64 @_add(i64 %r488, i64 %r489)
  %r491 = getelementptr [10 x i8], [10 x i8]* @.str.557, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_add(i64 %r490, i64 %r492)
  %r494 = load i64, i64* %ptr_l_body
  %r495 = call i64 @_add(i64 %r493, i64 %r494)
  %r496 = getelementptr [10 x i8], [10 x i8]* @.str.558, i64 0, i64 0
  %r497 = ptrtoint i8* %r496 to i64
  %r498 = call i64 @_add(i64 %r495, i64 %r497)
  %r499 = load i64, i64* %ptr_l_end
  %r500 = call i64 @_add(i64 %r498, i64 %r499)
  %r501 = call i64 @emit(i64 %r500)
  %r502 = load i64, i64* %ptr_l_body
  %r503 = getelementptr [2 x i8], [2 x i8]* @.str.559, i64 0, i64 0
  %r504 = ptrtoint i8* %r503 to i64
  %r505 = call i64 @_add(i64 %r502, i64 %r504)
  %r506 = call i64 @emit_raw(i64 %r505)
  %r507 = load i64, i64* %ptr_node
  %r508 = getelementptr [5 x i8], [5 x i8]* @.str.560, i64 0, i64 0
  %r509 = ptrtoint i8* %r508 to i64
  %r510 = call i64 @_get(i64 %r507, i64 %r509)
  %r511 = call i64 @compile_block(i64 %r510)
  %r512 = getelementptr [11 x i8], [11 x i8]* @.str.561, i64 0, i64 0
  %r513 = ptrtoint i8* %r512 to i64
  %r514 = load i64, i64* %ptr_l_cond
  %r515 = call i64 @_add(i64 %r513, i64 %r514)
  %r516 = call i64 @emit(i64 %r515)
  %r517 = load i64, i64* %ptr_l_end
  %r518 = getelementptr [2 x i8], [2 x i8]* @.str.562, i64 0, i64 0
  %r519 = ptrtoint i8* %r518 to i64
  %r520 = call i64 @_add(i64 %r517, i64 %r519)
  %r521 = call i64 @emit_raw(i64 %r520)
  %r522 = load i64, i64* @loop_cond_stack
  %r523 = call i64 @mensura(i64 %r522)
  store i64 %r523, i64* %ptr_len
  %r524 = getelementptr [1 x i8], [1 x i8]* @.str.563, i64 0, i64 0
  %r525 = ptrtoint i8* %r524 to i64
  store i64 %r525, i64* %ptr_extract_dummy
  %r526 = call i64 @_list_new()
  store i64 %r526, i64* %ptr_popped_cond
  store i64 0, i64* %ptr_i
  br label %L886
L886:
  %r527 = load i64, i64* %ptr_i
  %r528 = load i64, i64* %ptr_len
  %r529 = sub i64 %r528, 1
  %r531 = icmp slt i64 %r527, %r529
  %r530 = zext i1 %r531 to i64
  %r532 = icmp ne i64 %r530, 0
  br i1 %r532, label %L887, label %L888
L887:
  %r533 = load i64, i64* @loop_cond_stack
  %r534 = load i64, i64* %ptr_i
  %r535 = call i64 @_get(i64 %r533, i64 %r534)
  %r536 = load i64, i64* %ptr_popped_cond
  call i64 @_append_poly(i64 %r536, i64 %r535)
  %r537 = load i64, i64* %ptr_i
  %r538 = call i64 @_add(i64 %r537, i64 1)
  store i64 %r538, i64* %ptr_i
  br label %L886
L888:
  %r539 = load i64, i64* %ptr_popped_cond
  store i64 %r539, i64* @loop_cond_stack
  %r540 = call i64 @_list_new()
  store i64 %r540, i64* %ptr_popped_end
  store i64 0, i64* %ptr_i
  br label %L889
L889:
  %r541 = load i64, i64* %ptr_i
  %r542 = load i64, i64* %ptr_len
  %r543 = sub i64 %r542, 1
  %r545 = icmp slt i64 %r541, %r543
  %r544 = zext i1 %r545 to i64
  %r546 = icmp ne i64 %r544, 0
  br i1 %r546, label %L890, label %L891
L890:
  %r547 = load i64, i64* @loop_end_stack
  %r548 = load i64, i64* %ptr_i
  %r549 = call i64 @_get(i64 %r547, i64 %r548)
  %r550 = load i64, i64* %ptr_popped_end
  call i64 @_append_poly(i64 %r550, i64 %r549)
  %r551 = load i64, i64* %ptr_i
  %r552 = call i64 @_add(i64 %r551, i64 1)
  store i64 %r552, i64* %ptr_i
  br label %L889
L891:
  %r553 = load i64, i64* %ptr_popped_end
  store i64 %r553, i64* @loop_end_stack
  br label %L885
L884:
  br label %L885
L885:
  ret i64 0
}
define i64 @compile_block(i64 %arg_stmts) {
  %ptr_stmts = alloca i64
  store i64 %arg_stmts, i64* %ptr_stmts
  %ptr_i = alloca i64
  store i64 0, i64* %ptr_i
  br label %L892
L892:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L893, label %L894
L893:
  %r7 = load i64, i64* %ptr_stmts
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  %r10 = call i64 @compile_stmt(i64 %r9)
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @_add(i64 %r11, i64 1)
  store i64 %r12, i64* %ptr_i
  br label %L892
L894:
  ret i64 0
}
define i64 @scan_for_vars(i64 %arg_stmts) {
  %ptr_stmts = alloca i64
  store i64 %arg_stmts, i64* %ptr_stmts
  %ptr_i = alloca i64
  %ptr_s = alloca i64
  %ptr_nm = alloca i64
  %ptr_ptr = alloca i64
  store i64 0, i64* %ptr_i
  br label %L895
L895:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L896, label %L897
L896:
  %r7 = load i64, i64* %ptr_stmts
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  store i64 %r9, i64* %ptr_s
  %r10 = load i64, i64* %ptr_s
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.564, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = call i64 @_get(i64 %r10, i64 %r12)
  %r14 = load i64, i64* @STMT_LET
  %r15 = call i64 @_eq(i64 %r13, i64 %r14)
  %r16 = icmp ne i64 %r15, 0
  br i1 %r16, label %L898, label %L899
L898:
  %r17 = load i64, i64* %ptr_s
  %r18 = getelementptr [5 x i8], [5 x i8]* @.str.565, i64 0, i64 0
  %r19 = ptrtoint i8* %r18 to i64
  %r20 = call i64 @_get(i64 %r17, i64 %r19)
  store i64 %r20, i64* %ptr_nm
  %r21 = load i64, i64* @var_map
  %r22 = load i64, i64* %ptr_nm
  %r23 = call i64 @_get(i64 %r21, i64 %r22)
  store i64 %r23, i64* %ptr_ptr
  %r24 = load i64, i64* %ptr_ptr
  %r25 = call i64 @mensura(i64 %r24)
  %r26 = call i64 @_eq(i64 %r25, i64 0)
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L901, label %L902
L901:
  %r28 = getelementptr [6 x i8], [6 x i8]* @.str.566, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_nm
  %r31 = call i64 @_add(i64 %r29, i64 %r30)
  store i64 %r31, i64* %ptr_ptr
  %r32 = load i64, i64* %ptr_ptr
  %r33 = getelementptr [14 x i8], [14 x i8]* @.str.567, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_add(i64 %r32, i64 %r34)
  %r36 = call i64 @emit(i64 %r35)
  %r37 = load i64, i64* %ptr_ptr
  %r38 = load i64, i64* %ptr_nm
  %r39 = load i64, i64* @var_map
  call i64 @_set(i64 %r39, i64 %r38, i64 %r37)
  br label %L903
L902:
  br label %L903
L903:
  br label %L900
L899:
  br label %L900
L900:
  %r40 = load i64, i64* %ptr_s
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.568, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = call i64 @_get(i64 %r40, i64 %r42)
  %r44 = load i64, i64* @STMT_IF
  %r45 = call i64 @_eq(i64 %r43, i64 %r44)
  %r46 = icmp ne i64 %r45, 0
  br i1 %r46, label %L904, label %L905
L904:
  %r47 = load i64, i64* %ptr_s
  %r48 = getelementptr [5 x i8], [5 x i8]* @.str.569, i64 0, i64 0
  %r49 = ptrtoint i8* %r48 to i64
  %r50 = call i64 @_get(i64 %r47, i64 %r49)
  %r51 = call i64 @scan_for_vars(i64 %r50)
  %r52 = load i64, i64* %ptr_s
  %r53 = getelementptr [5 x i8], [5 x i8]* @.str.570, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = call i64 @_get(i64 %r52, i64 %r54)
  %r56 = call i64 @mensura(i64 %r55)
  %r58 = icmp sgt i64 %r56, 0
  %r57 = zext i1 %r58 to i64
  %r59 = icmp ne i64 %r57, 0
  br i1 %r59, label %L907, label %L908
L907:
  %r60 = load i64, i64* %ptr_s
  %r61 = getelementptr [5 x i8], [5 x i8]* @.str.571, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = call i64 @_get(i64 %r60, i64 %r62)
  %r64 = call i64 @scan_for_vars(i64 %r63)
  br label %L909
L908:
  br label %L909
L909:
  br label %L906
L905:
  br label %L906
L906:
  %r65 = load i64, i64* %ptr_s
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.572, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = call i64 @_get(i64 %r65, i64 %r67)
  %r69 = load i64, i64* @STMT_WHILE
  %r70 = call i64 @_eq(i64 %r68, i64 %r69)
  %r71 = icmp ne i64 %r70, 0
  br i1 %r71, label %L910, label %L911
L910:
  %r72 = load i64, i64* %ptr_s
  %r73 = getelementptr [5 x i8], [5 x i8]* @.str.573, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = call i64 @_get(i64 %r72, i64 %r74)
  %r76 = call i64 @scan_for_vars(i64 %r75)
  br label %L912
L911:
  br label %L912
L912:
  %r77 = load i64, i64* %ptr_i
  %r78 = call i64 @_add(i64 %r77, i64 1)
  store i64 %r78, i64* %ptr_i
  br label %L895
L897:
  ret i64 0
}
define i64 @compile_func(i64 %arg_node) {
  %ptr_node = alloca i64
  store i64 %arg_node, i64* %ptr_node
  %ptr_name = alloca i64
  %ptr_header = alloca i64
  %ptr_params = alloca i64
  %ptr_i = alloca i64
  %ptr_p = alloca i64
  %ptr_ptr = alloca i64
  %r1 = load i64, i64* %ptr_node
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.574, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  store i64 %r4, i64* %ptr_name
  %r5 = load i64, i64* %ptr_name
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.575, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_eq(i64 %r5, i64 %r7)
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L913, label %L914
L913:
  %r10 = getelementptr [12 x i8], [12 x i8]* @.str.576, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  store i64 %r11, i64* %ptr_name
  br label %L915
L914:
  br label %L915
L915:
  %r12 = getelementptr [13 x i8], [13 x i8]* @.str.577, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = load i64, i64* %ptr_name
  %r15 = call i64 @_add(i64 %r13, i64 %r14)
  %r16 = getelementptr [2 x i8], [2 x i8]* @.str.578, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  %r18 = call i64 @_add(i64 %r15, i64 %r17)
  store i64 %r18, i64* %ptr_header
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [7 x i8], [7 x i8]* @.str.579, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  store i64 %r22, i64* %ptr_params
  store i64 0, i64* %ptr_i
  %r23 = call i64 @_map_new()
  store i64 %r23, i64* @var_map
  store i64 0, i64* @reg_count
  br label %L916
L916:
  %r24 = load i64, i64* %ptr_i
  %r25 = load i64, i64* %ptr_params
  %r26 = call i64 @mensura(i64 %r25)
  %r28 = icmp slt i64 %r24, %r26
  %r27 = zext i1 %r28 to i64
  %r29 = icmp ne i64 %r27, 0
  br i1 %r29, label %L917, label %L918
L917:
  %r30 = load i64, i64* %ptr_header
  %r31 = getelementptr [10 x i8], [10 x i8]* @.str.580, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = call i64 @_add(i64 %r30, i64 %r32)
  %r34 = load i64, i64* %ptr_params
  %r35 = load i64, i64* %ptr_i
  %r36 = call i64 @_get(i64 %r34, i64 %r35)
  %r37 = call i64 @_add(i64 %r33, i64 %r36)
  store i64 %r37, i64* %ptr_header
  %r38 = load i64, i64* %ptr_i
  %r39 = load i64, i64* %ptr_params
  %r40 = call i64 @mensura(i64 %r39)
  %r41 = sub i64 %r40, 1
  %r43 = icmp slt i64 %r38, %r41
  %r42 = zext i1 %r43 to i64
  %r44 = icmp ne i64 %r42, 0
  br i1 %r44, label %L919, label %L920
L919:
  %r45 = load i64, i64* %ptr_header
  %r46 = getelementptr [3 x i8], [3 x i8]* @.str.581, i64 0, i64 0
  %r47 = ptrtoint i8* %r46 to i64
  %r48 = call i64 @_add(i64 %r45, i64 %r47)
  store i64 %r48, i64* %ptr_header
  br label %L921
L920:
  br label %L921
L921:
  %r49 = load i64, i64* %ptr_i
  %r50 = call i64 @_add(i64 %r49, i64 1)
  store i64 %r50, i64* %ptr_i
  br label %L916
L918:
  %r51 = load i64, i64* %ptr_header
  %r52 = getelementptr [4 x i8], [4 x i8]* @.str.582, i64 0, i64 0
  %r53 = ptrtoint i8* %r52 to i64
  %r54 = call i64 @_add(i64 %r51, i64 %r53)
  store i64 %r54, i64* %ptr_header
  %r55 = load i64, i64* %ptr_header
  %r56 = call i64 @emit_raw(i64 %r55)
  store i64 0, i64* %ptr_i
  br label %L922
L922:
  %r57 = load i64, i64* %ptr_i
  %r58 = load i64, i64* %ptr_params
  %r59 = call i64 @mensura(i64 %r58)
  %r61 = icmp slt i64 %r57, %r59
  %r60 = zext i1 %r61 to i64
  %r62 = icmp ne i64 %r60, 0
  br i1 %r62, label %L923, label %L924
L923:
  %r63 = load i64, i64* %ptr_params
  %r64 = load i64, i64* %ptr_i
  %r65 = call i64 @_get(i64 %r63, i64 %r64)
  store i64 %r65, i64* %ptr_p
  %r66 = getelementptr [6 x i8], [6 x i8]* @.str.583, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = load i64, i64* %ptr_p
  %r69 = call i64 @_add(i64 %r67, i64 %r68)
  store i64 %r69, i64* %ptr_ptr
  %r70 = load i64, i64* %ptr_ptr
  %r71 = getelementptr [14 x i8], [14 x i8]* @.str.584, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  %r74 = call i64 @emit(i64 %r73)
  %r75 = getelementptr [16 x i8], [16 x i8]* @.str.585, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = load i64, i64* %ptr_p
  %r78 = call i64 @_add(i64 %r76, i64 %r77)
  %r79 = getelementptr [8 x i8], [8 x i8]* @.str.586, i64 0, i64 0
  %r80 = ptrtoint i8* %r79 to i64
  %r81 = call i64 @_add(i64 %r78, i64 %r80)
  %r82 = load i64, i64* %ptr_ptr
  %r83 = call i64 @_add(i64 %r81, i64 %r82)
  %r84 = call i64 @emit(i64 %r83)
  %r85 = load i64, i64* %ptr_ptr
  %r86 = load i64, i64* %ptr_p
  %r87 = load i64, i64* @var_map
  call i64 @_set(i64 %r87, i64 %r86, i64 %r85)
  %r88 = load i64, i64* %ptr_i
  %r89 = call i64 @_add(i64 %r88, i64 1)
  store i64 %r89, i64* %ptr_i
  br label %L922
L924:
  %r90 = load i64, i64* %ptr_node
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.587, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = call i64 @scan_for_vars(i64 %r93)
  %r95 = load i64, i64* %ptr_node
  %r96 = getelementptr [5 x i8], [5 x i8]* @.str.588, i64 0, i64 0
  %r97 = ptrtoint i8* %r96 to i64
  %r98 = call i64 @_get(i64 %r95, i64 %r97)
  %r99 = call i64 @compile_block(i64 %r98)
  %r100 = getelementptr [10 x i8], [10 x i8]* @.str.589, i64 0, i64 0
  %r101 = ptrtoint i8* %r100 to i64
  %r102 = call i64 @emit(i64 %r101)
  %r103 = getelementptr [2 x i8], [2 x i8]* @.str.590, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @emit_raw(i64 %r104)
  ret i64 0
}
define i64 @get_llvm_header() {
  %ptr_NL = alloca i64
  %ptr_s = alloca i64
  %r1 = call i64 @signum_ex(i64 10)
  store i64 %r1, i64* %ptr_NL
  %r2 = getelementptr [29 x i8], [29 x i8]* @.str.591, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = load i64, i64* %ptr_NL
  %r5 = call i64 @_add(i64 %r3, i64 %r4)
  store i64 %r5, i64* %ptr_s
  %r6 = load i64, i64* %ptr_s
  %r7 = getelementptr [38 x i8], [38 x i8]* @.str.592, i64 0, i64 0
  %r8 = ptrtoint i8* %r7 to i64
  %r9 = call i64 @_add(i64 %r6, i64 %r8)
  %r10 = load i64, i64* %ptr_NL
  %r11 = call i64 @_add(i64 %r9, i64 %r10)
  store i64 %r11, i64* %ptr_s
  %r12 = load i64, i64* %ptr_s
  %r13 = getelementptr [30 x i8], [30 x i8]* @.str.593, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_add(i64 %r12, i64 %r14)
  %r16 = load i64, i64* %ptr_NL
  %r17 = call i64 @_add(i64 %r15, i64 %r16)
  store i64 %r17, i64* %ptr_s
  %r18 = load i64, i64* %ptr_s
  %r19 = getelementptr [36 x i8], [36 x i8]* @.str.594, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  %r22 = load i64, i64* %ptr_NL
  %r23 = call i64 @_add(i64 %r21, i64 %r22)
  store i64 %r23, i64* %ptr_s
  %r24 = load i64, i64* %ptr_s
  %r25 = getelementptr [25 x i8], [25 x i8]* @.str.595, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = call i64 @_add(i64 %r24, i64 %r26)
  %r28 = load i64, i64* %ptr_NL
  %r29 = call i64 @_add(i64 %r27, i64 %r28)
  store i64 %r29, i64* %ptr_s
  %r30 = load i64, i64* %ptr_s
  %r31 = getelementptr [25 x i8], [25 x i8]* @.str.596, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = call i64 @_add(i64 %r30, i64 %r32)
  %r34 = load i64, i64* %ptr_NL
  %r35 = call i64 @_add(i64 %r33, i64 %r34)
  store i64 %r35, i64* %ptr_s
  %r36 = load i64, i64* %ptr_s
  %r37 = getelementptr [31 x i8], [31 x i8]* @.str.597, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_add(i64 %r36, i64 %r38)
  %r40 = load i64, i64* %ptr_NL
  %r41 = call i64 @_add(i64 %r39, i64 %r40)
  store i64 %r41, i64* %ptr_s
  %r42 = load i64, i64* %ptr_s
  %r43 = getelementptr [23 x i8], [23 x i8]* @.str.598, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = call i64 @_add(i64 %r42, i64 %r44)
  %r46 = load i64, i64* %ptr_NL
  %r47 = call i64 @_add(i64 %r45, i64 %r46)
  store i64 %r47, i64* %ptr_s
  %r48 = load i64, i64* %ptr_s
  %r49 = getelementptr [24 x i8], [24 x i8]* @.str.599, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_add(i64 %r48, i64 %r50)
  %r52 = load i64, i64* %ptr_NL
  %r53 = call i64 @_add(i64 %r51, i64 %r52)
  store i64 %r53, i64* %ptr_s
  %r54 = load i64, i64* %ptr_s
  %r55 = getelementptr [29 x i8], [29 x i8]* @.str.600, i64 0, i64 0
  %r56 = ptrtoint i8* %r55 to i64
  %r57 = call i64 @_add(i64 %r54, i64 %r56)
  %r58 = load i64, i64* %ptr_NL
  %r59 = call i64 @_add(i64 %r57, i64 %r58)
  store i64 %r59, i64* %ptr_s
  %r60 = load i64, i64* %ptr_s
  %r61 = getelementptr [34 x i8], [34 x i8]* @.str.601, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = call i64 @_add(i64 %r60, i64 %r62)
  %r64 = load i64, i64* %ptr_NL
  %r65 = call i64 @_add(i64 %r63, i64 %r64)
  store i64 %r65, i64* %ptr_s
  %r66 = load i64, i64* %ptr_s
  %r67 = getelementptr [24 x i8], [24 x i8]* @.str.602, i64 0, i64 0
  %r68 = ptrtoint i8* %r67 to i64
  %r69 = call i64 @_add(i64 %r66, i64 %r68)
  %r70 = load i64, i64* %ptr_NL
  %r71 = call i64 @_add(i64 %r69, i64 %r70)
  store i64 %r71, i64* %ptr_s
  %r72 = load i64, i64* %ptr_s
  %r73 = getelementptr [39 x i8], [39 x i8]* @.str.603, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = call i64 @_add(i64 %r72, i64 %r74)
  %r76 = load i64, i64* %ptr_NL
  %r77 = call i64 @_add(i64 %r75, i64 %r76)
  store i64 %r77, i64* %ptr_s
  %r78 = load i64, i64* %ptr_s
  %r79 = getelementptr [40 x i8], [40 x i8]* @.str.604, i64 0, i64 0
  %r80 = ptrtoint i8* %r79 to i64
  %r81 = call i64 @_add(i64 %r78, i64 %r80)
  %r82 = load i64, i64* %ptr_NL
  %r83 = call i64 @_add(i64 %r81, i64 %r82)
  store i64 %r83, i64* %ptr_s
  %r84 = load i64, i64* %ptr_s
  %r85 = getelementptr [25 x i8], [25 x i8]* @.str.605, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = call i64 @_add(i64 %r84, i64 %r86)
  %r88 = load i64, i64* %ptr_NL
  %r89 = call i64 @_add(i64 %r87, i64 %r88)
  store i64 %r89, i64* %ptr_s
  %r90 = load i64, i64* %ptr_s
  %r91 = getelementptr [25 x i8], [25 x i8]* @.str.606, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_add(i64 %r90, i64 %r92)
  %r94 = load i64, i64* %ptr_NL
  %r95 = call i64 @_add(i64 %r93, i64 %r94)
  store i64 %r95, i64* %ptr_s
  %r96 = load i64, i64* %ptr_s
  %r97 = getelementptr [25 x i8], [25 x i8]* @.str.607, i64 0, i64 0
  %r98 = ptrtoint i8* %r97 to i64
  %r99 = call i64 @_add(i64 %r96, i64 %r98)
  %r100 = load i64, i64* %ptr_NL
  %r101 = call i64 @_add(i64 %r99, i64 %r100)
  store i64 %r101, i64* %ptr_s
  %r102 = load i64, i64* %ptr_s
  %r103 = getelementptr [23 x i8], [23 x i8]* @.str.608, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @_add(i64 %r102, i64 %r104)
  %r106 = load i64, i64* %ptr_NL
  %r107 = call i64 @_add(i64 %r105, i64 %r106)
  store i64 %r107, i64* %ptr_s
  %r108 = load i64, i64* %ptr_s
  %r109 = getelementptr [30 x i8], [30 x i8]* @.str.609, i64 0, i64 0
  %r110 = ptrtoint i8* %r109 to i64
  %r111 = call i64 @_add(i64 %r108, i64 %r110)
  %r112 = load i64, i64* %ptr_NL
  %r113 = call i64 @_add(i64 %r111, i64 %r112)
  store i64 %r113, i64* %ptr_s
  %r114 = load i64, i64* %ptr_s
  %r115 = getelementptr [73 x i8], [73 x i8]* @.str.610, i64 0, i64 0
  %r116 = ptrtoint i8* %r115 to i64
  %r117 = call i64 @_add(i64 %r114, i64 %r116)
  %r118 = load i64, i64* %ptr_NL
  %r119 = call i64 @_add(i64 %r117, i64 %r118)
  store i64 %r119, i64* %ptr_s
  %r120 = load i64, i64* %ptr_s
  %r121 = getelementptr [72 x i8], [72 x i8]* @.str.611, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = call i64 @_add(i64 %r120, i64 %r122)
  %r124 = load i64, i64* %ptr_NL
  %r125 = call i64 @_add(i64 %r123, i64 %r124)
  store i64 %r125, i64* %ptr_s
  %r126 = load i64, i64* %ptr_s
  %r127 = getelementptr [71 x i8], [71 x i8]* @.str.612, i64 0, i64 0
  %r128 = ptrtoint i8* %r127 to i64
  %r129 = call i64 @_add(i64 %r126, i64 %r128)
  %r130 = load i64, i64* %ptr_NL
  %r131 = call i64 @_add(i64 %r129, i64 %r130)
  store i64 %r131, i64* %ptr_s
  %r132 = load i64, i64* %ptr_s
  %r133 = getelementptr [72 x i8], [72 x i8]* @.str.613, i64 0, i64 0
  %r134 = ptrtoint i8* %r133 to i64
  %r135 = call i64 @_add(i64 %r132, i64 %r134)
  %r136 = load i64, i64* %ptr_NL
  %r137 = call i64 @_add(i64 %r135, i64 %r136)
  store i64 %r137, i64* %ptr_s
  %r138 = load i64, i64* %ptr_s
  %r139 = getelementptr [67 x i8], [67 x i8]* @.str.614, i64 0, i64 0
  %r140 = ptrtoint i8* %r139 to i64
  %r141 = call i64 @_add(i64 %r138, i64 %r140)
  %r142 = load i64, i64* %ptr_NL
  %r143 = call i64 @_add(i64 %r141, i64 %r142)
  store i64 %r143, i64* %ptr_s
  %r144 = load i64, i64* %ptr_s
  %r145 = getelementptr [67 x i8], [67 x i8]* @.str.615, i64 0, i64 0
  %r146 = ptrtoint i8* %r145 to i64
  %r147 = call i64 @_add(i64 %r144, i64 %r146)
  %r148 = load i64, i64* %ptr_NL
  %r149 = call i64 @_add(i64 %r147, i64 %r148)
  store i64 %r149, i64* %ptr_s
  %r150 = load i64, i64* %ptr_s
  %r151 = getelementptr [73 x i8], [73 x i8]* @.str.616, i64 0, i64 0
  %r152 = ptrtoint i8* %r151 to i64
  %r153 = call i64 @_add(i64 %r150, i64 %r152)
  %r154 = load i64, i64* %ptr_NL
  %r155 = call i64 @_add(i64 %r153, i64 %r154)
  store i64 %r155, i64* %ptr_s
  %r156 = load i64, i64* %ptr_s
  %r157 = getelementptr [72 x i8], [72 x i8]* @.str.617, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = call i64 @_add(i64 %r156, i64 %r158)
  %r160 = load i64, i64* %ptr_NL
  %r161 = call i64 @_add(i64 %r159, i64 %r160)
  store i64 %r161, i64* %ptr_s
  %r162 = load i64, i64* %ptr_s
  %r163 = getelementptr [40 x i8], [40 x i8]* @.str.618, i64 0, i64 0
  %r164 = ptrtoint i8* %r163 to i64
  %r165 = call i64 @_add(i64 %r162, i64 %r164)
  %r166 = load i64, i64* %ptr_NL
  %r167 = call i64 @_add(i64 %r165, i64 %r166)
  store i64 %r167, i64* %ptr_s
  %r168 = load i64, i64* %ptr_s
  %r169 = getelementptr [36 x i8], [36 x i8]* @.str.619, i64 0, i64 0
  %r170 = ptrtoint i8* %r169 to i64
  %r171 = call i64 @_add(i64 %r168, i64 %r170)
  %r172 = load i64, i64* %ptr_NL
  %r173 = call i64 @_add(i64 %r171, i64 %r172)
  store i64 %r173, i64* %ptr_s
  %r174 = load i64, i64* %ptr_s
  %r175 = getelementptr [68 x i8], [68 x i8]* @.str.620, i64 0, i64 0
  %r176 = ptrtoint i8* %r175 to i64
  %r177 = call i64 @_add(i64 %r174, i64 %r176)
  %r178 = load i64, i64* %ptr_NL
  %r179 = call i64 @_add(i64 %r177, i64 %r178)
  store i64 %r179, i64* %ptr_s
  %r180 = load i64, i64* %ptr_s
  %r181 = getelementptr [71 x i8], [71 x i8]* @.str.621, i64 0, i64 0
  %r182 = ptrtoint i8* %r181 to i64
  %r183 = call i64 @_add(i64 %r180, i64 %r182)
  %r184 = load i64, i64* %ptr_NL
  %r185 = call i64 @_add(i64 %r183, i64 %r184)
  store i64 %r185, i64* %ptr_s
  %r186 = load i64, i64* %ptr_s
  %r187 = getelementptr [69 x i8], [69 x i8]* @.str.622, i64 0, i64 0
  %r188 = ptrtoint i8* %r187 to i64
  %r189 = call i64 @_add(i64 %r186, i64 %r188)
  %r190 = load i64, i64* %ptr_NL
  %r191 = call i64 @_add(i64 %r189, i64 %r190)
  store i64 %r191, i64* %ptr_s
  %r192 = load i64, i64* %ptr_s
  %r193 = getelementptr [39 x i8], [39 x i8]* @.str.623, i64 0, i64 0
  %r194 = ptrtoint i8* %r193 to i64
  %r195 = call i64 @_add(i64 %r192, i64 %r194)
  %r196 = load i64, i64* %ptr_NL
  %r197 = call i64 @_add(i64 %r195, i64 %r196)
  store i64 %r197, i64* %ptr_s
  %r198 = load i64, i64* %ptr_s
  %r199 = getelementptr [31 x i8], [31 x i8]* @.str.624, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_add(i64 %r198, i64 %r200)
  %r202 = load i64, i64* %ptr_NL
  %r203 = call i64 @_add(i64 %r201, i64 %r202)
  store i64 %r203, i64* %ptr_s
  %r204 = load i64, i64* %ptr_s
  %r205 = getelementptr [31 x i8], [31 x i8]* @.str.625, i64 0, i64 0
  %r206 = ptrtoint i8* %r205 to i64
  %r207 = call i64 @_add(i64 %r204, i64 %r206)
  %r208 = load i64, i64* %ptr_NL
  %r209 = call i64 @_add(i64 %r207, i64 %r208)
  store i64 %r209, i64* %ptr_s
  %r210 = load i64, i64* %ptr_s
  %r211 = getelementptr [34 x i8], [34 x i8]* @.str.626, i64 0, i64 0
  %r212 = ptrtoint i8* %r211 to i64
  %r213 = call i64 @_add(i64 %r210, i64 %r212)
  %r214 = load i64, i64* %ptr_NL
  %r215 = call i64 @_add(i64 %r213, i64 %r214)
  store i64 %r215, i64* %ptr_s
  %r216 = load i64, i64* %ptr_s
  %r217 = getelementptr [34 x i8], [34 x i8]* @.str.627, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_add(i64 %r216, i64 %r218)
  %r220 = load i64, i64* %ptr_NL
  %r221 = call i64 @_add(i64 %r219, i64 %r220)
  store i64 %r221, i64* %ptr_s
  %r222 = load i64, i64* %ptr_s
  %r223 = getelementptr [25 x i8], [25 x i8]* @.str.628, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = call i64 @_add(i64 %r222, i64 %r224)
  %r226 = load i64, i64* %ptr_NL
  %r227 = call i64 @_add(i64 %r225, i64 %r226)
  store i64 %r227, i64* %ptr_s
  %r228 = load i64, i64* %ptr_s
  %r229 = getelementptr [24 x i8], [24 x i8]* @.str.629, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @_add(i64 %r228, i64 %r230)
  %r232 = load i64, i64* %ptr_NL
  %r233 = call i64 @_add(i64 %r231, i64 %r232)
  store i64 %r233, i64* %ptr_s
  %r234 = load i64, i64* %ptr_s
  %r235 = getelementptr [36 x i8], [36 x i8]* @.str.630, i64 0, i64 0
  %r236 = ptrtoint i8* %r235 to i64
  %r237 = call i64 @_add(i64 %r234, i64 %r236)
  %r238 = load i64, i64* %ptr_NL
  %r239 = call i64 @_add(i64 %r237, i64 %r238)
  store i64 %r239, i64* %ptr_s
  %r240 = load i64, i64* %ptr_s
  %r241 = getelementptr [34 x i8], [34 x i8]* @.str.631, i64 0, i64 0
  %r242 = ptrtoint i8* %r241 to i64
  %r243 = call i64 @_add(i64 %r240, i64 %r242)
  %r244 = load i64, i64* %ptr_NL
  %r245 = call i64 @_add(i64 %r243, i64 %r244)
  store i64 %r245, i64* %ptr_s
  %r246 = load i64, i64* %ptr_s
  %r247 = getelementptr [38 x i8], [38 x i8]* @.str.632, i64 0, i64 0
  %r248 = ptrtoint i8* %r247 to i64
  %r249 = call i64 @_add(i64 %r246, i64 %r248)
  %r250 = load i64, i64* %ptr_NL
  %r251 = call i64 @_add(i64 %r249, i64 %r250)
  store i64 %r251, i64* %ptr_s
  %r252 = load i64, i64* %ptr_s
  %r253 = getelementptr [38 x i8], [38 x i8]* @.str.633, i64 0, i64 0
  %r254 = ptrtoint i8* %r253 to i64
  %r255 = call i64 @_add(i64 %r252, i64 %r254)
  %r256 = load i64, i64* %ptr_NL
  %r257 = call i64 @_add(i64 %r255, i64 %r256)
  store i64 %r257, i64* %ptr_s
  %r258 = load i64, i64* %ptr_s
  %r259 = getelementptr [15 x i8], [15 x i8]* @.str.634, i64 0, i64 0
  %r260 = ptrtoint i8* %r259 to i64
  %r261 = call i64 @_add(i64 %r258, i64 %r260)
  %r262 = load i64, i64* %ptr_NL
  %r263 = call i64 @_add(i64 %r261, i64 %r262)
  store i64 %r263, i64* %ptr_s
  %r264 = load i64, i64* %ptr_s
  %r265 = getelementptr [2 x i8], [2 x i8]* @.str.635, i64 0, i64 0
  %r266 = ptrtoint i8* %r265 to i64
  %r267 = call i64 @_add(i64 %r264, i64 %r266)
  %r268 = load i64, i64* %ptr_NL
  %r269 = call i64 @_add(i64 %r267, i64 %r268)
  store i64 %r269, i64* %ptr_s
  %r270 = load i64, i64* %ptr_s
  %r271 = getelementptr [34 x i8], [34 x i8]* @.str.636, i64 0, i64 0
  %r272 = ptrtoint i8* %r271 to i64
  %r273 = call i64 @_add(i64 %r270, i64 %r272)
  %r274 = load i64, i64* %ptr_NL
  %r275 = call i64 @_add(i64 %r273, i64 %r274)
  store i64 %r275, i64* %ptr_s
  %r276 = load i64, i64* %ptr_s
  %r277 = getelementptr [42 x i8], [42 x i8]* @.str.637, i64 0, i64 0
  %r278 = ptrtoint i8* %r277 to i64
  %r279 = call i64 @_add(i64 %r276, i64 %r278)
  %r280 = load i64, i64* %ptr_NL
  %r281 = call i64 @_add(i64 %r279, i64 %r280)
  store i64 %r281, i64* %ptr_s
  %r282 = load i64, i64* %ptr_s
  %r283 = getelementptr [46 x i8], [46 x i8]* @.str.638, i64 0, i64 0
  %r284 = ptrtoint i8* %r283 to i64
  %r285 = call i64 @_add(i64 %r282, i64 %r284)
  %r286 = load i64, i64* %ptr_NL
  %r287 = call i64 @_add(i64 %r285, i64 %r286)
  store i64 %r287, i64* %ptr_s
  %r288 = load i64, i64* %ptr_s
  %r289 = getelementptr [21 x i8], [21 x i8]* @.str.639, i64 0, i64 0
  %r290 = ptrtoint i8* %r289 to i64
  %r291 = call i64 @_add(i64 %r288, i64 %r290)
  %r292 = load i64, i64* %ptr_NL
  %r293 = call i64 @_add(i64 %r291, i64 %r292)
  store i64 %r293, i64* %ptr_s
  %r294 = load i64, i64* %ptr_s
  %r295 = getelementptr [8 x i8], [8 x i8]* @.str.640, i64 0, i64 0
  %r296 = ptrtoint i8* %r295 to i64
  %r297 = call i64 @_add(i64 %r294, i64 %r296)
  %r298 = load i64, i64* %ptr_NL
  %r299 = call i64 @_add(i64 %r297, i64 %r298)
  store i64 %r299, i64* %ptr_s
  %r300 = load i64, i64* %ptr_s
  %r301 = getelementptr [34 x i8], [34 x i8]* @.str.641, i64 0, i64 0
  %r302 = ptrtoint i8* %r301 to i64
  %r303 = call i64 @_add(i64 %r300, i64 %r302)
  %r304 = load i64, i64* %ptr_NL
  %r305 = call i64 @_add(i64 %r303, i64 %r304)
  store i64 %r305, i64* %ptr_s
  %r306 = load i64, i64* %ptr_s
  %r307 = getelementptr [32 x i8], [32 x i8]* @.str.642, i64 0, i64 0
  %r308 = ptrtoint i8* %r307 to i64
  %r309 = call i64 @_add(i64 %r306, i64 %r308)
  %r310 = load i64, i64* %ptr_NL
  %r311 = call i64 @_add(i64 %r309, i64 %r310)
  store i64 %r311, i64* %ptr_s
  %r312 = load i64, i64* %ptr_s
  %r313 = getelementptr [69 x i8], [69 x i8]* @.str.643, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_add(i64 %r312, i64 %r314)
  %r316 = load i64, i64* %ptr_NL
  %r317 = call i64 @_add(i64 %r315, i64 %r316)
  store i64 %r317, i64* %ptr_s
  %r318 = load i64, i64* %ptr_s
  %r319 = getelementptr [64 x i8], [64 x i8]* @.str.644, i64 0, i64 0
  %r320 = ptrtoint i8* %r319 to i64
  %r321 = call i64 @_add(i64 %r318, i64 %r320)
  %r322 = load i64, i64* %ptr_NL
  %r323 = call i64 @_add(i64 %r321, i64 %r322)
  store i64 %r323, i64* %ptr_s
  %r324 = load i64, i64* %ptr_s
  %r325 = getelementptr [15 x i8], [15 x i8]* @.str.645, i64 0, i64 0
  %r326 = ptrtoint i8* %r325 to i64
  %r327 = call i64 @_add(i64 %r324, i64 %r326)
  %r328 = load i64, i64* %ptr_NL
  %r329 = call i64 @_add(i64 %r327, i64 %r328)
  store i64 %r329, i64* %ptr_s
  %r330 = load i64, i64* %ptr_s
  %r331 = getelementptr [2 x i8], [2 x i8]* @.str.646, i64 0, i64 0
  %r332 = ptrtoint i8* %r331 to i64
  %r333 = call i64 @_add(i64 %r330, i64 %r332)
  %r334 = load i64, i64* %ptr_NL
  %r335 = call i64 @_add(i64 %r333, i64 %r334)
  store i64 %r335, i64* %ptr_s
  %r336 = load i64, i64* %ptr_s
  %r337 = getelementptr [35 x i8], [35 x i8]* @.str.647, i64 0, i64 0
  %r338 = ptrtoint i8* %r337 to i64
  %r339 = call i64 @_add(i64 %r336, i64 %r338)
  %r340 = load i64, i64* %ptr_NL
  %r341 = call i64 @_add(i64 %r339, i64 %r340)
  store i64 %r341, i64* %ptr_s
  %r342 = load i64, i64* %ptr_s
  %r343 = getelementptr [42 x i8], [42 x i8]* @.str.648, i64 0, i64 0
  %r344 = ptrtoint i8* %r343 to i64
  %r345 = call i64 @_add(i64 %r342, i64 %r344)
  %r346 = load i64, i64* %ptr_NL
  %r347 = call i64 @_add(i64 %r345, i64 %r346)
  store i64 %r347, i64* %ptr_s
  %r348 = load i64, i64* %ptr_s
  %r349 = getelementptr [42 x i8], [42 x i8]* @.str.649, i64 0, i64 0
  %r350 = ptrtoint i8* %r349 to i64
  %r351 = call i64 @_add(i64 %r348, i64 %r350)
  %r352 = load i64, i64* %ptr_NL
  %r353 = call i64 @_add(i64 %r351, i64 %r352)
  store i64 %r353, i64* %ptr_s
  %r354 = load i64, i64* %ptr_s
  %r355 = getelementptr [42 x i8], [42 x i8]* @.str.650, i64 0, i64 0
  %r356 = ptrtoint i8* %r355 to i64
  %r357 = call i64 @_add(i64 %r354, i64 %r356)
  %r358 = load i64, i64* %ptr_NL
  %r359 = call i64 @_add(i64 %r357, i64 %r358)
  store i64 %r359, i64* %ptr_s
  %r360 = load i64, i64* %ptr_s
  %r361 = getelementptr [40 x i8], [40 x i8]* @.str.651, i64 0, i64 0
  %r362 = ptrtoint i8* %r361 to i64
  %r363 = call i64 @_add(i64 %r360, i64 %r362)
  %r364 = load i64, i64* %ptr_NL
  %r365 = call i64 @_add(i64 %r363, i64 %r364)
  store i64 %r365, i64* %ptr_s
  %r366 = load i64, i64* %ptr_s
  %r367 = getelementptr [55 x i8], [55 x i8]* @.str.652, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_add(i64 %r366, i64 %r368)
  %r370 = load i64, i64* %ptr_NL
  %r371 = call i64 @_add(i64 %r369, i64 %r370)
  store i64 %r371, i64* %ptr_s
  %r372 = load i64, i64* %ptr_s
  %r373 = getelementptr [12 x i8], [12 x i8]* @.str.653, i64 0, i64 0
  %r374 = ptrtoint i8* %r373 to i64
  %r375 = call i64 @_add(i64 %r372, i64 %r374)
  %r376 = load i64, i64* %ptr_NL
  %r377 = call i64 @_add(i64 %r375, i64 %r376)
  store i64 %r377, i64* %ptr_s
  %r378 = load i64, i64* %ptr_s
  %r379 = getelementptr [34 x i8], [34 x i8]* @.str.654, i64 0, i64 0
  %r380 = ptrtoint i8* %r379 to i64
  %r381 = call i64 @_add(i64 %r378, i64 %r380)
  %r382 = load i64, i64* %ptr_NL
  %r383 = call i64 @_add(i64 %r381, i64 %r382)
  store i64 %r383, i64* %ptr_s
  %r384 = load i64, i64* %ptr_s
  %r385 = getelementptr [32 x i8], [32 x i8]* @.str.655, i64 0, i64 0
  %r386 = ptrtoint i8* %r385 to i64
  %r387 = call i64 @_add(i64 %r384, i64 %r386)
  %r388 = load i64, i64* %ptr_NL
  %r389 = call i64 @_add(i64 %r387, i64 %r388)
  store i64 %r389, i64* %ptr_s
  %r390 = load i64, i64* %ptr_s
  %r391 = getelementptr [35 x i8], [35 x i8]* @.str.656, i64 0, i64 0
  %r392 = ptrtoint i8* %r391 to i64
  %r393 = call i64 @_add(i64 %r390, i64 %r392)
  %r394 = load i64, i64* %ptr_NL
  %r395 = call i64 @_add(i64 %r393, i64 %r394)
  store i64 %r395, i64* %ptr_s
  %r396 = load i64, i64* %ptr_s
  %r397 = getelementptr [51 x i8], [51 x i8]* @.str.657, i64 0, i64 0
  %r398 = ptrtoint i8* %r397 to i64
  %r399 = call i64 @_add(i64 %r396, i64 %r398)
  %r400 = load i64, i64* %ptr_NL
  %r401 = call i64 @_add(i64 %r399, i64 %r400)
  store i64 %r401, i64* %ptr_s
  %r402 = load i64, i64* %ptr_s
  %r403 = getelementptr [11 x i8], [11 x i8]* @.str.658, i64 0, i64 0
  %r404 = ptrtoint i8* %r403 to i64
  %r405 = call i64 @_add(i64 %r402, i64 %r404)
  %r406 = load i64, i64* %ptr_NL
  %r407 = call i64 @_add(i64 %r405, i64 %r406)
  store i64 %r407, i64* %ptr_s
  %r408 = load i64, i64* %ptr_s
  %r409 = getelementptr [44 x i8], [44 x i8]* @.str.659, i64 0, i64 0
  %r410 = ptrtoint i8* %r409 to i64
  %r411 = call i64 @_add(i64 %r408, i64 %r410)
  %r412 = load i64, i64* %ptr_NL
  %r413 = call i64 @_add(i64 %r411, i64 %r412)
  store i64 %r413, i64* %ptr_s
  %r414 = load i64, i64* %ptr_s
  %r415 = getelementptr [8 x i8], [8 x i8]* @.str.660, i64 0, i64 0
  %r416 = ptrtoint i8* %r415 to i64
  %r417 = call i64 @_add(i64 %r414, i64 %r416)
  %r418 = load i64, i64* %ptr_NL
  %r419 = call i64 @_add(i64 %r417, i64 %r418)
  store i64 %r419, i64* %ptr_s
  %r420 = load i64, i64* %ptr_s
  %r421 = getelementptr [36 x i8], [36 x i8]* @.str.661, i64 0, i64 0
  %r422 = ptrtoint i8* %r421 to i64
  %r423 = call i64 @_add(i64 %r420, i64 %r422)
  %r424 = load i64, i64* %ptr_NL
  %r425 = call i64 @_add(i64 %r423, i64 %r424)
  store i64 %r425, i64* %ptr_s
  %r426 = load i64, i64* %ptr_s
  %r427 = getelementptr [36 x i8], [36 x i8]* @.str.662, i64 0, i64 0
  %r428 = ptrtoint i8* %r427 to i64
  %r429 = call i64 @_add(i64 %r426, i64 %r428)
  %r430 = load i64, i64* %ptr_NL
  %r431 = call i64 @_add(i64 %r429, i64 %r430)
  store i64 %r431, i64* %ptr_s
  %r432 = load i64, i64* %ptr_s
  %r433 = getelementptr [50 x i8], [50 x i8]* @.str.663, i64 0, i64 0
  %r434 = ptrtoint i8* %r433 to i64
  %r435 = call i64 @_add(i64 %r432, i64 %r434)
  %r436 = load i64, i64* %ptr_NL
  %r437 = call i64 @_add(i64 %r435, i64 %r436)
  store i64 %r437, i64* %ptr_s
  %r438 = load i64, i64* %ptr_s
  %r439 = getelementptr [19 x i8], [19 x i8]* @.str.664, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  %r441 = call i64 @_add(i64 %r438, i64 %r440)
  %r442 = load i64, i64* %ptr_NL
  %r443 = call i64 @_add(i64 %r441, i64 %r442)
  store i64 %r443, i64* %ptr_s
  %r444 = load i64, i64* %ptr_s
  %r445 = getelementptr [9 x i8], [9 x i8]* @.str.665, i64 0, i64 0
  %r446 = ptrtoint i8* %r445 to i64
  %r447 = call i64 @_add(i64 %r444, i64 %r446)
  %r448 = load i64, i64* %ptr_NL
  %r449 = call i64 @_add(i64 %r447, i64 %r448)
  store i64 %r449, i64* %ptr_s
  %r450 = load i64, i64* %ptr_s
  %r451 = getelementptr [36 x i8], [36 x i8]* @.str.666, i64 0, i64 0
  %r452 = ptrtoint i8* %r451 to i64
  %r453 = call i64 @_add(i64 %r450, i64 %r452)
  %r454 = load i64, i64* %ptr_NL
  %r455 = call i64 @_add(i64 %r453, i64 %r454)
  store i64 %r455, i64* %ptr_s
  %r456 = load i64, i64* %ptr_s
  %r457 = getelementptr [47 x i8], [47 x i8]* @.str.667, i64 0, i64 0
  %r458 = ptrtoint i8* %r457 to i64
  %r459 = call i64 @_add(i64 %r456, i64 %r458)
  %r460 = load i64, i64* %ptr_NL
  %r461 = call i64 @_add(i64 %r459, i64 %r460)
  store i64 %r461, i64* %ptr_s
  %r462 = load i64, i64* %ptr_s
  %r463 = getelementptr [47 x i8], [47 x i8]* @.str.668, i64 0, i64 0
  %r464 = ptrtoint i8* %r463 to i64
  %r465 = call i64 @_add(i64 %r462, i64 %r464)
  %r466 = load i64, i64* %ptr_NL
  %r467 = call i64 @_add(i64 %r465, i64 %r466)
  store i64 %r467, i64* %ptr_s
  %r468 = load i64, i64* %ptr_s
  %r469 = getelementptr [20 x i8], [20 x i8]* @.str.669, i64 0, i64 0
  %r470 = ptrtoint i8* %r469 to i64
  %r471 = call i64 @_add(i64 %r468, i64 %r470)
  %r472 = load i64, i64* %ptr_NL
  %r473 = call i64 @_add(i64 %r471, i64 %r472)
  store i64 %r473, i64* %ptr_s
  %r474 = load i64, i64* %ptr_s
  %r475 = getelementptr [5 x i8], [5 x i8]* @.str.670, i64 0, i64 0
  %r476 = ptrtoint i8* %r475 to i64
  %r477 = call i64 @_add(i64 %r474, i64 %r476)
  %r478 = load i64, i64* %ptr_NL
  %r479 = call i64 @_add(i64 %r477, i64 %r478)
  store i64 %r479, i64* %ptr_s
  %r480 = load i64, i64* %ptr_s
  %r481 = getelementptr [28 x i8], [28 x i8]* @.str.671, i64 0, i64 0
  %r482 = ptrtoint i8* %r481 to i64
  %r483 = call i64 @_add(i64 %r480, i64 %r482)
  %r484 = load i64, i64* %ptr_NL
  %r485 = call i64 @_add(i64 %r483, i64 %r484)
  store i64 %r485, i64* %ptr_s
  %r486 = load i64, i64* %ptr_s
  %r487 = getelementptr [19 x i8], [19 x i8]* @.str.672, i64 0, i64 0
  %r488 = ptrtoint i8* %r487 to i64
  %r489 = call i64 @_add(i64 %r486, i64 %r488)
  %r490 = load i64, i64* %ptr_NL
  %r491 = call i64 @_add(i64 %r489, i64 %r490)
  store i64 %r491, i64* %ptr_s
  %r492 = load i64, i64* %ptr_s
  %r493 = getelementptr [2 x i8], [2 x i8]* @.str.673, i64 0, i64 0
  %r494 = ptrtoint i8* %r493 to i64
  %r495 = call i64 @_add(i64 %r492, i64 %r494)
  %r496 = load i64, i64* %ptr_NL
  %r497 = call i64 @_add(i64 %r495, i64 %r496)
  store i64 %r497, i64* %ptr_s
  %r498 = load i64, i64* %ptr_s
  %r499 = getelementptr [47 x i8], [47 x i8]* @.str.674, i64 0, i64 0
  %r500 = ptrtoint i8* %r499 to i64
  %r501 = call i64 @_add(i64 %r498, i64 %r500)
  %r502 = load i64, i64* %ptr_NL
  %r503 = call i64 @_add(i64 %r501, i64 %r502)
  store i64 %r503, i64* %ptr_s
  %r504 = load i64, i64* %ptr_s
  %r505 = getelementptr [35 x i8], [35 x i8]* @.str.675, i64 0, i64 0
  %r506 = ptrtoint i8* %r505 to i64
  %r507 = call i64 @_add(i64 %r504, i64 %r506)
  %r508 = load i64, i64* %ptr_NL
  %r509 = call i64 @_add(i64 %r507, i64 %r508)
  store i64 %r509, i64* %ptr_s
  %r510 = load i64, i64* %ptr_s
  %r511 = getelementptr [49 x i8], [49 x i8]* @.str.676, i64 0, i64 0
  %r512 = ptrtoint i8* %r511 to i64
  %r513 = call i64 @_add(i64 %r510, i64 %r512)
  %r514 = load i64, i64* %ptr_NL
  %r515 = call i64 @_add(i64 %r513, i64 %r514)
  store i64 %r515, i64* %ptr_s
  %r516 = load i64, i64* %ptr_s
  %r517 = getelementptr [33 x i8], [33 x i8]* @.str.677, i64 0, i64 0
  %r518 = ptrtoint i8* %r517 to i64
  %r519 = call i64 @_add(i64 %r516, i64 %r518)
  %r520 = load i64, i64* %ptr_NL
  %r521 = call i64 @_add(i64 %r519, i64 %r520)
  store i64 %r521, i64* %ptr_s
  %r522 = load i64, i64* %ptr_s
  %r523 = getelementptr [50 x i8], [50 x i8]* @.str.678, i64 0, i64 0
  %r524 = ptrtoint i8* %r523 to i64
  %r525 = call i64 @_add(i64 %r522, i64 %r524)
  %r526 = load i64, i64* %ptr_NL
  %r527 = call i64 @_add(i64 %r525, i64 %r526)
  store i64 %r527, i64* %ptr_s
  %r528 = load i64, i64* %ptr_s
  %r529 = getelementptr [35 x i8], [35 x i8]* @.str.679, i64 0, i64 0
  %r530 = ptrtoint i8* %r529 to i64
  %r531 = call i64 @_add(i64 %r528, i64 %r530)
  %r532 = load i64, i64* %ptr_NL
  %r533 = call i64 @_add(i64 %r531, i64 %r532)
  store i64 %r533, i64* %ptr_s
  %r534 = load i64, i64* %ptr_s
  %r535 = getelementptr [41 x i8], [41 x i8]* @.str.680, i64 0, i64 0
  %r536 = ptrtoint i8* %r535 to i64
  %r537 = call i64 @_add(i64 %r534, i64 %r536)
  %r538 = load i64, i64* %ptr_NL
  %r539 = call i64 @_add(i64 %r537, i64 %r538)
  store i64 %r539, i64* %ptr_s
  %r540 = load i64, i64* %ptr_s
  %r541 = getelementptr [17 x i8], [17 x i8]* @.str.681, i64 0, i64 0
  %r542 = ptrtoint i8* %r541 to i64
  %r543 = call i64 @_add(i64 %r540, i64 %r542)
  %r544 = load i64, i64* %ptr_NL
  %r545 = call i64 @_add(i64 %r543, i64 %r544)
  store i64 %r545, i64* %ptr_s
  %r546 = load i64, i64* %ptr_s
  %r547 = getelementptr [6 x i8], [6 x i8]* @.str.682, i64 0, i64 0
  %r548 = ptrtoint i8* %r547 to i64
  %r549 = call i64 @_add(i64 %r546, i64 %r548)
  %r550 = load i64, i64* %ptr_NL
  %r551 = call i64 @_add(i64 %r549, i64 %r550)
  store i64 %r551, i64* %ptr_s
  %r552 = load i64, i64* %ptr_s
  %r553 = getelementptr [45 x i8], [45 x i8]* @.str.683, i64 0, i64 0
  %r554 = ptrtoint i8* %r553 to i64
  %r555 = call i64 @_add(i64 %r552, i64 %r554)
  %r556 = load i64, i64* %ptr_NL
  %r557 = call i64 @_add(i64 %r555, i64 %r556)
  store i64 %r557, i64* %ptr_s
  %r558 = load i64, i64* %ptr_s
  %r559 = getelementptr [32 x i8], [32 x i8]* @.str.684, i64 0, i64 0
  %r560 = ptrtoint i8* %r559 to i64
  %r561 = call i64 @_add(i64 %r558, i64 %r560)
  %r562 = load i64, i64* %ptr_NL
  %r563 = call i64 @_add(i64 %r561, i64 %r562)
  store i64 %r563, i64* %ptr_s
  %r564 = load i64, i64* %ptr_s
  %r565 = getelementptr [40 x i8], [40 x i8]* @.str.685, i64 0, i64 0
  %r566 = ptrtoint i8* %r565 to i64
  %r567 = call i64 @_add(i64 %r564, i64 %r566)
  %r568 = load i64, i64* %ptr_NL
  %r569 = call i64 @_add(i64 %r567, i64 %r568)
  store i64 %r569, i64* %ptr_s
  %r570 = load i64, i64* %ptr_s
  %r571 = getelementptr [6 x i8], [6 x i8]* @.str.686, i64 0, i64 0
  %r572 = ptrtoint i8* %r571 to i64
  %r573 = call i64 @_add(i64 %r570, i64 %r572)
  %r574 = load i64, i64* %ptr_NL
  %r575 = call i64 @_add(i64 %r573, i64 %r574)
  store i64 %r575, i64* %ptr_s
  %r576 = load i64, i64* %ptr_s
  %r577 = getelementptr [52 x i8], [52 x i8]* @.str.687, i64 0, i64 0
  %r578 = ptrtoint i8* %r577 to i64
  %r579 = call i64 @_add(i64 %r576, i64 %r578)
  %r580 = load i64, i64* %ptr_NL
  %r581 = call i64 @_add(i64 %r579, i64 %r580)
  store i64 %r581, i64* %ptr_s
  %r582 = load i64, i64* %ptr_s
  %r583 = getelementptr [30 x i8], [30 x i8]* @.str.688, i64 0, i64 0
  %r584 = ptrtoint i8* %r583 to i64
  %r585 = call i64 @_add(i64 %r582, i64 %r584)
  %r586 = load i64, i64* %ptr_NL
  %r587 = call i64 @_add(i64 %r585, i64 %r586)
  store i64 %r587, i64* %ptr_s
  %r588 = load i64, i64* %ptr_s
  %r589 = getelementptr [44 x i8], [44 x i8]* @.str.689, i64 0, i64 0
  %r590 = ptrtoint i8* %r589 to i64
  %r591 = call i64 @_add(i64 %r588, i64 %r590)
  %r592 = load i64, i64* %ptr_NL
  %r593 = call i64 @_add(i64 %r591, i64 %r592)
  store i64 %r593, i64* %ptr_s
  %r594 = load i64, i64* %ptr_s
  %r595 = getelementptr [26 x i8], [26 x i8]* @.str.690, i64 0, i64 0
  %r596 = ptrtoint i8* %r595 to i64
  %r597 = call i64 @_add(i64 %r594, i64 %r596)
  %r598 = load i64, i64* %ptr_NL
  %r599 = call i64 @_add(i64 %r597, i64 %r598)
  store i64 %r599, i64* %ptr_s
  %r600 = load i64, i64* %ptr_s
  %r601 = getelementptr [17 x i8], [17 x i8]* @.str.691, i64 0, i64 0
  %r602 = ptrtoint i8* %r601 to i64
  %r603 = call i64 @_add(i64 %r600, i64 %r602)
  %r604 = load i64, i64* %ptr_NL
  %r605 = call i64 @_add(i64 %r603, i64 %r604)
  store i64 %r605, i64* %ptr_s
  %r606 = load i64, i64* %ptr_s
  %r607 = getelementptr [6 x i8], [6 x i8]* @.str.692, i64 0, i64 0
  %r608 = ptrtoint i8* %r607 to i64
  %r609 = call i64 @_add(i64 %r606, i64 %r608)
  %r610 = load i64, i64* %ptr_NL
  %r611 = call i64 @_add(i64 %r609, i64 %r610)
  store i64 %r611, i64* %ptr_s
  %r612 = load i64, i64* %ptr_s
  %r613 = getelementptr [11 x i8], [11 x i8]* @.str.693, i64 0, i64 0
  %r614 = ptrtoint i8* %r613 to i64
  %r615 = call i64 @_add(i64 %r612, i64 %r614)
  %r616 = load i64, i64* %ptr_NL
  %r617 = call i64 @_add(i64 %r615, i64 %r616)
  store i64 %r617, i64* %ptr_s
  %r618 = load i64, i64* %ptr_s
  %r619 = getelementptr [2 x i8], [2 x i8]* @.str.694, i64 0, i64 0
  %r620 = ptrtoint i8* %r619 to i64
  %r621 = call i64 @_add(i64 %r618, i64 %r620)
  %r622 = load i64, i64* %ptr_NL
  %r623 = call i64 @_add(i64 %r621, i64 %r622)
  store i64 %r623, i64* %ptr_s
  %r624 = load i64, i64* %ptr_s
  %r625 = getelementptr [48 x i8], [48 x i8]* @.str.695, i64 0, i64 0
  %r626 = ptrtoint i8* %r625 to i64
  %r627 = call i64 @_add(i64 %r624, i64 %r626)
  %r628 = load i64, i64* %ptr_NL
  %r629 = call i64 @_add(i64 %r627, i64 %r628)
  store i64 %r629, i64* %ptr_s
  %r630 = load i64, i64* %ptr_s
  %r631 = getelementptr [42 x i8], [42 x i8]* @.str.696, i64 0, i64 0
  %r632 = ptrtoint i8* %r631 to i64
  %r633 = call i64 @_add(i64 %r630, i64 %r632)
  %r634 = load i64, i64* %ptr_NL
  %r635 = call i64 @_add(i64 %r633, i64 %r634)
  store i64 %r635, i64* %ptr_s
  %r636 = load i64, i64* %ptr_s
  %r637 = getelementptr [52 x i8], [52 x i8]* @.str.697, i64 0, i64 0
  %r638 = ptrtoint i8* %r637 to i64
  %r639 = call i64 @_add(i64 %r636, i64 %r638)
  %r640 = load i64, i64* %ptr_NL
  %r641 = call i64 @_add(i64 %r639, i64 %r640)
  store i64 %r641, i64* %ptr_s
  %r642 = load i64, i64* %ptr_s
  %r643 = getelementptr [12 x i8], [12 x i8]* @.str.698, i64 0, i64 0
  %r644 = ptrtoint i8* %r643 to i64
  %r645 = call i64 @_add(i64 %r642, i64 %r644)
  %r646 = load i64, i64* %ptr_NL
  %r647 = call i64 @_add(i64 %r645, i64 %r646)
  store i64 %r647, i64* %ptr_s
  %r648 = load i64, i64* %ptr_s
  %r649 = getelementptr [34 x i8], [34 x i8]* @.str.699, i64 0, i64 0
  %r650 = ptrtoint i8* %r649 to i64
  %r651 = call i64 @_add(i64 %r648, i64 %r650)
  %r652 = load i64, i64* %ptr_NL
  %r653 = call i64 @_add(i64 %r651, i64 %r652)
  store i64 %r653, i64* %ptr_s
  %r654 = load i64, i64* %ptr_s
  %r655 = getelementptr [28 x i8], [28 x i8]* @.str.700, i64 0, i64 0
  %r656 = ptrtoint i8* %r655 to i64
  %r657 = call i64 @_add(i64 %r654, i64 %r656)
  %r658 = load i64, i64* %ptr_NL
  %r659 = call i64 @_add(i64 %r657, i64 %r658)
  store i64 %r659, i64* %ptr_s
  %r660 = load i64, i64* %ptr_s
  %r661 = getelementptr [33 x i8], [33 x i8]* @.str.701, i64 0, i64 0
  %r662 = ptrtoint i8* %r661 to i64
  %r663 = call i64 @_add(i64 %r660, i64 %r662)
  %r664 = load i64, i64* %ptr_NL
  %r665 = call i64 @_add(i64 %r663, i64 %r664)
  store i64 %r665, i64* %ptr_s
  %r666 = load i64, i64* %ptr_s
  %r667 = getelementptr [48 x i8], [48 x i8]* @.str.702, i64 0, i64 0
  %r668 = ptrtoint i8* %r667 to i64
  %r669 = call i64 @_add(i64 %r666, i64 %r668)
  %r670 = load i64, i64* %ptr_NL
  %r671 = call i64 @_add(i64 %r669, i64 %r670)
  store i64 %r671, i64* %ptr_s
  %r672 = load i64, i64* %ptr_s
  %r673 = getelementptr [7 x i8], [7 x i8]* @.str.703, i64 0, i64 0
  %r674 = ptrtoint i8* %r673 to i64
  %r675 = call i64 @_add(i64 %r672, i64 %r674)
  %r676 = load i64, i64* %ptr_NL
  %r677 = call i64 @_add(i64 %r675, i64 %r676)
  store i64 %r677, i64* %ptr_s
  %r678 = load i64, i64* %ptr_s
  %r679 = getelementptr [45 x i8], [45 x i8]* @.str.704, i64 0, i64 0
  %r680 = ptrtoint i8* %r679 to i64
  %r681 = call i64 @_add(i64 %r678, i64 %r680)
  %r682 = load i64, i64* %ptr_NL
  %r683 = call i64 @_add(i64 %r681, i64 %r682)
  store i64 %r683, i64* %ptr_s
  %r684 = load i64, i64* %ptr_s
  %r685 = getelementptr [12 x i8], [12 x i8]* @.str.705, i64 0, i64 0
  %r686 = ptrtoint i8* %r685 to i64
  %r687 = call i64 @_add(i64 %r684, i64 %r686)
  %r688 = load i64, i64* %ptr_NL
  %r689 = call i64 @_add(i64 %r687, i64 %r688)
  store i64 %r689, i64* %ptr_s
  %r690 = load i64, i64* %ptr_s
  %r691 = getelementptr [10 x i8], [10 x i8]* @.str.706, i64 0, i64 0
  %r692 = ptrtoint i8* %r691 to i64
  %r693 = call i64 @_add(i64 %r690, i64 %r692)
  %r694 = load i64, i64* %ptr_NL
  %r695 = call i64 @_add(i64 %r693, i64 %r694)
  store i64 %r695, i64* %ptr_s
  %r696 = load i64, i64* %ptr_s
  %r697 = getelementptr [44 x i8], [44 x i8]* @.str.707, i64 0, i64 0
  %r698 = ptrtoint i8* %r697 to i64
  %r699 = call i64 @_add(i64 %r696, i64 %r698)
  %r700 = load i64, i64* %ptr_NL
  %r701 = call i64 @_add(i64 %r699, i64 %r700)
  store i64 %r701, i64* %ptr_s
  %r702 = load i64, i64* %ptr_s
  %r703 = getelementptr [12 x i8], [12 x i8]* @.str.708, i64 0, i64 0
  %r704 = ptrtoint i8* %r703 to i64
  %r705 = call i64 @_add(i64 %r702, i64 %r704)
  %r706 = load i64, i64* %ptr_NL
  %r707 = call i64 @_add(i64 %r705, i64 %r706)
  store i64 %r707, i64* %ptr_s
  %r708 = load i64, i64* %ptr_s
  %r709 = getelementptr [2 x i8], [2 x i8]* @.str.709, i64 0, i64 0
  %r710 = ptrtoint i8* %r709 to i64
  %r711 = call i64 @_add(i64 %r708, i64 %r710)
  %r712 = load i64, i64* %ptr_NL
  %r713 = call i64 @_add(i64 %r711, i64 %r712)
  store i64 %r713, i64* %ptr_s
  %r714 = load i64, i64* %ptr_s
  %r715 = getelementptr [34 x i8], [34 x i8]* @.str.710, i64 0, i64 0
  %r716 = ptrtoint i8* %r715 to i64
  %r717 = call i64 @_add(i64 %r714, i64 %r716)
  %r718 = load i64, i64* %ptr_NL
  %r719 = call i64 @_add(i64 %r717, i64 %r718)
  store i64 %r719, i64* %ptr_s
  %r720 = load i64, i64* %ptr_s
  %r721 = getelementptr [42 x i8], [42 x i8]* @.str.711, i64 0, i64 0
  %r722 = ptrtoint i8* %r721 to i64
  %r723 = call i64 @_add(i64 %r720, i64 %r722)
  %r724 = load i64, i64* %ptr_NL
  %r725 = call i64 @_add(i64 %r723, i64 %r724)
  store i64 %r725, i64* %ptr_s
  %r726 = load i64, i64* %ptr_s
  %r727 = getelementptr [42 x i8], [42 x i8]* @.str.712, i64 0, i64 0
  %r728 = ptrtoint i8* %r727 to i64
  %r729 = call i64 @_add(i64 %r726, i64 %r728)
  %r730 = load i64, i64* %ptr_NL
  %r731 = call i64 @_add(i64 %r729, i64 %r730)
  store i64 %r731, i64* %ptr_s
  %r732 = load i64, i64* %ptr_s
  %r733 = getelementptr [42 x i8], [42 x i8]* @.str.713, i64 0, i64 0
  %r734 = ptrtoint i8* %r733 to i64
  %r735 = call i64 @_add(i64 %r732, i64 %r734)
  %r736 = load i64, i64* %ptr_NL
  %r737 = call i64 @_add(i64 %r735, i64 %r736)
  store i64 %r737, i64* %ptr_s
  %r738 = load i64, i64* %ptr_s
  %r739 = getelementptr [53 x i8], [53 x i8]* @.str.714, i64 0, i64 0
  %r740 = ptrtoint i8* %r739 to i64
  %r741 = call i64 @_add(i64 %r738, i64 %r740)
  %r742 = load i64, i64* %ptr_NL
  %r743 = call i64 @_add(i64 %r741, i64 %r742)
  store i64 %r743, i64* %ptr_s
  %r744 = load i64, i64* %ptr_s
  %r745 = getelementptr [12 x i8], [12 x i8]* @.str.715, i64 0, i64 0
  %r746 = ptrtoint i8* %r745 to i64
  %r747 = call i64 @_add(i64 %r744, i64 %r746)
  %r748 = load i64, i64* %ptr_NL
  %r749 = call i64 @_add(i64 %r747, i64 %r748)
  store i64 %r749, i64* %ptr_s
  %r750 = load i64, i64* %ptr_s
  %r751 = getelementptr [30 x i8], [30 x i8]* @.str.716, i64 0, i64 0
  %r752 = ptrtoint i8* %r751 to i64
  %r753 = call i64 @_add(i64 %r750, i64 %r752)
  %r754 = load i64, i64* %ptr_NL
  %r755 = call i64 @_add(i64 %r753, i64 %r754)
  store i64 %r755, i64* %ptr_s
  %r756 = load i64, i64* %ptr_s
  %r757 = getelementptr [30 x i8], [30 x i8]* @.str.717, i64 0, i64 0
  %r758 = ptrtoint i8* %r757 to i64
  %r759 = call i64 @_add(i64 %r756, i64 %r758)
  %r760 = load i64, i64* %ptr_NL
  %r761 = call i64 @_add(i64 %r759, i64 %r760)
  store i64 %r761, i64* %ptr_s
  %r762 = load i64, i64* %ptr_s
  %r763 = getelementptr [37 x i8], [37 x i8]* @.str.718, i64 0, i64 0
  %r764 = ptrtoint i8* %r763 to i64
  %r765 = call i64 @_add(i64 %r762, i64 %r764)
  %r766 = load i64, i64* %ptr_NL
  %r767 = call i64 @_add(i64 %r765, i64 %r766)
  store i64 %r767, i64* %ptr_s
  %r768 = load i64, i64* %ptr_s
  %r769 = getelementptr [50 x i8], [50 x i8]* @.str.719, i64 0, i64 0
  %r770 = ptrtoint i8* %r769 to i64
  %r771 = call i64 @_add(i64 %r768, i64 %r770)
  %r772 = load i64, i64* %ptr_NL
  %r773 = call i64 @_add(i64 %r771, i64 %r772)
  store i64 %r773, i64* %ptr_s
  %r774 = load i64, i64* %ptr_s
  %r775 = getelementptr [9 x i8], [9 x i8]* @.str.720, i64 0, i64 0
  %r776 = ptrtoint i8* %r775 to i64
  %r777 = call i64 @_add(i64 %r774, i64 %r776)
  %r778 = load i64, i64* %ptr_NL
  %r779 = call i64 @_add(i64 %r777, i64 %r778)
  store i64 %r779, i64* %ptr_s
  %r780 = load i64, i64* %ptr_s
  %r781 = getelementptr [31 x i8], [31 x i8]* @.str.721, i64 0, i64 0
  %r782 = ptrtoint i8* %r781 to i64
  %r783 = call i64 @_add(i64 %r780, i64 %r782)
  %r784 = load i64, i64* %ptr_NL
  %r785 = call i64 @_add(i64 %r783, i64 %r784)
  store i64 %r785, i64* %ptr_s
  %r786 = load i64, i64* %ptr_s
  %r787 = getelementptr [31 x i8], [31 x i8]* @.str.722, i64 0, i64 0
  %r788 = ptrtoint i8* %r787 to i64
  %r789 = call i64 @_add(i64 %r786, i64 %r788)
  %r790 = load i64, i64* %ptr_NL
  %r791 = call i64 @_add(i64 %r789, i64 %r790)
  store i64 %r791, i64* %ptr_s
  %r792 = load i64, i64* %ptr_s
  %r793 = getelementptr [44 x i8], [44 x i8]* @.str.723, i64 0, i64 0
  %r794 = ptrtoint i8* %r793 to i64
  %r795 = call i64 @_add(i64 %r792, i64 %r794)
  %r796 = load i64, i64* %ptr_NL
  %r797 = call i64 @_add(i64 %r795, i64 %r796)
  store i64 %r797, i64* %ptr_s
  %r798 = load i64, i64* %ptr_s
  %r799 = getelementptr [30 x i8], [30 x i8]* @.str.724, i64 0, i64 0
  %r800 = ptrtoint i8* %r799 to i64
  %r801 = call i64 @_add(i64 %r798, i64 %r800)
  %r802 = load i64, i64* %ptr_NL
  %r803 = call i64 @_add(i64 %r801, i64 %r802)
  store i64 %r803, i64* %ptr_s
  %r804 = load i64, i64* %ptr_s
  %r805 = getelementptr [34 x i8], [34 x i8]* @.str.725, i64 0, i64 0
  %r806 = ptrtoint i8* %r805 to i64
  %r807 = call i64 @_add(i64 %r804, i64 %r806)
  %r808 = load i64, i64* %ptr_NL
  %r809 = call i64 @_add(i64 %r807, i64 %r808)
  store i64 %r809, i64* %ptr_s
  %r810 = load i64, i64* %ptr_s
  %r811 = getelementptr [19 x i8], [19 x i8]* @.str.726, i64 0, i64 0
  %r812 = ptrtoint i8* %r811 to i64
  %r813 = call i64 @_add(i64 %r810, i64 %r812)
  %r814 = load i64, i64* %ptr_NL
  %r815 = call i64 @_add(i64 %r813, i64 %r814)
  store i64 %r815, i64* %ptr_s
  %r816 = load i64, i64* %ptr_s
  %r817 = getelementptr [9 x i8], [9 x i8]* @.str.727, i64 0, i64 0
  %r818 = ptrtoint i8* %r817 to i64
  %r819 = call i64 @_add(i64 %r816, i64 %r818)
  %r820 = load i64, i64* %ptr_NL
  %r821 = call i64 @_add(i64 %r819, i64 %r820)
  store i64 %r821, i64* %ptr_s
  %r822 = load i64, i64* %ptr_s
  %r823 = getelementptr [33 x i8], [33 x i8]* @.str.728, i64 0, i64 0
  %r824 = ptrtoint i8* %r823 to i64
  %r825 = call i64 @_add(i64 %r822, i64 %r824)
  %r826 = load i64, i64* %ptr_NL
  %r827 = call i64 @_add(i64 %r825, i64 %r826)
  store i64 %r827, i64* %ptr_s
  %r828 = load i64, i64* %ptr_s
  %r829 = getelementptr [38 x i8], [38 x i8]* @.str.729, i64 0, i64 0
  %r830 = ptrtoint i8* %r829 to i64
  %r831 = call i64 @_add(i64 %r828, i64 %r830)
  %r832 = load i64, i64* %ptr_NL
  %r833 = call i64 @_add(i64 %r831, i64 %r832)
  store i64 %r833, i64* %ptr_s
  %r834 = load i64, i64* %ptr_s
  %r835 = getelementptr [19 x i8], [19 x i8]* @.str.730, i64 0, i64 0
  %r836 = ptrtoint i8* %r835 to i64
  %r837 = call i64 @_add(i64 %r834, i64 %r836)
  %r838 = load i64, i64* %ptr_NL
  %r839 = call i64 @_add(i64 %r837, i64 %r838)
  store i64 %r839, i64* %ptr_s
  %r840 = load i64, i64* %ptr_s
  %r841 = getelementptr [2 x i8], [2 x i8]* @.str.731, i64 0, i64 0
  %r842 = ptrtoint i8* %r841 to i64
  %r843 = call i64 @_add(i64 %r840, i64 %r842)
  %r844 = load i64, i64* %ptr_NL
  %r845 = call i64 @_add(i64 %r843, i64 %r844)
  store i64 %r845, i64* %ptr_s
  %r846 = load i64, i64* %ptr_s
  %r847 = getelementptr [26 x i8], [26 x i8]* @.str.732, i64 0, i64 0
  %r848 = ptrtoint i8* %r847 to i64
  %r849 = call i64 @_add(i64 %r846, i64 %r848)
  %r850 = load i64, i64* %ptr_NL
  %r851 = call i64 @_add(i64 %r849, i64 %r850)
  store i64 %r851, i64* %ptr_s
  %r852 = load i64, i64* %ptr_s
  %r853 = getelementptr [34 x i8], [34 x i8]* @.str.733, i64 0, i64 0
  %r854 = ptrtoint i8* %r853 to i64
  %r855 = call i64 @_add(i64 %r852, i64 %r854)
  %r856 = load i64, i64* %ptr_NL
  %r857 = call i64 @_add(i64 %r855, i64 %r856)
  store i64 %r857, i64* %ptr_s
  %r858 = load i64, i64* %ptr_s
  %r859 = getelementptr [35 x i8], [35 x i8]* @.str.734, i64 0, i64 0
  %r860 = ptrtoint i8* %r859 to i64
  %r861 = call i64 @_add(i64 %r858, i64 %r860)
  %r862 = load i64, i64* %ptr_NL
  %r863 = call i64 @_add(i64 %r861, i64 %r862)
  store i64 %r863, i64* %ptr_s
  %r864 = load i64, i64* %ptr_s
  %r865 = getelementptr [25 x i8], [25 x i8]* @.str.735, i64 0, i64 0
  %r866 = ptrtoint i8* %r865 to i64
  %r867 = call i64 @_add(i64 %r864, i64 %r866)
  %r868 = load i64, i64* %ptr_NL
  %r869 = call i64 @_add(i64 %r867, i64 %r868)
  store i64 %r869, i64* %ptr_s
  %r870 = load i64, i64* %ptr_s
  %r871 = getelementptr [45 x i8], [45 x i8]* @.str.736, i64 0, i64 0
  %r872 = ptrtoint i8* %r871 to i64
  %r873 = call i64 @_add(i64 %r870, i64 %r872)
  %r874 = load i64, i64* %ptr_NL
  %r875 = call i64 @_add(i64 %r873, i64 %r874)
  store i64 %r875, i64* %ptr_s
  %r876 = load i64, i64* %ptr_s
  %r877 = getelementptr [25 x i8], [25 x i8]* @.str.737, i64 0, i64 0
  %r878 = ptrtoint i8* %r877 to i64
  %r879 = call i64 @_add(i64 %r876, i64 %r878)
  %r880 = load i64, i64* %ptr_NL
  %r881 = call i64 @_add(i64 %r879, i64 %r880)
  store i64 %r881, i64* %ptr_s
  %r882 = load i64, i64* %ptr_s
  %r883 = getelementptr [46 x i8], [46 x i8]* @.str.738, i64 0, i64 0
  %r884 = ptrtoint i8* %r883 to i64
  %r885 = call i64 @_add(i64 %r882, i64 %r884)
  %r886 = load i64, i64* %ptr_NL
  %r887 = call i64 @_add(i64 %r885, i64 %r886)
  store i64 %r887, i64* %ptr_s
  %r888 = load i64, i64* %ptr_s
  %r889 = getelementptr [26 x i8], [26 x i8]* @.str.739, i64 0, i64 0
  %r890 = ptrtoint i8* %r889 to i64
  %r891 = call i64 @_add(i64 %r888, i64 %r890)
  %r892 = load i64, i64* %ptr_NL
  %r893 = call i64 @_add(i64 %r891, i64 %r892)
  store i64 %r893, i64* %ptr_s
  %r894 = load i64, i64* %ptr_s
  %r895 = getelementptr [15 x i8], [15 x i8]* @.str.740, i64 0, i64 0
  %r896 = ptrtoint i8* %r895 to i64
  %r897 = call i64 @_add(i64 %r894, i64 %r896)
  %r898 = load i64, i64* %ptr_NL
  %r899 = call i64 @_add(i64 %r897, i64 %r898)
  store i64 %r899, i64* %ptr_s
  %r900 = load i64, i64* %ptr_s
  %r901 = getelementptr [2 x i8], [2 x i8]* @.str.741, i64 0, i64 0
  %r902 = ptrtoint i8* %r901 to i64
  %r903 = call i64 @_add(i64 %r900, i64 %r902)
  %r904 = load i64, i64* %ptr_NL
  %r905 = call i64 @_add(i64 %r903, i64 %r904)
  store i64 %r905, i64* %ptr_s
  %r906 = load i64, i64* %ptr_s
  %r907 = getelementptr [50 x i8], [50 x i8]* @.str.742, i64 0, i64 0
  %r908 = ptrtoint i8* %r907 to i64
  %r909 = call i64 @_add(i64 %r906, i64 %r908)
  %r910 = load i64, i64* %ptr_NL
  %r911 = call i64 @_add(i64 %r909, i64 %r910)
  store i64 %r911, i64* %ptr_s
  %r912 = load i64, i64* %ptr_s
  %r913 = getelementptr [33 x i8], [33 x i8]* @.str.743, i64 0, i64 0
  %r914 = ptrtoint i8* %r913 to i64
  %r915 = call i64 @_add(i64 %r912, i64 %r914)
  %r916 = load i64, i64* %ptr_NL
  %r917 = call i64 @_add(i64 %r915, i64 %r916)
  store i64 %r917, i64* %ptr_s
  %r918 = load i64, i64* %ptr_s
  %r919 = getelementptr [50 x i8], [50 x i8]* @.str.744, i64 0, i64 0
  %r920 = ptrtoint i8* %r919 to i64
  %r921 = call i64 @_add(i64 %r918, i64 %r920)
  %r922 = load i64, i64* %ptr_NL
  %r923 = call i64 @_add(i64 %r921, i64 %r922)
  store i64 %r923, i64* %ptr_s
  %r924 = load i64, i64* %ptr_s
  %r925 = getelementptr [35 x i8], [35 x i8]* @.str.745, i64 0, i64 0
  %r926 = ptrtoint i8* %r925 to i64
  %r927 = call i64 @_add(i64 %r924, i64 %r926)
  %r928 = load i64, i64* %ptr_NL
  %r929 = call i64 @_add(i64 %r927, i64 %r928)
  store i64 %r929, i64* %ptr_s
  %r930 = load i64, i64* %ptr_s
  %r931 = getelementptr [41 x i8], [41 x i8]* @.str.746, i64 0, i64 0
  %r932 = ptrtoint i8* %r931 to i64
  %r933 = call i64 @_add(i64 %r930, i64 %r932)
  %r934 = load i64, i64* %ptr_NL
  %r935 = call i64 @_add(i64 %r933, i64 %r934)
  store i64 %r935, i64* %ptr_s
  %r936 = load i64, i64* %ptr_s
  %r937 = getelementptr [54 x i8], [54 x i8]* @.str.747, i64 0, i64 0
  %r938 = ptrtoint i8* %r937 to i64
  %r939 = call i64 @_add(i64 %r936, i64 %r938)
  %r940 = load i64, i64* %ptr_NL
  %r941 = call i64 @_add(i64 %r939, i64 %r940)
  store i64 %r941, i64* %ptr_s
  %r942 = load i64, i64* %ptr_s
  %r943 = getelementptr [27 x i8], [27 x i8]* @.str.748, i64 0, i64 0
  %r944 = ptrtoint i8* %r943 to i64
  %r945 = call i64 @_add(i64 %r942, i64 %r944)
  %r946 = load i64, i64* %ptr_NL
  %r947 = call i64 @_add(i64 %r945, i64 %r946)
  store i64 %r947, i64* %ptr_s
  %r948 = load i64, i64* %ptr_s
  %r949 = getelementptr [12 x i8], [12 x i8]* @.str.749, i64 0, i64 0
  %r950 = ptrtoint i8* %r949 to i64
  %r951 = call i64 @_add(i64 %r948, i64 %r950)
  %r952 = load i64, i64* %ptr_NL
  %r953 = call i64 @_add(i64 %r951, i64 %r952)
  store i64 %r953, i64* %ptr_s
  %r954 = load i64, i64* %ptr_s
  %r955 = getelementptr [2 x i8], [2 x i8]* @.str.750, i64 0, i64 0
  %r956 = ptrtoint i8* %r955 to i64
  %r957 = call i64 @_add(i64 %r954, i64 %r956)
  %r958 = load i64, i64* %ptr_NL
  %r959 = call i64 @_add(i64 %r957, i64 %r958)
  store i64 %r959, i64* %ptr_s
  %r960 = load i64, i64* %ptr_s
  %r961 = getelementptr [41 x i8], [41 x i8]* @.str.751, i64 0, i64 0
  %r962 = ptrtoint i8* %r961 to i64
  %r963 = call i64 @_add(i64 %r960, i64 %r962)
  %r964 = load i64, i64* %ptr_NL
  %r965 = call i64 @_add(i64 %r963, i64 %r964)
  store i64 %r965, i64* %ptr_s
  %r966 = load i64, i64* %ptr_s
  %r967 = getelementptr [33 x i8], [33 x i8]* @.str.752, i64 0, i64 0
  %r968 = ptrtoint i8* %r967 to i64
  %r969 = call i64 @_add(i64 %r966, i64 %r968)
  %r970 = load i64, i64* %ptr_NL
  %r971 = call i64 @_add(i64 %r969, i64 %r970)
  store i64 %r971, i64* %ptr_s
  %r972 = load i64, i64* %ptr_s
  %r973 = getelementptr [49 x i8], [49 x i8]* @.str.753, i64 0, i64 0
  %r974 = ptrtoint i8* %r973 to i64
  %r975 = call i64 @_add(i64 %r972, i64 %r974)
  %r976 = load i64, i64* %ptr_NL
  %r977 = call i64 @_add(i64 %r975, i64 %r976)
  store i64 %r977, i64* %ptr_s
  %r978 = load i64, i64* %ptr_s
  %r979 = getelementptr [33 x i8], [33 x i8]* @.str.754, i64 0, i64 0
  %r980 = ptrtoint i8* %r979 to i64
  %r981 = call i64 @_add(i64 %r978, i64 %r980)
  %r982 = load i64, i64* %ptr_NL
  %r983 = call i64 @_add(i64 %r981, i64 %r982)
  store i64 %r983, i64* %ptr_s
  %r984 = load i64, i64* %ptr_s
  %r985 = getelementptr [29 x i8], [29 x i8]* @.str.755, i64 0, i64 0
  %r986 = ptrtoint i8* %r985 to i64
  %r987 = call i64 @_add(i64 %r984, i64 %r986)
  %r988 = load i64, i64* %ptr_NL
  %r989 = call i64 @_add(i64 %r987, i64 %r988)
  store i64 %r989, i64* %ptr_s
  %r990 = load i64, i64* %ptr_s
  %r991 = getelementptr [36 x i8], [36 x i8]* @.str.756, i64 0, i64 0
  %r992 = ptrtoint i8* %r991 to i64
  %r993 = call i64 @_add(i64 %r990, i64 %r992)
  %r994 = load i64, i64* %ptr_NL
  %r995 = call i64 @_add(i64 %r993, i64 %r994)
  store i64 %r995, i64* %ptr_s
  %r996 = load i64, i64* %ptr_s
  %r997 = getelementptr [50 x i8], [50 x i8]* @.str.757, i64 0, i64 0
  %r998 = ptrtoint i8* %r997 to i64
  %r999 = call i64 @_add(i64 %r996, i64 %r998)
  %r1000 = load i64, i64* %ptr_NL
  %r1001 = call i64 @_add(i64 %r999, i64 %r1000)
  store i64 %r1001, i64* %ptr_s
  %r1002 = load i64, i64* %ptr_s
  %r1003 = getelementptr [40 x i8], [40 x i8]* @.str.758, i64 0, i64 0
  %r1004 = ptrtoint i8* %r1003 to i64
  %r1005 = call i64 @_add(i64 %r1002, i64 %r1004)
  %r1006 = load i64, i64* %ptr_NL
  %r1007 = call i64 @_add(i64 %r1005, i64 %r1006)
  store i64 %r1007, i64* %ptr_s
  %r1008 = load i64, i64* %ptr_s
  %r1009 = getelementptr [35 x i8], [35 x i8]* @.str.759, i64 0, i64 0
  %r1010 = ptrtoint i8* %r1009 to i64
  %r1011 = call i64 @_add(i64 %r1008, i64 %r1010)
  %r1012 = load i64, i64* %ptr_NL
  %r1013 = call i64 @_add(i64 %r1011, i64 %r1012)
  store i64 %r1013, i64* %ptr_s
  %r1014 = load i64, i64* %ptr_s
  %r1015 = getelementptr [44 x i8], [44 x i8]* @.str.760, i64 0, i64 0
  %r1016 = ptrtoint i8* %r1015 to i64
  %r1017 = call i64 @_add(i64 %r1014, i64 %r1016)
  %r1018 = load i64, i64* %ptr_NL
  %r1019 = call i64 @_add(i64 %r1017, i64 %r1018)
  store i64 %r1019, i64* %ptr_s
  %r1020 = load i64, i64* %ptr_s
  %r1021 = getelementptr [61 x i8], [61 x i8]* @.str.761, i64 0, i64 0
  %r1022 = ptrtoint i8* %r1021 to i64
  %r1023 = call i64 @_add(i64 %r1020, i64 %r1022)
  %r1024 = load i64, i64* %ptr_NL
  %r1025 = call i64 @_add(i64 %r1023, i64 %r1024)
  store i64 %r1025, i64* %ptr_s
  %r1026 = load i64, i64* %ptr_s
  %r1027 = getelementptr [42 x i8], [42 x i8]* @.str.762, i64 0, i64 0
  %r1028 = ptrtoint i8* %r1027 to i64
  %r1029 = call i64 @_add(i64 %r1026, i64 %r1028)
  %r1030 = load i64, i64* %ptr_NL
  %r1031 = call i64 @_add(i64 %r1029, i64 %r1030)
  store i64 %r1031, i64* %ptr_s
  %r1032 = load i64, i64* %ptr_s
  %r1033 = getelementptr [37 x i8], [37 x i8]* @.str.763, i64 0, i64 0
  %r1034 = ptrtoint i8* %r1033 to i64
  %r1035 = call i64 @_add(i64 %r1032, i64 %r1034)
  %r1036 = load i64, i64* %ptr_NL
  %r1037 = call i64 @_add(i64 %r1035, i64 %r1036)
  store i64 %r1037, i64* %ptr_s
  %r1038 = load i64, i64* %ptr_s
  %r1039 = getelementptr [44 x i8], [44 x i8]* @.str.764, i64 0, i64 0
  %r1040 = ptrtoint i8* %r1039 to i64
  %r1041 = call i64 @_add(i64 %r1038, i64 %r1040)
  %r1042 = load i64, i64* %ptr_NL
  %r1043 = call i64 @_add(i64 %r1041, i64 %r1042)
  store i64 %r1043, i64* %ptr_s
  %r1044 = load i64, i64* %ptr_s
  %r1045 = getelementptr [53 x i8], [53 x i8]* @.str.765, i64 0, i64 0
  %r1046 = ptrtoint i8* %r1045 to i64
  %r1047 = call i64 @_add(i64 %r1044, i64 %r1046)
  %r1048 = load i64, i64* %ptr_NL
  %r1049 = call i64 @_add(i64 %r1047, i64 %r1048)
  store i64 %r1049, i64* %ptr_s
  %r1050 = load i64, i64* %ptr_s
  %r1051 = getelementptr [26 x i8], [26 x i8]* @.str.766, i64 0, i64 0
  %r1052 = ptrtoint i8* %r1051 to i64
  %r1053 = call i64 @_add(i64 %r1050, i64 %r1052)
  %r1054 = load i64, i64* %ptr_NL
  %r1055 = call i64 @_add(i64 %r1053, i64 %r1054)
  store i64 %r1055, i64* %ptr_s
  %r1056 = load i64, i64* %ptr_s
  %r1057 = getelementptr [12 x i8], [12 x i8]* @.str.767, i64 0, i64 0
  %r1058 = ptrtoint i8* %r1057 to i64
  %r1059 = call i64 @_add(i64 %r1056, i64 %r1058)
  %r1060 = load i64, i64* %ptr_NL
  %r1061 = call i64 @_add(i64 %r1059, i64 %r1060)
  store i64 %r1061, i64* %ptr_s
  %r1062 = load i64, i64* %ptr_s
  %r1063 = getelementptr [2 x i8], [2 x i8]* @.str.768, i64 0, i64 0
  %r1064 = ptrtoint i8* %r1063 to i64
  %r1065 = call i64 @_add(i64 %r1062, i64 %r1064)
  %r1066 = load i64, i64* %ptr_NL
  %r1067 = call i64 @_add(i64 %r1065, i64 %r1066)
  store i64 %r1067, i64* %ptr_s
  %r1068 = load i64, i64* %ptr_s
  %r1069 = getelementptr [25 x i8], [25 x i8]* @.str.769, i64 0, i64 0
  %r1070 = ptrtoint i8* %r1069 to i64
  %r1071 = call i64 @_add(i64 %r1068, i64 %r1070)
  %r1072 = load i64, i64* %ptr_NL
  %r1073 = call i64 @_add(i64 %r1071, i64 %r1072)
  store i64 %r1073, i64* %ptr_s
  %r1074 = load i64, i64* %ptr_s
  %r1075 = getelementptr [29 x i8], [29 x i8]* @.str.770, i64 0, i64 0
  %r1076 = ptrtoint i8* %r1075 to i64
  %r1077 = call i64 @_add(i64 %r1074, i64 %r1076)
  %r1078 = load i64, i64* %ptr_NL
  %r1079 = call i64 @_add(i64 %r1077, i64 %r1078)
  store i64 %r1079, i64* %ptr_s
  %r1080 = load i64, i64* %ptr_s
  %r1081 = getelementptr [33 x i8], [33 x i8]* @.str.771, i64 0, i64 0
  %r1082 = ptrtoint i8* %r1081 to i64
  %r1083 = call i64 @_add(i64 %r1080, i64 %r1082)
  %r1084 = load i64, i64* %ptr_NL
  %r1085 = call i64 @_add(i64 %r1083, i64 %r1084)
  store i64 %r1085, i64* %ptr_s
  %r1086 = load i64, i64* %ptr_s
  %r1087 = getelementptr [25 x i8], [25 x i8]* @.str.772, i64 0, i64 0
  %r1088 = ptrtoint i8* %r1087 to i64
  %r1089 = call i64 @_add(i64 %r1086, i64 %r1088)
  %r1090 = load i64, i64* %ptr_NL
  %r1091 = call i64 @_add(i64 %r1089, i64 %r1090)
  store i64 %r1091, i64* %ptr_s
  %r1092 = load i64, i64* %ptr_s
  %r1093 = getelementptr [13 x i8], [13 x i8]* @.str.773, i64 0, i64 0
  %r1094 = ptrtoint i8* %r1093 to i64
  %r1095 = call i64 @_add(i64 %r1092, i64 %r1094)
  %r1096 = load i64, i64* %ptr_NL
  %r1097 = call i64 @_add(i64 %r1095, i64 %r1096)
  store i64 %r1097, i64* %ptr_s
  %r1098 = load i64, i64* %ptr_s
  %r1099 = getelementptr [2 x i8], [2 x i8]* @.str.774, i64 0, i64 0
  %r1100 = ptrtoint i8* %r1099 to i64
  %r1101 = call i64 @_add(i64 %r1098, i64 %r1100)
  %r1102 = load i64, i64* %ptr_NL
  %r1103 = call i64 @_add(i64 %r1101, i64 %r1102)
  store i64 %r1103, i64* %ptr_s
  %r1104 = load i64, i64* %ptr_s
  %r1105 = getelementptr [47 x i8], [47 x i8]* @.str.775, i64 0, i64 0
  %r1106 = ptrtoint i8* %r1105 to i64
  %r1107 = call i64 @_add(i64 %r1104, i64 %r1106)
  %r1108 = load i64, i64* %ptr_NL
  %r1109 = call i64 @_add(i64 %r1107, i64 %r1108)
  store i64 %r1109, i64* %ptr_s
  %r1110 = load i64, i64* %ptr_s
  %r1111 = getelementptr [39 x i8], [39 x i8]* @.str.776, i64 0, i64 0
  %r1112 = ptrtoint i8* %r1111 to i64
  %r1113 = call i64 @_add(i64 %r1110, i64 %r1112)
  %r1114 = load i64, i64* %ptr_NL
  %r1115 = call i64 @_add(i64 %r1113, i64 %r1114)
  store i64 %r1115, i64* %ptr_s
  %r1116 = load i64, i64* %ptr_s
  %r1117 = getelementptr [39 x i8], [39 x i8]* @.str.777, i64 0, i64 0
  %r1118 = ptrtoint i8* %r1117 to i64
  %r1119 = call i64 @_add(i64 %r1116, i64 %r1118)
  %r1120 = load i64, i64* %ptr_NL
  %r1121 = call i64 @_add(i64 %r1119, i64 %r1120)
  store i64 %r1121, i64* %ptr_s
  %r1122 = load i64, i64* %ptr_s
  %r1123 = getelementptr [12 x i8], [12 x i8]* @.str.778, i64 0, i64 0
  %r1124 = ptrtoint i8* %r1123 to i64
  %r1125 = call i64 @_add(i64 %r1122, i64 %r1124)
  %r1126 = load i64, i64* %ptr_NL
  %r1127 = call i64 @_add(i64 %r1125, i64 %r1126)
  store i64 %r1127, i64* %ptr_s
  %r1128 = load i64, i64* %ptr_s
  %r1129 = getelementptr [2 x i8], [2 x i8]* @.str.779, i64 0, i64 0
  %r1130 = ptrtoint i8* %r1129 to i64
  %r1131 = call i64 @_add(i64 %r1128, i64 %r1130)
  %r1132 = load i64, i64* %ptr_NL
  %r1133 = call i64 @_add(i64 %r1131, i64 %r1132)
  store i64 %r1133, i64* %ptr_s
  %r1134 = load i64, i64* %ptr_s
  %r1135 = getelementptr [47 x i8], [47 x i8]* @.str.780, i64 0, i64 0
  %r1136 = ptrtoint i8* %r1135 to i64
  %r1137 = call i64 @_add(i64 %r1134, i64 %r1136)
  %r1138 = load i64, i64* %ptr_NL
  %r1139 = call i64 @_add(i64 %r1137, i64 %r1138)
  store i64 %r1139, i64* %ptr_s
  %r1140 = load i64, i64* %ptr_s
  %r1141 = getelementptr [35 x i8], [35 x i8]* @.str.781, i64 0, i64 0
  %r1142 = ptrtoint i8* %r1141 to i64
  %r1143 = call i64 @_add(i64 %r1140, i64 %r1142)
  %r1144 = load i64, i64* %ptr_NL
  %r1145 = call i64 @_add(i64 %r1143, i64 %r1144)
  store i64 %r1145, i64* %ptr_s
  %r1146 = load i64, i64* %ptr_s
  %r1147 = getelementptr [30 x i8], [30 x i8]* @.str.782, i64 0, i64 0
  %r1148 = ptrtoint i8* %r1147 to i64
  %r1149 = call i64 @_add(i64 %r1146, i64 %r1148)
  %r1150 = load i64, i64* %ptr_NL
  %r1151 = call i64 @_add(i64 %r1149, i64 %r1150)
  store i64 %r1151, i64* %ptr_s
  %r1152 = load i64, i64* %ptr_s
  %r1153 = getelementptr [33 x i8], [33 x i8]* @.str.783, i64 0, i64 0
  %r1154 = ptrtoint i8* %r1153 to i64
  %r1155 = call i64 @_add(i64 %r1152, i64 %r1154)
  %r1156 = load i64, i64* %ptr_NL
  %r1157 = call i64 @_add(i64 %r1155, i64 %r1156)
  store i64 %r1157, i64* %ptr_s
  %r1158 = load i64, i64* %ptr_s
  %r1159 = getelementptr [47 x i8], [47 x i8]* @.str.784, i64 0, i64 0
  %r1160 = ptrtoint i8* %r1159 to i64
  %r1161 = call i64 @_add(i64 %r1158, i64 %r1160)
  %r1162 = load i64, i64* %ptr_NL
  %r1163 = call i64 @_add(i64 %r1161, i64 %r1162)
  store i64 %r1163, i64* %ptr_s
  %r1164 = load i64, i64* %ptr_s
  %r1165 = getelementptr [9 x i8], [9 x i8]* @.str.785, i64 0, i64 0
  %r1166 = ptrtoint i8* %r1165 to i64
  %r1167 = call i64 @_add(i64 %r1164, i64 %r1166)
  %r1168 = load i64, i64* %ptr_NL
  %r1169 = call i64 @_add(i64 %r1167, i64 %r1168)
  store i64 %r1169, i64* %ptr_s
  %r1170 = load i64, i64* %ptr_s
  %r1171 = getelementptr [50 x i8], [50 x i8]* @.str.786, i64 0, i64 0
  %r1172 = ptrtoint i8* %r1171 to i64
  %r1173 = call i64 @_add(i64 %r1170, i64 %r1172)
  %r1174 = load i64, i64* %ptr_NL
  %r1175 = call i64 @_add(i64 %r1173, i64 %r1174)
  store i64 %r1175, i64* %ptr_s
  %r1176 = load i64, i64* %ptr_s
  %r1177 = getelementptr [12 x i8], [12 x i8]* @.str.787, i64 0, i64 0
  %r1178 = ptrtoint i8* %r1177 to i64
  %r1179 = call i64 @_add(i64 %r1176, i64 %r1178)
  %r1180 = load i64, i64* %ptr_NL
  %r1181 = call i64 @_add(i64 %r1179, i64 %r1180)
  store i64 %r1181, i64* %ptr_s
  %r1182 = load i64, i64* %ptr_s
  %r1183 = getelementptr [8 x i8], [8 x i8]* @.str.788, i64 0, i64 0
  %r1184 = ptrtoint i8* %r1183 to i64
  %r1185 = call i64 @_add(i64 %r1182, i64 %r1184)
  %r1186 = load i64, i64* %ptr_NL
  %r1187 = call i64 @_add(i64 %r1185, i64 %r1186)
  store i64 %r1187, i64* %ptr_s
  %r1188 = load i64, i64* %ptr_s
  %r1189 = getelementptr [49 x i8], [49 x i8]* @.str.789, i64 0, i64 0
  %r1190 = ptrtoint i8* %r1189 to i64
  %r1191 = call i64 @_add(i64 %r1188, i64 %r1190)
  %r1192 = load i64, i64* %ptr_NL
  %r1193 = call i64 @_add(i64 %r1191, i64 %r1192)
  store i64 %r1193, i64* %ptr_s
  %r1194 = load i64, i64* %ptr_s
  %r1195 = getelementptr [12 x i8], [12 x i8]* @.str.790, i64 0, i64 0
  %r1196 = ptrtoint i8* %r1195 to i64
  %r1197 = call i64 @_add(i64 %r1194, i64 %r1196)
  %r1198 = load i64, i64* %ptr_NL
  %r1199 = call i64 @_add(i64 %r1197, i64 %r1198)
  store i64 %r1199, i64* %ptr_s
  %r1200 = load i64, i64* %ptr_s
  %r1201 = getelementptr [2 x i8], [2 x i8]* @.str.791, i64 0, i64 0
  %r1202 = ptrtoint i8* %r1201 to i64
  %r1203 = call i64 @_add(i64 %r1200, i64 %r1202)
  %r1204 = load i64, i64* %ptr_NL
  %r1205 = call i64 @_add(i64 %r1203, i64 %r1204)
  store i64 %r1205, i64* %ptr_s
  %r1206 = load i64, i64* %ptr_s
  %r1207 = getelementptr [41 x i8], [41 x i8]* @.str.792, i64 0, i64 0
  %r1208 = ptrtoint i8* %r1207 to i64
  %r1209 = call i64 @_add(i64 %r1206, i64 %r1208)
  %r1210 = load i64, i64* %ptr_NL
  %r1211 = call i64 @_add(i64 %r1209, i64 %r1210)
  store i64 %r1211, i64* %ptr_s
  %r1212 = load i64, i64* %ptr_s
  %r1213 = getelementptr [33 x i8], [33 x i8]* @.str.793, i64 0, i64 0
  %r1214 = ptrtoint i8* %r1213 to i64
  %r1215 = call i64 @_add(i64 %r1212, i64 %r1214)
  %r1216 = load i64, i64* %ptr_NL
  %r1217 = call i64 @_add(i64 %r1215, i64 %r1216)
  store i64 %r1217, i64* %ptr_s
  %r1218 = load i64, i64* %ptr_s
  %r1219 = getelementptr [49 x i8], [49 x i8]* @.str.794, i64 0, i64 0
  %r1220 = ptrtoint i8* %r1219 to i64
  %r1221 = call i64 @_add(i64 %r1218, i64 %r1220)
  %r1222 = load i64, i64* %ptr_NL
  %r1223 = call i64 @_add(i64 %r1221, i64 %r1222)
  store i64 %r1223, i64* %ptr_s
  %r1224 = load i64, i64* %ptr_s
  %r1225 = getelementptr [33 x i8], [33 x i8]* @.str.795, i64 0, i64 0
  %r1226 = ptrtoint i8* %r1225 to i64
  %r1227 = call i64 @_add(i64 %r1224, i64 %r1226)
  %r1228 = load i64, i64* %ptr_NL
  %r1229 = call i64 @_add(i64 %r1227, i64 %r1228)
  store i64 %r1229, i64* %ptr_s
  %r1230 = load i64, i64* %ptr_s
  %r1231 = getelementptr [50 x i8], [50 x i8]* @.str.796, i64 0, i64 0
  %r1232 = ptrtoint i8* %r1231 to i64
  %r1233 = call i64 @_add(i64 %r1230, i64 %r1232)
  %r1234 = load i64, i64* %ptr_NL
  %r1235 = call i64 @_add(i64 %r1233, i64 %r1234)
  store i64 %r1235, i64* %ptr_s
  %r1236 = load i64, i64* %ptr_s
  %r1237 = getelementptr [35 x i8], [35 x i8]* @.str.797, i64 0, i64 0
  %r1238 = ptrtoint i8* %r1237 to i64
  %r1239 = call i64 @_add(i64 %r1236, i64 %r1238)
  %r1240 = load i64, i64* %ptr_NL
  %r1241 = call i64 @_add(i64 %r1239, i64 %r1240)
  store i64 %r1241, i64* %ptr_s
  %r1242 = load i64, i64* %ptr_s
  %r1243 = getelementptr [41 x i8], [41 x i8]* @.str.798, i64 0, i64 0
  %r1244 = ptrtoint i8* %r1243 to i64
  %r1245 = call i64 @_add(i64 %r1242, i64 %r1244)
  %r1246 = load i64, i64* %ptr_NL
  %r1247 = call i64 @_add(i64 %r1245, i64 %r1246)
  store i64 %r1247, i64* %ptr_s
  %r1248 = load i64, i64* %ptr_s
  %r1249 = getelementptr [36 x i8], [36 x i8]* @.str.799, i64 0, i64 0
  %r1250 = ptrtoint i8* %r1249 to i64
  %r1251 = call i64 @_add(i64 %r1248, i64 %r1250)
  %r1252 = load i64, i64* %ptr_NL
  %r1253 = call i64 @_add(i64 %r1251, i64 %r1252)
  store i64 %r1253, i64* %ptr_s
  %r1254 = load i64, i64* %ptr_s
  %r1255 = getelementptr [29 x i8], [29 x i8]* @.str.800, i64 0, i64 0
  %r1256 = ptrtoint i8* %r1255 to i64
  %r1257 = call i64 @_add(i64 %r1254, i64 %r1256)
  %r1258 = load i64, i64* %ptr_NL
  %r1259 = call i64 @_add(i64 %r1257, i64 %r1258)
  store i64 %r1259, i64* %ptr_s
  %r1260 = load i64, i64* %ptr_s
  %r1261 = getelementptr [17 x i8], [17 x i8]* @.str.801, i64 0, i64 0
  %r1262 = ptrtoint i8* %r1261 to i64
  %r1263 = call i64 @_add(i64 %r1260, i64 %r1262)
  %r1264 = load i64, i64* %ptr_NL
  %r1265 = call i64 @_add(i64 %r1263, i64 %r1264)
  store i64 %r1265, i64* %ptr_s
  %r1266 = load i64, i64* %ptr_s
  %r1267 = getelementptr [6 x i8], [6 x i8]* @.str.802, i64 0, i64 0
  %r1268 = ptrtoint i8* %r1267 to i64
  %r1269 = call i64 @_add(i64 %r1266, i64 %r1268)
  %r1270 = load i64, i64* %ptr_NL
  %r1271 = call i64 @_add(i64 %r1269, i64 %r1270)
  store i64 %r1271, i64* %ptr_s
  %r1272 = load i64, i64* %ptr_s
  %r1273 = getelementptr [52 x i8], [52 x i8]* @.str.803, i64 0, i64 0
  %r1274 = ptrtoint i8* %r1273 to i64
  %r1275 = call i64 @_add(i64 %r1272, i64 %r1274)
  %r1276 = load i64, i64* %ptr_NL
  %r1277 = call i64 @_add(i64 %r1275, i64 %r1276)
  store i64 %r1277, i64* %ptr_s
  %r1278 = load i64, i64* %ptr_s
  %r1279 = getelementptr [29 x i8], [29 x i8]* @.str.804, i64 0, i64 0
  %r1280 = ptrtoint i8* %r1279 to i64
  %r1281 = call i64 @_add(i64 %r1278, i64 %r1280)
  %r1282 = load i64, i64* %ptr_NL
  %r1283 = call i64 @_add(i64 %r1281, i64 %r1282)
  store i64 %r1283, i64* %ptr_s
  %r1284 = load i64, i64* %ptr_s
  %r1285 = getelementptr [50 x i8], [50 x i8]* @.str.805, i64 0, i64 0
  %r1286 = ptrtoint i8* %r1285 to i64
  %r1287 = call i64 @_add(i64 %r1284, i64 %r1286)
  %r1288 = load i64, i64* %ptr_NL
  %r1289 = call i64 @_add(i64 %r1287, i64 %r1288)
  store i64 %r1289, i64* %ptr_s
  %r1290 = load i64, i64* %ptr_s
  %r1291 = getelementptr [11 x i8], [11 x i8]* @.str.806, i64 0, i64 0
  %r1292 = ptrtoint i8* %r1291 to i64
  %r1293 = call i64 @_add(i64 %r1290, i64 %r1292)
  %r1294 = load i64, i64* %ptr_NL
  %r1295 = call i64 @_add(i64 %r1293, i64 %r1294)
  store i64 %r1295, i64* %ptr_s
  %r1296 = load i64, i64* %ptr_s
  %r1297 = getelementptr [54 x i8], [54 x i8]* @.str.807, i64 0, i64 0
  %r1298 = ptrtoint i8* %r1297 to i64
  %r1299 = call i64 @_add(i64 %r1296, i64 %r1298)
  %r1300 = load i64, i64* %ptr_NL
  %r1301 = call i64 @_add(i64 %r1299, i64 %r1300)
  store i64 %r1301, i64* %ptr_s
  %r1302 = load i64, i64* %ptr_s
  %r1303 = getelementptr [34 x i8], [34 x i8]* @.str.808, i64 0, i64 0
  %r1304 = ptrtoint i8* %r1303 to i64
  %r1305 = call i64 @_add(i64 %r1302, i64 %r1304)
  %r1306 = load i64, i64* %ptr_NL
  %r1307 = call i64 @_add(i64 %r1305, i64 %r1306)
  store i64 %r1307, i64* %ptr_s
  %r1308 = load i64, i64* %ptr_s
  %r1309 = getelementptr [38 x i8], [38 x i8]* @.str.809, i64 0, i64 0
  %r1310 = ptrtoint i8* %r1309 to i64
  %r1311 = call i64 @_add(i64 %r1308, i64 %r1310)
  %r1312 = load i64, i64* %ptr_NL
  %r1313 = call i64 @_add(i64 %r1311, i64 %r1312)
  store i64 %r1313, i64* %ptr_s
  %r1314 = load i64, i64* %ptr_s
  %r1315 = getelementptr [50 x i8], [50 x i8]* @.str.810, i64 0, i64 0
  %r1316 = ptrtoint i8* %r1315 to i64
  %r1317 = call i64 @_add(i64 %r1314, i64 %r1316)
  %r1318 = load i64, i64* %ptr_NL
  %r1319 = call i64 @_add(i64 %r1317, i64 %r1318)
  store i64 %r1319, i64* %ptr_s
  %r1320 = load i64, i64* %ptr_s
  %r1321 = getelementptr [31 x i8], [31 x i8]* @.str.811, i64 0, i64 0
  %r1322 = ptrtoint i8* %r1321 to i64
  %r1323 = call i64 @_add(i64 %r1320, i64 %r1322)
  %r1324 = load i64, i64* %ptr_NL
  %r1325 = call i64 @_add(i64 %r1323, i64 %r1324)
  store i64 %r1325, i64* %ptr_s
  %r1326 = load i64, i64* %ptr_s
  %r1327 = getelementptr [42 x i8], [42 x i8]* @.str.812, i64 0, i64 0
  %r1328 = ptrtoint i8* %r1327 to i64
  %r1329 = call i64 @_add(i64 %r1326, i64 %r1328)
  %r1330 = load i64, i64* %ptr_NL
  %r1331 = call i64 @_add(i64 %r1329, i64 %r1330)
  store i64 %r1331, i64* %ptr_s
  %r1332 = load i64, i64* %ptr_s
  %r1333 = getelementptr [6 x i8], [6 x i8]* @.str.813, i64 0, i64 0
  %r1334 = ptrtoint i8* %r1333 to i64
  %r1335 = call i64 @_add(i64 %r1332, i64 %r1334)
  %r1336 = load i64, i64* %ptr_NL
  %r1337 = call i64 @_add(i64 %r1335, i64 %r1336)
  store i64 %r1337, i64* %ptr_s
  %r1338 = load i64, i64* %ptr_s
  %r1339 = getelementptr [26 x i8], [26 x i8]* @.str.814, i64 0, i64 0
  %r1340 = ptrtoint i8* %r1339 to i64
  %r1341 = call i64 @_add(i64 %r1338, i64 %r1340)
  %r1342 = load i64, i64* %ptr_NL
  %r1343 = call i64 @_add(i64 %r1341, i64 %r1342)
  store i64 %r1343, i64* %ptr_s
  %r1344 = load i64, i64* %ptr_s
  %r1345 = getelementptr [17 x i8], [17 x i8]* @.str.815, i64 0, i64 0
  %r1346 = ptrtoint i8* %r1345 to i64
  %r1347 = call i64 @_add(i64 %r1344, i64 %r1346)
  %r1348 = load i64, i64* %ptr_NL
  %r1349 = call i64 @_add(i64 %r1347, i64 %r1348)
  store i64 %r1349, i64* %ptr_s
  %r1350 = load i64, i64* %ptr_s
  %r1351 = getelementptr [7 x i8], [7 x i8]* @.str.816, i64 0, i64 0
  %r1352 = ptrtoint i8* %r1351 to i64
  %r1353 = call i64 @_add(i64 %r1350, i64 %r1352)
  %r1354 = load i64, i64* %ptr_NL
  %r1355 = call i64 @_add(i64 %r1353, i64 %r1354)
  store i64 %r1355, i64* %ptr_s
  %r1356 = load i64, i64* %ptr_s
  %r1357 = getelementptr [25 x i8], [25 x i8]* @.str.817, i64 0, i64 0
  %r1358 = ptrtoint i8* %r1357 to i64
  %r1359 = call i64 @_add(i64 %r1356, i64 %r1358)
  %r1360 = load i64, i64* %ptr_NL
  %r1361 = call i64 @_add(i64 %r1359, i64 %r1360)
  store i64 %r1361, i64* %ptr_s
  %r1362 = load i64, i64* %ptr_s
  %r1363 = getelementptr [58 x i8], [58 x i8]* @.str.818, i64 0, i64 0
  %r1364 = ptrtoint i8* %r1363 to i64
  %r1365 = call i64 @_add(i64 %r1362, i64 %r1364)
  %r1366 = load i64, i64* %ptr_NL
  %r1367 = call i64 @_add(i64 %r1365, i64 %r1366)
  store i64 %r1367, i64* %ptr_s
  %r1368 = load i64, i64* %ptr_s
  %r1369 = getelementptr [32 x i8], [32 x i8]* @.str.819, i64 0, i64 0
  %r1370 = ptrtoint i8* %r1369 to i64
  %r1371 = call i64 @_add(i64 %r1368, i64 %r1370)
  %r1372 = load i64, i64* %ptr_NL
  %r1373 = call i64 @_add(i64 %r1371, i64 %r1372)
  store i64 %r1373, i64* %ptr_s
  %r1374 = load i64, i64* %ptr_s
  %r1375 = getelementptr [15 x i8], [15 x i8]* @.str.820, i64 0, i64 0
  %r1376 = ptrtoint i8* %r1375 to i64
  %r1377 = call i64 @_add(i64 %r1374, i64 %r1376)
  %r1378 = load i64, i64* %ptr_NL
  %r1379 = call i64 @_add(i64 %r1377, i64 %r1378)
  store i64 %r1379, i64* %ptr_s
  %r1380 = load i64, i64* %ptr_s
  %r1381 = getelementptr [11 x i8], [11 x i8]* @.str.821, i64 0, i64 0
  %r1382 = ptrtoint i8* %r1381 to i64
  %r1383 = call i64 @_add(i64 %r1380, i64 %r1382)
  %r1384 = load i64, i64* %ptr_NL
  %r1385 = call i64 @_add(i64 %r1383, i64 %r1384)
  store i64 %r1385, i64* %ptr_s
  %r1386 = load i64, i64* %ptr_s
  %r1387 = getelementptr [12 x i8], [12 x i8]* @.str.822, i64 0, i64 0
  %r1388 = ptrtoint i8* %r1387 to i64
  %r1389 = call i64 @_add(i64 %r1386, i64 %r1388)
  %r1390 = load i64, i64* %ptr_NL
  %r1391 = call i64 @_add(i64 %r1389, i64 %r1390)
  store i64 %r1391, i64* %ptr_s
  %r1392 = load i64, i64* %ptr_s
  %r1393 = getelementptr [2 x i8], [2 x i8]* @.str.823, i64 0, i64 0
  %r1394 = ptrtoint i8* %r1393 to i64
  %r1395 = call i64 @_add(i64 %r1392, i64 %r1394)
  %r1396 = load i64, i64* %ptr_NL
  %r1397 = call i64 @_add(i64 %r1395, i64 %r1396)
  store i64 %r1397, i64* %ptr_s
  %r1398 = load i64, i64* %ptr_s
  %r1399 = getelementptr [39 x i8], [39 x i8]* @.str.824, i64 0, i64 0
  %r1400 = ptrtoint i8* %r1399 to i64
  %r1401 = call i64 @_add(i64 %r1398, i64 %r1400)
  %r1402 = load i64, i64* %ptr_NL
  %r1403 = call i64 @_add(i64 %r1401, i64 %r1402)
  store i64 %r1403, i64* %ptr_s
  %r1404 = load i64, i64* %ptr_s
  %r1405 = getelementptr [33 x i8], [33 x i8]* @.str.825, i64 0, i64 0
  %r1406 = ptrtoint i8* %r1405 to i64
  %r1407 = call i64 @_add(i64 %r1404, i64 %r1406)
  %r1408 = load i64, i64* %ptr_NL
  %r1409 = call i64 @_add(i64 %r1407, i64 %r1408)
  store i64 %r1409, i64* %ptr_s
  %r1410 = load i64, i64* %ptr_s
  %r1411 = getelementptr [43 x i8], [43 x i8]* @.str.826, i64 0, i64 0
  %r1412 = ptrtoint i8* %r1411 to i64
  %r1413 = call i64 @_add(i64 %r1410, i64 %r1412)
  %r1414 = load i64, i64* %ptr_NL
  %r1415 = call i64 @_add(i64 %r1413, i64 %r1414)
  store i64 %r1415, i64* %ptr_s
  %r1416 = load i64, i64* %ptr_s
  %r1417 = getelementptr [7 x i8], [7 x i8]* @.str.827, i64 0, i64 0
  %r1418 = ptrtoint i8* %r1417 to i64
  %r1419 = call i64 @_add(i64 %r1416, i64 %r1418)
  %r1420 = load i64, i64* %ptr_NL
  %r1421 = call i64 @_add(i64 %r1419, i64 %r1420)
  store i64 %r1421, i64* %ptr_s
  %r1422 = load i64, i64* %ptr_s
  %r1423 = getelementptr [35 x i8], [35 x i8]* @.str.828, i64 0, i64 0
  %r1424 = ptrtoint i8* %r1423 to i64
  %r1425 = call i64 @_add(i64 %r1422, i64 %r1424)
  %r1426 = load i64, i64* %ptr_NL
  %r1427 = call i64 @_add(i64 %r1425, i64 %r1426)
  store i64 %r1427, i64* %ptr_s
  %r1428 = load i64, i64* %ptr_s
  %r1429 = getelementptr [28 x i8], [28 x i8]* @.str.829, i64 0, i64 0
  %r1430 = ptrtoint i8* %r1429 to i64
  %r1431 = call i64 @_add(i64 %r1428, i64 %r1430)
  %r1432 = load i64, i64* %ptr_NL
  %r1433 = call i64 @_add(i64 %r1431, i64 %r1432)
  store i64 %r1433, i64* %ptr_s
  %r1434 = load i64, i64* %ptr_s
  %r1435 = getelementptr [32 x i8], [32 x i8]* @.str.830, i64 0, i64 0
  %r1436 = ptrtoint i8* %r1435 to i64
  %r1437 = call i64 @_add(i64 %r1434, i64 %r1436)
  %r1438 = load i64, i64* %ptr_NL
  %r1439 = call i64 @_add(i64 %r1437, i64 %r1438)
  store i64 %r1439, i64* %ptr_s
  %r1440 = load i64, i64* %ptr_s
  %r1441 = getelementptr [51 x i8], [51 x i8]* @.str.831, i64 0, i64 0
  %r1442 = ptrtoint i8* %r1441 to i64
  %r1443 = call i64 @_add(i64 %r1440, i64 %r1442)
  %r1444 = load i64, i64* %ptr_NL
  %r1445 = call i64 @_add(i64 %r1443, i64 %r1444)
  store i64 %r1445, i64* %ptr_s
  %r1446 = load i64, i64* %ptr_s
  %r1447 = getelementptr [11 x i8], [11 x i8]* @.str.832, i64 0, i64 0
  %r1448 = ptrtoint i8* %r1447 to i64
  %r1449 = call i64 @_add(i64 %r1446, i64 %r1448)
  %r1450 = load i64, i64* %ptr_NL
  %r1451 = call i64 @_add(i64 %r1449, i64 %r1450)
  store i64 %r1451, i64* %ptr_s
  %r1452 = load i64, i64* %ptr_s
  %r1453 = getelementptr [31 x i8], [31 x i8]* @.str.833, i64 0, i64 0
  %r1454 = ptrtoint i8* %r1453 to i64
  %r1455 = call i64 @_add(i64 %r1452, i64 %r1454)
  %r1456 = load i64, i64* %ptr_NL
  %r1457 = call i64 @_add(i64 %r1455, i64 %r1456)
  store i64 %r1457, i64* %ptr_s
  %r1458 = load i64, i64* %ptr_s
  %r1459 = getelementptr [46 x i8], [46 x i8]* @.str.834, i64 0, i64 0
  %r1460 = ptrtoint i8* %r1459 to i64
  %r1461 = call i64 @_add(i64 %r1458, i64 %r1460)
  %r1462 = load i64, i64* %ptr_NL
  %r1463 = call i64 @_add(i64 %r1461, i64 %r1462)
  store i64 %r1463, i64* %ptr_s
  %r1464 = load i64, i64* %ptr_s
  %r1465 = getelementptr [8 x i8], [8 x i8]* @.str.835, i64 0, i64 0
  %r1466 = ptrtoint i8* %r1465 to i64
  %r1467 = call i64 @_add(i64 %r1464, i64 %r1466)
  %r1468 = load i64, i64* %ptr_NL
  %r1469 = call i64 @_add(i64 %r1467, i64 %r1468)
  store i64 %r1469, i64* %ptr_s
  %r1470 = load i64, i64* %ptr_s
  %r1471 = getelementptr [39 x i8], [39 x i8]* @.str.836, i64 0, i64 0
  %r1472 = ptrtoint i8* %r1471 to i64
  %r1473 = call i64 @_add(i64 %r1470, i64 %r1472)
  %r1474 = load i64, i64* %ptr_NL
  %r1475 = call i64 @_add(i64 %r1473, i64 %r1474)
  store i64 %r1475, i64* %ptr_s
  %r1476 = load i64, i64* %ptr_s
  %r1477 = getelementptr [56 x i8], [56 x i8]* @.str.837, i64 0, i64 0
  %r1478 = ptrtoint i8* %r1477 to i64
  %r1479 = call i64 @_add(i64 %r1476, i64 %r1478)
  %r1480 = load i64, i64* %ptr_NL
  %r1481 = call i64 @_add(i64 %r1479, i64 %r1480)
  store i64 %r1481, i64* %ptr_s
  %r1482 = load i64, i64* %ptr_s
  %r1483 = getelementptr [33 x i8], [33 x i8]* @.str.838, i64 0, i64 0
  %r1484 = ptrtoint i8* %r1483 to i64
  %r1485 = call i64 @_add(i64 %r1482, i64 %r1484)
  %r1486 = load i64, i64* %ptr_NL
  %r1487 = call i64 @_add(i64 %r1485, i64 %r1486)
  store i64 %r1487, i64* %ptr_s
  %r1488 = load i64, i64* %ptr_s
  %r1489 = getelementptr [37 x i8], [37 x i8]* @.str.839, i64 0, i64 0
  %r1490 = ptrtoint i8* %r1489 to i64
  %r1491 = call i64 @_add(i64 %r1488, i64 %r1490)
  %r1492 = load i64, i64* %ptr_NL
  %r1493 = call i64 @_add(i64 %r1491, i64 %r1492)
  store i64 %r1493, i64* %ptr_s
  %r1494 = load i64, i64* %ptr_s
  %r1495 = getelementptr [42 x i8], [42 x i8]* @.str.840, i64 0, i64 0
  %r1496 = ptrtoint i8* %r1495 to i64
  %r1497 = call i64 @_add(i64 %r1494, i64 %r1496)
  %r1498 = load i64, i64* %ptr_NL
  %r1499 = call i64 @_add(i64 %r1497, i64 %r1498)
  store i64 %r1499, i64* %ptr_s
  %r1500 = load i64, i64* %ptr_s
  %r1501 = getelementptr [31 x i8], [31 x i8]* @.str.841, i64 0, i64 0
  %r1502 = ptrtoint i8* %r1501 to i64
  %r1503 = call i64 @_add(i64 %r1500, i64 %r1502)
  %r1504 = load i64, i64* %ptr_NL
  %r1505 = call i64 @_add(i64 %r1503, i64 %r1504)
  store i64 %r1505, i64* %ptr_s
  %r1506 = load i64, i64* %ptr_s
  %r1507 = getelementptr [48 x i8], [48 x i8]* @.str.842, i64 0, i64 0
  %r1508 = ptrtoint i8* %r1507 to i64
  %r1509 = call i64 @_add(i64 %r1506, i64 %r1508)
  %r1510 = load i64, i64* %ptr_NL
  %r1511 = call i64 @_add(i64 %r1509, i64 %r1510)
  store i64 %r1511, i64* %ptr_s
  %r1512 = load i64, i64* %ptr_s
  %r1513 = getelementptr [24 x i8], [24 x i8]* @.str.843, i64 0, i64 0
  %r1514 = ptrtoint i8* %r1513 to i64
  %r1515 = call i64 @_add(i64 %r1512, i64 %r1514)
  %r1516 = load i64, i64* %ptr_NL
  %r1517 = call i64 @_add(i64 %r1515, i64 %r1516)
  store i64 %r1517, i64* %ptr_s
  %r1518 = load i64, i64* %ptr_s
  %r1519 = getelementptr [42 x i8], [42 x i8]* @.str.844, i64 0, i64 0
  %r1520 = ptrtoint i8* %r1519 to i64
  %r1521 = call i64 @_add(i64 %r1518, i64 %r1520)
  %r1522 = load i64, i64* %ptr_NL
  %r1523 = call i64 @_add(i64 %r1521, i64 %r1522)
  store i64 %r1523, i64* %ptr_s
  %r1524 = load i64, i64* %ptr_s
  %r1525 = getelementptr [19 x i8], [19 x i8]* @.str.845, i64 0, i64 0
  %r1526 = ptrtoint i8* %r1525 to i64
  %r1527 = call i64 @_add(i64 %r1524, i64 %r1526)
  %r1528 = load i64, i64* %ptr_NL
  %r1529 = call i64 @_add(i64 %r1527, i64 %r1528)
  store i64 %r1529, i64* %ptr_s
  %r1530 = load i64, i64* %ptr_s
  %r1531 = getelementptr [8 x i8], [8 x i8]* @.str.846, i64 0, i64 0
  %r1532 = ptrtoint i8* %r1531 to i64
  %r1533 = call i64 @_add(i64 %r1530, i64 %r1532)
  %r1534 = load i64, i64* %ptr_NL
  %r1535 = call i64 @_add(i64 %r1533, i64 %r1534)
  store i64 %r1535, i64* %ptr_s
  %r1536 = load i64, i64* %ptr_s
  %r1537 = getelementptr [52 x i8], [52 x i8]* @.str.847, i64 0, i64 0
  %r1538 = ptrtoint i8* %r1537 to i64
  %r1539 = call i64 @_add(i64 %r1536, i64 %r1538)
  %r1540 = load i64, i64* %ptr_NL
  %r1541 = call i64 @_add(i64 %r1539, i64 %r1540)
  store i64 %r1541, i64* %ptr_s
  %r1542 = load i64, i64* %ptr_s
  %r1543 = getelementptr [19 x i8], [19 x i8]* @.str.848, i64 0, i64 0
  %r1544 = ptrtoint i8* %r1543 to i64
  %r1545 = call i64 @_add(i64 %r1542, i64 %r1544)
  %r1546 = load i64, i64* %ptr_NL
  %r1547 = call i64 @_add(i64 %r1545, i64 %r1546)
  store i64 %r1547, i64* %ptr_s
  %r1548 = load i64, i64* %ptr_s
  %r1549 = getelementptr [9 x i8], [9 x i8]* @.str.849, i64 0, i64 0
  %r1550 = ptrtoint i8* %r1549 to i64
  %r1551 = call i64 @_add(i64 %r1548, i64 %r1550)
  %r1552 = load i64, i64* %ptr_NL
  %r1553 = call i64 @_add(i64 %r1551, i64 %r1552)
  store i64 %r1553, i64* %ptr_s
  %r1554 = load i64, i64* %ptr_s
  %r1555 = getelementptr [37 x i8], [37 x i8]* @.str.850, i64 0, i64 0
  %r1556 = ptrtoint i8* %r1555 to i64
  %r1557 = call i64 @_add(i64 %r1554, i64 %r1556)
  %r1558 = load i64, i64* %ptr_NL
  %r1559 = call i64 @_add(i64 %r1557, i64 %r1558)
  store i64 %r1559, i64* %ptr_s
  %r1560 = load i64, i64* %ptr_s
  %r1561 = getelementptr [52 x i8], [52 x i8]* @.str.851, i64 0, i64 0
  %r1562 = ptrtoint i8* %r1561 to i64
  %r1563 = call i64 @_add(i64 %r1560, i64 %r1562)
  %r1564 = load i64, i64* %ptr_NL
  %r1565 = call i64 @_add(i64 %r1563, i64 %r1564)
  store i64 %r1565, i64* %ptr_s
  %r1566 = load i64, i64* %ptr_s
  %r1567 = getelementptr [35 x i8], [35 x i8]* @.str.852, i64 0, i64 0
  %r1568 = ptrtoint i8* %r1567 to i64
  %r1569 = call i64 @_add(i64 %r1566, i64 %r1568)
  %r1570 = load i64, i64* %ptr_NL
  %r1571 = call i64 @_add(i64 %r1569, i64 %r1570)
  store i64 %r1571, i64* %ptr_s
  %r1572 = load i64, i64* %ptr_s
  %r1573 = getelementptr [36 x i8], [36 x i8]* @.str.853, i64 0, i64 0
  %r1574 = ptrtoint i8* %r1573 to i64
  %r1575 = call i64 @_add(i64 %r1572, i64 %r1574)
  %r1576 = load i64, i64* %ptr_NL
  %r1577 = call i64 @_add(i64 %r1575, i64 %r1576)
  store i64 %r1577, i64* %ptr_s
  %r1578 = load i64, i64* %ptr_s
  %r1579 = getelementptr [49 x i8], [49 x i8]* @.str.854, i64 0, i64 0
  %r1580 = ptrtoint i8* %r1579 to i64
  %r1581 = call i64 @_add(i64 %r1578, i64 %r1580)
  %r1582 = load i64, i64* %ptr_NL
  %r1583 = call i64 @_add(i64 %r1581, i64 %r1582)
  store i64 %r1583, i64* %ptr_s
  %r1584 = load i64, i64* %ptr_s
  %r1585 = getelementptr [30 x i8], [30 x i8]* @.str.855, i64 0, i64 0
  %r1586 = ptrtoint i8* %r1585 to i64
  %r1587 = call i64 @_add(i64 %r1584, i64 %r1586)
  %r1588 = load i64, i64* %ptr_NL
  %r1589 = call i64 @_add(i64 %r1587, i64 %r1588)
  store i64 %r1589, i64* %ptr_s
  %r1590 = load i64, i64* %ptr_s
  %r1591 = getelementptr [15 x i8], [15 x i8]* @.str.856, i64 0, i64 0
  %r1592 = ptrtoint i8* %r1591 to i64
  %r1593 = call i64 @_add(i64 %r1590, i64 %r1592)
  %r1594 = load i64, i64* %ptr_NL
  %r1595 = call i64 @_add(i64 %r1593, i64 %r1594)
  store i64 %r1595, i64* %ptr_s
  %r1596 = load i64, i64* %ptr_s
  %r1597 = getelementptr [15 x i8], [15 x i8]* @.str.857, i64 0, i64 0
  %r1598 = ptrtoint i8* %r1597 to i64
  %r1599 = call i64 @_add(i64 %r1596, i64 %r1598)
  %r1600 = load i64, i64* %ptr_NL
  %r1601 = call i64 @_add(i64 %r1599, i64 %r1600)
  store i64 %r1601, i64* %ptr_s
  %r1602 = load i64, i64* %ptr_s
  %r1603 = getelementptr [2 x i8], [2 x i8]* @.str.858, i64 0, i64 0
  %r1604 = ptrtoint i8* %r1603 to i64
  %r1605 = call i64 @_add(i64 %r1602, i64 %r1604)
  %r1606 = load i64, i64* %ptr_NL
  %r1607 = call i64 @_add(i64 %r1605, i64 %r1606)
  store i64 %r1607, i64* %ptr_s
  %r1608 = load i64, i64* %ptr_s
  %r1609 = getelementptr [34 x i8], [34 x i8]* @.str.859, i64 0, i64 0
  %r1610 = ptrtoint i8* %r1609 to i64
  %r1611 = call i64 @_add(i64 %r1608, i64 %r1610)
  %r1612 = load i64, i64* %ptr_NL
  %r1613 = call i64 @_add(i64 %r1611, i64 %r1612)
  store i64 %r1613, i64* %ptr_s
  %r1614 = load i64, i64* %ptr_s
  %r1615 = getelementptr [37 x i8], [37 x i8]* @.str.860, i64 0, i64 0
  %r1616 = ptrtoint i8* %r1615 to i64
  %r1617 = call i64 @_add(i64 %r1614, i64 %r1616)
  %r1618 = load i64, i64* %ptr_NL
  %r1619 = call i64 @_add(i64 %r1617, i64 %r1618)
  store i64 %r1619, i64* %ptr_s
  %r1620 = load i64, i64* %ptr_s
  %r1621 = getelementptr [34 x i8], [34 x i8]* @.str.861, i64 0, i64 0
  %r1622 = ptrtoint i8* %r1621 to i64
  %r1623 = call i64 @_add(i64 %r1620, i64 %r1622)
  %r1624 = load i64, i64* %ptr_NL
  %r1625 = call i64 @_add(i64 %r1623, i64 %r1624)
  store i64 %r1625, i64* %ptr_s
  %r1626 = load i64, i64* %ptr_s
  %r1627 = getelementptr [39 x i8], [39 x i8]* @.str.862, i64 0, i64 0
  %r1628 = ptrtoint i8* %r1627 to i64
  %r1629 = call i64 @_add(i64 %r1626, i64 %r1628)
  %r1630 = load i64, i64* %ptr_NL
  %r1631 = call i64 @_add(i64 %r1629, i64 %r1630)
  store i64 %r1631, i64* %ptr_s
  %r1632 = load i64, i64* %ptr_s
  %r1633 = getelementptr [39 x i8], [39 x i8]* @.str.863, i64 0, i64 0
  %r1634 = ptrtoint i8* %r1633 to i64
  %r1635 = call i64 @_add(i64 %r1632, i64 %r1634)
  %r1636 = load i64, i64* %ptr_NL
  %r1637 = call i64 @_add(i64 %r1635, i64 %r1636)
  store i64 %r1637, i64* %ptr_s
  %r1638 = load i64, i64* %ptr_s
  %r1639 = getelementptr [5 x i8], [5 x i8]* @.str.864, i64 0, i64 0
  %r1640 = ptrtoint i8* %r1639 to i64
  %r1641 = call i64 @_add(i64 %r1638, i64 %r1640)
  %r1642 = load i64, i64* %ptr_NL
  %r1643 = call i64 @_add(i64 %r1641, i64 %r1642)
  store i64 %r1643, i64* %ptr_s
  %r1644 = load i64, i64* %ptr_s
  %r1645 = getelementptr [33 x i8], [33 x i8]* @.str.865, i64 0, i64 0
  %r1646 = ptrtoint i8* %r1645 to i64
  %r1647 = call i64 @_add(i64 %r1644, i64 %r1646)
  %r1648 = load i64, i64* %ptr_NL
  %r1649 = call i64 @_add(i64 %r1647, i64 %r1648)
  store i64 %r1649, i64* %ptr_s
  %r1650 = load i64, i64* %ptr_s
  %r1651 = getelementptr [36 x i8], [36 x i8]* @.str.866, i64 0, i64 0
  %r1652 = ptrtoint i8* %r1651 to i64
  %r1653 = call i64 @_add(i64 %r1650, i64 %r1652)
  %r1654 = load i64, i64* %ptr_NL
  %r1655 = call i64 @_add(i64 %r1653, i64 %r1654)
  store i64 %r1655, i64* %ptr_s
  %r1656 = load i64, i64* %ptr_s
  %r1657 = getelementptr [25 x i8], [25 x i8]* @.str.867, i64 0, i64 0
  %r1658 = ptrtoint i8* %r1657 to i64
  %r1659 = call i64 @_add(i64 %r1656, i64 %r1658)
  %r1660 = load i64, i64* %ptr_NL
  %r1661 = call i64 @_add(i64 %r1659, i64 %r1660)
  store i64 %r1661, i64* %ptr_s
  %r1662 = load i64, i64* %ptr_s
  %r1663 = getelementptr [15 x i8], [15 x i8]* @.str.868, i64 0, i64 0
  %r1664 = ptrtoint i8* %r1663 to i64
  %r1665 = call i64 @_add(i64 %r1662, i64 %r1664)
  %r1666 = load i64, i64* %ptr_NL
  %r1667 = call i64 @_add(i64 %r1665, i64 %r1666)
  store i64 %r1667, i64* %ptr_s
  %r1668 = load i64, i64* %ptr_s
  %r1669 = getelementptr [4 x i8], [4 x i8]* @.str.869, i64 0, i64 0
  %r1670 = ptrtoint i8* %r1669 to i64
  %r1671 = call i64 @_add(i64 %r1668, i64 %r1670)
  %r1672 = load i64, i64* %ptr_NL
  %r1673 = call i64 @_add(i64 %r1671, i64 %r1672)
  store i64 %r1673, i64* %ptr_s
  %r1674 = load i64, i64* %ptr_s
  %r1675 = getelementptr [39 x i8], [39 x i8]* @.str.870, i64 0, i64 0
  %r1676 = ptrtoint i8* %r1675 to i64
  %r1677 = call i64 @_add(i64 %r1674, i64 %r1676)
  %r1678 = load i64, i64* %ptr_NL
  %r1679 = call i64 @_add(i64 %r1677, i64 %r1678)
  store i64 %r1679, i64* %ptr_s
  %r1680 = load i64, i64* %ptr_s
  %r1681 = getelementptr [49 x i8], [49 x i8]* @.str.871, i64 0, i64 0
  %r1682 = ptrtoint i8* %r1681 to i64
  %r1683 = call i64 @_add(i64 %r1680, i64 %r1682)
  %r1684 = load i64, i64* %ptr_NL
  %r1685 = call i64 @_add(i64 %r1683, i64 %r1684)
  store i64 %r1685, i64* %ptr_s
  %r1686 = load i64, i64* %ptr_s
  %r1687 = getelementptr [29 x i8], [29 x i8]* @.str.872, i64 0, i64 0
  %r1688 = ptrtoint i8* %r1687 to i64
  %r1689 = call i64 @_add(i64 %r1686, i64 %r1688)
  %r1690 = load i64, i64* %ptr_NL
  %r1691 = call i64 @_add(i64 %r1689, i64 %r1690)
  store i64 %r1691, i64* %ptr_s
  %r1692 = load i64, i64* %ptr_s
  %r1693 = getelementptr [34 x i8], [34 x i8]* @.str.873, i64 0, i64 0
  %r1694 = ptrtoint i8* %r1693 to i64
  %r1695 = call i64 @_add(i64 %r1692, i64 %r1694)
  %r1696 = load i64, i64* %ptr_NL
  %r1697 = call i64 @_add(i64 %r1695, i64 %r1696)
  store i64 %r1697, i64* %ptr_s
  %r1698 = load i64, i64* %ptr_s
  %r1699 = getelementptr [15 x i8], [15 x i8]* @.str.874, i64 0, i64 0
  %r1700 = ptrtoint i8* %r1699 to i64
  %r1701 = call i64 @_add(i64 %r1698, i64 %r1700)
  %r1702 = load i64, i64* %ptr_NL
  %r1703 = call i64 @_add(i64 %r1701, i64 %r1702)
  store i64 %r1703, i64* %ptr_s
  %r1704 = load i64, i64* %ptr_s
  %r1705 = getelementptr [2 x i8], [2 x i8]* @.str.875, i64 0, i64 0
  %r1706 = ptrtoint i8* %r1705 to i64
  %r1707 = call i64 @_add(i64 %r1704, i64 %r1706)
  %r1708 = load i64, i64* %ptr_NL
  %r1709 = call i64 @_add(i64 %r1707, i64 %r1708)
  store i64 %r1709, i64* %ptr_s
  %r1710 = load i64, i64* %ptr_s
  %r1711 = getelementptr [36 x i8], [36 x i8]* @.str.876, i64 0, i64 0
  %r1712 = ptrtoint i8* %r1711 to i64
  %r1713 = call i64 @_add(i64 %r1710, i64 %r1712)
  %r1714 = load i64, i64* %ptr_NL
  %r1715 = call i64 @_add(i64 %r1713, i64 %r1714)
  store i64 %r1715, i64* %ptr_s
  %r1716 = load i64, i64* %ptr_s
  %r1717 = getelementptr [38 x i8], [38 x i8]* @.str.877, i64 0, i64 0
  %r1718 = ptrtoint i8* %r1717 to i64
  %r1719 = call i64 @_add(i64 %r1716, i64 %r1718)
  %r1720 = load i64, i64* %ptr_NL
  %r1721 = call i64 @_add(i64 %r1719, i64 %r1720)
  store i64 %r1721, i64* %ptr_s
  %r1722 = load i64, i64* %ptr_s
  %r1723 = getelementptr [67 x i8], [67 x i8]* @.str.878, i64 0, i64 0
  %r1724 = ptrtoint i8* %r1723 to i64
  %r1725 = call i64 @_add(i64 %r1722, i64 %r1724)
  %r1726 = load i64, i64* %ptr_NL
  %r1727 = call i64 @_add(i64 %r1725, i64 %r1726)
  store i64 %r1727, i64* %ptr_s
  %r1728 = load i64, i64* %ptr_s
  %r1729 = getelementptr [45 x i8], [45 x i8]* @.str.879, i64 0, i64 0
  %r1730 = ptrtoint i8* %r1729 to i64
  %r1731 = call i64 @_add(i64 %r1728, i64 %r1730)
  %r1732 = load i64, i64* %ptr_NL
  %r1733 = call i64 @_add(i64 %r1731, i64 %r1732)
  store i64 %r1733, i64* %ptr_s
  %r1734 = load i64, i64* %ptr_s
  %r1735 = getelementptr [34 x i8], [34 x i8]* @.str.880, i64 0, i64 0
  %r1736 = ptrtoint i8* %r1735 to i64
  %r1737 = call i64 @_add(i64 %r1734, i64 %r1736)
  %r1738 = load i64, i64* %ptr_NL
  %r1739 = call i64 @_add(i64 %r1737, i64 %r1738)
  store i64 %r1739, i64* %ptr_s
  %r1740 = load i64, i64* %ptr_s
  %r1741 = getelementptr [33 x i8], [33 x i8]* @.str.881, i64 0, i64 0
  %r1742 = ptrtoint i8* %r1741 to i64
  %r1743 = call i64 @_add(i64 %r1740, i64 %r1742)
  %r1744 = load i64, i64* %ptr_NL
  %r1745 = call i64 @_add(i64 %r1743, i64 %r1744)
  store i64 %r1745, i64* %ptr_s
  %r1746 = load i64, i64* %ptr_s
  %r1747 = getelementptr [40 x i8], [40 x i8]* @.str.882, i64 0, i64 0
  %r1748 = ptrtoint i8* %r1747 to i64
  %r1749 = call i64 @_add(i64 %r1746, i64 %r1748)
  %r1750 = load i64, i64* %ptr_NL
  %r1751 = call i64 @_add(i64 %r1749, i64 %r1750)
  store i64 %r1751, i64* %ptr_s
  %r1752 = load i64, i64* %ptr_s
  %r1753 = getelementptr [6 x i8], [6 x i8]* @.str.883, i64 0, i64 0
  %r1754 = ptrtoint i8* %r1753 to i64
  %r1755 = call i64 @_add(i64 %r1752, i64 %r1754)
  %r1756 = load i64, i64* %ptr_NL
  %r1757 = call i64 @_add(i64 %r1755, i64 %r1756)
  store i64 %r1757, i64* %ptr_s
  %r1758 = load i64, i64* %ptr_s
  %r1759 = getelementptr [40 x i8], [40 x i8]* @.str.884, i64 0, i64 0
  %r1760 = ptrtoint i8* %r1759 to i64
  %r1761 = call i64 @_add(i64 %r1758, i64 %r1760)
  %r1762 = load i64, i64* %ptr_NL
  %r1763 = call i64 @_add(i64 %r1761, i64 %r1762)
  store i64 %r1763, i64* %ptr_s
  %r1764 = load i64, i64* %ptr_s
  %r1765 = getelementptr [33 x i8], [33 x i8]* @.str.885, i64 0, i64 0
  %r1766 = ptrtoint i8* %r1765 to i64
  %r1767 = call i64 @_add(i64 %r1764, i64 %r1766)
  %r1768 = load i64, i64* %ptr_NL
  %r1769 = call i64 @_add(i64 %r1767, i64 %r1768)
  store i64 %r1769, i64* %ptr_s
  %r1770 = load i64, i64* %ptr_s
  %r1771 = getelementptr [40 x i8], [40 x i8]* @.str.886, i64 0, i64 0
  %r1772 = ptrtoint i8* %r1771 to i64
  %r1773 = call i64 @_add(i64 %r1770, i64 %r1772)
  %r1774 = load i64, i64* %ptr_NL
  %r1775 = call i64 @_add(i64 %r1773, i64 %r1774)
  store i64 %r1775, i64* %ptr_s
  %r1776 = load i64, i64* %ptr_s
  %r1777 = getelementptr [30 x i8], [30 x i8]* @.str.887, i64 0, i64 0
  %r1778 = ptrtoint i8* %r1777 to i64
  %r1779 = call i64 @_add(i64 %r1776, i64 %r1778)
  %r1780 = load i64, i64* %ptr_NL
  %r1781 = call i64 @_add(i64 %r1779, i64 %r1780)
  store i64 %r1781, i64* %ptr_s
  %r1782 = load i64, i64* %ptr_s
  %r1783 = getelementptr [41 x i8], [41 x i8]* @.str.888, i64 0, i64 0
  %r1784 = ptrtoint i8* %r1783 to i64
  %r1785 = call i64 @_add(i64 %r1782, i64 %r1784)
  %r1786 = load i64, i64* %ptr_NL
  %r1787 = call i64 @_add(i64 %r1785, i64 %r1786)
  store i64 %r1787, i64* %ptr_s
  %r1788 = load i64, i64* %ptr_s
  %r1789 = getelementptr [38 x i8], [38 x i8]* @.str.889, i64 0, i64 0
  %r1790 = ptrtoint i8* %r1789 to i64
  %r1791 = call i64 @_add(i64 %r1788, i64 %r1790)
  %r1792 = load i64, i64* %ptr_NL
  %r1793 = call i64 @_add(i64 %r1791, i64 %r1792)
  store i64 %r1793, i64* %ptr_s
  %r1794 = load i64, i64* %ptr_s
  %r1795 = getelementptr [57 x i8], [57 x i8]* @.str.890, i64 0, i64 0
  %r1796 = ptrtoint i8* %r1795 to i64
  %r1797 = call i64 @_add(i64 %r1794, i64 %r1796)
  %r1798 = load i64, i64* %ptr_NL
  %r1799 = call i64 @_add(i64 %r1797, i64 %r1798)
  store i64 %r1799, i64* %ptr_s
  %r1800 = load i64, i64* %ptr_s
  %r1801 = getelementptr [51 x i8], [51 x i8]* @.str.891, i64 0, i64 0
  %r1802 = ptrtoint i8* %r1801 to i64
  %r1803 = call i64 @_add(i64 %r1800, i64 %r1802)
  %r1804 = load i64, i64* %ptr_NL
  %r1805 = call i64 @_add(i64 %r1803, i64 %r1804)
  store i64 %r1805, i64* %ptr_s
  %r1806 = load i64, i64* %ptr_s
  %r1807 = getelementptr [24 x i8], [24 x i8]* @.str.892, i64 0, i64 0
  %r1808 = ptrtoint i8* %r1807 to i64
  %r1809 = call i64 @_add(i64 %r1806, i64 %r1808)
  %r1810 = load i64, i64* %ptr_NL
  %r1811 = call i64 @_add(i64 %r1809, i64 %r1810)
  store i64 %r1811, i64* %ptr_s
  %r1812 = load i64, i64* %ptr_s
  %r1813 = getelementptr [27 x i8], [27 x i8]* @.str.893, i64 0, i64 0
  %r1814 = ptrtoint i8* %r1813 to i64
  %r1815 = call i64 @_add(i64 %r1812, i64 %r1814)
  %r1816 = load i64, i64* %ptr_NL
  %r1817 = call i64 @_add(i64 %r1815, i64 %r1816)
  store i64 %r1817, i64* %ptr_s
  %r1818 = load i64, i64* %ptr_s
  %r1819 = getelementptr [15 x i8], [15 x i8]* @.str.894, i64 0, i64 0
  %r1820 = ptrtoint i8* %r1819 to i64
  %r1821 = call i64 @_add(i64 %r1818, i64 %r1820)
  %r1822 = load i64, i64* %ptr_NL
  %r1823 = call i64 @_add(i64 %r1821, i64 %r1822)
  store i64 %r1823, i64* %ptr_s
  %r1824 = load i64, i64* %ptr_s
  %r1825 = getelementptr [5 x i8], [5 x i8]* @.str.895, i64 0, i64 0
  %r1826 = ptrtoint i8* %r1825 to i64
  %r1827 = call i64 @_add(i64 %r1824, i64 %r1826)
  %r1828 = load i64, i64* %ptr_NL
  %r1829 = call i64 @_add(i64 %r1827, i64 %r1828)
  store i64 %r1829, i64* %ptr_s
  %r1830 = load i64, i64* %ptr_s
  %r1831 = getelementptr [12 x i8], [12 x i8]* @.str.896, i64 0, i64 0
  %r1832 = ptrtoint i8* %r1831 to i64
  %r1833 = call i64 @_add(i64 %r1830, i64 %r1832)
  %r1834 = load i64, i64* %ptr_NL
  %r1835 = call i64 @_add(i64 %r1833, i64 %r1834)
  store i64 %r1835, i64* %ptr_s
  %r1836 = load i64, i64* %ptr_s
  %r1837 = getelementptr [2 x i8], [2 x i8]* @.str.897, i64 0, i64 0
  %r1838 = ptrtoint i8* %r1837 to i64
  %r1839 = call i64 @_add(i64 %r1836, i64 %r1838)
  %r1840 = load i64, i64* %ptr_NL
  %r1841 = call i64 @_add(i64 %r1839, i64 %r1840)
  store i64 %r1841, i64* %ptr_s
  %r1842 = load i64, i64* %ptr_s
  %r1843 = getelementptr [52 x i8], [52 x i8]* @.str.898, i64 0, i64 0
  %r1844 = ptrtoint i8* %r1843 to i64
  %r1845 = call i64 @_add(i64 %r1842, i64 %r1844)
  %r1846 = load i64, i64* %ptr_NL
  %r1847 = call i64 @_add(i64 %r1845, i64 %r1846)
  store i64 %r1847, i64* %ptr_s
  %r1848 = load i64, i64* %ptr_s
  %r1849 = getelementptr [38 x i8], [38 x i8]* @.str.899, i64 0, i64 0
  %r1850 = ptrtoint i8* %r1849 to i64
  %r1851 = call i64 @_add(i64 %r1848, i64 %r1850)
  %r1852 = load i64, i64* %ptr_NL
  %r1853 = call i64 @_add(i64 %r1851, i64 %r1852)
  store i64 %r1853, i64* %ptr_s
  %r1854 = load i64, i64* %ptr_s
  %r1855 = getelementptr [44 x i8], [44 x i8]* @.str.900, i64 0, i64 0
  %r1856 = ptrtoint i8* %r1855 to i64
  %r1857 = call i64 @_add(i64 %r1854, i64 %r1856)
  %r1858 = load i64, i64* %ptr_NL
  %r1859 = call i64 @_add(i64 %r1857, i64 %r1858)
  store i64 %r1859, i64* %ptr_s
  %r1860 = load i64, i64* %ptr_s
  %r1861 = getelementptr [67 x i8], [67 x i8]* @.str.901, i64 0, i64 0
  %r1862 = ptrtoint i8* %r1861 to i64
  %r1863 = call i64 @_add(i64 %r1860, i64 %r1862)
  %r1864 = load i64, i64* %ptr_NL
  %r1865 = call i64 @_add(i64 %r1863, i64 %r1864)
  store i64 %r1865, i64* %ptr_s
  %r1866 = load i64, i64* %ptr_s
  %r1867 = getelementptr [45 x i8], [45 x i8]* @.str.902, i64 0, i64 0
  %r1868 = ptrtoint i8* %r1867 to i64
  %r1869 = call i64 @_add(i64 %r1866, i64 %r1868)
  %r1870 = load i64, i64* %ptr_NL
  %r1871 = call i64 @_add(i64 %r1869, i64 %r1870)
  store i64 %r1871, i64* %ptr_s
  %r1872 = load i64, i64* %ptr_s
  %r1873 = getelementptr [40 x i8], [40 x i8]* @.str.903, i64 0, i64 0
  %r1874 = ptrtoint i8* %r1873 to i64
  %r1875 = call i64 @_add(i64 %r1872, i64 %r1874)
  %r1876 = load i64, i64* %ptr_NL
  %r1877 = call i64 @_add(i64 %r1875, i64 %r1876)
  store i64 %r1877, i64* %ptr_s
  %r1878 = load i64, i64* %ptr_s
  %r1879 = getelementptr [58 x i8], [58 x i8]* @.str.904, i64 0, i64 0
  %r1880 = ptrtoint i8* %r1879 to i64
  %r1881 = call i64 @_add(i64 %r1878, i64 %r1880)
  %r1882 = load i64, i64* %ptr_NL
  %r1883 = call i64 @_add(i64 %r1881, i64 %r1882)
  store i64 %r1883, i64* %ptr_s
  %r1884 = load i64, i64* %ptr_s
  %r1885 = getelementptr [27 x i8], [27 x i8]* @.str.905, i64 0, i64 0
  %r1886 = ptrtoint i8* %r1885 to i64
  %r1887 = call i64 @_add(i64 %r1884, i64 %r1886)
  %r1888 = load i64, i64* %ptr_NL
  %r1889 = call i64 @_add(i64 %r1887, i64 %r1888)
  store i64 %r1889, i64* %ptr_s
  %r1890 = load i64, i64* %ptr_s
  %r1891 = getelementptr [12 x i8], [12 x i8]* @.str.906, i64 0, i64 0
  %r1892 = ptrtoint i8* %r1891 to i64
  %r1893 = call i64 @_add(i64 %r1890, i64 %r1892)
  %r1894 = load i64, i64* %ptr_NL
  %r1895 = call i64 @_add(i64 %r1893, i64 %r1894)
  store i64 %r1895, i64* %ptr_s
  %r1896 = load i64, i64* %ptr_s
  %r1897 = getelementptr [2 x i8], [2 x i8]* @.str.907, i64 0, i64 0
  %r1898 = ptrtoint i8* %r1897 to i64
  %r1899 = call i64 @_add(i64 %r1896, i64 %r1898)
  %r1900 = load i64, i64* %ptr_NL
  %r1901 = call i64 @_add(i64 %r1899, i64 %r1900)
  store i64 %r1901, i64* %ptr_s
  %r1902 = load i64, i64* %ptr_s
  %r1903 = getelementptr [34 x i8], [34 x i8]* @.str.908, i64 0, i64 0
  %r1904 = ptrtoint i8* %r1903 to i64
  %r1905 = call i64 @_add(i64 %r1902, i64 %r1904)
  %r1906 = load i64, i64* %ptr_NL
  %r1907 = call i64 @_add(i64 %r1905, i64 %r1906)
  store i64 %r1907, i64* %ptr_s
  %r1908 = load i64, i64* %ptr_s
  %r1909 = getelementptr [7 x i8], [7 x i8]* @.str.909, i64 0, i64 0
  %r1910 = ptrtoint i8* %r1909 to i64
  %r1911 = call i64 @_add(i64 %r1908, i64 %r1910)
  %r1912 = load i64, i64* %ptr_NL
  %r1913 = call i64 @_add(i64 %r1911, i64 %r1912)
  store i64 %r1913, i64* %ptr_s
  %r1914 = load i64, i64* %ptr_s
  %r1915 = getelementptr [42 x i8], [42 x i8]* @.str.910, i64 0, i64 0
  %r1916 = ptrtoint i8* %r1915 to i64
  %r1917 = call i64 @_add(i64 %r1914, i64 %r1916)
  %r1918 = load i64, i64* %ptr_NL
  %r1919 = call i64 @_add(i64 %r1917, i64 %r1918)
  store i64 %r1919, i64* %ptr_s
  %r1920 = load i64, i64* %ptr_s
  %r1921 = getelementptr [52 x i8], [52 x i8]* @.str.911, i64 0, i64 0
  %r1922 = ptrtoint i8* %r1921 to i64
  %r1923 = call i64 @_add(i64 %r1920, i64 %r1922)
  %r1924 = load i64, i64* %ptr_NL
  %r1925 = call i64 @_add(i64 %r1923, i64 %r1924)
  store i64 %r1925, i64* %ptr_s
  %r1926 = load i64, i64* %ptr_s
  %r1927 = getelementptr [11 x i8], [11 x i8]* @.str.912, i64 0, i64 0
  %r1928 = ptrtoint i8* %r1927 to i64
  %r1929 = call i64 @_add(i64 %r1926, i64 %r1928)
  %r1930 = load i64, i64* %ptr_NL
  %r1931 = call i64 @_add(i64 %r1929, i64 %r1930)
  store i64 %r1931, i64* %ptr_s
  %r1932 = load i64, i64* %ptr_s
  %r1933 = getelementptr [35 x i8], [35 x i8]* @.str.913, i64 0, i64 0
  %r1934 = ptrtoint i8* %r1933 to i64
  %r1935 = call i64 @_add(i64 %r1932, i64 %r1934)
  %r1936 = load i64, i64* %ptr_NL
  %r1937 = call i64 @_add(i64 %r1935, i64 %r1936)
  store i64 %r1937, i64* %ptr_s
  %r1938 = load i64, i64* %ptr_s
  %r1939 = getelementptr [28 x i8], [28 x i8]* @.str.914, i64 0, i64 0
  %r1940 = ptrtoint i8* %r1939 to i64
  %r1941 = call i64 @_add(i64 %r1938, i64 %r1940)
  %r1942 = load i64, i64* %ptr_NL
  %r1943 = call i64 @_add(i64 %r1941, i64 %r1942)
  store i64 %r1943, i64* %ptr_s
  %r1944 = load i64, i64* %ptr_s
  %r1945 = getelementptr [32 x i8], [32 x i8]* @.str.915, i64 0, i64 0
  %r1946 = ptrtoint i8* %r1945 to i64
  %r1947 = call i64 @_add(i64 %r1944, i64 %r1946)
  %r1948 = load i64, i64* %ptr_NL
  %r1949 = call i64 @_add(i64 %r1947, i64 %r1948)
  store i64 %r1949, i64* %ptr_s
  %r1950 = load i64, i64* %ptr_s
  %r1951 = getelementptr [54 x i8], [54 x i8]* @.str.916, i64 0, i64 0
  %r1952 = ptrtoint i8* %r1951 to i64
  %r1953 = call i64 @_add(i64 %r1950, i64 %r1952)
  %r1954 = load i64, i64* %ptr_NL
  %r1955 = call i64 @_add(i64 %r1953, i64 %r1954)
  store i64 %r1955, i64* %ptr_s
  %r1956 = load i64, i64* %ptr_s
  %r1957 = getelementptr [12 x i8], [12 x i8]* @.str.917, i64 0, i64 0
  %r1958 = ptrtoint i8* %r1957 to i64
  %r1959 = call i64 @_add(i64 %r1956, i64 %r1958)
  %r1960 = load i64, i64* %ptr_NL
  %r1961 = call i64 @_add(i64 %r1959, i64 %r1960)
  store i64 %r1961, i64* %ptr_s
  %r1962 = load i64, i64* %ptr_s
  %r1963 = getelementptr [70 x i8], [70 x i8]* @.str.918, i64 0, i64 0
  %r1964 = ptrtoint i8* %r1963 to i64
  %r1965 = call i64 @_add(i64 %r1962, i64 %r1964)
  %r1966 = load i64, i64* %ptr_NL
  %r1967 = call i64 @_add(i64 %r1965, i64 %r1966)
  store i64 %r1967, i64* %ptr_s
  %r1968 = load i64, i64* %ptr_s
  %r1969 = getelementptr [67 x i8], [67 x i8]* @.str.919, i64 0, i64 0
  %r1970 = ptrtoint i8* %r1969 to i64
  %r1971 = call i64 @_add(i64 %r1968, i64 %r1970)
  %r1972 = load i64, i64* %ptr_NL
  %r1973 = call i64 @_add(i64 %r1971, i64 %r1972)
  store i64 %r1973, i64* %ptr_s
  %r1974 = load i64, i64* %ptr_s
  %r1975 = getelementptr [51 x i8], [51 x i8]* @.str.920, i64 0, i64 0
  %r1976 = ptrtoint i8* %r1975 to i64
  %r1977 = call i64 @_add(i64 %r1974, i64 %r1976)
  %r1978 = load i64, i64* %ptr_NL
  %r1979 = call i64 @_add(i64 %r1977, i64 %r1978)
  store i64 %r1979, i64* %ptr_s
  %r1980 = load i64, i64* %ptr_s
  %r1981 = getelementptr [29 x i8], [29 x i8]* @.str.921, i64 0, i64 0
  %r1982 = ptrtoint i8* %r1981 to i64
  %r1983 = call i64 @_add(i64 %r1980, i64 %r1982)
  %r1984 = load i64, i64* %ptr_NL
  %r1985 = call i64 @_add(i64 %r1983, i64 %r1984)
  store i64 %r1985, i64* %ptr_s
  %r1986 = load i64, i64* %ptr_s
  %r1987 = getelementptr [37 x i8], [37 x i8]* @.str.922, i64 0, i64 0
  %r1988 = ptrtoint i8* %r1987 to i64
  %r1989 = call i64 @_add(i64 %r1986, i64 %r1988)
  %r1990 = load i64, i64* %ptr_NL
  %r1991 = call i64 @_add(i64 %r1989, i64 %r1990)
  store i64 %r1991, i64* %ptr_s
  %r1992 = load i64, i64* %ptr_s
  %r1993 = getelementptr [51 x i8], [51 x i8]* @.str.923, i64 0, i64 0
  %r1994 = ptrtoint i8* %r1993 to i64
  %r1995 = call i64 @_add(i64 %r1992, i64 %r1994)
  %r1996 = load i64, i64* %ptr_NL
  %r1997 = call i64 @_add(i64 %r1995, i64 %r1996)
  store i64 %r1997, i64* %ptr_s
  %r1998 = load i64, i64* %ptr_s
  %r1999 = getelementptr [33 x i8], [33 x i8]* @.str.924, i64 0, i64 0
  %r2000 = ptrtoint i8* %r1999 to i64
  %r2001 = call i64 @_add(i64 %r1998, i64 %r2000)
  %r2002 = load i64, i64* %ptr_NL
  %r2003 = call i64 @_add(i64 %r2001, i64 %r2002)
  store i64 %r2003, i64* %ptr_s
  %r2004 = load i64, i64* %ptr_s
  %r2005 = getelementptr [34 x i8], [34 x i8]* @.str.925, i64 0, i64 0
  %r2006 = ptrtoint i8* %r2005 to i64
  %r2007 = call i64 @_add(i64 %r2004, i64 %r2006)
  %r2008 = load i64, i64* %ptr_NL
  %r2009 = call i64 @_add(i64 %r2007, i64 %r2008)
  store i64 %r2009, i64* %ptr_s
  %r2010 = load i64, i64* %ptr_s
  %r2011 = getelementptr [50 x i8], [50 x i8]* @.str.926, i64 0, i64 0
  %r2012 = ptrtoint i8* %r2011 to i64
  %r2013 = call i64 @_add(i64 %r2010, i64 %r2012)
  %r2014 = load i64, i64* %ptr_NL
  %r2015 = call i64 @_add(i64 %r2013, i64 %r2014)
  store i64 %r2015, i64* %ptr_s
  %r2016 = load i64, i64* %ptr_s
  %r2017 = getelementptr [12 x i8], [12 x i8]* @.str.927, i64 0, i64 0
  %r2018 = ptrtoint i8* %r2017 to i64
  %r2019 = call i64 @_add(i64 %r2016, i64 %r2018)
  %r2020 = load i64, i64* %ptr_NL
  %r2021 = call i64 @_add(i64 %r2019, i64 %r2020)
  store i64 %r2021, i64* %ptr_s
  %r2022 = load i64, i64* %ptr_s
  %r2023 = getelementptr [52 x i8], [52 x i8]* @.str.928, i64 0, i64 0
  %r2024 = ptrtoint i8* %r2023 to i64
  %r2025 = call i64 @_add(i64 %r2022, i64 %r2024)
  %r2026 = load i64, i64* %ptr_NL
  %r2027 = call i64 @_add(i64 %r2025, i64 %r2026)
  store i64 %r2027, i64* %ptr_s
  %r2028 = load i64, i64* %ptr_s
  %r2029 = getelementptr [35 x i8], [35 x i8]* @.str.929, i64 0, i64 0
  %r2030 = ptrtoint i8* %r2029 to i64
  %r2031 = call i64 @_add(i64 %r2028, i64 %r2030)
  %r2032 = load i64, i64* %ptr_NL
  %r2033 = call i64 @_add(i64 %r2031, i64 %r2032)
  store i64 %r2033, i64* %ptr_s
  %r2034 = load i64, i64* %ptr_s
  %r2035 = getelementptr [41 x i8], [41 x i8]* @.str.930, i64 0, i64 0
  %r2036 = ptrtoint i8* %r2035 to i64
  %r2037 = call i64 @_add(i64 %r2034, i64 %r2036)
  %r2038 = load i64, i64* %ptr_NL
  %r2039 = call i64 @_add(i64 %r2037, i64 %r2038)
  store i64 %r2039, i64* %ptr_s
  %r2040 = load i64, i64* %ptr_s
  %r2041 = getelementptr [17 x i8], [17 x i8]* @.str.931, i64 0, i64 0
  %r2042 = ptrtoint i8* %r2041 to i64
  %r2043 = call i64 @_add(i64 %r2040, i64 %r2042)
  %r2044 = load i64, i64* %ptr_NL
  %r2045 = call i64 @_add(i64 %r2043, i64 %r2044)
  store i64 %r2045, i64* %ptr_s
  %r2046 = load i64, i64* %ptr_s
  %r2047 = getelementptr [6 x i8], [6 x i8]* @.str.932, i64 0, i64 0
  %r2048 = ptrtoint i8* %r2047 to i64
  %r2049 = call i64 @_add(i64 %r2046, i64 %r2048)
  %r2050 = load i64, i64* %ptr_NL
  %r2051 = call i64 @_add(i64 %r2049, i64 %r2050)
  store i64 %r2051, i64* %ptr_s
  %r2052 = load i64, i64* %ptr_s
  %r2053 = getelementptr [58 x i8], [58 x i8]* @.str.933, i64 0, i64 0
  %r2054 = ptrtoint i8* %r2053 to i64
  %r2055 = call i64 @_add(i64 %r2052, i64 %r2054)
  %r2056 = load i64, i64* %ptr_NL
  %r2057 = call i64 @_add(i64 %r2055, i64 %r2056)
  store i64 %r2057, i64* %ptr_s
  %r2058 = load i64, i64* %ptr_s
  %r2059 = getelementptr [32 x i8], [32 x i8]* @.str.934, i64 0, i64 0
  %r2060 = ptrtoint i8* %r2059 to i64
  %r2061 = call i64 @_add(i64 %r2058, i64 %r2060)
  %r2062 = load i64, i64* %ptr_NL
  %r2063 = call i64 @_add(i64 %r2061, i64 %r2062)
  store i64 %r2063, i64* %ptr_s
  %r2064 = load i64, i64* %ptr_s
  %r2065 = getelementptr [40 x i8], [40 x i8]* @.str.935, i64 0, i64 0
  %r2066 = ptrtoint i8* %r2065 to i64
  %r2067 = call i64 @_add(i64 %r2064, i64 %r2066)
  %r2068 = load i64, i64* %ptr_NL
  %r2069 = call i64 @_add(i64 %r2067, i64 %r2068)
  store i64 %r2069, i64* %ptr_s
  %r2070 = load i64, i64* %ptr_s
  %r2071 = getelementptr [6 x i8], [6 x i8]* @.str.936, i64 0, i64 0
  %r2072 = ptrtoint i8* %r2071 to i64
  %r2073 = call i64 @_add(i64 %r2070, i64 %r2072)
  %r2074 = load i64, i64* %ptr_NL
  %r2075 = call i64 @_add(i64 %r2073, i64 %r2074)
  store i64 %r2075, i64* %ptr_s
  %r2076 = load i64, i64* %ptr_s
  %r2077 = getelementptr [33 x i8], [33 x i8]* @.str.937, i64 0, i64 0
  %r2078 = ptrtoint i8* %r2077 to i64
  %r2079 = call i64 @_add(i64 %r2076, i64 %r2078)
  %r2080 = load i64, i64* %ptr_NL
  %r2081 = call i64 @_add(i64 %r2079, i64 %r2080)
  store i64 %r2081, i64* %ptr_s
  %r2082 = load i64, i64* %ptr_s
  %r2083 = getelementptr [51 x i8], [51 x i8]* @.str.938, i64 0, i64 0
  %r2084 = ptrtoint i8* %r2083 to i64
  %r2085 = call i64 @_add(i64 %r2082, i64 %r2084)
  %r2086 = load i64, i64* %ptr_NL
  %r2087 = call i64 @_add(i64 %r2085, i64 %r2086)
  store i64 %r2087, i64* %ptr_s
  %r2088 = load i64, i64* %ptr_s
  %r2089 = getelementptr [7 x i8], [7 x i8]* @.str.939, i64 0, i64 0
  %r2090 = ptrtoint i8* %r2089 to i64
  %r2091 = call i64 @_add(i64 %r2088, i64 %r2090)
  %r2092 = load i64, i64* %ptr_NL
  %r2093 = call i64 @_add(i64 %r2091, i64 %r2092)
  store i64 %r2093, i64* %ptr_s
  %r2094 = load i64, i64* %ptr_s
  %r2095 = getelementptr [70 x i8], [70 x i8]* @.str.940, i64 0, i64 0
  %r2096 = ptrtoint i8* %r2095 to i64
  %r2097 = call i64 @_add(i64 %r2094, i64 %r2096)
  %r2098 = load i64, i64* %ptr_NL
  %r2099 = call i64 @_add(i64 %r2097, i64 %r2098)
  store i64 %r2099, i64* %ptr_s
  %r2100 = load i64, i64* %ptr_s
  %r2101 = getelementptr [67 x i8], [67 x i8]* @.str.941, i64 0, i64 0
  %r2102 = ptrtoint i8* %r2101 to i64
  %r2103 = call i64 @_add(i64 %r2100, i64 %r2102)
  %r2104 = load i64, i64* %ptr_NL
  %r2105 = call i64 @_add(i64 %r2103, i64 %r2104)
  store i64 %r2105, i64* %ptr_s
  %r2106 = load i64, i64* %ptr_s
  %r2107 = getelementptr [51 x i8], [51 x i8]* @.str.942, i64 0, i64 0
  %r2108 = ptrtoint i8* %r2107 to i64
  %r2109 = call i64 @_add(i64 %r2106, i64 %r2108)
  %r2110 = load i64, i64* %ptr_NL
  %r2111 = call i64 @_add(i64 %r2109, i64 %r2110)
  store i64 %r2111, i64* %ptr_s
  %r2112 = load i64, i64* %ptr_s
  %r2113 = getelementptr [29 x i8], [29 x i8]* @.str.943, i64 0, i64 0
  %r2114 = ptrtoint i8* %r2113 to i64
  %r2115 = call i64 @_add(i64 %r2112, i64 %r2114)
  %r2116 = load i64, i64* %ptr_NL
  %r2117 = call i64 @_add(i64 %r2115, i64 %r2116)
  store i64 %r2117, i64* %ptr_s
  %r2118 = load i64, i64* %ptr_s
  %r2119 = getelementptr [22 x i8], [22 x i8]* @.str.944, i64 0, i64 0
  %r2120 = ptrtoint i8* %r2119 to i64
  %r2121 = call i64 @_add(i64 %r2118, i64 %r2120)
  %r2122 = load i64, i64* %ptr_NL
  %r2123 = call i64 @_add(i64 %r2121, i64 %r2122)
  store i64 %r2123, i64* %ptr_s
  %r2124 = load i64, i64* %ptr_s
  %r2125 = getelementptr [11 x i8], [11 x i8]* @.str.945, i64 0, i64 0
  %r2126 = ptrtoint i8* %r2125 to i64
  %r2127 = call i64 @_add(i64 %r2124, i64 %r2126)
  %r2128 = load i64, i64* %ptr_NL
  %r2129 = call i64 @_add(i64 %r2127, i64 %r2128)
  store i64 %r2129, i64* %ptr_s
  %r2130 = load i64, i64* %ptr_s
  %r2131 = getelementptr [52 x i8], [52 x i8]* @.str.946, i64 0, i64 0
  %r2132 = ptrtoint i8* %r2131 to i64
  %r2133 = call i64 @_add(i64 %r2130, i64 %r2132)
  %r2134 = load i64, i64* %ptr_NL
  %r2135 = call i64 @_add(i64 %r2133, i64 %r2134)
  store i64 %r2135, i64* %ptr_s
  %r2136 = load i64, i64* %ptr_s
  %r2137 = getelementptr [28 x i8], [28 x i8]* @.str.947, i64 0, i64 0
  %r2138 = ptrtoint i8* %r2137 to i64
  %r2139 = call i64 @_add(i64 %r2136, i64 %r2138)
  %r2140 = load i64, i64* %ptr_NL
  %r2141 = call i64 @_add(i64 %r2139, i64 %r2140)
  store i64 %r2141, i64* %ptr_s
  %r2142 = load i64, i64* %ptr_s
  %r2143 = getelementptr [42 x i8], [42 x i8]* @.str.948, i64 0, i64 0
  %r2144 = ptrtoint i8* %r2143 to i64
  %r2145 = call i64 @_add(i64 %r2142, i64 %r2144)
  %r2146 = load i64, i64* %ptr_NL
  %r2147 = call i64 @_add(i64 %r2145, i64 %r2146)
  store i64 %r2147, i64* %ptr_s
  %r2148 = load i64, i64* %ptr_s
  %r2149 = getelementptr [52 x i8], [52 x i8]* @.str.949, i64 0, i64 0
  %r2150 = ptrtoint i8* %r2149 to i64
  %r2151 = call i64 @_add(i64 %r2148, i64 %r2150)
  %r2152 = load i64, i64* %ptr_NL
  %r2153 = call i64 @_add(i64 %r2151, i64 %r2152)
  store i64 %r2153, i64* %ptr_s
  %r2154 = load i64, i64* %ptr_s
  %r2155 = getelementptr [13 x i8], [13 x i8]* @.str.950, i64 0, i64 0
  %r2156 = ptrtoint i8* %r2155 to i64
  %r2157 = call i64 @_add(i64 %r2154, i64 %r2156)
  %r2158 = load i64, i64* %ptr_NL
  %r2159 = call i64 @_add(i64 %r2157, i64 %r2158)
  store i64 %r2159, i64* %ptr_s
  %r2160 = load i64, i64* %ptr_s
  %r2161 = getelementptr [36 x i8], [36 x i8]* @.str.951, i64 0, i64 0
  %r2162 = ptrtoint i8* %r2161 to i64
  %r2163 = call i64 @_add(i64 %r2160, i64 %r2162)
  %r2164 = load i64, i64* %ptr_NL
  %r2165 = call i64 @_add(i64 %r2163, i64 %r2164)
  store i64 %r2165, i64* %ptr_s
  %r2166 = load i64, i64* %ptr_s
  %r2167 = getelementptr [34 x i8], [34 x i8]* @.str.952, i64 0, i64 0
  %r2168 = ptrtoint i8* %r2167 to i64
  %r2169 = call i64 @_add(i64 %r2166, i64 %r2168)
  %r2170 = load i64, i64* %ptr_NL
  %r2171 = call i64 @_add(i64 %r2169, i64 %r2170)
  store i64 %r2171, i64* %ptr_s
  %r2172 = load i64, i64* %ptr_s
  %r2173 = getelementptr [38 x i8], [38 x i8]* @.str.953, i64 0, i64 0
  %r2174 = ptrtoint i8* %r2173 to i64
  %r2175 = call i64 @_add(i64 %r2172, i64 %r2174)
  %r2176 = load i64, i64* %ptr_NL
  %r2177 = call i64 @_add(i64 %r2175, i64 %r2176)
  store i64 %r2177, i64* %ptr_s
  %r2178 = load i64, i64* %ptr_s
  %r2179 = getelementptr [55 x i8], [55 x i8]* @.str.954, i64 0, i64 0
  %r2180 = ptrtoint i8* %r2179 to i64
  %r2181 = call i64 @_add(i64 %r2178, i64 %r2180)
  %r2182 = load i64, i64* %ptr_NL
  %r2183 = call i64 @_add(i64 %r2181, i64 %r2182)
  store i64 %r2183, i64* %ptr_s
  %r2184 = load i64, i64* %ptr_s
  %r2185 = getelementptr [10 x i8], [10 x i8]* @.str.955, i64 0, i64 0
  %r2186 = ptrtoint i8* %r2185 to i64
  %r2187 = call i64 @_add(i64 %r2184, i64 %r2186)
  %r2188 = load i64, i64* %ptr_NL
  %r2189 = call i64 @_add(i64 %r2187, i64 %r2188)
  store i64 %r2189, i64* %ptr_s
  %r2190 = load i64, i64* %ptr_s
  %r2191 = getelementptr [30 x i8], [30 x i8]* @.str.956, i64 0, i64 0
  %r2192 = ptrtoint i8* %r2191 to i64
  %r2193 = call i64 @_add(i64 %r2190, i64 %r2192)
  %r2194 = load i64, i64* %ptr_NL
  %r2195 = call i64 @_add(i64 %r2193, i64 %r2194)
  store i64 %r2195, i64* %ptr_s
  %r2196 = load i64, i64* %ptr_s
  %r2197 = getelementptr [21 x i8], [21 x i8]* @.str.957, i64 0, i64 0
  %r2198 = ptrtoint i8* %r2197 to i64
  %r2199 = call i64 @_add(i64 %r2196, i64 %r2198)
  %r2200 = load i64, i64* %ptr_NL
  %r2201 = call i64 @_add(i64 %r2199, i64 %r2200)
  store i64 %r2201, i64* %ptr_s
  %r2202 = load i64, i64* %ptr_s
  %r2203 = getelementptr [11 x i8], [11 x i8]* @.str.958, i64 0, i64 0
  %r2204 = ptrtoint i8* %r2203 to i64
  %r2205 = call i64 @_add(i64 %r2202, i64 %r2204)
  %r2206 = load i64, i64* %ptr_NL
  %r2207 = call i64 @_add(i64 %r2205, i64 %r2206)
  store i64 %r2207, i64* %ptr_s
  %r2208 = load i64, i64* %ptr_s
  %r2209 = getelementptr [70 x i8], [70 x i8]* @.str.959, i64 0, i64 0
  %r2210 = ptrtoint i8* %r2209 to i64
  %r2211 = call i64 @_add(i64 %r2208, i64 %r2210)
  %r2212 = load i64, i64* %ptr_NL
  %r2213 = call i64 @_add(i64 %r2211, i64 %r2212)
  store i64 %r2213, i64* %ptr_s
  %r2214 = load i64, i64* %ptr_s
  %r2215 = getelementptr [35 x i8], [35 x i8]* @.str.960, i64 0, i64 0
  %r2216 = ptrtoint i8* %r2215 to i64
  %r2217 = call i64 @_add(i64 %r2214, i64 %r2216)
  %r2218 = load i64, i64* %ptr_NL
  %r2219 = call i64 @_add(i64 %r2217, i64 %r2218)
  store i64 %r2219, i64* %ptr_s
  %r2220 = load i64, i64* %ptr_s
  %r2221 = getelementptr [54 x i8], [54 x i8]* @.str.961, i64 0, i64 0
  %r2222 = ptrtoint i8* %r2221 to i64
  %r2223 = call i64 @_add(i64 %r2220, i64 %r2222)
  %r2224 = load i64, i64* %ptr_NL
  %r2225 = call i64 @_add(i64 %r2223, i64 %r2224)
  store i64 %r2225, i64* %ptr_s
  %r2226 = load i64, i64* %ptr_s
  %r2227 = getelementptr [29 x i8], [29 x i8]* @.str.962, i64 0, i64 0
  %r2228 = ptrtoint i8* %r2227 to i64
  %r2229 = call i64 @_add(i64 %r2226, i64 %r2228)
  %r2230 = load i64, i64* %ptr_NL
  %r2231 = call i64 @_add(i64 %r2229, i64 %r2230)
  store i64 %r2231, i64* %ptr_s
  %r2232 = load i64, i64* %ptr_s
  %r2233 = getelementptr [21 x i8], [21 x i8]* @.str.963, i64 0, i64 0
  %r2234 = ptrtoint i8* %r2233 to i64
  %r2235 = call i64 @_add(i64 %r2232, i64 %r2234)
  %r2236 = load i64, i64* %ptr_NL
  %r2237 = call i64 @_add(i64 %r2235, i64 %r2236)
  store i64 %r2237, i64* %ptr_s
  %r2238 = load i64, i64* %ptr_s
  %r2239 = getelementptr [7 x i8], [7 x i8]* @.str.964, i64 0, i64 0
  %r2240 = ptrtoint i8* %r2239 to i64
  %r2241 = call i64 @_add(i64 %r2238, i64 %r2240)
  %r2242 = load i64, i64* %ptr_NL
  %r2243 = call i64 @_add(i64 %r2241, i64 %r2242)
  store i64 %r2243, i64* %ptr_s
  %r2244 = load i64, i64* %ptr_s
  %r2245 = getelementptr [69 x i8], [69 x i8]* @.str.965, i64 0, i64 0
  %r2246 = ptrtoint i8* %r2245 to i64
  %r2247 = call i64 @_add(i64 %r2244, i64 %r2246)
  %r2248 = load i64, i64* %ptr_NL
  %r2249 = call i64 @_add(i64 %r2247, i64 %r2248)
  store i64 %r2249, i64* %ptr_s
  %r2250 = load i64, i64* %ptr_s
  %r2251 = getelementptr [48 x i8], [48 x i8]* @.str.966, i64 0, i64 0
  %r2252 = ptrtoint i8* %r2251 to i64
  %r2253 = call i64 @_add(i64 %r2250, i64 %r2252)
  %r2254 = load i64, i64* %ptr_NL
  %r2255 = call i64 @_add(i64 %r2253, i64 %r2254)
  store i64 %r2255, i64* %ptr_s
  %r2256 = load i64, i64* %ptr_s
  %r2257 = getelementptr [29 x i8], [29 x i8]* @.str.967, i64 0, i64 0
  %r2258 = ptrtoint i8* %r2257 to i64
  %r2259 = call i64 @_add(i64 %r2256, i64 %r2258)
  %r2260 = load i64, i64* %ptr_NL
  %r2261 = call i64 @_add(i64 %r2259, i64 %r2260)
  store i64 %r2261, i64* %ptr_s
  %r2262 = load i64, i64* %ptr_s
  %r2263 = getelementptr [21 x i8], [21 x i8]* @.str.968, i64 0, i64 0
  %r2264 = ptrtoint i8* %r2263 to i64
  %r2265 = call i64 @_add(i64 %r2262, i64 %r2264)
  %r2266 = load i64, i64* %ptr_NL
  %r2267 = call i64 @_add(i64 %r2265, i64 %r2266)
  store i64 %r2267, i64* %ptr_s
  %r2268 = load i64, i64* %ptr_s
  %r2269 = getelementptr [10 x i8], [10 x i8]* @.str.969, i64 0, i64 0
  %r2270 = ptrtoint i8* %r2269 to i64
  %r2271 = call i64 @_add(i64 %r2268, i64 %r2270)
  %r2272 = load i64, i64* %ptr_NL
  %r2273 = call i64 @_add(i64 %r2271, i64 %r2272)
  store i64 %r2273, i64* %ptr_s
  %r2274 = load i64, i64* %ptr_s
  %r2275 = getelementptr [26 x i8], [26 x i8]* @.str.970, i64 0, i64 0
  %r2276 = ptrtoint i8* %r2275 to i64
  %r2277 = call i64 @_add(i64 %r2274, i64 %r2276)
  %r2278 = load i64, i64* %ptr_NL
  %r2279 = call i64 @_add(i64 %r2277, i64 %r2278)
  store i64 %r2279, i64* %ptr_s
  %r2280 = load i64, i64* %ptr_s
  %r2281 = getelementptr [17 x i8], [17 x i8]* @.str.971, i64 0, i64 0
  %r2282 = ptrtoint i8* %r2281 to i64
  %r2283 = call i64 @_add(i64 %r2280, i64 %r2282)
  %r2284 = load i64, i64* %ptr_NL
  %r2285 = call i64 @_add(i64 %r2283, i64 %r2284)
  store i64 %r2285, i64* %ptr_s
  %r2286 = load i64, i64* %ptr_s
  %r2287 = getelementptr [6 x i8], [6 x i8]* @.str.972, i64 0, i64 0
  %r2288 = ptrtoint i8* %r2287 to i64
  %r2289 = call i64 @_add(i64 %r2286, i64 %r2288)
  %r2290 = load i64, i64* %ptr_NL
  %r2291 = call i64 @_add(i64 %r2289, i64 %r2290)
  store i64 %r2291, i64* %ptr_s
  %r2292 = load i64, i64* %ptr_s
  %r2293 = getelementptr [70 x i8], [70 x i8]* @.str.973, i64 0, i64 0
  %r2294 = ptrtoint i8* %r2293 to i64
  %r2295 = call i64 @_add(i64 %r2292, i64 %r2294)
  %r2296 = load i64, i64* %ptr_NL
  %r2297 = call i64 @_add(i64 %r2295, i64 %r2296)
  store i64 %r2297, i64* %ptr_s
  %r2298 = load i64, i64* %ptr_s
  %r2299 = getelementptr [67 x i8], [67 x i8]* @.str.974, i64 0, i64 0
  %r2300 = ptrtoint i8* %r2299 to i64
  %r2301 = call i64 @_add(i64 %r2298, i64 %r2300)
  %r2302 = load i64, i64* %ptr_NL
  %r2303 = call i64 @_add(i64 %r2301, i64 %r2302)
  store i64 %r2303, i64* %ptr_s
  %r2304 = load i64, i64* %ptr_s
  %r2305 = getelementptr [51 x i8], [51 x i8]* @.str.975, i64 0, i64 0
  %r2306 = ptrtoint i8* %r2305 to i64
  %r2307 = call i64 @_add(i64 %r2304, i64 %r2306)
  %r2308 = load i64, i64* %ptr_NL
  %r2309 = call i64 @_add(i64 %r2307, i64 %r2308)
  store i64 %r2309, i64* %ptr_s
  %r2310 = load i64, i64* %ptr_s
  %r2311 = getelementptr [29 x i8], [29 x i8]* @.str.976, i64 0, i64 0
  %r2312 = ptrtoint i8* %r2311 to i64
  %r2313 = call i64 @_add(i64 %r2310, i64 %r2312)
  %r2314 = load i64, i64* %ptr_NL
  %r2315 = call i64 @_add(i64 %r2313, i64 %r2314)
  store i64 %r2315, i64* %ptr_s
  %r2316 = load i64, i64* %ptr_s
  %r2317 = getelementptr [12 x i8], [12 x i8]* @.str.977, i64 0, i64 0
  %r2318 = ptrtoint i8* %r2317 to i64
  %r2319 = call i64 @_add(i64 %r2316, i64 %r2318)
  %r2320 = load i64, i64* %ptr_NL
  %r2321 = call i64 @_add(i64 %r2319, i64 %r2320)
  store i64 %r2321, i64* %ptr_s
  %r2322 = load i64, i64* %ptr_s
  %r2323 = getelementptr [11 x i8], [11 x i8]* @.str.978, i64 0, i64 0
  %r2324 = ptrtoint i8* %r2323 to i64
  %r2325 = call i64 @_add(i64 %r2322, i64 %r2324)
  %r2326 = load i64, i64* %ptr_NL
  %r2327 = call i64 @_add(i64 %r2325, i64 %r2326)
  store i64 %r2327, i64* %ptr_s
  %r2328 = load i64, i64* %ptr_s
  %r2329 = getelementptr [71 x i8], [71 x i8]* @.str.979, i64 0, i64 0
  %r2330 = ptrtoint i8* %r2329 to i64
  %r2331 = call i64 @_add(i64 %r2328, i64 %r2330)
  %r2332 = load i64, i64* %ptr_NL
  %r2333 = call i64 @_add(i64 %r2331, i64 %r2332)
  store i64 %r2333, i64* %ptr_s
  %r2334 = load i64, i64* %ptr_s
  %r2335 = getelementptr [54 x i8], [54 x i8]* @.str.980, i64 0, i64 0
  %r2336 = ptrtoint i8* %r2335 to i64
  %r2337 = call i64 @_add(i64 %r2334, i64 %r2336)
  %r2338 = load i64, i64* %ptr_NL
  %r2339 = call i64 @_add(i64 %r2337, i64 %r2338)
  store i64 %r2339, i64* %ptr_s
  %r2340 = load i64, i64* %ptr_s
  %r2341 = getelementptr [29 x i8], [29 x i8]* @.str.981, i64 0, i64 0
  %r2342 = ptrtoint i8* %r2341 to i64
  %r2343 = call i64 @_add(i64 %r2340, i64 %r2342)
  %r2344 = load i64, i64* %ptr_NL
  %r2345 = call i64 @_add(i64 %r2343, i64 %r2344)
  store i64 %r2345, i64* %ptr_s
  %r2346 = load i64, i64* %ptr_s
  %r2347 = getelementptr [12 x i8], [12 x i8]* @.str.982, i64 0, i64 0
  %r2348 = ptrtoint i8* %r2347 to i64
  %r2349 = call i64 @_add(i64 %r2346, i64 %r2348)
  %r2350 = load i64, i64* %ptr_NL
  %r2351 = call i64 @_add(i64 %r2349, i64 %r2350)
  store i64 %r2351, i64* %ptr_s
  %r2352 = load i64, i64* %ptr_s
  %r2353 = getelementptr [11 x i8], [11 x i8]* @.str.983, i64 0, i64 0
  %r2354 = ptrtoint i8* %r2353 to i64
  %r2355 = call i64 @_add(i64 %r2352, i64 %r2354)
  %r2356 = load i64, i64* %ptr_NL
  %r2357 = call i64 @_add(i64 %r2355, i64 %r2356)
  store i64 %r2357, i64* %ptr_s
  %r2358 = load i64, i64* %ptr_s
  %r2359 = getelementptr [71 x i8], [71 x i8]* @.str.984, i64 0, i64 0
  %r2360 = ptrtoint i8* %r2359 to i64
  %r2361 = call i64 @_add(i64 %r2358, i64 %r2360)
  %r2362 = load i64, i64* %ptr_NL
  %r2363 = call i64 @_add(i64 %r2361, i64 %r2362)
  store i64 %r2363, i64* %ptr_s
  %r2364 = load i64, i64* %ptr_s
  %r2365 = getelementptr [36 x i8], [36 x i8]* @.str.985, i64 0, i64 0
  %r2366 = ptrtoint i8* %r2365 to i64
  %r2367 = call i64 @_add(i64 %r2364, i64 %r2366)
  %r2368 = load i64, i64* %ptr_NL
  %r2369 = call i64 @_add(i64 %r2367, i64 %r2368)
  store i64 %r2369, i64* %ptr_s
  %r2370 = load i64, i64* %ptr_s
  %r2371 = getelementptr [56 x i8], [56 x i8]* @.str.986, i64 0, i64 0
  %r2372 = ptrtoint i8* %r2371 to i64
  %r2373 = call i64 @_add(i64 %r2370, i64 %r2372)
  %r2374 = load i64, i64* %ptr_NL
  %r2375 = call i64 @_add(i64 %r2373, i64 %r2374)
  store i64 %r2375, i64* %ptr_s
  %r2376 = load i64, i64* %ptr_s
  %r2377 = getelementptr [29 x i8], [29 x i8]* @.str.987, i64 0, i64 0
  %r2378 = ptrtoint i8* %r2377 to i64
  %r2379 = call i64 @_add(i64 %r2376, i64 %r2378)
  %r2380 = load i64, i64* %ptr_NL
  %r2381 = call i64 @_add(i64 %r2379, i64 %r2380)
  store i64 %r2381, i64* %ptr_s
  %r2382 = load i64, i64* %ptr_s
  %r2383 = getelementptr [12 x i8], [12 x i8]* @.str.988, i64 0, i64 0
  %r2384 = ptrtoint i8* %r2383 to i64
  %r2385 = call i64 @_add(i64 %r2382, i64 %r2384)
  %r2386 = load i64, i64* %ptr_NL
  %r2387 = call i64 @_add(i64 %r2385, i64 %r2386)
  store i64 %r2387, i64* %ptr_s
  %r2388 = load i64, i64* %ptr_s
  %r2389 = getelementptr [2 x i8], [2 x i8]* @.str.989, i64 0, i64 0
  %r2390 = ptrtoint i8* %r2389 to i64
  %r2391 = call i64 @_add(i64 %r2388, i64 %r2390)
  %r2392 = load i64, i64* %ptr_NL
  %r2393 = call i64 @_add(i64 %r2391, i64 %r2392)
  store i64 %r2393, i64* %ptr_s
  %r2394 = load i64, i64* %ptr_s
  %r2395 = getelementptr [30 x i8], [30 x i8]* @.str.990, i64 0, i64 0
  %r2396 = ptrtoint i8* %r2395 to i64
  %r2397 = call i64 @_add(i64 %r2394, i64 %r2396)
  %r2398 = load i64, i64* %ptr_NL
  %r2399 = call i64 @_add(i64 %r2397, i64 %r2398)
  store i64 %r2399, i64* %ptr_s
  %r2400 = load i64, i64* %ptr_s
  %r2401 = getelementptr [34 x i8], [34 x i8]* @.str.991, i64 0, i64 0
  %r2402 = ptrtoint i8* %r2401 to i64
  %r2403 = call i64 @_add(i64 %r2400, i64 %r2402)
  %r2404 = load i64, i64* %ptr_NL
  %r2405 = call i64 @_add(i64 %r2403, i64 %r2404)
  store i64 %r2405, i64* %ptr_s
  %r2406 = load i64, i64* %ptr_s
  %r2407 = getelementptr [25 x i8], [25 x i8]* @.str.992, i64 0, i64 0
  %r2408 = ptrtoint i8* %r2407 to i64
  %r2409 = call i64 @_add(i64 %r2406, i64 %r2408)
  %r2410 = load i64, i64* %ptr_NL
  %r2411 = call i64 @_add(i64 %r2409, i64 %r2410)
  store i64 %r2411, i64* %ptr_s
  %r2412 = load i64, i64* %ptr_s
  %r2413 = getelementptr [27 x i8], [27 x i8]* @.str.993, i64 0, i64 0
  %r2414 = ptrtoint i8* %r2413 to i64
  %r2415 = call i64 @_add(i64 %r2412, i64 %r2414)
  %r2416 = load i64, i64* %ptr_NL
  %r2417 = call i64 @_add(i64 %r2415, i64 %r2416)
  store i64 %r2417, i64* %ptr_s
  %r2418 = load i64, i64* %ptr_s
  %r2419 = getelementptr [15 x i8], [15 x i8]* @.str.994, i64 0, i64 0
  %r2420 = ptrtoint i8* %r2419 to i64
  %r2421 = call i64 @_add(i64 %r2418, i64 %r2420)
  %r2422 = load i64, i64* %ptr_NL
  %r2423 = call i64 @_add(i64 %r2421, i64 %r2422)
  store i64 %r2423, i64* %ptr_s
  %r2424 = load i64, i64* %ptr_s
  %r2425 = getelementptr [2 x i8], [2 x i8]* @.str.995, i64 0, i64 0
  %r2426 = ptrtoint i8* %r2425 to i64
  %r2427 = call i64 @_add(i64 %r2424, i64 %r2426)
  %r2428 = load i64, i64* %ptr_NL
  %r2429 = call i64 @_add(i64 %r2427, i64 %r2428)
  store i64 %r2429, i64* %ptr_s
  %r2430 = load i64, i64* %ptr_s
  %r2431 = getelementptr [51 x i8], [51 x i8]* @.str.996, i64 0, i64 0
  %r2432 = ptrtoint i8* %r2431 to i64
  %r2433 = call i64 @_add(i64 %r2430, i64 %r2432)
  %r2434 = load i64, i64* %ptr_NL
  %r2435 = call i64 @_add(i64 %r2433, i64 %r2434)
  store i64 %r2435, i64* %ptr_s
  %r2436 = load i64, i64* %ptr_s
  %r2437 = getelementptr [34 x i8], [34 x i8]* @.str.997, i64 0, i64 0
  %r2438 = ptrtoint i8* %r2437 to i64
  %r2439 = call i64 @_add(i64 %r2436, i64 %r2438)
  %r2440 = load i64, i64* %ptr_NL
  %r2441 = call i64 @_add(i64 %r2439, i64 %r2440)
  store i64 %r2441, i64* %ptr_s
  %r2442 = load i64, i64* %ptr_s
  %r2443 = getelementptr [37 x i8], [37 x i8]* @.str.998, i64 0, i64 0
  %r2444 = ptrtoint i8* %r2443 to i64
  %r2445 = call i64 @_add(i64 %r2442, i64 %r2444)
  %r2446 = load i64, i64* %ptr_NL
  %r2447 = call i64 @_add(i64 %r2445, i64 %r2446)
  store i64 %r2447, i64* %ptr_s
  %r2448 = load i64, i64* %ptr_s
  %r2449 = getelementptr [39 x i8], [39 x i8]* @.str.999, i64 0, i64 0
  %r2450 = ptrtoint i8* %r2449 to i64
  %r2451 = call i64 @_add(i64 %r2448, i64 %r2450)
  %r2452 = load i64, i64* %ptr_NL
  %r2453 = call i64 @_add(i64 %r2451, i64 %r2452)
  store i64 %r2453, i64* %ptr_s
  %r2454 = load i64, i64* %ptr_s
  %r2455 = getelementptr [39 x i8], [39 x i8]* @.str.1000, i64 0, i64 0
  %r2456 = ptrtoint i8* %r2455 to i64
  %r2457 = call i64 @_add(i64 %r2454, i64 %r2456)
  %r2458 = load i64, i64* %ptr_NL
  %r2459 = call i64 @_add(i64 %r2457, i64 %r2458)
  store i64 %r2459, i64* %ptr_s
  %r2460 = load i64, i64* %ptr_s
  %r2461 = getelementptr [5 x i8], [5 x i8]* @.str.1001, i64 0, i64 0
  %r2462 = ptrtoint i8* %r2461 to i64
  %r2463 = call i64 @_add(i64 %r2460, i64 %r2462)
  %r2464 = load i64, i64* %ptr_NL
  %r2465 = call i64 @_add(i64 %r2463, i64 %r2464)
  store i64 %r2465, i64* %ptr_s
  %r2466 = load i64, i64* %ptr_s
  %r2467 = getelementptr [33 x i8], [33 x i8]* @.str.1002, i64 0, i64 0
  %r2468 = ptrtoint i8* %r2467 to i64
  %r2469 = call i64 @_add(i64 %r2466, i64 %r2468)
  %r2470 = load i64, i64* %ptr_NL
  %r2471 = call i64 @_add(i64 %r2469, i64 %r2470)
  store i64 %r2471, i64* %ptr_s
  %r2472 = load i64, i64* %ptr_s
  %r2473 = getelementptr [36 x i8], [36 x i8]* @.str.1003, i64 0, i64 0
  %r2474 = ptrtoint i8* %r2473 to i64
  %r2475 = call i64 @_add(i64 %r2472, i64 %r2474)
  %r2476 = load i64, i64* %ptr_NL
  %r2477 = call i64 @_add(i64 %r2475, i64 %r2476)
  store i64 %r2477, i64* %ptr_s
  %r2478 = load i64, i64* %ptr_s
  %r2479 = getelementptr [25 x i8], [25 x i8]* @.str.1004, i64 0, i64 0
  %r2480 = ptrtoint i8* %r2479 to i64
  %r2481 = call i64 @_add(i64 %r2478, i64 %r2480)
  %r2482 = load i64, i64* %ptr_NL
  %r2483 = call i64 @_add(i64 %r2481, i64 %r2482)
  store i64 %r2483, i64* %ptr_s
  %r2484 = load i64, i64* %ptr_s
  %r2485 = getelementptr [15 x i8], [15 x i8]* @.str.1005, i64 0, i64 0
  %r2486 = ptrtoint i8* %r2485 to i64
  %r2487 = call i64 @_add(i64 %r2484, i64 %r2486)
  %r2488 = load i64, i64* %ptr_NL
  %r2489 = call i64 @_add(i64 %r2487, i64 %r2488)
  store i64 %r2489, i64* %ptr_s
  %r2490 = load i64, i64* %ptr_s
  %r2491 = getelementptr [4 x i8], [4 x i8]* @.str.1006, i64 0, i64 0
  %r2492 = ptrtoint i8* %r2491 to i64
  %r2493 = call i64 @_add(i64 %r2490, i64 %r2492)
  %r2494 = load i64, i64* %ptr_NL
  %r2495 = call i64 @_add(i64 %r2493, i64 %r2494)
  store i64 %r2495, i64* %ptr_s
  %r2496 = load i64, i64* %ptr_s
  %r2497 = getelementptr [31 x i8], [31 x i8]* @.str.1007, i64 0, i64 0
  %r2498 = ptrtoint i8* %r2497 to i64
  %r2499 = call i64 @_add(i64 %r2496, i64 %r2498)
  %r2500 = load i64, i64* %ptr_NL
  %r2501 = call i64 @_add(i64 %r2499, i64 %r2500)
  store i64 %r2501, i64* %ptr_s
  %r2502 = load i64, i64* %ptr_s
  %r2503 = getelementptr [37 x i8], [37 x i8]* @.str.1008, i64 0, i64 0
  %r2504 = ptrtoint i8* %r2503 to i64
  %r2505 = call i64 @_add(i64 %r2502, i64 %r2504)
  %r2506 = load i64, i64* %ptr_NL
  %r2507 = call i64 @_add(i64 %r2505, i64 %r2506)
  store i64 %r2507, i64* %ptr_s
  %r2508 = load i64, i64* %ptr_s
  %r2509 = getelementptr [53 x i8], [53 x i8]* @.str.1009, i64 0, i64 0
  %r2510 = ptrtoint i8* %r2509 to i64
  %r2511 = call i64 @_add(i64 %r2508, i64 %r2510)
  %r2512 = load i64, i64* %ptr_NL
  %r2513 = call i64 @_add(i64 %r2511, i64 %r2512)
  store i64 %r2513, i64* %ptr_s
  %r2514 = load i64, i64* %ptr_s
  %r2515 = getelementptr [52 x i8], [52 x i8]* @.str.1010, i64 0, i64 0
  %r2516 = ptrtoint i8* %r2515 to i64
  %r2517 = call i64 @_add(i64 %r2514, i64 %r2516)
  %r2518 = load i64, i64* %ptr_NL
  %r2519 = call i64 @_add(i64 %r2517, i64 %r2518)
  store i64 %r2519, i64* %ptr_s
  %r2520 = load i64, i64* %ptr_s
  %r2521 = getelementptr [35 x i8], [35 x i8]* @.str.1011, i64 0, i64 0
  %r2522 = ptrtoint i8* %r2521 to i64
  %r2523 = call i64 @_add(i64 %r2520, i64 %r2522)
  %r2524 = load i64, i64* %ptr_NL
  %r2525 = call i64 @_add(i64 %r2523, i64 %r2524)
  store i64 %r2525, i64* %ptr_s
  %r2526 = load i64, i64* %ptr_s
  %r2527 = getelementptr [42 x i8], [42 x i8]* @.str.1012, i64 0, i64 0
  %r2528 = ptrtoint i8* %r2527 to i64
  %r2529 = call i64 @_add(i64 %r2526, i64 %r2528)
  %r2530 = load i64, i64* %ptr_NL
  %r2531 = call i64 @_add(i64 %r2529, i64 %r2530)
  store i64 %r2531, i64* %ptr_s
  %r2532 = load i64, i64* %ptr_s
  %r2533 = getelementptr [40 x i8], [40 x i8]* @.str.1013, i64 0, i64 0
  %r2534 = ptrtoint i8* %r2533 to i64
  %r2535 = call i64 @_add(i64 %r2532, i64 %r2534)
  %r2536 = load i64, i64* %ptr_NL
  %r2537 = call i64 @_add(i64 %r2535, i64 %r2536)
  store i64 %r2537, i64* %ptr_s
  %r2538 = load i64, i64* %ptr_s
  %r2539 = getelementptr [64 x i8], [64 x i8]* @.str.1014, i64 0, i64 0
  %r2540 = ptrtoint i8* %r2539 to i64
  %r2541 = call i64 @_add(i64 %r2538, i64 %r2540)
  %r2542 = load i64, i64* %ptr_NL
  %r2543 = call i64 @_add(i64 %r2541, i64 %r2542)
  store i64 %r2543, i64* %ptr_s
  %r2544 = load i64, i64* %ptr_s
  %r2545 = getelementptr [57 x i8], [57 x i8]* @.str.1015, i64 0, i64 0
  %r2546 = ptrtoint i8* %r2545 to i64
  %r2547 = call i64 @_add(i64 %r2544, i64 %r2546)
  %r2548 = load i64, i64* %ptr_NL
  %r2549 = call i64 @_add(i64 %r2547, i64 %r2548)
  store i64 %r2549, i64* %ptr_s
  %r2550 = load i64, i64* %ptr_s
  %r2551 = getelementptr [24 x i8], [24 x i8]* @.str.1016, i64 0, i64 0
  %r2552 = ptrtoint i8* %r2551 to i64
  %r2553 = call i64 @_add(i64 %r2550, i64 %r2552)
  %r2554 = load i64, i64* %ptr_NL
  %r2555 = call i64 @_add(i64 %r2553, i64 %r2554)
  store i64 %r2555, i64* %ptr_s
  %r2556 = load i64, i64* %ptr_s
  %r2557 = getelementptr [16 x i8], [16 x i8]* @.str.1017, i64 0, i64 0
  %r2558 = ptrtoint i8* %r2557 to i64
  %r2559 = call i64 @_add(i64 %r2556, i64 %r2558)
  %r2560 = load i64, i64* %ptr_NL
  %r2561 = call i64 @_add(i64 %r2559, i64 %r2560)
  store i64 %r2561, i64* %ptr_s
  %r2562 = load i64, i64* %ptr_s
  %r2563 = getelementptr [2 x i8], [2 x i8]* @.str.1018, i64 0, i64 0
  %r2564 = ptrtoint i8* %r2563 to i64
  %r2565 = call i64 @_add(i64 %r2562, i64 %r2564)
  %r2566 = load i64, i64* %ptr_NL
  %r2567 = call i64 @_add(i64 %r2565, i64 %r2566)
  store i64 %r2567, i64* %ptr_s
  %r2568 = load i64, i64* %ptr_s
  %r2569 = getelementptr [34 x i8], [34 x i8]* @.str.1019, i64 0, i64 0
  %r2570 = ptrtoint i8* %r2569 to i64
  %r2571 = call i64 @_add(i64 %r2568, i64 %r2570)
  %r2572 = load i64, i64* %ptr_NL
  %r2573 = call i64 @_add(i64 %r2571, i64 %r2572)
  store i64 %r2573, i64* %ptr_s
  %r2574 = load i64, i64* %ptr_s
  %r2575 = getelementptr [33 x i8], [33 x i8]* @.str.1020, i64 0, i64 0
  %r2576 = ptrtoint i8* %r2575 to i64
  %r2577 = call i64 @_add(i64 %r2574, i64 %r2576)
  %r2578 = load i64, i64* %ptr_NL
  %r2579 = call i64 @_add(i64 %r2577, i64 %r2578)
  store i64 %r2579, i64* %ptr_s
  %r2580 = load i64, i64* %ptr_s
  %r2581 = getelementptr [34 x i8], [34 x i8]* @.str.1021, i64 0, i64 0
  %r2582 = ptrtoint i8* %r2581 to i64
  %r2583 = call i64 @_add(i64 %r2580, i64 %r2582)
  %r2584 = load i64, i64* %ptr_NL
  %r2585 = call i64 @_add(i64 %r2583, i64 %r2584)
  store i64 %r2585, i64* %ptr_s
  %r2586 = load i64, i64* %ptr_s
  %r2587 = getelementptr [28 x i8], [28 x i8]* @.str.1022, i64 0, i64 0
  %r2588 = ptrtoint i8* %r2587 to i64
  %r2589 = call i64 @_add(i64 %r2586, i64 %r2588)
  %r2590 = load i64, i64* %ptr_NL
  %r2591 = call i64 @_add(i64 %r2589, i64 %r2590)
  store i64 %r2591, i64* %ptr_s
  %r2592 = load i64, i64* %ptr_s
  %r2593 = getelementptr [24 x i8], [24 x i8]* @.str.1023, i64 0, i64 0
  %r2594 = ptrtoint i8* %r2593 to i64
  %r2595 = call i64 @_add(i64 %r2592, i64 %r2594)
  %r2596 = load i64, i64* %ptr_NL
  %r2597 = call i64 @_add(i64 %r2595, i64 %r2596)
  store i64 %r2597, i64* %ptr_s
  %r2598 = load i64, i64* %ptr_s
  %r2599 = getelementptr [44 x i8], [44 x i8]* @.str.1024, i64 0, i64 0
  %r2600 = ptrtoint i8* %r2599 to i64
  %r2601 = call i64 @_add(i64 %r2598, i64 %r2600)
  %r2602 = load i64, i64* %ptr_NL
  %r2603 = call i64 @_add(i64 %r2601, i64 %r2602)
  store i64 %r2603, i64* %ptr_s
  %r2604 = load i64, i64* %ptr_s
  %r2605 = getelementptr [24 x i8], [24 x i8]* @.str.1025, i64 0, i64 0
  %r2606 = ptrtoint i8* %r2605 to i64
  %r2607 = call i64 @_add(i64 %r2604, i64 %r2606)
  %r2608 = load i64, i64* %ptr_NL
  %r2609 = call i64 @_add(i64 %r2607, i64 %r2608)
  store i64 %r2609, i64* %ptr_s
  %r2610 = load i64, i64* %ptr_s
  %r2611 = getelementptr [15 x i8], [15 x i8]* @.str.1026, i64 0, i64 0
  %r2612 = ptrtoint i8* %r2611 to i64
  %r2613 = call i64 @_add(i64 %r2610, i64 %r2612)
  %r2614 = load i64, i64* %ptr_NL
  %r2615 = call i64 @_add(i64 %r2613, i64 %r2614)
  store i64 %r2615, i64* %ptr_s
  %r2616 = load i64, i64* %ptr_s
  %r2617 = getelementptr [2 x i8], [2 x i8]* @.str.1027, i64 0, i64 0
  %r2618 = ptrtoint i8* %r2617 to i64
  %r2619 = call i64 @_add(i64 %r2616, i64 %r2618)
  %r2620 = load i64, i64* %ptr_NL
  %r2621 = call i64 @_add(i64 %r2619, i64 %r2620)
  store i64 %r2621, i64* %ptr_s
  %r2622 = load i64, i64* %ptr_s
  %r2623 = getelementptr [32 x i8], [32 x i8]* @.str.1028, i64 0, i64 0
  %r2624 = ptrtoint i8* %r2623 to i64
  %r2625 = call i64 @_add(i64 %r2622, i64 %r2624)
  %r2626 = load i64, i64* %ptr_NL
  %r2627 = call i64 @_add(i64 %r2625, i64 %r2626)
  store i64 %r2627, i64* %ptr_s
  %r2628 = load i64, i64* %ptr_s
  %r2629 = getelementptr [33 x i8], [33 x i8]* @.str.1029, i64 0, i64 0
  %r2630 = ptrtoint i8* %r2629 to i64
  %r2631 = call i64 @_add(i64 %r2628, i64 %r2630)
  %r2632 = load i64, i64* %ptr_NL
  %r2633 = call i64 @_add(i64 %r2631, i64 %r2632)
  store i64 %r2633, i64* %ptr_s
  %r2634 = load i64, i64* %ptr_s
  %r2635 = getelementptr [47 x i8], [47 x i8]* @.str.1030, i64 0, i64 0
  %r2636 = ptrtoint i8* %r2635 to i64
  %r2637 = call i64 @_add(i64 %r2634, i64 %r2636)
  %r2638 = load i64, i64* %ptr_NL
  %r2639 = call i64 @_add(i64 %r2637, i64 %r2638)
  store i64 %r2639, i64* %ptr_s
  %r2640 = load i64, i64* %ptr_s
  %r2641 = getelementptr [10 x i8], [10 x i8]* @.str.1031, i64 0, i64 0
  %r2642 = ptrtoint i8* %r2641 to i64
  %r2643 = call i64 @_add(i64 %r2640, i64 %r2642)
  %r2644 = load i64, i64* %ptr_NL
  %r2645 = call i64 @_add(i64 %r2643, i64 %r2644)
  store i64 %r2645, i64* %ptr_s
  %r2646 = load i64, i64* %ptr_s
  %r2647 = getelementptr [12 x i8], [12 x i8]* @.str.1032, i64 0, i64 0
  %r2648 = ptrtoint i8* %r2647 to i64
  %r2649 = call i64 @_add(i64 %r2646, i64 %r2648)
  %r2650 = load i64, i64* %ptr_NL
  %r2651 = call i64 @_add(i64 %r2649, i64 %r2650)
  store i64 %r2651, i64* %ptr_s
  %r2652 = load i64, i64* %ptr_s
  %r2653 = getelementptr [6 x i8], [6 x i8]* @.str.1033, i64 0, i64 0
  %r2654 = ptrtoint i8* %r2653 to i64
  %r2655 = call i64 @_add(i64 %r2652, i64 %r2654)
  %r2656 = load i64, i64* %ptr_NL
  %r2657 = call i64 @_add(i64 %r2655, i64 %r2656)
  store i64 %r2657, i64* %ptr_s
  %r2658 = load i64, i64* %ptr_s
  %r2659 = getelementptr [35 x i8], [35 x i8]* @.str.1034, i64 0, i64 0
  %r2660 = ptrtoint i8* %r2659 to i64
  %r2661 = call i64 @_add(i64 %r2658, i64 %r2660)
  %r2662 = load i64, i64* %ptr_NL
  %r2663 = call i64 @_add(i64 %r2661, i64 %r2662)
  store i64 %r2663, i64* %ptr_s
  %r2664 = load i64, i64* %ptr_s
  %r2665 = getelementptr [29 x i8], [29 x i8]* @.str.1035, i64 0, i64 0
  %r2666 = ptrtoint i8* %r2665 to i64
  %r2667 = call i64 @_add(i64 %r2664, i64 %r2666)
  %r2668 = load i64, i64* %ptr_NL
  %r2669 = call i64 @_add(i64 %r2667, i64 %r2668)
  store i64 %r2669, i64* %ptr_s
  %r2670 = load i64, i64* %ptr_s
  %r2671 = getelementptr [33 x i8], [33 x i8]* @.str.1036, i64 0, i64 0
  %r2672 = ptrtoint i8* %r2671 to i64
  %r2673 = call i64 @_add(i64 %r2670, i64 %r2672)
  %r2674 = load i64, i64* %ptr_NL
  %r2675 = call i64 @_add(i64 %r2673, i64 %r2674)
  store i64 %r2675, i64* %ptr_s
  %r2676 = load i64, i64* %ptr_s
  %r2677 = getelementptr [32 x i8], [32 x i8]* @.str.1037, i64 0, i64 0
  %r2678 = ptrtoint i8* %r2677 to i64
  %r2679 = call i64 @_add(i64 %r2676, i64 %r2678)
  %r2680 = load i64, i64* %ptr_NL
  %r2681 = call i64 @_add(i64 %r2679, i64 %r2680)
  store i64 %r2681, i64* %ptr_s
  %r2682 = load i64, i64* %ptr_s
  %r2683 = getelementptr [36 x i8], [36 x i8]* @.str.1038, i64 0, i64 0
  %r2684 = ptrtoint i8* %r2683 to i64
  %r2685 = call i64 @_add(i64 %r2682, i64 %r2684)
  %r2686 = load i64, i64* %ptr_NL
  %r2687 = call i64 @_add(i64 %r2685, i64 %r2686)
  store i64 %r2687, i64* %ptr_s
  %r2688 = load i64, i64* %ptr_s
  %r2689 = getelementptr [48 x i8], [48 x i8]* @.str.1039, i64 0, i64 0
  %r2690 = ptrtoint i8* %r2689 to i64
  %r2691 = call i64 @_add(i64 %r2688, i64 %r2690)
  %r2692 = load i64, i64* %ptr_NL
  %r2693 = call i64 @_add(i64 %r2691, i64 %r2692)
  store i64 %r2693, i64* %ptr_s
  %r2694 = load i64, i64* %ptr_s
  %r2695 = getelementptr [9 x i8], [9 x i8]* @.str.1040, i64 0, i64 0
  %r2696 = ptrtoint i8* %r2695 to i64
  %r2697 = call i64 @_add(i64 %r2694, i64 %r2696)
  %r2698 = load i64, i64* %ptr_NL
  %r2699 = call i64 @_add(i64 %r2697, i64 %r2698)
  store i64 %r2699, i64* %ptr_s
  %r2700 = load i64, i64* %ptr_s
  %r2701 = getelementptr [37 x i8], [37 x i8]* @.str.1041, i64 0, i64 0
  %r2702 = ptrtoint i8* %r2701 to i64
  %r2703 = call i64 @_add(i64 %r2700, i64 %r2702)
  %r2704 = load i64, i64* %ptr_NL
  %r2705 = call i64 @_add(i64 %r2703, i64 %r2704)
  store i64 %r2705, i64* %ptr_s
  %r2706 = load i64, i64* %ptr_s
  %r2707 = getelementptr [51 x i8], [51 x i8]* @.str.1042, i64 0, i64 0
  %r2708 = ptrtoint i8* %r2707 to i64
  %r2709 = call i64 @_add(i64 %r2706, i64 %r2708)
  %r2710 = load i64, i64* %ptr_NL
  %r2711 = call i64 @_add(i64 %r2709, i64 %r2710)
  store i64 %r2711, i64* %ptr_s
  %r2712 = load i64, i64* %ptr_s
  %r2713 = getelementptr [33 x i8], [33 x i8]* @.str.1043, i64 0, i64 0
  %r2714 = ptrtoint i8* %r2713 to i64
  %r2715 = call i64 @_add(i64 %r2712, i64 %r2714)
  %r2716 = load i64, i64* %ptr_NL
  %r2717 = call i64 @_add(i64 %r2715, i64 %r2716)
  store i64 %r2717, i64* %ptr_s
  %r2718 = load i64, i64* %ptr_s
  %r2719 = getelementptr [15 x i8], [15 x i8]* @.str.1044, i64 0, i64 0
  %r2720 = ptrtoint i8* %r2719 to i64
  %r2721 = call i64 @_add(i64 %r2718, i64 %r2720)
  %r2722 = load i64, i64* %ptr_NL
  %r2723 = call i64 @_add(i64 %r2721, i64 %r2722)
  store i64 %r2723, i64* %ptr_s
  %r2724 = load i64, i64* %ptr_s
  %r2725 = getelementptr [9 x i8], [9 x i8]* @.str.1045, i64 0, i64 0
  %r2726 = ptrtoint i8* %r2725 to i64
  %r2727 = call i64 @_add(i64 %r2724, i64 %r2726)
  %r2728 = load i64, i64* %ptr_NL
  %r2729 = call i64 @_add(i64 %r2727, i64 %r2728)
  store i64 %r2729, i64* %ptr_s
  %r2730 = load i64, i64* %ptr_s
  %r2731 = getelementptr [38 x i8], [38 x i8]* @.str.1046, i64 0, i64 0
  %r2732 = ptrtoint i8* %r2731 to i64
  %r2733 = call i64 @_add(i64 %r2730, i64 %r2732)
  %r2734 = load i64, i64* %ptr_NL
  %r2735 = call i64 @_add(i64 %r2733, i64 %r2734)
  store i64 %r2735, i64* %ptr_s
  %r2736 = load i64, i64* %ptr_s
  %r2737 = getelementptr [40 x i8], [40 x i8]* @.str.1047, i64 0, i64 0
  %r2738 = ptrtoint i8* %r2737 to i64
  %r2739 = call i64 @_add(i64 %r2736, i64 %r2738)
  %r2740 = load i64, i64* %ptr_NL
  %r2741 = call i64 @_add(i64 %r2739, i64 %r2740)
  store i64 %r2741, i64* %ptr_s
  %r2742 = load i64, i64* %ptr_s
  %r2743 = getelementptr [15 x i8], [15 x i8]* @.str.1048, i64 0, i64 0
  %r2744 = ptrtoint i8* %r2743 to i64
  %r2745 = call i64 @_add(i64 %r2742, i64 %r2744)
  %r2746 = load i64, i64* %ptr_NL
  %r2747 = call i64 @_add(i64 %r2745, i64 %r2746)
  store i64 %r2747, i64* %ptr_s
  %r2748 = load i64, i64* %ptr_s
  %r2749 = getelementptr [2 x i8], [2 x i8]* @.str.1049, i64 0, i64 0
  %r2750 = ptrtoint i8* %r2749 to i64
  %r2751 = call i64 @_add(i64 %r2748, i64 %r2750)
  %r2752 = load i64, i64* %ptr_NL
  %r2753 = call i64 @_add(i64 %r2751, i64 %r2752)
  store i64 %r2753, i64* %ptr_s
  %r2754 = load i64, i64* %ptr_s
  %r2755 = getelementptr [22 x i8], [22 x i8]* @.str.1050, i64 0, i64 0
  %r2756 = ptrtoint i8* %r2755 to i64
  %r2757 = call i64 @_add(i64 %r2754, i64 %r2756)
  %r2758 = load i64, i64* %ptr_NL
  %r2759 = call i64 @_add(i64 %r2757, i64 %r2758)
  store i64 %r2759, i64* %ptr_s
  %r2760 = load i64, i64* %ptr_s
  %r2761 = getelementptr [35 x i8], [35 x i8]* @.str.1051, i64 0, i64 0
  %r2762 = ptrtoint i8* %r2761 to i64
  %r2763 = call i64 @_add(i64 %r2760, i64 %r2762)
  %r2764 = load i64, i64* %ptr_NL
  %r2765 = call i64 @_add(i64 %r2763, i64 %r2764)
  store i64 %r2765, i64* %ptr_s
  %r2766 = load i64, i64* %ptr_s
  %r2767 = getelementptr [34 x i8], [34 x i8]* @.str.1052, i64 0, i64 0
  %r2768 = ptrtoint i8* %r2767 to i64
  %r2769 = call i64 @_add(i64 %r2766, i64 %r2768)
  %r2770 = load i64, i64* %ptr_NL
  %r2771 = call i64 @_add(i64 %r2769, i64 %r2770)
  store i64 %r2771, i64* %ptr_s
  %r2772 = load i64, i64* %ptr_s
  %r2773 = getelementptr [17 x i8], [17 x i8]* @.str.1053, i64 0, i64 0
  %r2774 = ptrtoint i8* %r2773 to i64
  %r2775 = call i64 @_add(i64 %r2772, i64 %r2774)
  %r2776 = load i64, i64* %ptr_NL
  %r2777 = call i64 @_add(i64 %r2775, i64 %r2776)
  store i64 %r2777, i64* %ptr_s
  %r2778 = load i64, i64* %ptr_s
  %r2779 = getelementptr [6 x i8], [6 x i8]* @.str.1054, i64 0, i64 0
  %r2780 = ptrtoint i8* %r2779 to i64
  %r2781 = call i64 @_add(i64 %r2778, i64 %r2780)
  %r2782 = load i64, i64* %ptr_NL
  %r2783 = call i64 @_add(i64 %r2781, i64 %r2782)
  store i64 %r2783, i64* %ptr_s
  %r2784 = load i64, i64* %ptr_s
  %r2785 = getelementptr [45 x i8], [45 x i8]* @.str.1055, i64 0, i64 0
  %r2786 = ptrtoint i8* %r2785 to i64
  %r2787 = call i64 @_add(i64 %r2784, i64 %r2786)
  %r2788 = load i64, i64* %ptr_NL
  %r2789 = call i64 @_add(i64 %r2787, i64 %r2788)
  store i64 %r2789, i64* %ptr_s
  %r2790 = load i64, i64* %ptr_s
  %r2791 = getelementptr [27 x i8], [27 x i8]* @.str.1056, i64 0, i64 0
  %r2792 = ptrtoint i8* %r2791 to i64
  %r2793 = call i64 @_add(i64 %r2790, i64 %r2792)
  %r2794 = load i64, i64* %ptr_NL
  %r2795 = call i64 @_add(i64 %r2793, i64 %r2794)
  store i64 %r2795, i64* %ptr_s
  %r2796 = load i64, i64* %ptr_s
  %r2797 = getelementptr [31 x i8], [31 x i8]* @.str.1057, i64 0, i64 0
  %r2798 = ptrtoint i8* %r2797 to i64
  %r2799 = call i64 @_add(i64 %r2796, i64 %r2798)
  %r2800 = load i64, i64* %ptr_NL
  %r2801 = call i64 @_add(i64 %r2799, i64 %r2800)
  store i64 %r2801, i64* %ptr_s
  %r2802 = load i64, i64* %ptr_s
  %r2803 = getelementptr [30 x i8], [30 x i8]* @.str.1058, i64 0, i64 0
  %r2804 = ptrtoint i8* %r2803 to i64
  %r2805 = call i64 @_add(i64 %r2802, i64 %r2804)
  %r2806 = load i64, i64* %ptr_NL
  %r2807 = call i64 @_add(i64 %r2805, i64 %r2806)
  store i64 %r2807, i64* %ptr_s
  %r2808 = load i64, i64* %ptr_s
  %r2809 = getelementptr [32 x i8], [32 x i8]* @.str.1059, i64 0, i64 0
  %r2810 = ptrtoint i8* %r2809 to i64
  %r2811 = call i64 @_add(i64 %r2808, i64 %r2810)
  %r2812 = load i64, i64* %ptr_NL
  %r2813 = call i64 @_add(i64 %r2811, i64 %r2812)
  store i64 %r2813, i64* %ptr_s
  %r2814 = load i64, i64* %ptr_s
  %r2815 = getelementptr [40 x i8], [40 x i8]* @.str.1060, i64 0, i64 0
  %r2816 = ptrtoint i8* %r2815 to i64
  %r2817 = call i64 @_add(i64 %r2814, i64 %r2816)
  %r2818 = load i64, i64* %ptr_NL
  %r2819 = call i64 @_add(i64 %r2817, i64 %r2818)
  store i64 %r2819, i64* %ptr_s
  %r2820 = load i64, i64* %ptr_s
  %r2821 = getelementptr [6 x i8], [6 x i8]* @.str.1061, i64 0, i64 0
  %r2822 = ptrtoint i8* %r2821 to i64
  %r2823 = call i64 @_add(i64 %r2820, i64 %r2822)
  %r2824 = load i64, i64* %ptr_NL
  %r2825 = call i64 @_add(i64 %r2823, i64 %r2824)
  store i64 %r2825, i64* %ptr_s
  %r2826 = load i64, i64* %ptr_s
  %r2827 = getelementptr [29 x i8], [29 x i8]* @.str.1062, i64 0, i64 0
  %r2828 = ptrtoint i8* %r2827 to i64
  %r2829 = call i64 @_add(i64 %r2826, i64 %r2828)
  %r2830 = load i64, i64* %ptr_NL
  %r2831 = call i64 @_add(i64 %r2829, i64 %r2830)
  store i64 %r2831, i64* %ptr_s
  %r2832 = load i64, i64* %ptr_s
  %r2833 = getelementptr [45 x i8], [45 x i8]* @.str.1063, i64 0, i64 0
  %r2834 = ptrtoint i8* %r2833 to i64
  %r2835 = call i64 @_add(i64 %r2832, i64 %r2834)
  %r2836 = load i64, i64* %ptr_NL
  %r2837 = call i64 @_add(i64 %r2835, i64 %r2836)
  store i64 %r2837, i64* %ptr_s
  %r2838 = load i64, i64* %ptr_s
  %r2839 = getelementptr [28 x i8], [28 x i8]* @.str.1064, i64 0, i64 0
  %r2840 = ptrtoint i8* %r2839 to i64
  %r2841 = call i64 @_add(i64 %r2838, i64 %r2840)
  %r2842 = load i64, i64* %ptr_NL
  %r2843 = call i64 @_add(i64 %r2841, i64 %r2842)
  store i64 %r2843, i64* %ptr_s
  %r2844 = load i64, i64* %ptr_s
  %r2845 = getelementptr [26 x i8], [26 x i8]* @.str.1065, i64 0, i64 0
  %r2846 = ptrtoint i8* %r2845 to i64
  %r2847 = call i64 @_add(i64 %r2844, i64 %r2846)
  %r2848 = load i64, i64* %ptr_NL
  %r2849 = call i64 @_add(i64 %r2847, i64 %r2848)
  store i64 %r2849, i64* %ptr_s
  %r2850 = load i64, i64* %ptr_s
  %r2851 = getelementptr [37 x i8], [37 x i8]* @.str.1066, i64 0, i64 0
  %r2852 = ptrtoint i8* %r2851 to i64
  %r2853 = call i64 @_add(i64 %r2850, i64 %r2852)
  %r2854 = load i64, i64* %ptr_NL
  %r2855 = call i64 @_add(i64 %r2853, i64 %r2854)
  store i64 %r2855, i64* %ptr_s
  %r2856 = load i64, i64* %ptr_s
  %r2857 = getelementptr [41 x i8], [41 x i8]* @.str.1067, i64 0, i64 0
  %r2858 = ptrtoint i8* %r2857 to i64
  %r2859 = call i64 @_add(i64 %r2856, i64 %r2858)
  %r2860 = load i64, i64* %ptr_NL
  %r2861 = call i64 @_add(i64 %r2859, i64 %r2860)
  store i64 %r2861, i64* %ptr_s
  %r2862 = load i64, i64* %ptr_s
  %r2863 = getelementptr [6 x i8], [6 x i8]* @.str.1068, i64 0, i64 0
  %r2864 = ptrtoint i8* %r2863 to i64
  %r2865 = call i64 @_add(i64 %r2862, i64 %r2864)
  %r2866 = load i64, i64* %ptr_NL
  %r2867 = call i64 @_add(i64 %r2865, i64 %r2866)
  store i64 %r2867, i64* %ptr_s
  %r2868 = load i64, i64* %ptr_s
  %r2869 = getelementptr [50 x i8], [50 x i8]* @.str.1069, i64 0, i64 0
  %r2870 = ptrtoint i8* %r2869 to i64
  %r2871 = call i64 @_add(i64 %r2868, i64 %r2870)
  %r2872 = load i64, i64* %ptr_NL
  %r2873 = call i64 @_add(i64 %r2871, i64 %r2872)
  store i64 %r2873, i64* %ptr_s
  %r2874 = load i64, i64* %ptr_s
  %r2875 = getelementptr [29 x i8], [29 x i8]* @.str.1070, i64 0, i64 0
  %r2876 = ptrtoint i8* %r2875 to i64
  %r2877 = call i64 @_add(i64 %r2874, i64 %r2876)
  %r2878 = load i64, i64* %ptr_NL
  %r2879 = call i64 @_add(i64 %r2877, i64 %r2878)
  store i64 %r2879, i64* %ptr_s
  %r2880 = load i64, i64* %ptr_s
  %r2881 = getelementptr [15 x i8], [15 x i8]* @.str.1071, i64 0, i64 0
  %r2882 = ptrtoint i8* %r2881 to i64
  %r2883 = call i64 @_add(i64 %r2880, i64 %r2882)
  %r2884 = load i64, i64* %ptr_NL
  %r2885 = call i64 @_add(i64 %r2883, i64 %r2884)
  store i64 %r2885, i64* %ptr_s
  %r2886 = load i64, i64* %ptr_s
  %r2887 = getelementptr [2 x i8], [2 x i8]* @.str.1072, i64 0, i64 0
  %r2888 = ptrtoint i8* %r2887 to i64
  %r2889 = call i64 @_add(i64 %r2886, i64 %r2888)
  %r2890 = load i64, i64* %ptr_NL
  %r2891 = call i64 @_add(i64 %r2889, i64 %r2890)
  store i64 %r2891, i64* %ptr_s
  %r2892 = load i64, i64* %ptr_s
  %r2893 = getelementptr [33 x i8], [33 x i8]* @.str.1073, i64 0, i64 0
  %r2894 = ptrtoint i8* %r2893 to i64
  %r2895 = call i64 @_add(i64 %r2892, i64 %r2894)
  %r2896 = load i64, i64* %ptr_NL
  %r2897 = call i64 @_add(i64 %r2895, i64 %r2896)
  store i64 %r2897, i64* %ptr_s
  %r2898 = load i64, i64* %ptr_s
  %r2899 = getelementptr [32 x i8], [32 x i8]* @.str.1074, i64 0, i64 0
  %r2900 = ptrtoint i8* %r2899 to i64
  %r2901 = call i64 @_add(i64 %r2898, i64 %r2900)
  %r2902 = load i64, i64* %ptr_NL
  %r2903 = call i64 @_add(i64 %r2901, i64 %r2902)
  store i64 %r2903, i64* %ptr_s
  %r2904 = load i64, i64* %ptr_s
  %r2905 = getelementptr [34 x i8], [34 x i8]* @.str.1075, i64 0, i64 0
  %r2906 = ptrtoint i8* %r2905 to i64
  %r2907 = call i64 @_add(i64 %r2904, i64 %r2906)
  %r2908 = load i64, i64* %ptr_NL
  %r2909 = call i64 @_add(i64 %r2907, i64 %r2908)
  store i64 %r2909, i64* %ptr_s
  %r2910 = load i64, i64* %ptr_s
  %r2911 = getelementptr [30 x i8], [30 x i8]* @.str.1076, i64 0, i64 0
  %r2912 = ptrtoint i8* %r2911 to i64
  %r2913 = call i64 @_add(i64 %r2910, i64 %r2912)
  %r2914 = load i64, i64* %ptr_NL
  %r2915 = call i64 @_add(i64 %r2913, i64 %r2914)
  store i64 %r2915, i64* %ptr_s
  %r2916 = load i64, i64* %ptr_s
  %r2917 = getelementptr [15 x i8], [15 x i8]* @.str.1077, i64 0, i64 0
  %r2918 = ptrtoint i8* %r2917 to i64
  %r2919 = call i64 @_add(i64 %r2916, i64 %r2918)
  %r2920 = load i64, i64* %ptr_NL
  %r2921 = call i64 @_add(i64 %r2919, i64 %r2920)
  store i64 %r2921, i64* %ptr_s
  %r2922 = load i64, i64* %ptr_s
  %r2923 = getelementptr [2 x i8], [2 x i8]* @.str.1078, i64 0, i64 0
  %r2924 = ptrtoint i8* %r2923 to i64
  %r2925 = call i64 @_add(i64 %r2922, i64 %r2924)
  %r2926 = load i64, i64* %ptr_NL
  %r2927 = call i64 @_add(i64 %r2925, i64 %r2926)
  store i64 %r2927, i64* %ptr_s
  %r2928 = load i64, i64* %ptr_s
  %r2929 = getelementptr [31 x i8], [31 x i8]* @.str.1079, i64 0, i64 0
  %r2930 = ptrtoint i8* %r2929 to i64
  %r2931 = call i64 @_add(i64 %r2928, i64 %r2930)
  %r2932 = load i64, i64* %ptr_NL
  %r2933 = call i64 @_add(i64 %r2931, i64 %r2932)
  store i64 %r2933, i64* %ptr_s
  %r2934 = load i64, i64* %ptr_s
  %r2935 = getelementptr [26 x i8], [26 x i8]* @.str.1080, i64 0, i64 0
  %r2936 = ptrtoint i8* %r2935 to i64
  %r2937 = call i64 @_add(i64 %r2934, i64 %r2936)
  %r2938 = load i64, i64* %ptr_NL
  %r2939 = call i64 @_add(i64 %r2937, i64 %r2938)
  store i64 %r2939, i64* %ptr_s
  %r2940 = load i64, i64* %ptr_s
  %r2941 = getelementptr [31 x i8], [31 x i8]* @.str.1081, i64 0, i64 0
  %r2942 = ptrtoint i8* %r2941 to i64
  %r2943 = call i64 @_add(i64 %r2940, i64 %r2942)
  %r2944 = load i64, i64* %ptr_NL
  %r2945 = call i64 @_add(i64 %r2943, i64 %r2944)
  store i64 %r2945, i64* %ptr_s
  %r2946 = load i64, i64* %ptr_s
  %r2947 = getelementptr [30 x i8], [30 x i8]* @.str.1082, i64 0, i64 0
  %r2948 = ptrtoint i8* %r2947 to i64
  %r2949 = call i64 @_add(i64 %r2946, i64 %r2948)
  %r2950 = load i64, i64* %ptr_NL
  %r2951 = call i64 @_add(i64 %r2949, i64 %r2950)
  store i64 %r2951, i64* %ptr_s
  %r2952 = load i64, i64* %ptr_s
  %r2953 = getelementptr [12 x i8], [12 x i8]* @.str.1083, i64 0, i64 0
  %r2954 = ptrtoint i8* %r2953 to i64
  %r2955 = call i64 @_add(i64 %r2952, i64 %r2954)
  %r2956 = load i64, i64* %ptr_NL
  %r2957 = call i64 @_add(i64 %r2955, i64 %r2956)
  store i64 %r2957, i64* %ptr_s
  %r2958 = load i64, i64* %ptr_s
  %r2959 = getelementptr [2 x i8], [2 x i8]* @.str.1084, i64 0, i64 0
  %r2960 = ptrtoint i8* %r2959 to i64
  %r2961 = call i64 @_add(i64 %r2958, i64 %r2960)
  %r2962 = load i64, i64* %ptr_NL
  %r2963 = call i64 @_add(i64 %r2961, i64 %r2962)
  store i64 %r2963, i64* %ptr_s
  %r2964 = load i64, i64* %ptr_s
  %r2965 = getelementptr [32 x i8], [32 x i8]* @.str.1085, i64 0, i64 0
  %r2966 = ptrtoint i8* %r2965 to i64
  %r2967 = call i64 @_add(i64 %r2964, i64 %r2966)
  %r2968 = load i64, i64* %ptr_NL
  %r2969 = call i64 @_add(i64 %r2967, i64 %r2968)
  store i64 %r2969, i64* %ptr_s
  %r2970 = load i64, i64* %ptr_s
  %r2971 = getelementptr [32 x i8], [32 x i8]* @.str.1086, i64 0, i64 0
  %r2972 = ptrtoint i8* %r2971 to i64
  %r2973 = call i64 @_add(i64 %r2970, i64 %r2972)
  %r2974 = load i64, i64* %ptr_NL
  %r2975 = call i64 @_add(i64 %r2973, i64 %r2974)
  store i64 %r2975, i64* %ptr_s
  %r2976 = load i64, i64* %ptr_s
  %r2977 = getelementptr [32 x i8], [32 x i8]* @.str.1087, i64 0, i64 0
  %r2978 = ptrtoint i8* %r2977 to i64
  %r2979 = call i64 @_add(i64 %r2976, i64 %r2978)
  %r2980 = load i64, i64* %ptr_NL
  %r2981 = call i64 @_add(i64 %r2979, i64 %r2980)
  store i64 %r2981, i64* %ptr_s
  %r2982 = load i64, i64* %ptr_s
  %r2983 = getelementptr [15 x i8], [15 x i8]* @.str.1088, i64 0, i64 0
  %r2984 = ptrtoint i8* %r2983 to i64
  %r2985 = call i64 @_add(i64 %r2982, i64 %r2984)
  %r2986 = load i64, i64* %ptr_NL
  %r2987 = call i64 @_add(i64 %r2985, i64 %r2986)
  store i64 %r2987, i64* %ptr_s
  %r2988 = load i64, i64* %ptr_s
  %r2989 = getelementptr [2 x i8], [2 x i8]* @.str.1089, i64 0, i64 0
  %r2990 = ptrtoint i8* %r2989 to i64
  %r2991 = call i64 @_add(i64 %r2988, i64 %r2990)
  %r2992 = load i64, i64* %ptr_NL
  %r2993 = call i64 @_add(i64 %r2991, i64 %r2992)
  store i64 %r2993, i64* %ptr_s
  %r2994 = load i64, i64* %ptr_s
  %r2995 = getelementptr [45 x i8], [45 x i8]* @.str.1090, i64 0, i64 0
  %r2996 = ptrtoint i8* %r2995 to i64
  %r2997 = call i64 @_add(i64 %r2994, i64 %r2996)
  %r2998 = load i64, i64* %ptr_NL
  %r2999 = call i64 @_add(i64 %r2997, i64 %r2998)
  store i64 %r2999, i64* %ptr_s
  %r3000 = load i64, i64* %ptr_s
  %r3001 = getelementptr [32 x i8], [32 x i8]* @.str.1091, i64 0, i64 0
  %r3002 = ptrtoint i8* %r3001 to i64
  %r3003 = call i64 @_add(i64 %r3000, i64 %r3002)
  %r3004 = load i64, i64* %ptr_NL
  %r3005 = call i64 @_add(i64 %r3003, i64 %r3004)
  store i64 %r3005, i64* %ptr_s
  %r3006 = load i64, i64* %ptr_s
  %r3007 = getelementptr [34 x i8], [34 x i8]* @.str.1092, i64 0, i64 0
  %r3008 = ptrtoint i8* %r3007 to i64
  %r3009 = call i64 @_add(i64 %r3006, i64 %r3008)
  %r3010 = load i64, i64* %ptr_NL
  %r3011 = call i64 @_add(i64 %r3009, i64 %r3010)
  store i64 %r3011, i64* %ptr_s
  %r3012 = load i64, i64* %ptr_s
  %r3013 = getelementptr [36 x i8], [36 x i8]* @.str.1093, i64 0, i64 0
  %r3014 = ptrtoint i8* %r3013 to i64
  %r3015 = call i64 @_add(i64 %r3012, i64 %r3014)
  %r3016 = load i64, i64* %ptr_NL
  %r3017 = call i64 @_add(i64 %r3015, i64 %r3016)
  store i64 %r3017, i64* %ptr_s
  %r3018 = load i64, i64* %ptr_s
  %r3019 = getelementptr [36 x i8], [36 x i8]* @.str.1094, i64 0, i64 0
  %r3020 = ptrtoint i8* %r3019 to i64
  %r3021 = call i64 @_add(i64 %r3018, i64 %r3020)
  %r3022 = load i64, i64* %ptr_NL
  %r3023 = call i64 @_add(i64 %r3021, i64 %r3022)
  store i64 %r3023, i64* %ptr_s
  %r3024 = load i64, i64* %ptr_s
  %r3025 = getelementptr [24 x i8], [24 x i8]* @.str.1095, i64 0, i64 0
  %r3026 = ptrtoint i8* %r3025 to i64
  %r3027 = call i64 @_add(i64 %r3024, i64 %r3026)
  %r3028 = load i64, i64* %ptr_NL
  %r3029 = call i64 @_add(i64 %r3027, i64 %r3028)
  store i64 %r3029, i64* %ptr_s
  %r3030 = load i64, i64* %ptr_s
  %r3031 = getelementptr [35 x i8], [35 x i8]* @.str.1096, i64 0, i64 0
  %r3032 = ptrtoint i8* %r3031 to i64
  %r3033 = call i64 @_add(i64 %r3030, i64 %r3032)
  %r3034 = load i64, i64* %ptr_NL
  %r3035 = call i64 @_add(i64 %r3033, i64 %r3034)
  store i64 %r3035, i64* %ptr_s
  %r3036 = load i64, i64* %ptr_s
  %r3037 = getelementptr [33 x i8], [33 x i8]* @.str.1097, i64 0, i64 0
  %r3038 = ptrtoint i8* %r3037 to i64
  %r3039 = call i64 @_add(i64 %r3036, i64 %r3038)
  %r3040 = load i64, i64* %ptr_NL
  %r3041 = call i64 @_add(i64 %r3039, i64 %r3040)
  store i64 %r3041, i64* %ptr_s
  %r3042 = load i64, i64* %ptr_s
  %r3043 = getelementptr [38 x i8], [38 x i8]* @.str.1098, i64 0, i64 0
  %r3044 = ptrtoint i8* %r3043 to i64
  %r3045 = call i64 @_add(i64 %r3042, i64 %r3044)
  %r3046 = load i64, i64* %ptr_NL
  %r3047 = call i64 @_add(i64 %r3045, i64 %r3046)
  store i64 %r3047, i64* %ptr_s
  %r3048 = load i64, i64* %ptr_s
  %r3049 = getelementptr [45 x i8], [45 x i8]* @.str.1099, i64 0, i64 0
  %r3050 = ptrtoint i8* %r3049 to i64
  %r3051 = call i64 @_add(i64 %r3048, i64 %r3050)
  %r3052 = load i64, i64* %ptr_NL
  %r3053 = call i64 @_add(i64 %r3051, i64 %r3052)
  store i64 %r3053, i64* %ptr_s
  %r3054 = load i64, i64* %ptr_s
  %r3055 = getelementptr [17 x i8], [17 x i8]* @.str.1100, i64 0, i64 0
  %r3056 = ptrtoint i8* %r3055 to i64
  %r3057 = call i64 @_add(i64 %r3054, i64 %r3056)
  %r3058 = load i64, i64* %ptr_NL
  %r3059 = call i64 @_add(i64 %r3057, i64 %r3058)
  store i64 %r3059, i64* %ptr_s
  %r3060 = load i64, i64* %ptr_s
  %r3061 = getelementptr [6 x i8], [6 x i8]* @.str.1101, i64 0, i64 0
  %r3062 = ptrtoint i8* %r3061 to i64
  %r3063 = call i64 @_add(i64 %r3060, i64 %r3062)
  %r3064 = load i64, i64* %ptr_NL
  %r3065 = call i64 @_add(i64 %r3063, i64 %r3064)
  store i64 %r3065, i64* %ptr_s
  %r3066 = load i64, i64* %ptr_s
  %r3067 = getelementptr [48 x i8], [48 x i8]* @.str.1102, i64 0, i64 0
  %r3068 = ptrtoint i8* %r3067 to i64
  %r3069 = call i64 @_add(i64 %r3066, i64 %r3068)
  %r3070 = load i64, i64* %ptr_NL
  %r3071 = call i64 @_add(i64 %r3069, i64 %r3070)
  store i64 %r3071, i64* %ptr_s
  %r3072 = load i64, i64* %ptr_s
  %r3073 = getelementptr [37 x i8], [37 x i8]* @.str.1103, i64 0, i64 0
  %r3074 = ptrtoint i8* %r3073 to i64
  %r3075 = call i64 @_add(i64 %r3072, i64 %r3074)
  %r3076 = load i64, i64* %ptr_NL
  %r3077 = call i64 @_add(i64 %r3075, i64 %r3076)
  store i64 %r3077, i64* %ptr_s
  %r3078 = load i64, i64* %ptr_s
  %r3079 = getelementptr [43 x i8], [43 x i8]* @.str.1104, i64 0, i64 0
  %r3080 = ptrtoint i8* %r3079 to i64
  %r3081 = call i64 @_add(i64 %r3078, i64 %r3080)
  %r3082 = load i64, i64* %ptr_NL
  %r3083 = call i64 @_add(i64 %r3081, i64 %r3082)
  store i64 %r3083, i64* %ptr_s
  %r3084 = load i64, i64* %ptr_s
  %r3085 = getelementptr [6 x i8], [6 x i8]* @.str.1105, i64 0, i64 0
  %r3086 = ptrtoint i8* %r3085 to i64
  %r3087 = call i64 @_add(i64 %r3084, i64 %r3086)
  %r3088 = load i64, i64* %ptr_NL
  %r3089 = call i64 @_add(i64 %r3087, i64 %r3088)
  store i64 %r3089, i64* %ptr_s
  %r3090 = load i64, i64* %ptr_s
  %r3091 = getelementptr [37 x i8], [37 x i8]* @.str.1106, i64 0, i64 0
  %r3092 = ptrtoint i8* %r3091 to i64
  %r3093 = call i64 @_add(i64 %r3090, i64 %r3092)
  %r3094 = load i64, i64* %ptr_NL
  %r3095 = call i64 @_add(i64 %r3093, i64 %r3094)
  store i64 %r3095, i64* %ptr_s
  %r3096 = load i64, i64* %ptr_s
  %r3097 = getelementptr [46 x i8], [46 x i8]* @.str.1107, i64 0, i64 0
  %r3098 = ptrtoint i8* %r3097 to i64
  %r3099 = call i64 @_add(i64 %r3096, i64 %r3098)
  %r3100 = load i64, i64* %ptr_NL
  %r3101 = call i64 @_add(i64 %r3099, i64 %r3100)
  store i64 %r3101, i64* %ptr_s
  %r3102 = load i64, i64* %ptr_s
  %r3103 = getelementptr [46 x i8], [46 x i8]* @.str.1108, i64 0, i64 0
  %r3104 = ptrtoint i8* %r3103 to i64
  %r3105 = call i64 @_add(i64 %r3102, i64 %r3104)
  %r3106 = load i64, i64* %ptr_NL
  %r3107 = call i64 @_add(i64 %r3105, i64 %r3106)
  store i64 %r3107, i64* %ptr_s
  %r3108 = load i64, i64* %ptr_s
  %r3109 = getelementptr [17 x i8], [17 x i8]* @.str.1109, i64 0, i64 0
  %r3110 = ptrtoint i8* %r3109 to i64
  %r3111 = call i64 @_add(i64 %r3108, i64 %r3110)
  %r3112 = load i64, i64* %ptr_NL
  %r3113 = call i64 @_add(i64 %r3111, i64 %r3112)
  store i64 %r3113, i64* %ptr_s
  %r3114 = load i64, i64* %ptr_s
  %r3115 = getelementptr [6 x i8], [6 x i8]* @.str.1110, i64 0, i64 0
  %r3116 = ptrtoint i8* %r3115 to i64
  %r3117 = call i64 @_add(i64 %r3114, i64 %r3116)
  %r3118 = load i64, i64* %ptr_NL
  %r3119 = call i64 @_add(i64 %r3117, i64 %r3118)
  store i64 %r3119, i64* %ptr_s
  %r3120 = load i64, i64* %ptr_s
  %r3121 = getelementptr [16 x i8], [16 x i8]* @.str.1111, i64 0, i64 0
  %r3122 = ptrtoint i8* %r3121 to i64
  %r3123 = call i64 @_add(i64 %r3120, i64 %r3122)
  %r3124 = load i64, i64* %ptr_NL
  %r3125 = call i64 @_add(i64 %r3123, i64 %r3124)
  store i64 %r3125, i64* %ptr_s
  %r3126 = load i64, i64* %ptr_s
  %r3127 = getelementptr [2 x i8], [2 x i8]* @.str.1112, i64 0, i64 0
  %r3128 = ptrtoint i8* %r3127 to i64
  %r3129 = call i64 @_add(i64 %r3126, i64 %r3128)
  %r3130 = load i64, i64* %ptr_NL
  %r3131 = call i64 @_add(i64 %r3129, i64 %r3130)
  store i64 %r3131, i64* %ptr_s
  %r3132 = load i64, i64* %ptr_s
  %r3133 = getelementptr [50 x i8], [50 x i8]* @.str.1113, i64 0, i64 0
  %r3134 = ptrtoint i8* %r3133 to i64
  %r3135 = call i64 @_add(i64 %r3132, i64 %r3134)
  %r3136 = load i64, i64* %ptr_NL
  %r3137 = call i64 @_add(i64 %r3135, i64 %r3136)
  store i64 %r3137, i64* %ptr_s
  %r3138 = load i64, i64* %ptr_s
  %r3139 = getelementptr [38 x i8], [38 x i8]* @.str.1114, i64 0, i64 0
  %r3140 = ptrtoint i8* %r3139 to i64
  %r3141 = call i64 @_add(i64 %r3138, i64 %r3140)
  %r3142 = load i64, i64* %ptr_NL
  %r3143 = call i64 @_add(i64 %r3141, i64 %r3142)
  store i64 %r3143, i64* %ptr_s
  %r3144 = load i64, i64* %ptr_s
  %r3145 = getelementptr [49 x i8], [49 x i8]* @.str.1115, i64 0, i64 0
  %r3146 = ptrtoint i8* %r3145 to i64
  %r3147 = call i64 @_add(i64 %r3144, i64 %r3146)
  %r3148 = load i64, i64* %ptr_NL
  %r3149 = call i64 @_add(i64 %r3147, i64 %r3148)
  store i64 %r3149, i64* %ptr_s
  %r3150 = load i64, i64* %ptr_s
  %r3151 = getelementptr [7 x i8], [7 x i8]* @.str.1116, i64 0, i64 0
  %r3152 = ptrtoint i8* %r3151 to i64
  %r3153 = call i64 @_add(i64 %r3150, i64 %r3152)
  %r3154 = load i64, i64* %ptr_NL
  %r3155 = call i64 @_add(i64 %r3153, i64 %r3154)
  store i64 %r3155, i64* %ptr_s
  %r3156 = load i64, i64* %ptr_s
  %r3157 = getelementptr [42 x i8], [42 x i8]* @.str.1117, i64 0, i64 0
  %r3158 = ptrtoint i8* %r3157 to i64
  %r3159 = call i64 @_add(i64 %r3156, i64 %r3158)
  %r3160 = load i64, i64* %ptr_NL
  %r3161 = call i64 @_add(i64 %r3159, i64 %r3160)
  store i64 %r3161, i64* %ptr_s
  %r3162 = load i64, i64* %ptr_s
  %r3163 = getelementptr [51 x i8], [51 x i8]* @.str.1118, i64 0, i64 0
  %r3164 = ptrtoint i8* %r3163 to i64
  %r3165 = call i64 @_add(i64 %r3162, i64 %r3164)
  %r3166 = load i64, i64* %ptr_NL
  %r3167 = call i64 @_add(i64 %r3165, i64 %r3166)
  store i64 %r3167, i64* %ptr_s
  %r3168 = load i64, i64* %ptr_s
  %r3169 = getelementptr [33 x i8], [33 x i8]* @.str.1119, i64 0, i64 0
  %r3170 = ptrtoint i8* %r3169 to i64
  %r3171 = call i64 @_add(i64 %r3168, i64 %r3170)
  %r3172 = load i64, i64* %ptr_NL
  %r3173 = call i64 @_add(i64 %r3171, i64 %r3172)
  store i64 %r3173, i64* %ptr_s
  %r3174 = load i64, i64* %ptr_s
  %r3175 = getelementptr [34 x i8], [34 x i8]* @.str.1120, i64 0, i64 0
  %r3176 = ptrtoint i8* %r3175 to i64
  %r3177 = call i64 @_add(i64 %r3174, i64 %r3176)
  %r3178 = load i64, i64* %ptr_NL
  %r3179 = call i64 @_add(i64 %r3177, i64 %r3178)
  store i64 %r3179, i64* %ptr_s
  %r3180 = load i64, i64* %ptr_s
  %r3181 = getelementptr [49 x i8], [49 x i8]* @.str.1121, i64 0, i64 0
  %r3182 = ptrtoint i8* %r3181 to i64
  %r3183 = call i64 @_add(i64 %r3180, i64 %r3182)
  %r3184 = load i64, i64* %ptr_NL
  %r3185 = call i64 @_add(i64 %r3183, i64 %r3184)
  store i64 %r3185, i64* %ptr_s
  %r3186 = load i64, i64* %ptr_s
  %r3187 = getelementptr [11 x i8], [11 x i8]* @.str.1122, i64 0, i64 0
  %r3188 = ptrtoint i8* %r3187 to i64
  %r3189 = call i64 @_add(i64 %r3186, i64 %r3188)
  %r3190 = load i64, i64* %ptr_NL
  %r3191 = call i64 @_add(i64 %r3189, i64 %r3190)
  store i64 %r3191, i64* %ptr_s
  %r3192 = load i64, i64* %ptr_s
  %r3193 = getelementptr [33 x i8], [33 x i8]* @.str.1123, i64 0, i64 0
  %r3194 = ptrtoint i8* %r3193 to i64
  %r3195 = call i64 @_add(i64 %r3192, i64 %r3194)
  %r3196 = load i64, i64* %ptr_NL
  %r3197 = call i64 @_add(i64 %r3195, i64 %r3196)
  store i64 %r3197, i64* %ptr_s
  %r3198 = load i64, i64* %ptr_s
  %r3199 = getelementptr [36 x i8], [36 x i8]* @.str.1124, i64 0, i64 0
  %r3200 = ptrtoint i8* %r3199 to i64
  %r3201 = call i64 @_add(i64 %r3198, i64 %r3200)
  %r3202 = load i64, i64* %ptr_NL
  %r3203 = call i64 @_add(i64 %r3201, i64 %r3202)
  store i64 %r3203, i64* %ptr_s
  %r3204 = load i64, i64* %ptr_s
  %r3205 = getelementptr [25 x i8], [25 x i8]* @.str.1125, i64 0, i64 0
  %r3206 = ptrtoint i8* %r3205 to i64
  %r3207 = call i64 @_add(i64 %r3204, i64 %r3206)
  %r3208 = load i64, i64* %ptr_NL
  %r3209 = call i64 @_add(i64 %r3207, i64 %r3208)
  store i64 %r3209, i64* %ptr_s
  %r3210 = load i64, i64* %ptr_s
  %r3211 = getelementptr [15 x i8], [15 x i8]* @.str.1126, i64 0, i64 0
  %r3212 = ptrtoint i8* %r3211 to i64
  %r3213 = call i64 @_add(i64 %r3210, i64 %r3212)
  %r3214 = load i64, i64* %ptr_NL
  %r3215 = call i64 @_add(i64 %r3213, i64 %r3214)
  store i64 %r3215, i64* %ptr_s
  %r3216 = load i64, i64* %ptr_s
  %r3217 = getelementptr [6 x i8], [6 x i8]* @.str.1127, i64 0, i64 0
  %r3218 = ptrtoint i8* %r3217 to i64
  %r3219 = call i64 @_add(i64 %r3216, i64 %r3218)
  %r3220 = load i64, i64* %ptr_NL
  %r3221 = call i64 @_add(i64 %r3219, i64 %r3220)
  store i64 %r3221, i64* %ptr_s
  %r3222 = load i64, i64* %ptr_s
  %r3223 = getelementptr [52 x i8], [52 x i8]* @.str.1128, i64 0, i64 0
  %r3224 = ptrtoint i8* %r3223 to i64
  %r3225 = call i64 @_add(i64 %r3222, i64 %r3224)
  %r3226 = load i64, i64* %ptr_NL
  %r3227 = call i64 @_add(i64 %r3225, i64 %r3226)
  store i64 %r3227, i64* %ptr_s
  %r3228 = load i64, i64* %ptr_s
  %r3229 = getelementptr [35 x i8], [35 x i8]* @.str.1129, i64 0, i64 0
  %r3230 = ptrtoint i8* %r3229 to i64
  %r3231 = call i64 @_add(i64 %r3228, i64 %r3230)
  %r3232 = load i64, i64* %ptr_NL
  %r3233 = call i64 @_add(i64 %r3231, i64 %r3232)
  store i64 %r3233, i64* %ptr_s
  %r3234 = load i64, i64* %ptr_s
  %r3235 = getelementptr [41 x i8], [41 x i8]* @.str.1130, i64 0, i64 0
  %r3236 = ptrtoint i8* %r3235 to i64
  %r3237 = call i64 @_add(i64 %r3234, i64 %r3236)
  %r3238 = load i64, i64* %ptr_NL
  %r3239 = call i64 @_add(i64 %r3237, i64 %r3238)
  store i64 %r3239, i64* %ptr_s
  %r3240 = load i64, i64* %ptr_s
  %r3241 = getelementptr [35 x i8], [35 x i8]* @.str.1131, i64 0, i64 0
  %r3242 = ptrtoint i8* %r3241 to i64
  %r3243 = call i64 @_add(i64 %r3240, i64 %r3242)
  %r3244 = load i64, i64* %ptr_NL
  %r3245 = call i64 @_add(i64 %r3243, i64 %r3244)
  store i64 %r3245, i64* %ptr_s
  %r3246 = load i64, i64* %ptr_s
  %r3247 = getelementptr [40 x i8], [40 x i8]* @.str.1132, i64 0, i64 0
  %r3248 = ptrtoint i8* %r3247 to i64
  %r3249 = call i64 @_add(i64 %r3246, i64 %r3248)
  %r3250 = load i64, i64* %ptr_NL
  %r3251 = call i64 @_add(i64 %r3249, i64 %r3250)
  store i64 %r3251, i64* %ptr_s
  %r3252 = load i64, i64* %ptr_s
  %r3253 = getelementptr [27 x i8], [27 x i8]* @.str.1133, i64 0, i64 0
  %r3254 = ptrtoint i8* %r3253 to i64
  %r3255 = call i64 @_add(i64 %r3252, i64 %r3254)
  %r3256 = load i64, i64* %ptr_NL
  %r3257 = call i64 @_add(i64 %r3255, i64 %r3256)
  store i64 %r3257, i64* %ptr_s
  %r3258 = load i64, i64* %ptr_s
  %r3259 = getelementptr [17 x i8], [17 x i8]* @.str.1134, i64 0, i64 0
  %r3260 = ptrtoint i8* %r3259 to i64
  %r3261 = call i64 @_add(i64 %r3258, i64 %r3260)
  %r3262 = load i64, i64* %ptr_NL
  %r3263 = call i64 @_add(i64 %r3261, i64 %r3262)
  store i64 %r3263, i64* %ptr_s
  %r3264 = load i64, i64* %ptr_s
  %r3265 = getelementptr [6 x i8], [6 x i8]* @.str.1135, i64 0, i64 0
  %r3266 = ptrtoint i8* %r3265 to i64
  %r3267 = call i64 @_add(i64 %r3264, i64 %r3266)
  %r3268 = load i64, i64* %ptr_NL
  %r3269 = call i64 @_add(i64 %r3267, i64 %r3268)
  store i64 %r3269, i64* %ptr_s
  %r3270 = load i64, i64* %ptr_s
  %r3271 = getelementptr [49 x i8], [49 x i8]* @.str.1136, i64 0, i64 0
  %r3272 = ptrtoint i8* %r3271 to i64
  %r3273 = call i64 @_add(i64 %r3270, i64 %r3272)
  %r3274 = load i64, i64* %ptr_NL
  %r3275 = call i64 @_add(i64 %r3273, i64 %r3274)
  store i64 %r3275, i64* %ptr_s
  %r3276 = load i64, i64* %ptr_s
  %r3277 = getelementptr [63 x i8], [63 x i8]* @.str.1137, i64 0, i64 0
  %r3278 = ptrtoint i8* %r3277 to i64
  %r3279 = call i64 @_add(i64 %r3276, i64 %r3278)
  %r3280 = load i64, i64* %ptr_NL
  %r3281 = call i64 @_add(i64 %r3279, i64 %r3280)
  store i64 %r3281, i64* %ptr_s
  %r3282 = load i64, i64* %ptr_s
  %r3283 = getelementptr [32 x i8], [32 x i8]* @.str.1138, i64 0, i64 0
  %r3284 = ptrtoint i8* %r3283 to i64
  %r3285 = call i64 @_add(i64 %r3282, i64 %r3284)
  %r3286 = load i64, i64* %ptr_NL
  %r3287 = call i64 @_add(i64 %r3285, i64 %r3286)
  store i64 %r3287, i64* %ptr_s
  %r3288 = load i64, i64* %ptr_s
  %r3289 = getelementptr [40 x i8], [40 x i8]* @.str.1139, i64 0, i64 0
  %r3290 = ptrtoint i8* %r3289 to i64
  %r3291 = call i64 @_add(i64 %r3288, i64 %r3290)
  %r3292 = load i64, i64* %ptr_NL
  %r3293 = call i64 @_add(i64 %r3291, i64 %r3292)
  store i64 %r3293, i64* %ptr_s
  %r3294 = load i64, i64* %ptr_s
  %r3295 = getelementptr [6 x i8], [6 x i8]* @.str.1140, i64 0, i64 0
  %r3296 = ptrtoint i8* %r3295 to i64
  %r3297 = call i64 @_add(i64 %r3294, i64 %r3296)
  %r3298 = load i64, i64* %ptr_NL
  %r3299 = call i64 @_add(i64 %r3297, i64 %r3298)
  store i64 %r3299, i64* %ptr_s
  %r3300 = load i64, i64* %ptr_s
  %r3301 = getelementptr [52 x i8], [52 x i8]* @.str.1141, i64 0, i64 0
  %r3302 = ptrtoint i8* %r3301 to i64
  %r3303 = call i64 @_add(i64 %r3300, i64 %r3302)
  %r3304 = load i64, i64* %ptr_NL
  %r3305 = call i64 @_add(i64 %r3303, i64 %r3304)
  store i64 %r3305, i64* %ptr_s
  %r3306 = load i64, i64* %ptr_s
  %r3307 = getelementptr [31 x i8], [31 x i8]* @.str.1142, i64 0, i64 0
  %r3308 = ptrtoint i8* %r3307 to i64
  %r3309 = call i64 @_add(i64 %r3306, i64 %r3308)
  %r3310 = load i64, i64* %ptr_NL
  %r3311 = call i64 @_add(i64 %r3309, i64 %r3310)
  store i64 %r3311, i64* %ptr_s
  %r3312 = load i64, i64* %ptr_s
  %r3313 = getelementptr [43 x i8], [43 x i8]* @.str.1143, i64 0, i64 0
  %r3314 = ptrtoint i8* %r3313 to i64
  %r3315 = call i64 @_add(i64 %r3312, i64 %r3314)
  %r3316 = load i64, i64* %ptr_NL
  %r3317 = call i64 @_add(i64 %r3315, i64 %r3316)
  store i64 %r3317, i64* %ptr_s
  %r3318 = load i64, i64* %ptr_s
  %r3319 = getelementptr [58 x i8], [58 x i8]* @.str.1144, i64 0, i64 0
  %r3320 = ptrtoint i8* %r3319 to i64
  %r3321 = call i64 @_add(i64 %r3318, i64 %r3320)
  %r3322 = load i64, i64* %ptr_NL
  %r3323 = call i64 @_add(i64 %r3321, i64 %r3322)
  store i64 %r3323, i64* %ptr_s
  %r3324 = load i64, i64* %ptr_s
  %r3325 = getelementptr [30 x i8], [30 x i8]* @.str.1145, i64 0, i64 0
  %r3326 = ptrtoint i8* %r3325 to i64
  %r3327 = call i64 @_add(i64 %r3324, i64 %r3326)
  %r3328 = load i64, i64* %ptr_NL
  %r3329 = call i64 @_add(i64 %r3327, i64 %r3328)
  store i64 %r3329, i64* %ptr_s
  %r3330 = load i64, i64* %ptr_s
  %r3331 = getelementptr [39 x i8], [39 x i8]* @.str.1146, i64 0, i64 0
  %r3332 = ptrtoint i8* %r3331 to i64
  %r3333 = call i64 @_add(i64 %r3330, i64 %r3332)
  %r3334 = load i64, i64* %ptr_NL
  %r3335 = call i64 @_add(i64 %r3333, i64 %r3334)
  store i64 %r3335, i64* %ptr_s
  %r3336 = load i64, i64* %ptr_s
  %r3337 = getelementptr [54 x i8], [54 x i8]* @.str.1147, i64 0, i64 0
  %r3338 = ptrtoint i8* %r3337 to i64
  %r3339 = call i64 @_add(i64 %r3336, i64 %r3338)
  %r3340 = load i64, i64* %ptr_NL
  %r3341 = call i64 @_add(i64 %r3339, i64 %r3340)
  store i64 %r3341, i64* %ptr_s
  %r3342 = load i64, i64* %ptr_s
  %r3343 = getelementptr [11 x i8], [11 x i8]* @.str.1148, i64 0, i64 0
  %r3344 = ptrtoint i8* %r3343 to i64
  %r3345 = call i64 @_add(i64 %r3342, i64 %r3344)
  %r3346 = load i64, i64* %ptr_NL
  %r3347 = call i64 @_add(i64 %r3345, i64 %r3346)
  store i64 %r3347, i64* %ptr_s
  %r3348 = load i64, i64* %ptr_s
  %r3349 = getelementptr [59 x i8], [59 x i8]* @.str.1149, i64 0, i64 0
  %r3350 = ptrtoint i8* %r3349 to i64
  %r3351 = call i64 @_add(i64 %r3348, i64 %r3350)
  %r3352 = load i64, i64* %ptr_NL
  %r3353 = call i64 @_add(i64 %r3351, i64 %r3352)
  store i64 %r3353, i64* %ptr_s
  %r3354 = load i64, i64* %ptr_s
  %r3355 = getelementptr [18 x i8], [18 x i8]* @.str.1150, i64 0, i64 0
  %r3356 = ptrtoint i8* %r3355 to i64
  %r3357 = call i64 @_add(i64 %r3354, i64 %r3356)
  %r3358 = load i64, i64* %ptr_NL
  %r3359 = call i64 @_add(i64 %r3357, i64 %r3358)
  store i64 %r3359, i64* %ptr_s
  %r3360 = load i64, i64* %ptr_s
  %r3361 = getelementptr [12 x i8], [12 x i8]* @.str.1151, i64 0, i64 0
  %r3362 = ptrtoint i8* %r3361 to i64
  %r3363 = call i64 @_add(i64 %r3360, i64 %r3362)
  %r3364 = load i64, i64* %ptr_NL
  %r3365 = call i64 @_add(i64 %r3363, i64 %r3364)
  store i64 %r3365, i64* %ptr_s
  %r3366 = load i64, i64* %ptr_s
  %r3367 = getelementptr [18 x i8], [18 x i8]* @.str.1152, i64 0, i64 0
  %r3368 = ptrtoint i8* %r3367 to i64
  %r3369 = call i64 @_add(i64 %r3366, i64 %r3368)
  %r3370 = load i64, i64* %ptr_NL
  %r3371 = call i64 @_add(i64 %r3369, i64 %r3370)
  store i64 %r3371, i64* %ptr_s
  %r3372 = load i64, i64* %ptr_s
  %r3373 = getelementptr [7 x i8], [7 x i8]* @.str.1153, i64 0, i64 0
  %r3374 = ptrtoint i8* %r3373 to i64
  %r3375 = call i64 @_add(i64 %r3372, i64 %r3374)
  %r3376 = load i64, i64* %ptr_NL
  %r3377 = call i64 @_add(i64 %r3375, i64 %r3376)
  store i64 %r3377, i64* %ptr_s
  %r3378 = load i64, i64* %ptr_s
  %r3379 = getelementptr [75 x i8], [75 x i8]* @.str.1154, i64 0, i64 0
  %r3380 = ptrtoint i8* %r3379 to i64
  %r3381 = call i64 @_add(i64 %r3378, i64 %r3380)
  %r3382 = load i64, i64* %ptr_NL
  %r3383 = call i64 @_add(i64 %r3381, i64 %r3382)
  store i64 %r3383, i64* %ptr_s
  %r3384 = load i64, i64* %ptr_s
  %r3385 = getelementptr [26 x i8], [26 x i8]* @.str.1155, i64 0, i64 0
  %r3386 = ptrtoint i8* %r3385 to i64
  %r3387 = call i64 @_add(i64 %r3384, i64 %r3386)
  %r3388 = load i64, i64* %ptr_NL
  %r3389 = call i64 @_add(i64 %r3387, i64 %r3388)
  store i64 %r3389, i64* %ptr_s
  %r3390 = load i64, i64* %ptr_s
  %r3391 = getelementptr [17 x i8], [17 x i8]* @.str.1156, i64 0, i64 0
  %r3392 = ptrtoint i8* %r3391 to i64
  %r3393 = call i64 @_add(i64 %r3390, i64 %r3392)
  %r3394 = load i64, i64* %ptr_NL
  %r3395 = call i64 @_add(i64 %r3393, i64 %r3394)
  store i64 %r3395, i64* %ptr_s
  %r3396 = load i64, i64* %ptr_s
  %r3397 = getelementptr [6 x i8], [6 x i8]* @.str.1157, i64 0, i64 0
  %r3398 = ptrtoint i8* %r3397 to i64
  %r3399 = call i64 @_add(i64 %r3396, i64 %r3398)
  %r3400 = load i64, i64* %ptr_NL
  %r3401 = call i64 @_add(i64 %r3399, i64 %r3400)
  store i64 %r3401, i64* %ptr_s
  %r3402 = load i64, i64* %ptr_s
  %r3403 = getelementptr [20 x i8], [20 x i8]* @.str.1158, i64 0, i64 0
  %r3404 = ptrtoint i8* %r3403 to i64
  %r3405 = call i64 @_add(i64 %r3402, i64 %r3404)
  %r3406 = load i64, i64* %ptr_NL
  %r3407 = call i64 @_add(i64 %r3405, i64 %r3406)
  store i64 %r3407, i64* %ptr_s
  %r3408 = load i64, i64* %ptr_s
  %r3409 = getelementptr [2 x i8], [2 x i8]* @.str.1159, i64 0, i64 0
  %r3410 = ptrtoint i8* %r3409 to i64
  %r3411 = call i64 @_add(i64 %r3408, i64 %r3410)
  %r3412 = load i64, i64* %ptr_NL
  %r3413 = call i64 @_add(i64 %r3411, i64 %r3412)
  store i64 %r3413, i64* %ptr_s
  %r3414 = load i64, i64* %ptr_s
  %r3415 = getelementptr [90 x i8], [90 x i8]* @.str.1160, i64 0, i64 0
  %r3416 = ptrtoint i8* %r3415 to i64
  %r3417 = call i64 @_add(i64 %r3414, i64 %r3416)
  %r3418 = load i64, i64* %ptr_NL
  %r3419 = call i64 @_add(i64 %r3417, i64 %r3418)
  store i64 %r3419, i64* %ptr_s
  %r3420 = load i64, i64* %ptr_s
  %r3421 = getelementptr [184 x i8], [184 x i8]* @.str.1161, i64 0, i64 0
  %r3422 = ptrtoint i8* %r3421 to i64
  %r3423 = call i64 @_add(i64 %r3420, i64 %r3422)
  %r3424 = load i64, i64* %ptr_NL
  %r3425 = call i64 @_add(i64 %r3423, i64 %r3424)
  store i64 %r3425, i64* %ptr_s
  %r3426 = load i64, i64* %ptr_s
  %r3427 = getelementptr [15 x i8], [15 x i8]* @.str.1162, i64 0, i64 0
  %r3428 = ptrtoint i8* %r3427 to i64
  %r3429 = call i64 @_add(i64 %r3426, i64 %r3428)
  %r3430 = load i64, i64* %ptr_NL
  %r3431 = call i64 @_add(i64 %r3429, i64 %r3430)
  store i64 %r3431, i64* %ptr_s
  %r3432 = load i64, i64* %ptr_s
  %r3433 = getelementptr [2 x i8], [2 x i8]* @.str.1163, i64 0, i64 0
  %r3434 = ptrtoint i8* %r3433 to i64
  %r3435 = call i64 @_add(i64 %r3432, i64 %r3434)
  %r3436 = load i64, i64* %ptr_NL
  %r3437 = call i64 @_add(i64 %r3435, i64 %r3436)
  store i64 %r3437, i64* %ptr_s
  %r3438 = load i64, i64* %ptr_s
  %r3439 = getelementptr [31 x i8], [31 x i8]* @.str.1164, i64 0, i64 0
  %r3440 = ptrtoint i8* %r3439 to i64
  %r3441 = call i64 @_add(i64 %r3438, i64 %r3440)
  %r3442 = load i64, i64* %ptr_NL
  %r3443 = call i64 @_add(i64 %r3441, i64 %r3442)
  store i64 %r3443, i64* %ptr_s
  %r3444 = load i64, i64* %ptr_s
  %r3445 = getelementptr [22 x i8], [22 x i8]* @.str.1165, i64 0, i64 0
  %r3446 = ptrtoint i8* %r3445 to i64
  %r3447 = call i64 @_add(i64 %r3444, i64 %r3446)
  %r3448 = load i64, i64* %ptr_NL
  %r3449 = call i64 @_add(i64 %r3447, i64 %r3448)
  store i64 %r3449, i64* %ptr_s
  %r3450 = load i64, i64* %ptr_s
  %r3451 = getelementptr [6 x i8], [6 x i8]* @.str.1166, i64 0, i64 0
  %r3452 = ptrtoint i8* %r3451 to i64
  %r3453 = call i64 @_add(i64 %r3450, i64 %r3452)
  %r3454 = load i64, i64* %ptr_NL
  %r3455 = call i64 @_add(i64 %r3453, i64 %r3454)
  store i64 %r3455, i64* %ptr_s
  %r3456 = load i64, i64* %ptr_s
  %r3457 = getelementptr [46 x i8], [46 x i8]* @.str.1167, i64 0, i64 0
  %r3458 = ptrtoint i8* %r3457 to i64
  %r3459 = call i64 @_add(i64 %r3456, i64 %r3458)
  %r3460 = load i64, i64* %ptr_NL
  %r3461 = call i64 @_add(i64 %r3459, i64 %r3460)
  store i64 %r3461, i64* %ptr_s
  %r3462 = load i64, i64* %ptr_s
  %r3463 = getelementptr [44 x i8], [44 x i8]* @.str.1168, i64 0, i64 0
  %r3464 = ptrtoint i8* %r3463 to i64
  %r3465 = call i64 @_add(i64 %r3462, i64 %r3464)
  %r3466 = load i64, i64* %ptr_NL
  %r3467 = call i64 @_add(i64 %r3465, i64 %r3466)
  store i64 %r3467, i64* %ptr_s
  %r3468 = load i64, i64* %ptr_s
  %r3469 = getelementptr [25 x i8], [25 x i8]* @.str.1169, i64 0, i64 0
  %r3470 = ptrtoint i8* %r3469 to i64
  %r3471 = call i64 @_add(i64 %r3468, i64 %r3470)
  %r3472 = load i64, i64* %ptr_NL
  %r3473 = call i64 @_add(i64 %r3471, i64 %r3472)
  store i64 %r3473, i64* %ptr_s
  %r3474 = load i64, i64* %ptr_s
  %r3475 = getelementptr [30 x i8], [30 x i8]* @.str.1170, i64 0, i64 0
  %r3476 = ptrtoint i8* %r3475 to i64
  %r3477 = call i64 @_add(i64 %r3474, i64 %r3476)
  %r3478 = load i64, i64* %ptr_NL
  %r3479 = call i64 @_add(i64 %r3477, i64 %r3478)
  store i64 %r3479, i64* %ptr_s
  %r3480 = load i64, i64* %ptr_s
  %r3481 = getelementptr [23 x i8], [23 x i8]* @.str.1171, i64 0, i64 0
  %r3482 = ptrtoint i8* %r3481 to i64
  %r3483 = call i64 @_add(i64 %r3480, i64 %r3482)
  %r3484 = load i64, i64* %ptr_NL
  %r3485 = call i64 @_add(i64 %r3483, i64 %r3484)
  store i64 %r3485, i64* %ptr_s
  %r3486 = load i64, i64* %ptr_s
  %r3487 = getelementptr [43 x i8], [43 x i8]* @.str.1172, i64 0, i64 0
  %r3488 = ptrtoint i8* %r3487 to i64
  %r3489 = call i64 @_add(i64 %r3486, i64 %r3488)
  %r3490 = load i64, i64* %ptr_NL
  %r3491 = call i64 @_add(i64 %r3489, i64 %r3490)
  store i64 %r3491, i64* %ptr_s
  %r3492 = load i64, i64* %ptr_s
  %r3493 = getelementptr [17 x i8], [17 x i8]* @.str.1173, i64 0, i64 0
  %r3494 = ptrtoint i8* %r3493 to i64
  %r3495 = call i64 @_add(i64 %r3492, i64 %r3494)
  %r3496 = load i64, i64* %ptr_NL
  %r3497 = call i64 @_add(i64 %r3495, i64 %r3496)
  store i64 %r3497, i64* %ptr_s
  %r3498 = load i64, i64* %ptr_s
  %r3499 = getelementptr [2 x i8], [2 x i8]* @.str.1174, i64 0, i64 0
  %r3500 = ptrtoint i8* %r3499 to i64
  %r3501 = call i64 @_add(i64 %r3498, i64 %r3500)
  %r3502 = load i64, i64* %ptr_NL
  %r3503 = call i64 @_add(i64 %r3501, i64 %r3502)
  store i64 %r3503, i64* %ptr_s
  %r3504 = load i64, i64* %ptr_s
  %r3505 = getelementptr [39 x i8], [39 x i8]* @.str.1175, i64 0, i64 0
  %r3506 = ptrtoint i8* %r3505 to i64
  %r3507 = call i64 @_add(i64 %r3504, i64 %r3506)
  %r3508 = load i64, i64* %ptr_NL
  %r3509 = call i64 @_add(i64 %r3507, i64 %r3508)
  store i64 %r3509, i64* %ptr_s
  %r3510 = load i64, i64* %ptr_s
  %r3511 = getelementptr [22 x i8], [22 x i8]* @.str.1176, i64 0, i64 0
  %r3512 = ptrtoint i8* %r3511 to i64
  %r3513 = call i64 @_add(i64 %r3510, i64 %r3512)
  %r3514 = load i64, i64* %ptr_NL
  %r3515 = call i64 @_add(i64 %r3513, i64 %r3514)
  store i64 %r3515, i64* %ptr_s
  %r3516 = load i64, i64* %ptr_s
  %r3517 = getelementptr [6 x i8], [6 x i8]* @.str.1177, i64 0, i64 0
  %r3518 = ptrtoint i8* %r3517 to i64
  %r3519 = call i64 @_add(i64 %r3516, i64 %r3518)
  %r3520 = load i64, i64* %ptr_NL
  %r3521 = call i64 @_add(i64 %r3519, i64 %r3520)
  store i64 %r3521, i64* %ptr_s
  %r3522 = load i64, i64* %ptr_s
  %r3523 = getelementptr [46 x i8], [46 x i8]* @.str.1178, i64 0, i64 0
  %r3524 = ptrtoint i8* %r3523 to i64
  %r3525 = call i64 @_add(i64 %r3522, i64 %r3524)
  %r3526 = load i64, i64* %ptr_NL
  %r3527 = call i64 @_add(i64 %r3525, i64 %r3526)
  store i64 %r3527, i64* %ptr_s
  %r3528 = load i64, i64* %ptr_s
  %r3529 = getelementptr [42 x i8], [42 x i8]* @.str.1179, i64 0, i64 0
  %r3530 = ptrtoint i8* %r3529 to i64
  %r3531 = call i64 @_add(i64 %r3528, i64 %r3530)
  %r3532 = load i64, i64* %ptr_NL
  %r3533 = call i64 @_add(i64 %r3531, i64 %r3532)
  store i64 %r3533, i64* %ptr_s
  %r3534 = load i64, i64* %ptr_s
  %r3535 = getelementptr [42 x i8], [42 x i8]* @.str.1180, i64 0, i64 0
  %r3536 = ptrtoint i8* %r3535 to i64
  %r3537 = call i64 @_add(i64 %r3534, i64 %r3536)
  %r3538 = load i64, i64* %ptr_NL
  %r3539 = call i64 @_add(i64 %r3537, i64 %r3538)
  store i64 %r3539, i64* %ptr_s
  %r3540 = load i64, i64* %ptr_s
  %r3541 = getelementptr [25 x i8], [25 x i8]* @.str.1181, i64 0, i64 0
  %r3542 = ptrtoint i8* %r3541 to i64
  %r3543 = call i64 @_add(i64 %r3540, i64 %r3542)
  %r3544 = load i64, i64* %ptr_NL
  %r3545 = call i64 @_add(i64 %r3543, i64 %r3544)
  store i64 %r3545, i64* %ptr_s
  %r3546 = load i64, i64* %ptr_s
  %r3547 = getelementptr [25 x i8], [25 x i8]* @.str.1182, i64 0, i64 0
  %r3548 = ptrtoint i8* %r3547 to i64
  %r3549 = call i64 @_add(i64 %r3546, i64 %r3548)
  %r3550 = load i64, i64* %ptr_NL
  %r3551 = call i64 @_add(i64 %r3549, i64 %r3550)
  store i64 %r3551, i64* %ptr_s
  %r3552 = load i64, i64* %ptr_s
  %r3553 = getelementptr [32 x i8], [32 x i8]* @.str.1183, i64 0, i64 0
  %r3554 = ptrtoint i8* %r3553 to i64
  %r3555 = call i64 @_add(i64 %r3552, i64 %r3554)
  %r3556 = load i64, i64* %ptr_NL
  %r3557 = call i64 @_add(i64 %r3555, i64 %r3556)
  store i64 %r3557, i64* %ptr_s
  %r3558 = load i64, i64* %ptr_s
  %r3559 = getelementptr [31 x i8], [31 x i8]* @.str.1184, i64 0, i64 0
  %r3560 = ptrtoint i8* %r3559 to i64
  %r3561 = call i64 @_add(i64 %r3558, i64 %r3560)
  %r3562 = load i64, i64* %ptr_NL
  %r3563 = call i64 @_add(i64 %r3561, i64 %r3562)
  store i64 %r3563, i64* %ptr_s
  %r3564 = load i64, i64* %ptr_s
  %r3565 = getelementptr [34 x i8], [34 x i8]* @.str.1185, i64 0, i64 0
  %r3566 = ptrtoint i8* %r3565 to i64
  %r3567 = call i64 @_add(i64 %r3564, i64 %r3566)
  %r3568 = load i64, i64* %ptr_NL
  %r3569 = call i64 @_add(i64 %r3567, i64 %r3568)
  store i64 %r3569, i64* %ptr_s
  %r3570 = load i64, i64* %ptr_s
  %r3571 = getelementptr [23 x i8], [23 x i8]* @.str.1186, i64 0, i64 0
  %r3572 = ptrtoint i8* %r3571 to i64
  %r3573 = call i64 @_add(i64 %r3570, i64 %r3572)
  %r3574 = load i64, i64* %ptr_NL
  %r3575 = call i64 @_add(i64 %r3573, i64 %r3574)
  store i64 %r3575, i64* %ptr_s
  %r3576 = load i64, i64* %ptr_s
  %r3577 = getelementptr [40 x i8], [40 x i8]* @.str.1187, i64 0, i64 0
  %r3578 = ptrtoint i8* %r3577 to i64
  %r3579 = call i64 @_add(i64 %r3576, i64 %r3578)
  %r3580 = load i64, i64* %ptr_NL
  %r3581 = call i64 @_add(i64 %r3579, i64 %r3580)
  store i64 %r3581, i64* %ptr_s
  %r3582 = load i64, i64* %ptr_s
  %r3583 = getelementptr [6 x i8], [6 x i8]* @.str.1188, i64 0, i64 0
  %r3584 = ptrtoint i8* %r3583 to i64
  %r3585 = call i64 @_add(i64 %r3582, i64 %r3584)
  %r3586 = load i64, i64* %ptr_NL
  %r3587 = call i64 @_add(i64 %r3585, i64 %r3586)
  store i64 %r3587, i64* %ptr_s
  %r3588 = load i64, i64* %ptr_s
  %r3589 = getelementptr [27 x i8], [27 x i8]* @.str.1189, i64 0, i64 0
  %r3590 = ptrtoint i8* %r3589 to i64
  %r3591 = call i64 @_add(i64 %r3588, i64 %r3590)
  %r3592 = load i64, i64* %ptr_NL
  %r3593 = call i64 @_add(i64 %r3591, i64 %r3592)
  store i64 %r3593, i64* %ptr_s
  %r3594 = load i64, i64* %ptr_s
  %r3595 = getelementptr [27 x i8], [27 x i8]* @.str.1190, i64 0, i64 0
  %r3596 = ptrtoint i8* %r3595 to i64
  %r3597 = call i64 @_add(i64 %r3594, i64 %r3596)
  %r3598 = load i64, i64* %ptr_NL
  %r3599 = call i64 @_add(i64 %r3597, i64 %r3598)
  store i64 %r3599, i64* %ptr_s
  %r3600 = load i64, i64* %ptr_s
  %r3601 = getelementptr [27 x i8], [27 x i8]* @.str.1191, i64 0, i64 0
  %r3602 = ptrtoint i8* %r3601 to i64
  %r3603 = call i64 @_add(i64 %r3600, i64 %r3602)
  %r3604 = load i64, i64* %ptr_NL
  %r3605 = call i64 @_add(i64 %r3603, i64 %r3604)
  store i64 %r3605, i64* %ptr_s
  %r3606 = load i64, i64* %ptr_s
  %r3607 = getelementptr [16 x i8], [16 x i8]* @.str.1192, i64 0, i64 0
  %r3608 = ptrtoint i8* %r3607 to i64
  %r3609 = call i64 @_add(i64 %r3606, i64 %r3608)
  %r3610 = load i64, i64* %ptr_NL
  %r3611 = call i64 @_add(i64 %r3609, i64 %r3610)
  store i64 %r3611, i64* %ptr_s
  %r3612 = load i64, i64* %ptr_s
  %r3613 = getelementptr [2 x i8], [2 x i8]* @.str.1193, i64 0, i64 0
  %r3614 = ptrtoint i8* %r3613 to i64
  %r3615 = call i64 @_add(i64 %r3612, i64 %r3614)
  %r3616 = load i64, i64* %ptr_NL
  %r3617 = call i64 @_add(i64 %r3615, i64 %r3616)
  store i64 %r3617, i64* %ptr_s
  %r3618 = load i64, i64* %ptr_s
  %r3619 = getelementptr [42 x i8], [42 x i8]* @.str.1194, i64 0, i64 0
  %r3620 = ptrtoint i8* %r3619 to i64
  %r3621 = call i64 @_add(i64 %r3618, i64 %r3620)
  %r3622 = load i64, i64* %ptr_NL
  %r3623 = call i64 @_add(i64 %r3621, i64 %r3622)
  store i64 %r3623, i64* %ptr_s
  %r3624 = load i64, i64* %ptr_s
  %r3625 = getelementptr [22 x i8], [22 x i8]* @.str.1195, i64 0, i64 0
  %r3626 = ptrtoint i8* %r3625 to i64
  %r3627 = call i64 @_add(i64 %r3624, i64 %r3626)
  %r3628 = load i64, i64* %ptr_NL
  %r3629 = call i64 @_add(i64 %r3627, i64 %r3628)
  store i64 %r3629, i64* %ptr_s
  %r3630 = load i64, i64* %ptr_s
  %r3631 = getelementptr [6 x i8], [6 x i8]* @.str.1196, i64 0, i64 0
  %r3632 = ptrtoint i8* %r3631 to i64
  %r3633 = call i64 @_add(i64 %r3630, i64 %r3632)
  %r3634 = load i64, i64* %ptr_NL
  %r3635 = call i64 @_add(i64 %r3633, i64 %r3634)
  store i64 %r3635, i64* %ptr_s
  %r3636 = load i64, i64* %ptr_s
  %r3637 = getelementptr [46 x i8], [46 x i8]* @.str.1197, i64 0, i64 0
  %r3638 = ptrtoint i8* %r3637 to i64
  %r3639 = call i64 @_add(i64 %r3636, i64 %r3638)
  %r3640 = load i64, i64* %ptr_NL
  %r3641 = call i64 @_add(i64 %r3639, i64 %r3640)
  store i64 %r3641, i64* %ptr_s
  %r3642 = load i64, i64* %ptr_s
  %r3643 = getelementptr [43 x i8], [43 x i8]* @.str.1198, i64 0, i64 0
  %r3644 = ptrtoint i8* %r3643 to i64
  %r3645 = call i64 @_add(i64 %r3642, i64 %r3644)
  %r3646 = load i64, i64* %ptr_NL
  %r3647 = call i64 @_add(i64 %r3645, i64 %r3646)
  store i64 %r3647, i64* %ptr_s
  %r3648 = load i64, i64* %ptr_s
  %r3649 = getelementptr [44 x i8], [44 x i8]* @.str.1199, i64 0, i64 0
  %r3650 = ptrtoint i8* %r3649 to i64
  %r3651 = call i64 @_add(i64 %r3648, i64 %r3650)
  %r3652 = load i64, i64* %ptr_NL
  %r3653 = call i64 @_add(i64 %r3651, i64 %r3652)
  store i64 %r3653, i64* %ptr_s
  %r3654 = load i64, i64* %ptr_s
  %r3655 = getelementptr [24 x i8], [24 x i8]* @.str.1200, i64 0, i64 0
  %r3656 = ptrtoint i8* %r3655 to i64
  %r3657 = call i64 @_add(i64 %r3654, i64 %r3656)
  %r3658 = load i64, i64* %ptr_NL
  %r3659 = call i64 @_add(i64 %r3657, i64 %r3658)
  store i64 %r3659, i64* %ptr_s
  %r3660 = load i64, i64* %ptr_s
  %r3661 = getelementptr [23 x i8], [23 x i8]* @.str.1201, i64 0, i64 0
  %r3662 = ptrtoint i8* %r3661 to i64
  %r3663 = call i64 @_add(i64 %r3660, i64 %r3662)
  %r3664 = load i64, i64* %ptr_NL
  %r3665 = call i64 @_add(i64 %r3663, i64 %r3664)
  store i64 %r3665, i64* %ptr_s
  %r3666 = load i64, i64* %ptr_s
  %r3667 = getelementptr [30 x i8], [30 x i8]* @.str.1202, i64 0, i64 0
  %r3668 = ptrtoint i8* %r3667 to i64
  %r3669 = call i64 @_add(i64 %r3666, i64 %r3668)
  %r3670 = load i64, i64* %ptr_NL
  %r3671 = call i64 @_add(i64 %r3669, i64 %r3670)
  store i64 %r3671, i64* %ptr_s
  %r3672 = load i64, i64* %ptr_s
  %r3673 = getelementptr [23 x i8], [23 x i8]* @.str.1203, i64 0, i64 0
  %r3674 = ptrtoint i8* %r3673 to i64
  %r3675 = call i64 @_add(i64 %r3672, i64 %r3674)
  %r3676 = load i64, i64* %ptr_NL
  %r3677 = call i64 @_add(i64 %r3675, i64 %r3676)
  store i64 %r3677, i64* %ptr_s
  %r3678 = load i64, i64* %ptr_s
  %r3679 = getelementptr [43 x i8], [43 x i8]* @.str.1204, i64 0, i64 0
  %r3680 = ptrtoint i8* %r3679 to i64
  %r3681 = call i64 @_add(i64 %r3678, i64 %r3680)
  %r3682 = load i64, i64* %ptr_NL
  %r3683 = call i64 @_add(i64 %r3681, i64 %r3682)
  store i64 %r3683, i64* %ptr_s
  %r3684 = load i64, i64* %ptr_s
  %r3685 = getelementptr [20 x i8], [20 x i8]* @.str.1205, i64 0, i64 0
  %r3686 = ptrtoint i8* %r3685 to i64
  %r3687 = call i64 @_add(i64 %r3684, i64 %r3686)
  %r3688 = load i64, i64* %ptr_NL
  %r3689 = call i64 @_add(i64 %r3687, i64 %r3688)
  store i64 %r3689, i64* %ptr_s
  %r3690 = load i64, i64* %ptr_s
  %r3691 = getelementptr [2 x i8], [2 x i8]* @.str.1206, i64 0, i64 0
  %r3692 = ptrtoint i8* %r3691 to i64
  %r3693 = call i64 @_add(i64 %r3690, i64 %r3692)
  %r3694 = load i64, i64* %ptr_NL
  %r3695 = call i64 @_add(i64 %r3693, i64 %r3694)
  store i64 %r3695, i64* %ptr_s
  %r3696 = load i64, i64* %ptr_s
  %r3697 = getelementptr [51 x i8], [51 x i8]* @.str.1207, i64 0, i64 0
  %r3698 = ptrtoint i8* %r3697 to i64
  %r3699 = call i64 @_add(i64 %r3696, i64 %r3698)
  %r3700 = load i64, i64* %ptr_NL
  %r3701 = call i64 @_add(i64 %r3699, i64 %r3700)
  store i64 %r3701, i64* %ptr_s
  %r3702 = load i64, i64* %ptr_s
  %r3703 = getelementptr [22 x i8], [22 x i8]* @.str.1208, i64 0, i64 0
  %r3704 = ptrtoint i8* %r3703 to i64
  %r3705 = call i64 @_add(i64 %r3702, i64 %r3704)
  %r3706 = load i64, i64* %ptr_NL
  %r3707 = call i64 @_add(i64 %r3705, i64 %r3706)
  store i64 %r3707, i64* %ptr_s
  %r3708 = load i64, i64* %ptr_s
  %r3709 = getelementptr [6 x i8], [6 x i8]* @.str.1209, i64 0, i64 0
  %r3710 = ptrtoint i8* %r3709 to i64
  %r3711 = call i64 @_add(i64 %r3708, i64 %r3710)
  %r3712 = load i64, i64* %ptr_NL
  %r3713 = call i64 @_add(i64 %r3711, i64 %r3712)
  store i64 %r3713, i64* %ptr_s
  %r3714 = load i64, i64* %ptr_s
  %r3715 = getelementptr [46 x i8], [46 x i8]* @.str.1210, i64 0, i64 0
  %r3716 = ptrtoint i8* %r3715 to i64
  %r3717 = call i64 @_add(i64 %r3714, i64 %r3716)
  %r3718 = load i64, i64* %ptr_NL
  %r3719 = call i64 @_add(i64 %r3717, i64 %r3718)
  store i64 %r3719, i64* %ptr_s
  %r3720 = load i64, i64* %ptr_s
  %r3721 = getelementptr [29 x i8], [29 x i8]* @.str.1211, i64 0, i64 0
  %r3722 = ptrtoint i8* %r3721 to i64
  %r3723 = call i64 @_add(i64 %r3720, i64 %r3722)
  %r3724 = load i64, i64* %ptr_NL
  %r3725 = call i64 @_add(i64 %r3723, i64 %r3724)
  store i64 %r3725, i64* %ptr_s
  %r3726 = load i64, i64* %ptr_s
  %r3727 = getelementptr [39 x i8], [39 x i8]* @.str.1212, i64 0, i64 0
  %r3728 = ptrtoint i8* %r3727 to i64
  %r3729 = call i64 @_add(i64 %r3726, i64 %r3728)
  %r3730 = load i64, i64* %ptr_NL
  %r3731 = call i64 @_add(i64 %r3729, i64 %r3730)
  store i64 %r3731, i64* %ptr_s
  %r3732 = load i64, i64* %ptr_s
  %r3733 = getelementptr [6 x i8], [6 x i8]* @.str.1213, i64 0, i64 0
  %r3734 = ptrtoint i8* %r3733 to i64
  %r3735 = call i64 @_add(i64 %r3732, i64 %r3734)
  %r3736 = load i64, i64* %ptr_NL
  %r3737 = call i64 @_add(i64 %r3735, i64 %r3736)
  store i64 %r3737, i64* %ptr_s
  %r3738 = load i64, i64* %ptr_s
  %r3739 = getelementptr [43 x i8], [43 x i8]* @.str.1214, i64 0, i64 0
  %r3740 = ptrtoint i8* %r3739 to i64
  %r3741 = call i64 @_add(i64 %r3738, i64 %r3740)
  %r3742 = load i64, i64* %ptr_NL
  %r3743 = call i64 @_add(i64 %r3741, i64 %r3742)
  store i64 %r3743, i64* %ptr_s
  %r3744 = load i64, i64* %ptr_s
  %r3745 = getelementptr [44 x i8], [44 x i8]* @.str.1215, i64 0, i64 0
  %r3746 = ptrtoint i8* %r3745 to i64
  %r3747 = call i64 @_add(i64 %r3744, i64 %r3746)
  %r3748 = load i64, i64* %ptr_NL
  %r3749 = call i64 @_add(i64 %r3747, i64 %r3748)
  store i64 %r3749, i64* %ptr_s
  %r3750 = load i64, i64* %ptr_s
  %r3751 = getelementptr [24 x i8], [24 x i8]* @.str.1216, i64 0, i64 0
  %r3752 = ptrtoint i8* %r3751 to i64
  %r3753 = call i64 @_add(i64 %r3750, i64 %r3752)
  %r3754 = load i64, i64* %ptr_NL
  %r3755 = call i64 @_add(i64 %r3753, i64 %r3754)
  store i64 %r3755, i64* %ptr_s
  %r3756 = load i64, i64* %ptr_s
  %r3757 = getelementptr [23 x i8], [23 x i8]* @.str.1217, i64 0, i64 0
  %r3758 = ptrtoint i8* %r3757 to i64
  %r3759 = call i64 @_add(i64 %r3756, i64 %r3758)
  %r3760 = load i64, i64* %ptr_NL
  %r3761 = call i64 @_add(i64 %r3759, i64 %r3760)
  store i64 %r3761, i64* %ptr_s
  %r3762 = load i64, i64* %ptr_s
  %r3763 = getelementptr [23 x i8], [23 x i8]* @.str.1218, i64 0, i64 0
  %r3764 = ptrtoint i8* %r3763 to i64
  %r3765 = call i64 @_add(i64 %r3762, i64 %r3764)
  %r3766 = load i64, i64* %ptr_NL
  %r3767 = call i64 @_add(i64 %r3765, i64 %r3766)
  store i64 %r3767, i64* %ptr_s
  %r3768 = load i64, i64* %ptr_s
  %r3769 = getelementptr [17 x i8], [17 x i8]* @.str.1219, i64 0, i64 0
  %r3770 = ptrtoint i8* %r3769 to i64
  %r3771 = call i64 @_add(i64 %r3768, i64 %r3770)
  %r3772 = load i64, i64* %ptr_NL
  %r3773 = call i64 @_add(i64 %r3771, i64 %r3772)
  store i64 %r3773, i64* %ptr_s
  %r3774 = load i64, i64* %ptr_s
  %r3775 = getelementptr [20 x i8], [20 x i8]* @.str.1220, i64 0, i64 0
  %r3776 = ptrtoint i8* %r3775 to i64
  %r3777 = call i64 @_add(i64 %r3774, i64 %r3776)
  %r3778 = load i64, i64* %ptr_NL
  %r3779 = call i64 @_add(i64 %r3777, i64 %r3778)
  store i64 %r3779, i64* %ptr_s
  %r3780 = load i64, i64* %ptr_s
  %r3781 = getelementptr [2 x i8], [2 x i8]* @.str.1221, i64 0, i64 0
  %r3782 = ptrtoint i8* %r3781 to i64
  %r3783 = call i64 @_add(i64 %r3780, i64 %r3782)
  %r3784 = load i64, i64* %ptr_NL
  %r3785 = call i64 @_add(i64 %r3783, i64 %r3784)
  store i64 %r3785, i64* %ptr_s
  %r3786 = load i64, i64* %ptr_s
  %r3787 = getelementptr [42 x i8], [42 x i8]* @.str.1222, i64 0, i64 0
  %r3788 = ptrtoint i8* %r3787 to i64
  %r3789 = call i64 @_add(i64 %r3786, i64 %r3788)
  %r3790 = load i64, i64* %ptr_NL
  %r3791 = call i64 @_add(i64 %r3789, i64 %r3790)
  store i64 %r3791, i64* %ptr_s
  %r3792 = load i64, i64* %ptr_s
  %r3793 = getelementptr [37 x i8], [37 x i8]* @.str.1223, i64 0, i64 0
  %r3794 = ptrtoint i8* %r3793 to i64
  %r3795 = call i64 @_add(i64 %r3792, i64 %r3794)
  %r3796 = load i64, i64* %ptr_NL
  %r3797 = call i64 @_add(i64 %r3795, i64 %r3796)
  store i64 %r3797, i64* %ptr_s
  %r3798 = load i64, i64* %ptr_s
  %r3799 = getelementptr [49 x i8], [49 x i8]* @.str.1224, i64 0, i64 0
  %r3800 = ptrtoint i8* %r3799 to i64
  %r3801 = call i64 @_add(i64 %r3798, i64 %r3800)
  %r3802 = load i64, i64* %ptr_NL
  %r3803 = call i64 @_add(i64 %r3801, i64 %r3802)
  store i64 %r3803, i64* %ptr_s
  %r3804 = load i64, i64* %ptr_s
  %r3805 = getelementptr [41 x i8], [41 x i8]* @.str.1225, i64 0, i64 0
  %r3806 = ptrtoint i8* %r3805 to i64
  %r3807 = call i64 @_add(i64 %r3804, i64 %r3806)
  %r3808 = load i64, i64* %ptr_NL
  %r3809 = call i64 @_add(i64 %r3807, i64 %r3808)
  store i64 %r3809, i64* %ptr_s
  %r3810 = load i64, i64* %ptr_s
  %r3811 = getelementptr [16 x i8], [16 x i8]* @.str.1226, i64 0, i64 0
  %r3812 = ptrtoint i8* %r3811 to i64
  %r3813 = call i64 @_add(i64 %r3810, i64 %r3812)
  %r3814 = load i64, i64* %ptr_NL
  %r3815 = call i64 @_add(i64 %r3813, i64 %r3814)
  store i64 %r3815, i64* %ptr_s
  %r3816 = load i64, i64* %ptr_s
  %r3817 = getelementptr [2 x i8], [2 x i8]* @.str.1227, i64 0, i64 0
  %r3818 = ptrtoint i8* %r3817 to i64
  %r3819 = call i64 @_add(i64 %r3816, i64 %r3818)
  %r3820 = load i64, i64* %ptr_NL
  %r3821 = call i64 @_add(i64 %r3819, i64 %r3820)
  store i64 %r3821, i64* %ptr_s
  %r3822 = load i64, i64* %ptr_s
  ret i64 %r3822
  ret i64 0
}
define i64 @expand_imports(i64 %arg_stmts) {
  %ptr_stmts = alloca i64
  store i64 %arg_stmts, i64* %ptr_stmts
  %ptr_expanded = alloca i64
  %ptr_i = alloca i64
  %ptr_s = alloca i64
  %ptr_path = alloca i64
  %ptr_src = alloca i64
  %ptr_old_toks = alloca i64
  %ptr_old_pos = alloca i64
  %ptr_imp_stmts = alloca i64
  %ptr_sub_exp = alloca i64
  %ptr_j = alloca i64
  %r1 = call i64 @_list_new()
  store i64 %r1, i64* %ptr_expanded
  store i64 0, i64* %ptr_i
  br label %L925
L925:
  %r2 = load i64, i64* %ptr_i
  %r3 = load i64, i64* %ptr_stmts
  %r4 = call i64 @mensura(i64 %r3)
  %r6 = icmp slt i64 %r2, %r4
  %r5 = zext i1 %r6 to i64
  %r7 = icmp ne i64 %r5, 0
  br i1 %r7, label %L926, label %L927
L926:
  %r8 = load i64, i64* %ptr_stmts
  %r9 = load i64, i64* %ptr_i
  %r10 = call i64 @_get(i64 %r8, i64 %r9)
  store i64 %r10, i64* %ptr_s
  %r11 = load i64, i64* %ptr_s
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.1228, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  %r15 = load i64, i64* @STMT_IMPORT
  %r16 = call i64 @_eq(i64 %r14, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L928, label %L929
L928:
  %r18 = load i64, i64* %ptr_s
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.1229, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_get(i64 %r18, i64 %r20)
  %r22 = getelementptr [4 x i8], [4 x i8]* @.str.1230, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_get(i64 %r21, i64 %r23)
  store i64 %r24, i64* %ptr_path
  %r25 = load i64, i64* %ptr_path
  %r26 = call i64 @revelare(i64 %r25)
  store i64 %r26, i64* %ptr_src
  %r27 = load i64, i64* %ptr_src
  %r28 = call i64 @mensura(i64 %r27)
  %r30 = icmp sgt i64 %r28, 0
  %r29 = zext i1 %r30 to i64
  %r31 = icmp ne i64 %r29, 0
  br i1 %r31, label %L931, label %L932
L931:
  %r32 = load i64, i64* @global_tokens
  store i64 %r32, i64* %ptr_old_toks
  %r33 = load i64, i64* @p_pos
  store i64 %r33, i64* %ptr_old_pos
  %r34 = load i64, i64* %ptr_src
  %r35 = call i64 @lex_source(i64 %r34)
  store i64 %r35, i64* @global_tokens
  store i64 0, i64* @p_pos
  %r36 = call i64 @_list_new()
  store i64 %r36, i64* %ptr_imp_stmts
  br label %L934
L934:
  %r37 = call i64 @peek()
  %r38 = getelementptr [5 x i8], [5 x i8]* @.str.1231, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = call i64 @_get(i64 %r37, i64 %r39)
  %r42 = call i64 @_eq(i64 %r40, i64 0)
  %r41 = xor i64 %r42, 1
  %r43 = icmp ne i64 %r41, 0
  br i1 %r43, label %L935, label %L936
L935:
  %r44 = call i64 @peek()
  %r45 = getelementptr [5 x i8], [5 x i8]* @.str.1232, i64 0, i64 0
  %r46 = ptrtoint i8* %r45 to i64
  %r47 = call i64 @_get(i64 %r44, i64 %r46)
  %r48 = call i64 @_eq(i64 %r47, i64 29)
  %r49 = icmp ne i64 %r48, 0
  br i1 %r49, label %L937, label %L938
L937:
  %r50 = call i64 @advance()
  br label %L939
L938:
  %r51 = call i64 @parse_stmt()
  %r52 = load i64, i64* %ptr_imp_stmts
  call i64 @_append_poly(i64 %r52, i64 %r51)
  br label %L939
L939:
  br label %L934
L936:
  %r53 = load i64, i64* %ptr_imp_stmts
  %r54 = call i64 @expand_imports(i64 %r53)
  store i64 %r54, i64* %ptr_sub_exp
  store i64 0, i64* %ptr_j
  br label %L940
L940:
  %r55 = load i64, i64* %ptr_j
  %r56 = load i64, i64* %ptr_sub_exp
  %r57 = call i64 @mensura(i64 %r56)
  %r59 = icmp slt i64 %r55, %r57
  %r58 = zext i1 %r59 to i64
  %r60 = icmp ne i64 %r58, 0
  br i1 %r60, label %L941, label %L942
L941:
  %r61 = load i64, i64* %ptr_sub_exp
  %r62 = load i64, i64* %ptr_j
  %r63 = call i64 @_get(i64 %r61, i64 %r62)
  %r64 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r64, i64 %r63)
  %r65 = load i64, i64* %ptr_j
  %r66 = call i64 @_add(i64 %r65, i64 1)
  store i64 %r66, i64* %ptr_j
  br label %L940
L942:
  %r67 = load i64, i64* %ptr_old_toks
  store i64 %r67, i64* @global_tokens
  %r68 = load i64, i64* %ptr_old_pos
  store i64 %r68, i64* @p_pos
  br label %L933
L932:
  %r69 = getelementptr [41 x i8], [41 x i8]* @.str.1233, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_path
  %r72 = call i64 @_add(i64 %r70, i64 %r71)
  call i64 @print_any(i64 %r72)
  br label %L933
L933:
  br label %L930
L929:
  %r73 = load i64, i64* %ptr_s
  %r74 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r74, i64 %r73)
  br label %L930
L930:
  %r75 = load i64, i64* %ptr_i
  %r76 = call i64 @_add(i64 %r75, i64 1)
  store i64 %r76, i64* %ptr_i
  br label %L925
L927:
  %r77 = load i64, i64* %ptr_expanded
  ret i64 %r77
  ret i64 0
}
define i64 @achlys_main() {
  %ptr_arg = alloca i64
  %ptr_filename = alloca i64
  %ptr_valid = alloca i64
  %ptr_src = alloca i64
  %ptr_token_count = alloca i64
  %ptr_k = alloca i64
  %ptr_t = alloca i64
  %ptr_stmts = alloca i64
  %ptr_pt = alloca i64
  %ptr_flat_stmts = alloca i64
  %ptr_header = alloca i64
  %ptr_top_level = alloca i64
  %ptr_i = alloca i64
  %ptr_s = alloca i64
  %ptr_g_name = alloca i64
  %ptr_assign = alloca i64
  %ptr_NL = alloca i64
  %ptr_boot_msg = alloca i64
  %ptr_final_ir = alloca i64
  %r1 = getelementptr [44 x i8], [44 x i8]* @.str.1234, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  call i64 @print_any(i64 %r2)
  %r3 = call i64 @init_constants()
  %r4 = call i64 @_list_new()
  store i64 %r4, i64* @global_tokens
  store i64 0, i64* @p_pos
  %r5 = call i64 @_get_argv(i64 1)
  store i64 %r5, i64* %ptr_arg
  %r6 = getelementptr [1 x i8], [1 x i8]* @.str.1235, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* %ptr_filename
  store i64 1, i64* %ptr_valid
  %r8 = load i64, i64* %ptr_arg
  %r9 = call i64 @mensura(i64 %r8)
  %r10 = call i64 @_eq(i64 %r9, i64 0)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L943, label %L944
L943:
  %r12 = getelementptr [27 x i8], [27 x i8]* @.str.1236, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  call i64 @print_any(i64 %r13)
  store i64 0, i64* %ptr_valid
  br label %L945
L944:
  %r14 = load i64, i64* %ptr_arg
  store i64 %r14, i64* %ptr_filename
  br label %L945
L945:
  %r15 = load i64, i64* %ptr_valid
  %r16 = icmp ne i64 %r15, 0
  br i1 %r16, label %L946, label %L947
L946:
  %r17 = load i64, i64* %ptr_filename
  %r18 = call i64 @revelare(i64 %r17)
  store i64 %r18, i64* %ptr_src
  %r19 = load i64, i64* %ptr_src
  %r20 = call i64 @mensura(i64 %r19)
  %r21 = call i64 @_eq(i64 %r20, i64 0)
  %r22 = icmp ne i64 %r21, 0
  br i1 %r22, label %L949, label %L950
L949:
  %r23 = getelementptr [25 x i8], [25 x i8]* @.str.1237, i64 0, i64 0
  %r24 = ptrtoint i8* %r23 to i64
  %r25 = load i64, i64* %ptr_filename
  %r26 = call i64 @_add(i64 %r24, i64 %r25)
  call i64 @print_any(i64 %r26)
  br label %L951
L950:
  %r27 = getelementptr [16 x i8], [16 x i8]* @.str.1238, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  call i64 @print_any(i64 %r28)
  %r29 = load i64, i64* %ptr_src
  %r30 = call i64 @lex_source(i64 %r29)
  store i64 %r30, i64* @global_tokens
  %r31 = load i64, i64* @global_tokens
  %r32 = call i64 @mensura(i64 %r31)
  store i64 %r32, i64* %ptr_token_count
  %r33 = getelementptr [19 x i8], [19 x i8]* @.str.1239, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = load i64, i64* %ptr_token_count
  %r36 = call i64 @int_to_str(i64 %r35)
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  %r38 = getelementptr [9 x i8], [9 x i8]* @.str.1240, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = call i64 @_add(i64 %r37, i64 %r39)
  call i64 @print_any(i64 %r40)
  store i64 0, i64* %ptr_k
  br label %L952
L952:
  %r41 = load i64, i64* %ptr_k
  %r42 = load i64, i64* %ptr_token_count
  %r44 = icmp slt i64 %r41, %r42
  %r43 = zext i1 %r44 to i64
  %r45 = icmp ne i64 %r43, 0
  br i1 %r45, label %L953, label %L954
L953:
  %r46 = load i64, i64* @global_tokens
  %r47 = load i64, i64* %ptr_k
  %r48 = call i64 @_get(i64 %r46, i64 %r47)
  store i64 %r48, i64* %ptr_t
  %r49 = getelementptr [4 x i8], [4 x i8]* @.str.1241, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = load i64, i64* %ptr_k
  %r52 = call i64 @int_to_str(i64 %r51)
  %r53 = call i64 @_add(i64 %r50, i64 %r52)
  %r54 = getelementptr [4 x i8], [4 x i8]* @.str.1242, i64 0, i64 0
  %r55 = ptrtoint i8* %r54 to i64
  %r56 = call i64 @_add(i64 %r53, i64 %r55)
  %r57 = load i64, i64* %ptr_t
  %r58 = getelementptr [5 x i8], [5 x i8]* @.str.1243, i64 0, i64 0
  %r59 = ptrtoint i8* %r58 to i64
  %r60 = call i64 @_get(i64 %r57, i64 %r59)
  %r61 = call i64 @_add(i64 %r56, i64 %r60)
  %r62 = getelementptr [3 x i8], [3 x i8]* @.str.1244, i64 0, i64 0
  %r63 = ptrtoint i8* %r62 to i64
  %r64 = call i64 @_add(i64 %r61, i64 %r63)
  %r65 = load i64, i64* %ptr_t
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.1245, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = call i64 @_get(i64 %r65, i64 %r67)
  %r69 = call i64 @int_to_str(i64 %r68)
  %r70 = call i64 @_add(i64 %r64, i64 %r69)
  %r71 = getelementptr [2 x i8], [2 x i8]* @.str.1246, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  call i64 @print_any(i64 %r73)
  %r74 = load i64, i64* %ptr_k
  %r75 = call i64 @_add(i64 %r74, i64 1)
  store i64 %r75, i64* %ptr_k
  br label %L952
L954:
  %r76 = getelementptr [17 x i8], [17 x i8]* @.str.1247, i64 0, i64 0
  %r77 = ptrtoint i8* %r76 to i64
  call i64 @print_any(i64 %r77)
  store i64 1, i64* @use_huge_lists
  %r78 = call i64 @_list_new()
  store i64 %r78, i64* %ptr_stmts
  store i64 0, i64* @use_huge_lists
  %r79 = call i64 @peek()
  store i64 %r79, i64* %ptr_pt
  br label %L955
L955:
  %r80 = load i64, i64* %ptr_pt
  %r81 = getelementptr [5 x i8], [5 x i8]* @.str.1248, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_get(i64 %r80, i64 %r82)
  %r84 = load i64, i64* @TOK_EOF
  %r86 = call i64 @_eq(i64 %r83, i64 %r84)
  %r85 = xor i64 %r86, 1
  %r87 = icmp ne i64 %r85, 0
  br i1 %r87, label %L956, label %L957
L956:
  %r88 = load i64, i64* @has_error
  %r89 = icmp ne i64 %r88, 0
  br i1 %r89, label %L958, label %L959
L958:
  br label %L957
  br label %L960
L959:
  br label %L960
L960:
  %r90 = load i64, i64* %ptr_pt
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.1249, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = load i64, i64* @TOK_CARET
  %r95 = call i64 @_eq(i64 %r93, i64 %r94)
  %r96 = icmp ne i64 %r95, 0
  br i1 %r96, label %L961, label %L962
L961:
  %r97 = call i64 @advance()
  br label %L955
  br label %L963
L962:
  br label %L963
L963:
  %r98 = call i64 @parse_stmt()
  %r99 = load i64, i64* %ptr_stmts
  call i64 @_append_poly(i64 %r99, i64 %r98)
  %r100 = call i64 @peek()
  store i64 %r100, i64* %ptr_pt
  br label %L955
L957:
  %r101 = load i64, i64* %ptr_stmts
  %r102 = call i64 @expand_imports(i64 %r101)
  store i64 %r102, i64* %ptr_flat_stmts
  %r103 = load i64, i64* @has_error
  %r104 = icmp ne i64 %r103, 0
  br i1 %r104, label %L964, label %L965
L964:
  %r105 = getelementptr [24 x i8], [24 x i8]* @.str.1250, i64 0, i64 0
  %r106 = ptrtoint i8* %r105 to i64
  call i64 @print_any(i64 %r106)
  br label %L966
L965:
  %r107 = getelementptr [28 x i8], [28 x i8]* @.str.1251, i64 0, i64 0
  %r108 = ptrtoint i8* %r107 to i64
  call i64 @print_any(i64 %r108)
  %r109 = call i64 @get_llvm_header()
  store i64 %r109, i64* %ptr_header
  %r110 = call i64 @_list_new()
  store i64 %r110, i64* %ptr_top_level
  store i64 0, i64* %ptr_i
  br label %L967
L967:
  %r111 = load i64, i64* %ptr_i
  %r112 = load i64, i64* %ptr_flat_stmts
  %r113 = call i64 @mensura(i64 %r112)
  %r115 = icmp slt i64 %r111, %r113
  %r114 = zext i1 %r115 to i64
  %r116 = icmp ne i64 %r114, 0
  br i1 %r116, label %L968, label %L969
L968:
  %r117 = load i64, i64* %ptr_flat_stmts
  %r118 = load i64, i64* %ptr_i
  %r119 = call i64 @_get(i64 %r117, i64 %r118)
  store i64 %r119, i64* %ptr_s
  %r120 = load i64, i64* %ptr_s
  %r121 = getelementptr [5 x i8], [5 x i8]* @.str.1252, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = call i64 @_get(i64 %r120, i64 %r122)
  %r124 = load i64, i64* @STMT_FUNC
  %r125 = call i64 @_eq(i64 %r123, i64 %r124)
  %r126 = icmp ne i64 %r125, 0
  br i1 %r126, label %L970, label %L971
L970:
  %r127 = load i64, i64* %ptr_s
  %r128 = call i64 @compile_func(i64 %r127)
  br label %L972
L971:
  %r129 = load i64, i64* %ptr_s
  %r130 = getelementptr [5 x i8], [5 x i8]* @.str.1253, i64 0, i64 0
  %r131 = ptrtoint i8* %r130 to i64
  %r132 = call i64 @_get(i64 %r129, i64 %r131)
  %r133 = load i64, i64* @STMT_SHARED
  %r134 = call i64 @_eq(i64 %r132, i64 %r133)
  %r135 = load i64, i64* %ptr_s
  %r136 = getelementptr [5 x i8], [5 x i8]* @.str.1254, i64 0, i64 0
  %r137 = ptrtoint i8* %r136 to i64
  %r138 = call i64 @_get(i64 %r135, i64 %r137)
  %r139 = load i64, i64* @STMT_CONST
  %r140 = call i64 @_eq(i64 %r138, i64 %r139)
  %r141 = or i64 %r134, %r140
  %r142 = icmp ne i64 %r141, 0
  br i1 %r142, label %L973, label %L974
L973:
  %r143 = getelementptr [2 x i8], [2 x i8]* @.str.1255, i64 0, i64 0
  %r144 = ptrtoint i8* %r143 to i64
  %r145 = load i64, i64* %ptr_s
  %r146 = getelementptr [5 x i8], [5 x i8]* @.str.1256, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = call i64 @_get(i64 %r145, i64 %r147)
  %r149 = call i64 @_add(i64 %r144, i64 %r148)
  store i64 %r149, i64* %ptr_g_name
  %r150 = load i64, i64* @out_data
  %r151 = load i64, i64* %ptr_g_name
  %r152 = call i64 @_add(i64 %r150, i64 %r151)
  %r153 = getelementptr [16 x i8], [16 x i8]* @.str.1257, i64 0, i64 0
  %r154 = ptrtoint i8* %r153 to i64
  %r155 = call i64 @_add(i64 %r152, i64 %r154)
  %r156 = call i64 @signum_ex(i64 10)
  %r157 = call i64 @_add(i64 %r155, i64 %r156)
  store i64 %r157, i64* @out_data
  %r158 = load i64, i64* %ptr_g_name
  %r159 = load i64, i64* %ptr_s
  %r160 = getelementptr [5 x i8], [5 x i8]* @.str.1258, i64 0, i64 0
  %r161 = ptrtoint i8* %r160 to i64
  %r162 = call i64 @_get(i64 %r159, i64 %r161)
  %r163 = load i64, i64* @global_map
  call i64 @_set(i64 %r163, i64 %r162, i64 %r158)
  %r164 = call i64 @_map_new()
  %r165 = getelementptr [5 x i8], [5 x i8]* @.str.1259, i64 0, i64 0
  %r166 = ptrtoint i8* %r165 to i64
  %r167 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r164, i64 %r166, i64 %r167)
  %r168 = getelementptr [5 x i8], [5 x i8]* @.str.1260, i64 0, i64 0
  %r169 = ptrtoint i8* %r168 to i64
  %r170 = load i64, i64* %ptr_s
  %r171 = getelementptr [5 x i8], [5 x i8]* @.str.1261, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_get(i64 %r170, i64 %r172)
  call i64 @_map_set(i64 %r164, i64 %r169, i64 %r173)
  %r174 = getelementptr [4 x i8], [4 x i8]* @.str.1262, i64 0, i64 0
  %r175 = ptrtoint i8* %r174 to i64
  %r176 = load i64, i64* %ptr_s
  %r177 = getelementptr [4 x i8], [4 x i8]* @.str.1263, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = call i64 @_get(i64 %r176, i64 %r178)
  call i64 @_map_set(i64 %r164, i64 %r175, i64 %r179)
  store i64 %r164, i64* %ptr_assign
  %r180 = load i64, i64* %ptr_assign
  %r181 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r181, i64 %r180)
  br label %L975
L974:
  %r182 = load i64, i64* %ptr_s
  %r183 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r183, i64 %r182)
  br label %L975
L975:
  br label %L972
L972:
  %r184 = load i64, i64* %ptr_i
  %r185 = call i64 @_add(i64 %r184, i64 1)
  store i64 %r185, i64* %ptr_i
  br label %L967
L969:
  %r186 = call i64 @signum_ex(i64 10)
  store i64 %r186, i64* %ptr_NL
  %r187 = getelementptr [42 x i8], [42 x i8]* @.str.1264, i64 0, i64 0
  %r188 = ptrtoint i8* %r187 to i64
  %r189 = call i64 @emit_raw(i64 %r188)
  %r190 = getelementptr [36 x i8], [36 x i8]* @.str.1265, i64 0, i64 0
  %r191 = ptrtoint i8* %r190 to i64
  %r192 = call i64 @emit_raw(i64 %r191)
  %r193 = getelementptr [38 x i8], [38 x i8]* @.str.1266, i64 0, i64 0
  %r194 = ptrtoint i8* %r193 to i64
  %r195 = call i64 @emit_raw(i64 %r194)
  %r196 = getelementptr [16 x i8], [16 x i8]* @.str.1267, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = call i64 @add_global_string(i64 %r197)
  store i64 %r198, i64* %ptr_boot_msg
  %r199 = getelementptr [55 x i8], [55 x i8]* @.str.1268, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = load i64, i64* %ptr_boot_msg
  %r202 = call i64 @_add(i64 %r200, i64 %r201)
  %r203 = getelementptr [15 x i8], [15 x i8]* @.str.1269, i64 0, i64 0
  %r204 = ptrtoint i8* %r203 to i64
  %r205 = call i64 @_add(i64 %r202, i64 %r204)
  %r206 = call i64 @emit_raw(i64 %r205)
  %r207 = getelementptr [52 x i8], [52 x i8]* @.str.1270, i64 0, i64 0
  %r208 = ptrtoint i8* %r207 to i64
  %r209 = call i64 @emit_raw(i64 %r208)
  %r210 = getelementptr [41 x i8], [41 x i8]* @.str.1271, i64 0, i64 0
  %r211 = ptrtoint i8* %r210 to i64
  %r212 = call i64 @emit_raw(i64 %r211)
  store i64 0, i64* @reg_count
  %r213 = call i64 @_map_new()
  store i64 %r213, i64* @var_map
  %r214 = getelementptr [31 x i8], [31 x i8]* @.str.1272, i64 0, i64 0
  %r215 = ptrtoint i8* %r214 to i64
  %r216 = load i64, i64* %ptr_top_level
  %r217 = call i64 @mensura(i64 %r216)
  %r218 = call i64 @int_to_str(i64 %r217)
  %r219 = call i64 @_add(i64 %r215, i64 %r218)
  call i64 @print_any(i64 %r219)
  store i64 0, i64* %ptr_i
  br label %L976
L976:
  %r220 = load i64, i64* %ptr_i
  %r221 = load i64, i64* %ptr_top_level
  %r222 = call i64 @mensura(i64 %r221)
  %r224 = icmp slt i64 %r220, %r222
  %r223 = zext i1 %r224 to i64
  %r225 = icmp ne i64 %r223, 0
  br i1 %r225, label %L977, label %L978
L977:
  %r226 = load i64, i64* %ptr_top_level
  %r227 = load i64, i64* %ptr_i
  %r228 = call i64 @_get(i64 %r226, i64 %r227)
  %r229 = call i64 @compile_stmt(i64 %r228)
  %r230 = load i64, i64* %ptr_i
  %r231 = call i64 @_add(i64 %r230, i64 1)
  store i64 %r231, i64* %ptr_i
  br label %L976
L978:
  %r232 = getelementptr [10 x i8], [10 x i8]* @.str.1273, i64 0, i64 0
  %r233 = ptrtoint i8* %r232 to i64
  %r234 = call i64 @emit(i64 %r233)
  %r235 = getelementptr [2 x i8], [2 x i8]* @.str.1274, i64 0, i64 0
  %r236 = ptrtoint i8* %r235 to i64
  %r237 = call i64 @emit_raw(i64 %r236)
  %r238 = load i64, i64* %ptr_header
  %r239 = load i64, i64* @out_data
  %r240 = call i64 @_add(i64 %r238, i64 %r239)
  %r241 = load i64, i64* @out_code
  %r242 = call i64 @_add(i64 %r240, i64 %r241)
  store i64 %r242, i64* %ptr_final_ir
  %r243 = getelementptr [10 x i8], [10 x i8]* @.str.1275, i64 0, i64 0
  %r244 = ptrtoint i8* %r243 to i64
  %r245 = load i64, i64* %ptr_final_ir
  %r246 = call i64 @inscribo(i64 %r244, i64 %r245)
  %r247 = getelementptr [36 x i8], [36 x i8]* @.str.1276, i64 0, i64 0
  %r248 = ptrtoint i8* %r247 to i64
  call i64 @print_any(i64 %r248)
  br label %L966
L966:
  br label %L951
L951:
  br label %L948
L947:
  br label %L948
L948:
  ret i64 0
}
define i32 @main(i32 %argc, i8** %argv) {
  store i32 %argc, i32* @__sys_argc
  store i8** %argv, i8*** @__sys_argv
  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* @.str.1277, i64 0, i64 0
  %boot_msg_int = ptrtoint i8* %boot_msg_ptr to i64
  call i64 @print_any(i64 %boot_msg_int)
  store i64 0, i64* @TOK_EOF
  store i64 1, i64* @TOK_INT
  store i64 2, i64* @TOK_FLOAT
  store i64 3, i64* @TOK_STRING
  store i64 4, i64* @TOK_IDENT
  store i64 5, i64* @TOK_LET
  store i64 6, i64* @TOK_PRINT
  store i64 7, i64* @TOK_IF
  store i64 8, i64* @TOK_ELSE
  store i64 9, i64* @TOK_WHILE
  store i64 10, i64* @TOK_OPUS
  store i64 11, i64* @TOK_REDDO
  store i64 12, i64* @TOK_BREAK
  store i64 13, i64* @TOK_CONTINUE
  store i64 20, i64* @TOK_IMPORT
  store i64 21, i64* @TOK_LPAREN
  store i64 22, i64* @TOK_RPAREN
  store i64 23, i64* @TOK_LBRACE
  store i64 24, i64* @TOK_RBRACE
  store i64 25, i64* @TOK_LBRACKET
  store i64 26, i64* @TOK_RBRACKET
  store i64 27, i64* @TOK_COLON
  store i64 28, i64* @TOK_ARROW
  store i64 29, i64* @TOK_CARET
  store i64 30, i64* @TOK_DOT
  store i64 31, i64* @TOK_APPEND
  store i64 32, i64* @TOK_EXTRACT
  store i64 33, i64* @TOK_AND
  store i64 34, i64* @TOK_OR
  store i64 35, i64* @TOK_CONST
  store i64 36, i64* @TOK_SHARED
  store i64 37, i64* @TOK_OP
  store i64 38, i64* @TOK_COMMA
  store i64 100, i64* @EXPR_INT
  store i64 101, i64* @EXPR_FLOAT
  store i64 102, i64* @EXPR_STRING
  store i64 103, i64* @EXPR_VAR
  store i64 104, i64* @EXPR_LIST
  store i64 105, i64* @EXPR_MAP
  store i64 106, i64* @EXPR_BINARY
  store i64 107, i64* @EXPR_INDEX
  store i64 108, i64* @EXPR_GET
  store i64 109, i64* @EXPR_CALL
  store i64 110, i64* @EXPR_INPUT
  store i64 111, i64* @EXPR_READ
  store i64 112, i64* @EXPR_MEASURE
  store i64 200, i64* @STMT_LET
  store i64 201, i64* @STMT_ASSIGN
  store i64 202, i64* @STMT_SET
  store i64 203, i64* @STMT_SET_INDEX
  store i64 204, i64* @STMT_APPEND
  store i64 205, i64* @STMT_EXTRACT
  store i64 206, i64* @STMT_PRINT
  store i64 207, i64* @STMT_IF
  store i64 208, i64* @STMT_WHILE
  store i64 209, i64* @STMT_FUNC
  store i64 210, i64* @STMT_RETURN
  store i64 211, i64* @STMT_IMPORT
  store i64 212, i64* @STMT_BREAK
  store i64 213, i64* @STMT_CONTINUE
  store i64 214, i64* @STMT_EXPR
  store i64 215, i64* @STMT_CONST
  store i64 216, i64* @STMT_SHARED
  store i64 0, i64* @VAL_INT
  store i64 1, i64* @VAL_FLOAT
  store i64 2, i64* @VAL_STRING
  store i64 3, i64* @VAL_LIST
  store i64 4, i64* @VAL_MAP
  store i64 5, i64* @VAL_FUNC
  store i64 6, i64* @VAL_VOID
  %r1 = call i64 @_list_new()
  store i64 %r1, i64* @global_tokens
  store i64 0, i64* @p_pos
  store i64 0, i64* @has_error
  store i64 0, i64* @use_huge_lists
  %r2 = call i64 @_list_new()
  store i64 %r2, i64* @str_table
  %r3 = call i64 @_map_new()
  store i64 %r3, i64* @stack_map
  store i64 0, i64* @stack_offset
  store i64 0, i64* @lbl_counter
  %r4 = getelementptr [1 x i8], [1 x i8]* @.str.1278, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  store i64 %r5, i64* @asm_main
  %r6 = getelementptr [1 x i8], [1 x i8]* @.str.1279, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* @asm_funcs
  store i64 0, i64* @in_func
  %r8 = call i64 @_list_new()
  store i64 %r8, i64* @local_vars
  store i64 0, i64* @stack_depth
  store i64 0, i64* @reg_count
  store i64 0, i64* @str_count
  store i64 0, i64* @label_count
  %r9 = getelementptr [1 x i8], [1 x i8]* @.str.1280, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  store i64 %r10, i64* @out_code
  %r11 = getelementptr [1 x i8], [1 x i8]* @.str.1281, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  store i64 %r12, i64* @out_data
  %r13 = call i64 @_map_new()
  store i64 %r13, i64* @var_map
  %r14 = call i64 @_map_new()
  store i64 %r14, i64* @global_map
  %r15 = call i64 @_list_new()
  store i64 %r15, i64* @loop_cond_stack
  %r16 = call i64 @_list_new()
  store i64 %r16, i64* @loop_end_stack
  %r17 = call i64 @achlys_main()
  ret i32 0
}
