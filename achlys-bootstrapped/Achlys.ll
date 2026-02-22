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
  %mem = call i64 @malloc(i64 4096)
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
  %limit = icmp slt i64 %next_i, 4095
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
  %ptr = inttoptr i64 %str to i8*
  br label %loop
loop:
  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]
  %acc = phi i64 [ 0, %0 ], [ %next_acc, %body ]
  %char_ptr = getelementptr i8, i8* %ptr, i64 %i
  %c = load i8, i8* %char_ptr
  %is_null = icmp eq i8 %c, 0
  br i1 %is_null, label %done, label %body
body:
  %c_ext = zext i8 %c to i64
  %digit = sub i64 %c_ext, 48
  %mul10 = mul i64 %acc, 10
  %next_acc = add i64 %mul10, %digit
  %next_i = add i64 %i, 1
  br label %loop
done:
  ret i64 %acc
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
@.str.16 = private unnamed_addr constant [11 x i8] c"Achlys.nox\00", align 8
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
@.str.234 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.235 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.236 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.237 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.238 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.239 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.240 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.241 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.242 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.243 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.244 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.245 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.246 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.247 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.248 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.249 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.250 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.251 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.252 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.253 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.254 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.255 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.256 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.257 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.258 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.259 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.260 = private unnamed_addr constant [15 x i8] c"Unexpected EOF\00", align 8
@.str.261 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.262 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.263 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.264 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.265 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.266 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.267 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.268 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.269 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.270 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.271 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.272 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.273 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.274 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.275 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.276 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.277 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.278 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.279 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.280 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.281 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.282 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.283 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.284 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.285 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@reg_count = global i64 0
@str_count = global i64 0
@label_count = global i64 0
@out_code = global i64 0
@out_data = global i64 0
@var_map = global i64 0
@global_map = global i64 0
@loop_cond_stack = global i64 0
@loop_end_stack = global i64 0
@block_terminated = global i64 0
@.str.286 = private unnamed_addr constant [3 x i8] c"%r\00", align 8
@.str.287 = private unnamed_addr constant [2 x i8] c"L\00", align 8
@.str.288 = private unnamed_addr constant [3 x i8] c"  \00", align 8
@.str.289 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.290 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.291 = private unnamed_addr constant [4 x i8] c"\5C22\00", align 8
@.str.292 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.293 = private unnamed_addr constant [4 x i8] c"\5C5C\00", align 8
@.str.294 = private unnamed_addr constant [4 x i8] c"\5C0A\00", align 8
@.str.295 = private unnamed_addr constant [7 x i8] c"@.str.\00", align 8
@.str.296 = private unnamed_addr constant [35 x i8] c" = private unnamed_addr constant [\00", align 8
@.str.297 = private unnamed_addr constant [10 x i8] c" x i8] c\22\00", align 8
@.str.298 = private unnamed_addr constant [14 x i8] c"\5C00\22, align 8\00", align 8
@.str.299 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.300 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.301 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.302 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.303 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.304 = private unnamed_addr constant [33 x i8] c"💀 FATAL: Undefined variable '\00", align 8
@.str.305 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.306 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.307 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.308 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.309 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.310 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.311 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.312 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.313 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.314 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.315 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.316 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.317 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.318 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.319 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.320 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.321 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.322 = private unnamed_addr constant [2 x i8] c"+\00", align 8
@.str.323 = private unnamed_addr constant [23 x i8] c" = call i64 @_add(i64 \00", align 8
@.str.324 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.325 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.326 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.327 = private unnamed_addr constant [12 x i8] c" = sub i64 \00", align 8
@.str.328 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.329 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.330 = private unnamed_addr constant [12 x i8] c" = mul i64 \00", align 8
@.str.331 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.332 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.333 = private unnamed_addr constant [13 x i8] c" = sdiv i64 \00", align 8
@.str.334 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.335 = private unnamed_addr constant [2 x i8] c"%\00", align 8
@.str.336 = private unnamed_addr constant [13 x i8] c" = srem i64 \00", align 8
@.str.337 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.338 = private unnamed_addr constant [2 x i8] c"&\00", align 8
@.str.339 = private unnamed_addr constant [12 x i8] c" = and i64 \00", align 8
@.str.340 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.341 = private unnamed_addr constant [2 x i8] c"|\00", align 8
@.str.342 = private unnamed_addr constant [11 x i8] c" = or i64 \00", align 8
@.str.343 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.344 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.345 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.346 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.347 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.348 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.349 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.350 = private unnamed_addr constant [2 x i8] c"~\00", align 8
@.str.351 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.352 = private unnamed_addr constant [5 x i8] c", -1\00", align 8
@.str.353 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.354 = private unnamed_addr constant [12 x i8] c" = shl i64 \00", align 8
@.str.355 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.356 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.357 = private unnamed_addr constant [13 x i8] c" = lshr i64 \00", align 8
@.str.358 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.359 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.360 = private unnamed_addr constant [12 x i8] c" = and i64 \00", align 8
@.str.361 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.362 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.363 = private unnamed_addr constant [11 x i8] c" = or i64 \00", align 8
@.str.364 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.365 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.366 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.367 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.368 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.369 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.370 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.371 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.372 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.373 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.374 = private unnamed_addr constant [4 x i8] c", 1\00", align 8
@.str.375 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.376 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.377 = private unnamed_addr constant [4 x i8] c"slt\00", align 8
@.str.378 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.379 = private unnamed_addr constant [4 x i8] c"sgt\00", align 8
@.str.380 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.381 = private unnamed_addr constant [4 x i8] c"sle\00", align 8
@.str.382 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.383 = private unnamed_addr constant [4 x i8] c"sge\00", align 8
@.str.384 = private unnamed_addr constant [9 x i8] c" = icmp \00", align 8
@.str.385 = private unnamed_addr constant [6 x i8] c" i64 \00", align 8
@.str.386 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.387 = private unnamed_addr constant [12 x i8] c" = zext i1 \00", align 8
@.str.388 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.389 = private unnamed_addr constant [16 x i8] c" = add i64 0, 0\00", align 8
@.str.390 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.391 = private unnamed_addr constant [25 x i8] c" = call i64 @_list_new()\00", align 8
@.str.392 = private unnamed_addr constant [6 x i8] c"items\00", align 8
@.str.393 = private unnamed_addr constant [26 x i8] c"call i64 @_list_push(i64 \00", align 8
@.str.394 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.395 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.396 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.397 = private unnamed_addr constant [24 x i8] c" = call i64 @_map_new()\00", align 8
@.str.398 = private unnamed_addr constant [5 x i8] c"keys\00", align 8
@.str.399 = private unnamed_addr constant [5 x i8] c"vals\00", align 8
@.str.400 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.401 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.402 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.403 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.404 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.405 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.406 = private unnamed_addr constant [24 x i8] c"call i64 @_map_set(i64 \00", align 8
@.str.407 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.408 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.409 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.410 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.411 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.412 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.413 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.414 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.415 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.416 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.417 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.418 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.419 = private unnamed_addr constant [23 x i8] c" = call i64 @_get(i64 \00", align 8
@.str.420 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.421 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.422 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.423 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.424 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.425 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.426 = private unnamed_addr constant [4 x i8] c"sys\00", align 8
@.str.427 = private unnamed_addr constant [9 x i8] c"imperium\00", align 8
@.str.428 = private unnamed_addr constant [9 x i8] c"scrutari\00", align 8
@.str.429 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.430 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.431 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.432 = private unnamed_addr constant [17 x i8] c" = load i8, ptr \00", align 8
@.str.433 = private unnamed_addr constant [12 x i8] c" = zext i8 \00", align 8
@.str.434 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.435 = private unnamed_addr constant [11 x i8] c"mutare_mem\00", align 8
@.str.436 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.437 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.438 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.439 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.440 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.441 = private unnamed_addr constant [7 x i8] c" to i8\00", align 8
@.str.442 = private unnamed_addr constant [10 x i8] c"store i8 \00", align 8
@.str.443 = private unnamed_addr constant [7 x i8] c", ptr \00", align 8
@.str.444 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.445 = private unnamed_addr constant [10 x i8] c"alloc_mem\00", align 8
@.str.446 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.447 = private unnamed_addr constant [25 x i8] c" = call i64 @malloc(i64 \00", align 8
@.str.448 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.449 = private unnamed_addr constant [8 x i8] c"ptr_add\00", align 8
@.str.450 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.451 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.452 = private unnamed_addr constant [12 x i8] c" = add i64 \00", align 8
@.str.453 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.454 = private unnamed_addr constant [16 x i8] c"imperium_kernel\00", align 8
@.str.455 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.456 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.457 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.458 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.459 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.460 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.461 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.462 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.463 = private unnamed_addr constant [27 x i8] c" = call i64 @syscall6(i64 \00", align 8
@.str.464 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.465 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.466 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.467 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.468 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.469 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.470 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.471 = private unnamed_addr constant [18 x i8] c"capere_argumentum\00", align 8
@.str.472 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.473 = private unnamed_addr constant [28 x i8] c" = call i64 @_get_argv(i64 \00", align 8
@.str.474 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.475 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.476 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.477 = private unnamed_addr constant [5 x i8] c"i64 \00", align 8
@.str.478 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.479 = private unnamed_addr constant [7 x i8] c"scribo\00", align 8
@.str.480 = private unnamed_addr constant [28 x i8] c" = call i64 @print_any(i64 \00", align 8
@.str.481 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.482 = private unnamed_addr constant [14 x i8] c" = call i64 @\00", align 8
@.str.483 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.484 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.485 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.486 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.487 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.488 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.489 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.490 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.491 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.492 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.493 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.494 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.495 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.496 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.497 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.498 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.499 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.500 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.501 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.502 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.503 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.504 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.505 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.506 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.507 = private unnamed_addr constant [46 x i8] c"💀 FATAL: Index set on undefined variable '\00", align 8
@.str.508 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.509 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.510 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.511 = private unnamed_addr constant [20 x i8] c"call i64 @_set(i64 \00", align 8
@.str.512 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.513 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.514 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.515 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.516 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.517 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.518 = private unnamed_addr constant [47 x i8] c"💀 FATAL: Assignment to undefined variable '\00", align 8
@.str.519 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.520 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.521 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.522 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.523 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.524 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.525 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.526 = private unnamed_addr constant [43 x i8] c"💀 FATAL: Append to undefined variable '\00", align 8
@.str.527 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.528 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.529 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.530 = private unnamed_addr constant [28 x i8] c"call i64 @_append_poly(i64 \00", align 8
@.str.531 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.532 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.533 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.534 = private unnamed_addr constant [29 x i8] c"[DEBUG] Compiling STMT_PRINT\00", align 8
@.str.535 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.536 = private unnamed_addr constant [25 x i8] c"call i64 @print_any(i64 \00", align 8
@.str.537 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.538 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.539 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.540 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.541 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.542 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.543 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.544 = private unnamed_addr constant [9 x i8] c"ret i64 \00", align 8
@.str.545 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.546 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.547 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.548 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.549 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.550 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.551 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.552 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.553 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.554 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.555 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.556 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.557 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.558 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.559 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.560 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.561 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.562 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.563 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.564 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.565 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.566 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.567 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.568 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.569 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.570 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.571 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.572 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.573 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.574 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.575 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.576 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.577 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.578 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.579 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.580 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.581 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.582 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.583 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.584 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.585 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.586 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.587 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.588 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.589 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.590 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.591 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.592 = private unnamed_addr constant [13 x i8] c"define i64 @\00", align 8
@.str.593 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.594 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.595 = private unnamed_addr constant [10 x i8] c"i64 %arg_\00", align 8
@.str.596 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.597 = private unnamed_addr constant [4 x i8] c") {\00", align 8
@.str.598 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.599 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.600 = private unnamed_addr constant [16 x i8] c"store i64 %arg_\00", align 8
@.str.601 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.602 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.603 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.604 = private unnamed_addr constant [10 x i8] c"ret i64 0\00", align 8
@.str.605 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.606 = private unnamed_addr constant [29 x i8] c"; ModuleID = 'achlys_kernel'\00", align 8
@.str.607 = private unnamed_addr constant [20 x i8] c"x86_64-pc-linux-gnu\00", align 8
@.str.608 = private unnamed_addr constant [22 x i8] c"aarch64-linux-android\00", align 8
@.str.609 = private unnamed_addr constant [18 x i8] c"target triple = \22\00", align 8
@.str.610 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.611 = private unnamed_addr constant [30 x i8] c"declare i32 @printf(i8*, ...)\00", align 8
@.str.612 = private unnamed_addr constant [36 x i8] c"declare i32 @sprintf(i8*, i8*, ...)\00", align 8
@.str.613 = private unnamed_addr constant [25 x i8] c"declare i32 @fflush(i8*)\00", align 8
@.str.614 = private unnamed_addr constant [25 x i8] c"declare i64 @malloc(i64)\00", align 8
@.str.615 = private unnamed_addr constant [31 x i8] c"declare i8* @realloc(i8*, i64)\00", align 8
@.str.616 = private unnamed_addr constant [23 x i8] c"declare i32 @getchar()\00", align 8
@.str.617 = private unnamed_addr constant [24 x i8] c"declare void @exit(i32)\00", align 8
@.str.618 = private unnamed_addr constant [29 x i8] c"declare i8* @fopen(i8*, i8*)\00", align 8
@.str.619 = private unnamed_addr constant [34 x i8] c"declare i32 @fseek(i8*, i64, i32)\00", align 8
@.str.620 = private unnamed_addr constant [24 x i8] c"declare i64 @ftell(i8*)\00", align 8
@.str.621 = private unnamed_addr constant [39 x i8] c"declare i64 @fread(i8*, i64, i64, i8*)\00", align 8
@.str.622 = private unnamed_addr constant [40 x i8] c"declare i64 @fwrite(i8*, i64, i64, i8*)\00", align 8
@.str.623 = private unnamed_addr constant [25 x i8] c"declare i32 @fclose(i8*)\00", align 8
@.str.624 = private unnamed_addr constant [25 x i8] c"declare i32 @system(i8*)\00", align 8
@.str.625 = private unnamed_addr constant [25 x i8] c"declare i32 @usleep(i32)\00", align 8
@.str.626 = private unnamed_addr constant [30 x i8] c"declare i8* @strtok(i8*, i8*)\00", align 8
@.str.627 = private unnamed_addr constant [73 x i8] c"@.fmt_int = private unnamed_addr constant [5 x i8] c\22%ld\5C0A\5C00\22, align 8\00", align 8
@.str.628 = private unnamed_addr constant [72 x i8] c"@.fmt_str = private unnamed_addr constant [4 x i8] c\22%s\5C0A\5C00\22, align 8\00", align 8
@.str.629 = private unnamed_addr constant [71 x i8] c"@.fmt_raw_s = private unnamed_addr constant [3 x i8] c\22%s\5C00\22, align 8\00", align 8
@.str.630 = private unnamed_addr constant [72 x i8] c"@.fmt_raw_i = private unnamed_addr constant [4 x i8] c\22%ld\5C00\22, align 8\00", align 8
@.str.631 = private unnamed_addr constant [67 x i8] c"@.mode_r = private unnamed_addr constant [2 x i8] c\22r\5C00\22, align 8\00", align 8
@.str.632 = private unnamed_addr constant [67 x i8] c"@.mode_w = private unnamed_addr constant [2 x i8] c\22w\5C00\22, align 8\00", align 8
@.str.633 = private unnamed_addr constant [73 x i8] c"@.str_lst = private unnamed_addr constant [7 x i8] c\22<list>\5C00\22, align 8\00", align 8
@.str.634 = private unnamed_addr constant [72 x i8] c"@.str_map = private unnamed_addr constant [6 x i8] c\22<map>\5C00\22, align 8\00", align 8
@.str.635 = private unnamed_addr constant [40 x i8] c"@__sys_argv = global i8** null, align 8\00", align 8
@.str.636 = private unnamed_addr constant [36 x i8] c"@__sys_argc = global i32 0, align 8\00", align 8
@.str.637 = private unnamed_addr constant [68 x i8] c"@.m_brk_l = private unnamed_addr constant [2 x i8] c\22[\5C00\22, align 8\00", align 8
@.str.638 = private unnamed_addr constant [71 x i8] c"@.m_brk_r = private unnamed_addr constant [3 x i8] c\22]\5C0A\5C00\22, align 8\00", align 8
@.str.639 = private unnamed_addr constant [69 x i8] c"@.m_comma = private unnamed_addr constant [3 x i8] c\22, \5C00\22, align 8\00", align 8
@.str.640 = private unnamed_addr constant [39 x i8] c"define i64 @_str_cat(i64 %a, i64 %b) {\00", align 8
@.str.641 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.642 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.643 = private unnamed_addr constant [34 x i8] c"  %la = call i64 @strlen(i8* %sa)\00", align 8
@.str.644 = private unnamed_addr constant [34 x i8] c"  %lb = call i64 @strlen(i8* %sb)\00", align 8
@.str.645 = private unnamed_addr constant [25 x i8] c"  %sz = add i64 %la, %lb\00", align 8
@.str.646 = private unnamed_addr constant [24 x i8] c"  %sz1 = add i64 %sz, 1\00", align 8
@.str.647 = private unnamed_addr constant [36 x i8] c"  %mem = call i64 @malloc(i64 %sz1)\00", align 8
@.str.648 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.649 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %ptr, i8* %sa)\00", align 8
@.str.650 = private unnamed_addr constant [38 x i8] c"  call i8* @strcat(i8* %ptr, i8* %sb)\00", align 8
@.str.651 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.652 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.653 = private unnamed_addr constant [34 x i8] c"define i64 @to_string(i64 %val) {\00", align 8
@.str.654 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.655 = private unnamed_addr constant [46 x i8] c"  br i1 %is_ptr, label %is_str, label %is_int\00", align 8
@.str.656 = private unnamed_addr constant [21 x i8] c"is_str: ret i64 %val\00", align 8
@.str.657 = private unnamed_addr constant [8 x i8] c"is_int:\00", align 8
@.str.658 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 32)\00", align 8
@.str.659 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %mem to i8*\00", align 8
@.str.660 = private unnamed_addr constant [69 x i8] c"  %fmt = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0\00", align 8
@.str.661 = private unnamed_addr constant [64 x i8] c"  call i32 (i8*, i8*, ...) @sprintf(i8* %p, i8* %fmt, i64 %val)\00", align 8
@.str.662 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.663 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.664 = private unnamed_addr constant [35 x i8] c"define i64 @_add(i64 %a, i64 %b) {\00", align 8
@.str.665 = private unnamed_addr constant [42 x i8] c"  %is_ptr_a = icmp sgt i64 %a, 4294967296\00", align 8
@.str.666 = private unnamed_addr constant [42 x i8] c"  %is_ptr_b = icmp sgt i64 %b, 4294967296\00", align 8
@.str.667 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.668 = private unnamed_addr constant [40 x i8] c"  %any_ptr = or i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.669 = private unnamed_addr constant [55 x i8] c"  br i1 %both_ptr, label %check_list, label %check_str\00", align 8
@.str.670 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.671 = private unnamed_addr constant [34 x i8] c"  %ptr_a = inttoptr i64 %a to i8*\00", align 8
@.str.672 = private unnamed_addr constant [32 x i8] c"  %type_a = load i8, i8* %ptr_a\00", align 8
@.str.673 = private unnamed_addr constant [35 x i8] c"  %is_list = icmp eq i8 %type_a, 3\00", align 8
@.str.674 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_str\00", align 8
@.str.675 = private unnamed_addr constant [11 x i8] c"check_str:\00", align 8
@.str.676 = private unnamed_addr constant [44 x i8] c"  br i1 %any_ptr, label %do_str, label %int\00", align 8
@.str.677 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.678 = private unnamed_addr constant [36 x i8] c"  %sa = call i64 @to_string(i64 %a)\00", align 8
@.str.679 = private unnamed_addr constant [36 x i8] c"  %sb = call i64 @to_string(i64 %b)\00", align 8
@.str.680 = private unnamed_addr constant [50 x i8] c"  %ret_str = call i64 @_str_cat(i64 %sa, i64 %sb)\00", align 8
@.str.681 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.682 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.683 = private unnamed_addr constant [36 x i8] c"  %new_list = call i64 @_list_new()\00", align 8
@.str.684 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %a)\00", align 8
@.str.685 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %b)\00", align 8
@.str.686 = private unnamed_addr constant [20 x i8] c"  ret i64 %new_list\00", align 8
@.str.687 = private unnamed_addr constant [5 x i8] c"int:\00", align 8
@.str.688 = private unnamed_addr constant [28 x i8] c"  %ret_int = add i64 %a, %b\00", align 8
@.str.689 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.690 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.691 = private unnamed_addr constant [47 x i8] c"define void @_list_copy(i64 %dest, i64 %src) {\00", align 8
@.str.692 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %src to i64*\00", align 8
@.str.693 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.694 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.695 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.696 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.697 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.698 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.699 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.700 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]\00", align 8
@.str.701 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.702 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.703 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.704 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.705 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.706 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %dest, i64 %val)\00", align 8
@.str.707 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.708 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.709 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.710 = private unnamed_addr constant [11 x i8] c"  ret void\00", align 8
@.str.711 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.712 = private unnamed_addr constant [48 x i8] c"define i64 @_append_poly(i64 %list, i64 %val) {\00", align 8
@.str.713 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.714 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_list, label %push_one\00", align 8
@.str.715 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.716 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.717 = private unnamed_addr constant [28 x i8] c"  %type = load i8, i8* %ptr\00", align 8
@.str.718 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.719 = private unnamed_addr constant [48 x i8] c"  br i1 %is_list, label %merge, label %push_one\00", align 8
@.str.720 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.721 = private unnamed_addr constant [45 x i8] c"  call void @_list_copy(i64 %list, i64 %val)\00", align 8
@.str.722 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.723 = private unnamed_addr constant [10 x i8] c"push_one:\00", align 8
@.str.724 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %list, i64 %val)\00", align 8
@.str.725 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.726 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.727 = private unnamed_addr constant [34 x i8] c"define i64 @_eq(i64 %a, i64 %b) {\00", align 8
@.str.728 = private unnamed_addr constant [42 x i8] c"  %a_is_ptr = icmp sgt i64 %a, 4294967296\00", align 8
@.str.729 = private unnamed_addr constant [42 x i8] c"  %b_is_ptr = icmp sgt i64 %b, 4294967296\00", align 8
@.str.730 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %a_is_ptr, %b_is_ptr\00", align 8
@.str.731 = private unnamed_addr constant [53 x i8] c"  br i1 %both_ptr, label %check_null, label %cmp_int\00", align 8
@.str.732 = private unnamed_addr constant [12 x i8] c"check_null:\00", align 8
@.str.733 = private unnamed_addr constant [30 x i8] c"  %a_null = icmp eq i64 %a, 0\00", align 8
@.str.734 = private unnamed_addr constant [30 x i8] c"  %b_null = icmp eq i64 %b, 0\00", align 8
@.str.735 = private unnamed_addr constant [37 x i8] c"  %any_null = or i1 %a_null, %b_null\00", align 8
@.str.736 = private unnamed_addr constant [50 x i8] c"  br i1 %any_null, label %cmp_int, label %cmp_str\00", align 8
@.str.737 = private unnamed_addr constant [9 x i8] c"cmp_str:\00", align 8
@.str.738 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.739 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.740 = private unnamed_addr constant [44 x i8] c"  %res = call i32 @strcmp(i8* %sa, i8* %sb)\00", align 8
@.str.741 = private unnamed_addr constant [30 x i8] c"  %iseq = icmp eq i32 %res, 0\00", align 8
@.str.742 = private unnamed_addr constant [34 x i8] c"  %ret_str = zext i1 %iseq to i64\00", align 8
@.str.743 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.744 = private unnamed_addr constant [9 x i8] c"cmp_int:\00", align 8
@.str.745 = private unnamed_addr constant [33 x i8] c"  %iseq_int = icmp eq i64 %a, %b\00", align 8
@.str.746 = private unnamed_addr constant [38 x i8] c"  %ret_int = zext i1 %iseq_int to i64\00", align 8
@.str.747 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.748 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.749 = private unnamed_addr constant [26 x i8] c"define i64 @_list_new() {\00", align 8
@.str.750 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 24)\00", align 8
@.str.751 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %mem to i64*\00", align 8
@.str.752 = private unnamed_addr constant [25 x i8] c"  store i64 3, i64* %ptr\00", align 8
@.str.753 = private unnamed_addr constant [45 x i8] c"  %cnt = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.754 = private unnamed_addr constant [25 x i8] c"  store i64 0, i64* %cnt\00", align 8
@.str.755 = private unnamed_addr constant [46 x i8] c"  %data = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.756 = private unnamed_addr constant [26 x i8] c"  store i64 0, i64* %data\00", align 8
@.str.757 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.758 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.759 = private unnamed_addr constant [50 x i8] c"define i64 @_list_set(i64 %l, i64 %idx, i64 %v) {\00", align 8
@.str.760 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.761 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.762 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.763 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.764 = private unnamed_addr constant [54 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %idx\00", align 8
@.str.765 = private unnamed_addr constant [27 x i8] c"  store i64 %v, i64* %slot\00", align 8
@.str.766 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.767 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.768 = private unnamed_addr constant [41 x i8] c"define i64 @_list_push(i64 %l, i64 %v) {\00", align 8
@.str.769 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.770 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.771 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.772 = private unnamed_addr constant [29 x i8] c"  %new_cnt = add i64 %cnt, 1\00", align 8
@.str.773 = private unnamed_addr constant [36 x i8] c"  store i64 %new_cnt, i64* %cnt_ptr\00", align 8
@.str.774 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.775 = private unnamed_addr constant [40 x i8] c"  %old_mem_i = load i64, i64* %data_ptr\00", align 8
@.str.776 = private unnamed_addr constant [35 x i8] c"  %req_bytes = mul i64 %new_cnt, 8\00", align 8
@.str.777 = private unnamed_addr constant [44 x i8] c"  %old_ptr = inttoptr i64 %old_mem_i to i8*\00", align 8
@.str.778 = private unnamed_addr constant [61 x i8] c"  %new_ptr = call i8* @realloc(i8* %old_ptr, i64 %req_bytes)\00", align 8
@.str.779 = private unnamed_addr constant [42 x i8] c"  %new_mem = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.780 = private unnamed_addr constant [37 x i8] c"  store i64 %new_mem, i64* %data_ptr\00", align 8
@.str.781 = private unnamed_addr constant [44 x i8] c"  %base_ptr = inttoptr i64 %new_mem to i64*\00", align 8
@.str.782 = private unnamed_addr constant [53 x i8] c"  %idx = getelementptr i64, i64* %base_ptr, i64 %cnt\00", align 8
@.str.783 = private unnamed_addr constant [26 x i8] c"  store i64 %v, i64* %idx\00", align 8
@.str.784 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.785 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.786 = private unnamed_addr constant [25 x i8] c"define i64 @_map_new() {\00", align 8
@.str.787 = private unnamed_addr constant [29 x i8] c"  %m = call i64 @_list_new()\00", align 8
@.str.788 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.789 = private unnamed_addr constant [25 x i8] c"  store i64 4, i64* %ptr\00", align 8
@.str.790 = private unnamed_addr constant [13 x i8] c"  ret i64 %m\00", align 8
@.str.791 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.792 = private unnamed_addr constant [47 x i8] c"define i64 @_map_set(i64 %m, i64 %k, i64 %v) {\00", align 8
@.str.793 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %k)\00", align 8
@.str.794 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %v)\00", align 8
@.str.795 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.796 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.797 = private unnamed_addr constant [47 x i8] c"define i64 @_set(i64 %col, i64 %idx, i64 %v) {\00", align 8
@.str.798 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %col to i64*\00", align 8
@.str.799 = private unnamed_addr constant [30 x i8] c"  %type = load i64, i64* %ptr\00", align 8
@.str.800 = private unnamed_addr constant [33 x i8] c"  %is_map = icmp eq i64 %type, 4\00", align 8
@.str.801 = private unnamed_addr constant [47 x i8] c"  br i1 %is_map, label %do_map, label %do_list\00", align 8
@.str.802 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.803 = private unnamed_addr constant [50 x i8] c"  call i64 @_list_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.804 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.805 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.806 = private unnamed_addr constant [49 x i8] c"  call i64 @_map_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.807 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.808 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.809 = private unnamed_addr constant [41 x i8] c"define i64 @_map_get(i64 %m, i64 %key) {\00", align 8
@.str.810 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.811 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.812 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.813 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.814 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.815 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.816 = private unnamed_addr constant [36 x i8] c"  %key_s = inttoptr i64 %key to i8*\00", align 8
@.str.817 = private unnamed_addr constant [29 x i8] c"  %start_i = sub i64 %cnt, 2\00", align 8
@.str.818 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.819 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.820 = private unnamed_addr constant [52 x i8] c"  %i = phi i64 [ %start_i, %0 ], [ %next_i, %next ]\00", align 8
@.str.821 = private unnamed_addr constant [29 x i8] c"  %cond = icmp sge i64 %i, 0\00", align 8
@.str.822 = private unnamed_addr constant [50 x i8] c"  br i1 %cond, label %check_key, label %not_found\00", align 8
@.str.823 = private unnamed_addr constant [11 x i8] c"check_key:\00", align 8
@.str.824 = private unnamed_addr constant [54 x i8] c"  %k_slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.825 = private unnamed_addr constant [34 x i8] c"  %k_val = load i64, i64* %k_slot\00", align 8
@.str.826 = private unnamed_addr constant [38 x i8] c"  %k_str = inttoptr i64 %k_val to i8*\00", align 8
@.str.827 = private unnamed_addr constant [50 x i8] c"  %cmp = call i32 @strcmp(i8* %k_str, i8* %key_s)\00", align 8
@.str.828 = private unnamed_addr constant [31 x i8] c"  %match = icmp eq i32 %cmp, 0\00", align 8
@.str.829 = private unnamed_addr constant [42 x i8] c"  br i1 %match, label %found, label %next\00", align 8
@.str.830 = private unnamed_addr constant [6 x i8] c"next:\00", align 8
@.str.831 = private unnamed_addr constant [26 x i8] c"  %next_i = sub i64 %i, 2\00", align 8
@.str.832 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.833 = private unnamed_addr constant [7 x i8] c"found:\00", align 8
@.str.834 = private unnamed_addr constant [25 x i8] c"  %v_idx = add i64 %i, 1\00", align 8
@.str.835 = private unnamed_addr constant [58 x i8] c"  %v_slot = getelementptr i64, i64* %base_ptr, i64 %v_idx\00", align 8
@.str.836 = private unnamed_addr constant [32 x i8] c"  %ret = load i64, i64* %v_slot\00", align 8
@.str.837 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.838 = private unnamed_addr constant [11 x i8] c"not_found:\00", align 8
@.str.839 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.840 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.841 = private unnamed_addr constant [39 x i8] c"define i64 @_get(i64 %col, i64 %idx) {\00", align 8
@.str.842 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %col, 0\00", align 8
@.str.843 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %err, label %check\00", align 8
@.str.844 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.845 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %col to i8*\00", align 8
@.str.846 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.847 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.848 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_map\00", align 8
@.str.849 = private unnamed_addr constant [11 x i8] c"check_map:\00", align 8
@.str.850 = private unnamed_addr constant [31 x i8] c"  %is_map = icmp eq i8 %tag, 4\00", align 8
@.str.851 = private unnamed_addr constant [46 x i8] c"  br i1 %is_map, label %do_map, label %do_str\00", align 8
@.str.852 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.853 = private unnamed_addr constant [39 x i8] c"  %str_base = inttoptr i64 %col to i8*\00", align 8
@.str.854 = private unnamed_addr constant [56 x i8] c"  %char_ptr = getelementptr i8, i8* %str_base, i64 %idx\00", align 8
@.str.855 = private unnamed_addr constant [33 x i8] c"  %char = load i8, i8* %char_ptr\00", align 8
@.str.856 = private unnamed_addr constant [37 x i8] c"  %new_mem = call i64 @malloc(i64 2)\00", align 8
@.str.857 = private unnamed_addr constant [42 x i8] c"  %new_ptr = inttoptr i64 %new_mem to i8*\00", align 8
@.str.858 = private unnamed_addr constant [31 x i8] c"  store i8 %char, i8* %new_ptr\00", align 8
@.str.859 = private unnamed_addr constant [48 x i8] c"  %term = getelementptr i8, i8* %new_ptr, i64 1\00", align 8
@.str.860 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.861 = private unnamed_addr constant [42 x i8] c"  %ret_str = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.862 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.863 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.864 = private unnamed_addr constant [52 x i8] c"  %map_val = call i64 @_map_get(i64 %col, i64 %idx)\00", align 8
@.str.865 = private unnamed_addr constant [19 x i8] c"  ret i64 %map_val\00", align 8
@.str.866 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.867 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %col to i64*\00", align 8
@.str.868 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.869 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.870 = private unnamed_addr constant [36 x i8] c"  %arr = inttoptr i64 %base to i64*\00", align 8
@.str.871 = private unnamed_addr constant [49 x i8] c"  %slot = getelementptr i64, i64* %arr, i64 %idx\00", align 8
@.str.872 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.873 = private unnamed_addr constant [15 x i8] c"  ret i64 %val\00", align 8
@.str.874 = private unnamed_addr constant [15 x i8] c"err: ret i64 0\00", align 8
@.str.875 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.876 = private unnamed_addr constant [34 x i8] c"define i64 @_get_argv(i64 %idx) {\00", align 8
@.str.877 = private unnamed_addr constant [37 x i8] c"  %argc = load i32, i32* @__sys_argc\00", align 8
@.str.878 = private unnamed_addr constant [34 x i8] c"  %argc64 = sext i32 %argc to i64\00", align 8
@.str.879 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %idx, %argc64\00", align 8
@.str.880 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %err, label %ok\00", align 8
@.str.881 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.882 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.883 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.884 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.885 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.886 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.887 = private unnamed_addr constant [39 x i8] c"  %argv = load i8**, i8*** @__sys_argv\00", align 8
@.str.888 = private unnamed_addr constant [49 x i8] c"  %ptr = getelementptr i8*, i8** %argv, i64 %idx\00", align 8
@.str.889 = private unnamed_addr constant [29 x i8] c"  %str = load i8*, i8** %ptr\00", align 8
@.str.890 = private unnamed_addr constant [34 x i8] c"  %ret = ptrtoint i8* %str to i64\00", align 8
@.str.891 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.892 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.893 = private unnamed_addr constant [36 x i8] c"define i64 @revelare(i64 %path_i) {\00", align 8
@.str.894 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.895 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_r, i64 0, i64 0\00", align 8
@.str.896 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.897 = private unnamed_addr constant [34 x i8] c"  %f_int = ptrtoint i8* %f to i64\00", align 8
@.str.898 = private unnamed_addr constant [33 x i8] c"  %valid = icmp ne i64 %f_int, 0\00", align 8
@.str.899 = private unnamed_addr constant [40 x i8] c"  br i1 %valid, label %read, label %err\00", align 8
@.str.900 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.901 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 2)\00", align 8
@.str.902 = private unnamed_addr constant [33 x i8] c"  %len = call i64 @ftell(i8* %f)\00", align 8
@.str.903 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 0)\00", align 8
@.str.904 = private unnamed_addr constant [30 x i8] c"  %alloc_sz = add i64 %len, 1\00", align 8
@.str.905 = private unnamed_addr constant [41 x i8] c"  %buf = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.906 = private unnamed_addr constant [38 x i8] c"  %buf_ptr = inttoptr i64 %buf to i8*\00", align 8
@.str.907 = private unnamed_addr constant [57 x i8] c"  call i64 @fread(i8* %buf_ptr, i64 1, i64 %len, i8* %f)\00", align 8
@.str.908 = private unnamed_addr constant [51 x i8] c"  %term = getelementptr i8, i8* %buf_ptr, i64 %len\00", align 8
@.str.909 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.910 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.911 = private unnamed_addr constant [15 x i8] c"  ret i64 %buf\00", align 8
@.str.912 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.913 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.914 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.915 = private unnamed_addr constant [52 x i8] c"define i64 @inscribo(i64 %path_i, i64 %content_i) {\00", align 8
@.str.916 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.917 = private unnamed_addr constant [44 x i8] c"  %content = inttoptr i64 %content_i to i8*\00", align 8
@.str.918 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_w, i64 0, i64 0\00", align 8
@.str.919 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.920 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %content)\00", align 8
@.str.921 = private unnamed_addr constant [58 x i8] c"  call i64 @fwrite(i8* %content, i64 1, i64 %len, i8* %f)\00", align 8
@.str.922 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.923 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.924 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.925 = private unnamed_addr constant [34 x i8] c"define i64 @print_any(i64 %val) {\00", align 8
@.str.926 = private unnamed_addr constant [7 x i8] c"entry:\00", align 8
@.str.927 = private unnamed_addr constant [42 x i8] c"  %is_ptr = icmp sgt i64 %val, 4294967296\00", align 8
@.str.928 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_obj, label %print_int\00", align 8
@.str.929 = private unnamed_addr constant [11 x i8] c"check_obj:\00", align 8
@.str.930 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.931 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.932 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.933 = private unnamed_addr constant [54 x i8] c"  br i1 %is_list, label %print_list, label %print_str\00", align 8
@.str.934 = private unnamed_addr constant [12 x i8] c"print_list:\00", align 8
@.str.935 = private unnamed_addr constant [70 x i8] c"  %f_s1 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.936 = private unnamed_addr constant [67 x i8] c"  %b_l = getelementptr [2 x i8], [2 x i8]* @.m_brk_l, i64 0, i64 0\00", align 8
@.str.937 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s1, i8* %b_l)\00", align 8
@.str.938 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.939 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.940 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.941 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.942 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.943 = private unnamed_addr constant [50 x i8] c"  br i1 %is_empty, label %done, label %setup_loop\00", align 8
@.str.944 = private unnamed_addr constant [12 x i8] c"setup_loop:\00", align 8
@.str.945 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.946 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.947 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.948 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.949 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.950 = private unnamed_addr constant [58 x i8] c"  %i = phi i64 [ 0, %setup_loop ], [ %next_i, %loop_end ]\00", align 8
@.str.951 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.952 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.953 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.954 = private unnamed_addr constant [33 x i8] c"  %not_first = icmp ne i64 %i, 0\00", align 8
@.str.955 = private unnamed_addr constant [51 x i8] c"  br i1 %not_first, label %comma, label %val_print\00", align 8
@.str.956 = private unnamed_addr constant [7 x i8] c"comma:\00", align 8
@.str.957 = private unnamed_addr constant [70 x i8] c"  %f_s2 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.958 = private unnamed_addr constant [67 x i8] c"  %com = getelementptr [3 x i8], [3 x i8]* @.m_comma, i64 0, i64 0\00", align 8
@.str.959 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s2, i8* %com)\00", align 8
@.str.960 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.961 = private unnamed_addr constant [22 x i8] c"  br label %val_print\00", align 8
@.str.962 = private unnamed_addr constant [11 x i8] c"val_print:\00", align 8
@.str.963 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.964 = private unnamed_addr constant [28 x i8] c"  %v = load i64, i64* %slot\00", align 8
@.str.965 = private unnamed_addr constant [42 x i8] c"  %v_is_ptr = icmp sgt i64 %v, 4294967296\00", align 8
@.str.966 = private unnamed_addr constant [52 x i8] c"  br i1 %v_is_ptr, label %v_ptr_check, label %v_int\00", align 8
@.str.967 = private unnamed_addr constant [13 x i8] c"v_ptr_check:\00", align 8
@.str.968 = private unnamed_addr constant [36 x i8] c"  %vs_ptr8 = inttoptr i64 %v to i8*\00", align 8
@.str.969 = private unnamed_addr constant [34 x i8] c"  %in_tag = load i8, i8* %vs_ptr8\00", align 8
@.str.970 = private unnamed_addr constant [38 x i8] c"  %in_is_list = icmp eq i8 %in_tag, 3\00", align 8
@.str.971 = private unnamed_addr constant [55 x i8] c"  br i1 %in_is_list, label %v_nested, label %v_raw_str\00", align 8
@.str.972 = private unnamed_addr constant [10 x i8] c"v_nested:\00", align 8
@.str.973 = private unnamed_addr constant [30 x i8] c"  call i64 @print_any(i64 %v)\00", align 8
@.str.974 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.975 = private unnamed_addr constant [11 x i8] c"v_raw_str:\00", align 8
@.str.976 = private unnamed_addr constant [70 x i8] c"  %f_s3 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.977 = private unnamed_addr constant [35 x i8] c"  %vs_str = inttoptr i64 %v to i8*\00", align 8
@.str.978 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s3, i8* %vs_str)\00", align 8
@.str.979 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.980 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.981 = private unnamed_addr constant [7 x i8] c"v_int:\00", align 8
@.str.982 = private unnamed_addr constant [69 x i8] c"  %f_i = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0\00", align 8
@.str.983 = private unnamed_addr constant [48 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i, i64 %v)\00", align 8
@.str.984 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.985 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.986 = private unnamed_addr constant [10 x i8] c"loop_end:\00", align 8
@.str.987 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.988 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.989 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.990 = private unnamed_addr constant [70 x i8] c"  %f_s4 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.991 = private unnamed_addr constant [67 x i8] c"  %b_r = getelementptr [3 x i8], [3 x i8]* @.m_brk_r, i64 0, i64 0\00", align 8
@.str.992 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s4, i8* %b_r)\00", align 8
@.str.993 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.994 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.995 = private unnamed_addr constant [11 x i8] c"print_int:\00", align 8
@.str.996 = private unnamed_addr constant [71 x i8] c"  %f_i_end = getelementptr [5 x i8], [5 x i8]* @.fmt_int, i64 0, i64 0\00", align 8
@.str.997 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i_end, i64 %val)\00", align 8
@.str.998 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.999 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1000 = private unnamed_addr constant [11 x i8] c"print_str:\00", align 8
@.str.1001 = private unnamed_addr constant [71 x i8] c"  %f_s_end = getelementptr [4 x i8], [4 x i8]* @.fmt_str, i64 0, i64 0\00", align 8
@.str.1002 = private unnamed_addr constant [36 x i8] c"  %str_p = inttoptr i64 %val to i8*\00", align 8
@.str.1003 = private unnamed_addr constant [56 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s_end, i8* %str_p)\00", align 8
@.str.1004 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1005 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1006 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1007 = private unnamed_addr constant [30 x i8] c"define i64 @codex(i64 %val) {\00", align 8
@.str.1008 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.1009 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.1010 = private unnamed_addr constant [27 x i8] c"  %ret = zext i8 %c to i64\00", align 8
@.str.1011 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.1012 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1013 = private unnamed_addr constant [51 x i8] c"define i64 @pars(i64 %str, i64 %start, i64 %len) {\00", align 8
@.str.1014 = private unnamed_addr constant [34 x i8] c"  %src = inttoptr i64 %str to i8*\00", align 8
@.str.1015 = private unnamed_addr constant [37 x i8] c"  %slen = call i64 @strlen(i8* %src)\00", align 8
@.str.1016 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %start, %slen\00", align 8
@.str.1017 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %oob, label %ok\00", align 8
@.str.1018 = private unnamed_addr constant [5 x i8] c"oob:\00", align 8
@.str.1019 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1020 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1021 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1022 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1023 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.1024 = private unnamed_addr constant [31 x i8] c"  %rem = sub i64 %slen, %start\00", align 8
@.str.1025 = private unnamed_addr constant [37 x i8] c"  %is_long = icmp sgt i64 %len, %rem\00", align 8
@.str.1026 = private unnamed_addr constant [53 x i8] c"  %safe_len = select i1 %is_long, i64 %rem, i64 %len\00", align 8
@.str.1027 = private unnamed_addr constant [52 x i8] c"  %src_off = getelementptr i8, i8* %src, i64 %start\00", align 8
@.str.1028 = private unnamed_addr constant [35 x i8] c"  %alloc_sz = add i64 %safe_len, 1\00", align 8
@.str.1029 = private unnamed_addr constant [42 x i8] c"  %dest = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.1030 = private unnamed_addr constant [40 x i8] c"  %dest_ptr = inttoptr i64 %dest to i8*\00", align 8
@.str.1031 = private unnamed_addr constant [64 x i8] c"  call i8* @strncpy(i8* %dest_ptr, i8* %src_off, i64 %safe_len)\00", align 8
@.str.1032 = private unnamed_addr constant [57 x i8] c"  %term = getelementptr i8, i8* %dest_ptr, i64 %safe_len\00", align 8
@.str.1033 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1034 = private unnamed_addr constant [16 x i8] c"  ret i64 %dest\00", align 8
@.str.1035 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1036 = private unnamed_addr constant [34 x i8] c"define i64 @signum_ex(i64 %val) {\00", align 8
@.str.1037 = private unnamed_addr constant [33 x i8] c"  %mem = call i64 @malloc(i64 2)\00", align 8
@.str.1038 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1039 = private unnamed_addr constant [28 x i8] c"  %c = trunc i64 %val to i8\00", align 8
@.str.1040 = private unnamed_addr constant [24 x i8] c"  store i8 %c, i8* %ptr\00", align 8
@.str.1041 = private unnamed_addr constant [44 x i8] c"  %term = getelementptr i8, i8* %ptr, i64 1\00", align 8
@.str.1042 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1043 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1044 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1045 = private unnamed_addr constant [32 x i8] c"define i64 @mensura(i64 %val) {\00", align 8
@.str.1046 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %val, 0\00", align 8
@.str.1047 = private unnamed_addr constant [47 x i8] c"  br i1 %is_null, label %ret_zero, label %read\00", align 8
@.str.1048 = private unnamed_addr constant [10 x i8] c"ret_zero:\00", align 8
@.str.1049 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1050 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1051 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.1052 = private unnamed_addr constant [29 x i8] c"  %type = load i8, i8* %ptr8\00", align 8
@.str.1053 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.1054 = private unnamed_addr constant [32 x i8] c"  %is_map = icmp eq i8 %type, 4\00", align 8
@.str.1055 = private unnamed_addr constant [36 x i8] c"  %is_col = or i1 %is_list, %is_map\00", align 8
@.str.1056 = private unnamed_addr constant [48 x i8] c"  br i1 %is_col, label %get_cnt, label %get_str\00", align 8
@.str.1057 = private unnamed_addr constant [9 x i8] c"get_cnt:\00", align 8
@.str.1058 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.1059 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1060 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1061 = private unnamed_addr constant [15 x i8] c"  ret i64 %cnt\00", align 8
@.str.1062 = private unnamed_addr constant [9 x i8] c"get_str:\00", align 8
@.str.1063 = private unnamed_addr constant [38 x i8] c"  %str_ptr = inttoptr i64 %val to i8*\00", align 8
@.str.1064 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %str_ptr)\00", align 8
@.str.1065 = private unnamed_addr constant [15 x i8] c"  ret i64 %len\00", align 8
@.str.1066 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1067 = private unnamed_addr constant [22 x i8] c"define i64 @capio() {\00", align 8
@.str.1068 = private unnamed_addr constant [36 x i8] c"  %mem = call i64 @malloc(i64 4096)\00", align 8
@.str.1069 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1070 = private unnamed_addr constant [17 x i8] c"  br label %read\00", align 8
@.str.1071 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1072 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %cont ]\00", align 8
@.str.1073 = private unnamed_addr constant [27 x i8] c"  %c = call i32 @getchar()\00", align 8
@.str.1074 = private unnamed_addr constant [31 x i8] c"  %is_eof = icmp eq i32 %c, -1\00", align 8
@.str.1075 = private unnamed_addr constant [30 x i8] c"  %is_nl = icmp eq i32 %c, 10\00", align 8
@.str.1076 = private unnamed_addr constant [32 x i8] c"  %stop = or i1 %is_eof, %is_nl\00", align 8
@.str.1077 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %cont\00", align 8
@.str.1078 = private unnamed_addr constant [6 x i8] c"cont:\00", align 8
@.str.1079 = private unnamed_addr constant [29 x i8] c"  %char = trunc i32 %c to i8\00", align 8
@.str.1080 = private unnamed_addr constant [45 x i8] c"  %slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1081 = private unnamed_addr constant [28 x i8] c"  store i8 %char, i8* %slot\00", align 8
@.str.1082 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1083 = private unnamed_addr constant [38 x i8] c"  %limit = icmp slt i64 %next_i, 4095\00", align 8
@.str.1084 = private unnamed_addr constant [41 x i8] c"  br i1 %limit, label %read, label %done\00", align 8
@.str.1085 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1086 = private unnamed_addr constant [50 x i8] c"  %term_slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1087 = private unnamed_addr constant [29 x i8] c"  store i8 0, i8* %term_slot\00", align 8
@.str.1088 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1089 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1090 = private unnamed_addr constant [33 x i8] c"define i64 @imperium(i64 %cmd) {\00", align 8
@.str.1091 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %cmd to i8*\00", align 8
@.str.1092 = private unnamed_addr constant [34 x i8] c"  %res = call i32 @system(i8* %p)\00", align 8
@.str.1093 = private unnamed_addr constant [30 x i8] c"  %ext = sext i32 %res to i64\00", align 8
@.str.1094 = private unnamed_addr constant [15 x i8] c"  ret i64 %ext\00", align 8
@.str.1095 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1096 = private unnamed_addr constant [31 x i8] c"define i64 @dormire(i64 %ms) {\00", align 8
@.str.1097 = private unnamed_addr constant [26 x i8] c"  %us = mul i64 %ms, 1000\00", align 8
@.str.1098 = private unnamed_addr constant [31 x i8] c"  %us32 = trunc i64 %us to i32\00", align 8
@.str.1099 = private unnamed_addr constant [30 x i8] c"  call i32 @usleep(i32 %us32)\00", align 8
@.str.1100 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1101 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1102 = private unnamed_addr constant [32 x i8] c"define i64 @numerus(i64 %str) {\00", align 8
@.str.1103 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %str to i8*\00", align 8
@.str.1104 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1105 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1106 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]\00", align 8
@.str.1107 = private unnamed_addr constant [49 x i8] c"  %acc = phi i64 [ 0, %0 ], [ %next_acc, %body ]\00", align 8
@.str.1108 = private unnamed_addr constant [49 x i8] c"  %char_ptr = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1109 = private unnamed_addr constant [30 x i8] c"  %c = load i8, i8* %char_ptr\00", align 8
@.str.1110 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1111 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %body\00", align 8
@.str.1112 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1113 = private unnamed_addr constant [29 x i8] c"  %c_ext = zext i8 %c to i64\00", align 8
@.str.1114 = private unnamed_addr constant [30 x i8] c"  %digit = sub i64 %c_ext, 48\00", align 8
@.str.1115 = private unnamed_addr constant [28 x i8] c"  %mul10 = mul i64 %acc, 10\00", align 8
@.str.1116 = private unnamed_addr constant [37 x i8] c"  %next_acc = add i64 %mul10, %digit\00", align 8
@.str.1117 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1118 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1119 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1120 = private unnamed_addr constant [15 x i8] c"  ret i64 %acc\00", align 8
@.str.1121 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1122 = private unnamed_addr constant [45 x i8] c"define i64 @scindere(i64 %str, i64 %delim) {\00", align 8
@.str.1123 = private unnamed_addr constant [32 x i8] c"  %list = call i64 @_list_new()\00", align 8
@.str.1124 = private unnamed_addr constant [34 x i8] c"  %s_p = inttoptr i64 %str to i8*\00", align 8
@.str.1125 = private unnamed_addr constant [36 x i8] c"  %d_p = inttoptr i64 %delim to i8*\00", align 8
@.str.1126 = private unnamed_addr constant [36 x i8] c"  %len = call i64 @strlen(i8* %s_p)\00", align 8
@.str.1127 = private unnamed_addr constant [24 x i8] c"  %sz = add i64 %len, 1\00", align 8
@.str.1128 = private unnamed_addr constant [35 x i8] c"  %mem = call i64 @malloc(i64 %sz)\00", align 8
@.str.1129 = private unnamed_addr constant [33 x i8] c"  %cp = inttoptr i64 %mem to i8*\00", align 8
@.str.1130 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %cp, i8* %s_p)\00", align 8
@.str.1131 = private unnamed_addr constant [45 x i8] c"  %tok = call i8* @strtok(i8* %cp, i8* %d_p)\00", align 8
@.str.1132 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1133 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1134 = private unnamed_addr constant [48 x i8] c"  %curr = phi i8* [ %tok, %0 ], [ %nxt, %body ]\00", align 8
@.str.1135 = private unnamed_addr constant [37 x i8] c"  %is_null = icmp eq i8* %curr, null\00", align 8
@.str.1136 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %body\00", align 8
@.str.1137 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1138 = private unnamed_addr constant [37 x i8] c"  %t_val = ptrtoint i8* %curr to i64\00", align 8
@.str.1139 = private unnamed_addr constant [46 x i8] c"  call i64 @_list_push(i64 %list, i64 %t_val)\00", align 8
@.str.1140 = private unnamed_addr constant [46 x i8] c"  %nxt = call i8* @strtok(i8* null, i8* %d_p)\00", align 8
@.str.1141 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1142 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1143 = private unnamed_addr constant [16 x i8] c"  ret i64 %list\00", align 8
@.str.1144 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1145 = private unnamed_addr constant [50 x i8] c"define i64 @iunctura(i64 %list_ptr, i64 %delim) {\00", align 8
@.str.1146 = private unnamed_addr constant [38 x i8] c"  %is_null = icmp eq i64 %list_ptr, 0\00", align 8
@.str.1147 = private unnamed_addr constant [49 x i8] c"  br i1 %is_null, label %ret_empty, label %check\00", align 8
@.str.1148 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.1149 = private unnamed_addr constant [42 x i8] c"  %ptr64 = inttoptr i64 %list_ptr to i64*\00", align 8
@.str.1150 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1151 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1152 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.1153 = private unnamed_addr constant [49 x i8] c"  br i1 %is_empty, label %ret_empty, label %calc\00", align 8
@.str.1154 = private unnamed_addr constant [11 x i8] c"ret_empty:\00", align 8
@.str.1155 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1156 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1157 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1158 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1159 = private unnamed_addr constant [6 x i8] c"calc:\00", align 8
@.str.1160 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.1161 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.1162 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.1163 = private unnamed_addr constant [35 x i8] c"  %res_0 = call i64 @malloc(i64 1)\00", align 8
@.str.1164 = private unnamed_addr constant [40 x i8] c"  %res_0_p = inttoptr i64 %res_0 to i8*\00", align 8
@.str.1165 = private unnamed_addr constant [27 x i8] c"  store i8 0, i8* %res_0_p\00", align 8
@.str.1166 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1167 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1168 = private unnamed_addr constant [49 x i8] c"  %i = phi i64 [ 0, %calc ], [ %next_i, %merge ]\00", align 8
@.str.1169 = private unnamed_addr constant [63 x i8] c"  %curr_str = phi i64 [ %res_0, %calc ], [ %next_str, %merge ]\00", align 8
@.str.1170 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.1171 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.1172 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1173 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.1174 = private unnamed_addr constant [31 x i8] c"  %item = load i64, i64* %slot\00", align 8
@.str.1175 = private unnamed_addr constant [43 x i8] c"  %item_s = call i64 @to_string(i64 %item)\00", align 8
@.str.1176 = private unnamed_addr constant [58 x i8] c"  %added = call i64 @_str_cat(i64 %curr_str, i64 %item_s)\00", align 8
@.str.1177 = private unnamed_addr constant [30 x i8] c"  %last_idx = sub i64 %cnt, 1\00", align 8
@.str.1178 = private unnamed_addr constant [39 x i8] c"  %is_last = icmp eq i64 %i, %last_idx\00", align 8
@.str.1179 = private unnamed_addr constant [54 x i8] c"  br i1 %is_last, label %skip_delim, label %add_delim\00", align 8
@.str.1180 = private unnamed_addr constant [11 x i8] c"add_delim:\00", align 8
@.str.1181 = private unnamed_addr constant [59 x i8] c"  %with_delim = call i64 @_str_cat(i64 %added, i64 %delim)\00", align 8
@.str.1182 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1183 = private unnamed_addr constant [12 x i8] c"skip_delim:\00", align 8
@.str.1184 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1185 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.1186 = private unnamed_addr constant [75 x i8] c"  %next_str = phi i64 [ %with_delim, %add_delim ], [ %added, %skip_delim ]\00", align 8
@.str.1187 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1188 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1189 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1190 = private unnamed_addr constant [20 x i8] c"  ret i64 %curr_str\00", align 8
@.str.1191 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1192 = private unnamed_addr constant [90 x i8] c"define i64 @syscall6(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) {\00", align 8
@.str.1193 = private unnamed_addr constant [184 x i8] c"  %res = call i64 asm sideeffect \22syscall\22, \22={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11},~{memory}\22(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6)\00", align 8
@.str.1194 = private unnamed_addr constant [15 x i8] c"  ret i64 %res\00", align 8
@.str.1195 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1196 = private unnamed_addr constant [31 x i8] c"define i64 @strlen(i8* %str) {\00", align 8
@.str.1197 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1198 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1199 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1200 = private unnamed_addr constant [44 x i8] c"  %ptr = getelementptr i8, i8* %str, i64 %i\00", align 8
@.str.1201 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.1202 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1203 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1204 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1205 = private unnamed_addr constant [17 x i8] c"done: ret i64 %i\00", align 8
@.str.1206 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1207 = private unnamed_addr constant [39 x i8] c"define i32 @strcmp(i8* %s1, i8* %s2) {\00", align 8
@.str.1208 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1209 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1210 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1211 = private unnamed_addr constant [42 x i8] c"  %p1 = getelementptr i8, i8* %s1, i64 %i\00", align 8
@.str.1212 = private unnamed_addr constant [42 x i8] c"  %p2 = getelementptr i8, i8* %s2, i64 %i\00", align 8
@.str.1213 = private unnamed_addr constant [25 x i8] c"  %c1 = load i8, i8* %p1\00", align 8
@.str.1214 = private unnamed_addr constant [25 x i8] c"  %c2 = load i8, i8* %p2\00", align 8
@.str.1215 = private unnamed_addr constant [32 x i8] c"  %not_eq = icmp ne i8 %c1, %c2\00", align 8
@.str.1216 = private unnamed_addr constant [31 x i8] c"  %is_null = icmp eq i8 %c1, 0\00", align 8
@.str.1217 = private unnamed_addr constant [34 x i8] c"  %stop = or i1 %not_eq, %is_null\00", align 8
@.str.1218 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1219 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %loop\00", align 8
@.str.1220 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1221 = private unnamed_addr constant [27 x i8] c"  %z1 = zext i8 %c1 to i32\00", align 8
@.str.1222 = private unnamed_addr constant [27 x i8] c"  %z2 = zext i8 %c2 to i32\00", align 8
@.str.1223 = private unnamed_addr constant [27 x i8] c"  %diff = sub i32 %z1, %z2\00", align 8
@.str.1224 = private unnamed_addr constant [16 x i8] c"  ret i32 %diff\00", align 8
@.str.1225 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1226 = private unnamed_addr constant [42 x i8] c"define i8* @strcpy(i8* %dest, i8* %src) {\00", align 8
@.str.1227 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1228 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1229 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1230 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1231 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1232 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1233 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1234 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1235 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1236 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1237 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1238 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1239 = private unnamed_addr constant [51 x i8] c"define i8* @strncpy(i8* %dest, i8* %src, i64 %n) {\00", align 8
@.str.1240 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1241 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1242 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %body ]\00", align 8
@.str.1243 = private unnamed_addr constant [29 x i8] c"  %cmp = icmp slt i64 %i, %n\00", align 8
@.str.1244 = private unnamed_addr constant [39 x i8] c"  br i1 %cmp, label %body, label %done\00", align 8
@.str.1245 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1246 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1247 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1248 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1249 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1250 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1251 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1252 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1253 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1254 = private unnamed_addr constant [42 x i8] c"define i8* @strcat(i8* %dest, i8* %src) {\00", align 8
@.str.1255 = private unnamed_addr constant [37 x i8] c"  %len = call i64 @strlen(i8* %dest)\00", align 8
@.str.1256 = private unnamed_addr constant [49 x i8] c"  %d_end = getelementptr i8, i8* %dest, i64 %len\00", align 8
@.str.1257 = private unnamed_addr constant [41 x i8] c"  call i8* @strcpy(i8* %d_end, i8* %src)\00", align 8
@.str.1258 = private unnamed_addr constant [16 x i8] c"  ret i8* %dest\00", align 8
@.str.1259 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1260 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1261 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1262 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1263 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1264 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1265 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.1266 = private unnamed_addr constant [61 x i8] c"⚔️  ACHLYS -> LLVM COMPILER (STAGE 1.8.4 - FREESTANDING)\00", align 8
@.str.1267 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1268 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1269 = private unnamed_addr constant [15 x i8] c"--freestanding\00", align 8
@.str.1270 = private unnamed_addr constant [8 x i8] c"--arm64\00", align 8
@.str.1271 = private unnamed_addr constant [52 x i8] c"Usage: ./mate <file.nox> [--freestanding] [--arm64]\00", align 8
@.str.1272 = private unnamed_addr constant [25 x i8] c"⚠️  File not found: \00", align 8
@.str.1273 = private unnamed_addr constant [16 x i8] c"[1/3] Lexing...\00", align 8
@.str.1274 = private unnamed_addr constant [19 x i8] c"[DEBUG] Main sees \00", align 8
@.str.1275 = private unnamed_addr constant [9 x i8] c" tokens.\00", align 8
@.str.1276 = private unnamed_addr constant [4 x i8] c" T[\00", align 8
@.str.1277 = private unnamed_addr constant [4 x i8] c"]: \00", align 8
@.str.1278 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.1279 = private unnamed_addr constant [3 x i8] c" (\00", align 8
@.str.1280 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1281 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.1282 = private unnamed_addr constant [17 x i8] c"[2/3] Parsing...\00", align 8
@.str.1283 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1284 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1285 = private unnamed_addr constant [24 x i8] c"❌ Compilation Failed.\00", align 8
@.str.1286 = private unnamed_addr constant [28 x i8] c"[3/3] Generating LLVM IR...\00", align 8
@.str.1287 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1288 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1289 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1290 = private unnamed_addr constant [2 x i8] c"@\00", align 8
@.str.1291 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1292 = private unnamed_addr constant [16 x i8] c" = global i64 0\00", align 8
@.str.1293 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1294 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1295 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1296 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1297 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1298 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1299 = private unnamed_addr constant [42 x i8] c"define i32 @main(i32 %argc, i8** %argv) {\00", align 8
@.str.1300 = private unnamed_addr constant [36 x i8] c"  store i32 %argc, i32* @__sys_argc\00", align 8
@.str.1301 = private unnamed_addr constant [38 x i8] c"  store i8** %argv, i8*** @__sys_argv\00", align 8
@.str.1302 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1303 = private unnamed_addr constant [55 x i8] c"  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* \00", align 8
@.str.1304 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.1305 = private unnamed_addr constant [52 x i8] c"  %boot_msg_int = ptrtoint i8* %boot_msg_ptr to i64\00", align 8
@.str.1306 = private unnamed_addr constant [41 x i8] c"  call i64 @print_any(i64 %boot_msg_int)\00", align 8
@.str.1307 = private unnamed_addr constant [31 x i8] c"[DEBUG] Top Level Statements: \00", align 8
@.str.1308 = private unnamed_addr constant [10 x i8] c"ret i32 0\00", align 8
@.str.1309 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1310 = private unnamed_addr constant [10 x i8] c"Achlys.ll\00", align 8
@.str.1311 = private unnamed_addr constant [36 x i8] c"✅ SUCCESS. 'Achlys.ll' generated.\00", align 8
@.str.1312 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1313 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1314 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1315 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1316 = private unnamed_addr constant [1 x i8] c"\00", align 8
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
  br i1 %r3, label %L1, label %L3
L1:
  %r4 = getelementptr [2 x i8], [2 x i8]* @.str.1, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  ret i64 %r5
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
  br i1 %r11, label %L4, label %L6
L4:
  store i64 1, i64* %ptr_is_neg
  %r12 = load i64, i64* %ptr_n
  %r13 = sub i64 0, %r12
  store i64 %r13, i64* %ptr_n
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
  br i1 %r29, label %L10, label %L12
L10:
  %r30 = getelementptr [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  %r31 = ptrtoint i8* %r30 to i64
  %r32 = load i64, i64* %ptr_out
  %r33 = call i64 @_add(i64 %r31, i64 %r32)
  store i64 %r33, i64* %ptr_out
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
  br i1 %r17, label %L16, label %L18
L16:
  %r18 = load i64, i64* %ptr_c
  %r20 = icmp sle i64 %r18, 57
  %r19 = zext i1 %r20 to i64
  %r21 = icmp ne i64 %r19, 0
  br i1 %r21, label %L19, label %L21
L19:
  %r22 = load i64, i64* %ptr_val
  %r23 = load i64, i64* %ptr_c
  %r24 = sub i64 %r23, 48
  %r25 = call i64 @_add(i64 %r22, i64 %r24)
  store i64 %r25, i64* %ptr_val
  br label %L21
L21:
  br label %L18
L18:
  %r26 = load i64, i64* %ptr_c
  %r28 = icmp sge i64 %r26, 65
  %r27 = zext i1 %r28 to i64
  %r29 = icmp ne i64 %r27, 0
  br i1 %r29, label %L22, label %L24
L22:
  %r30 = load i64, i64* %ptr_c
  %r32 = icmp sle i64 %r30, 70
  %r31 = zext i1 %r32 to i64
  %r33 = icmp ne i64 %r31, 0
  br i1 %r33, label %L25, label %L27
L25:
  %r34 = load i64, i64* %ptr_val
  %r35 = load i64, i64* %ptr_c
  %r36 = sub i64 %r35, 55
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  store i64 %r37, i64* %ptr_val
  br label %L27
L27:
  br label %L24
L24:
  %r38 = load i64, i64* %ptr_c
  %r40 = icmp sge i64 %r38, 97
  %r39 = zext i1 %r40 to i64
  %r41 = icmp ne i64 %r39, 0
  br i1 %r41, label %L28, label %L30
L28:
  %r42 = load i64, i64* %ptr_c
  %r44 = icmp sle i64 %r42, 102
  %r43 = zext i1 %r44 to i64
  %r45 = icmp ne i64 %r43, 0
  br i1 %r45, label %L31, label %L33
L31:
  %r46 = load i64, i64* %ptr_val
  %r47 = load i64, i64* %ptr_c
  %r48 = sub i64 %r47, 87
  %r49 = call i64 @_add(i64 %r46, i64 %r48)
  store i64 %r49, i64* %ptr_val
  br label %L33
L33:
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
  br i1 %r6, label %L34, label %L36
L34:
  %r7 = load i64, i64* %ptr_code
  %r9 = icmp sle i64 %r7, 57
  %r8 = zext i1 %r9 to i64
  %r10 = icmp ne i64 %r8, 0
  br i1 %r10, label %L37, label %L39
L37:
  ret i64 1
  br label %L39
L39:
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
  br i1 %r6, label %L40, label %L42
L40:
  %r7 = load i64, i64* %ptr_code
  %r9 = icmp sle i64 %r7, 90
  %r8 = zext i1 %r9 to i64
  %r10 = icmp ne i64 %r8, 0
  br i1 %r10, label %L43, label %L45
L43:
  ret i64 1
  br label %L45
L45:
  br label %L42
L42:
  %r11 = load i64, i64* %ptr_code
  %r13 = icmp sge i64 %r11, 97
  %r12 = zext i1 %r13 to i64
  %r14 = icmp ne i64 %r12, 0
  br i1 %r14, label %L46, label %L48
L46:
  %r15 = load i64, i64* %ptr_code
  %r17 = icmp sle i64 %r15, 122
  %r16 = zext i1 %r17 to i64
  %r18 = icmp ne i64 %r16, 0
  br i1 %r18, label %L49, label %L51
L49:
  ret i64 1
  br label %L51
L51:
  br label %L48
L48:
  %r19 = load i64, i64* %ptr_c
  %r20 = getelementptr [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_eq(i64 %r19, i64 %r21)
  %r23 = icmp ne i64 %r22, 0
  br i1 %r23, label %L52, label %L54
L52:
  ret i64 1
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
  br i1 %r5, label %L55, label %L57
L55:
  store i64 1, i64* %ptr_res
  br label %L57
L57:
  %r6 = load i64, i64* %ptr_res
  %r7 = call i64 @_eq(i64 %r6, i64 0)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L58, label %L60
L58:
  %r9 = load i64, i64* %ptr_c
  %r10 = call i64 @is_digit(i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L61, label %L63
L61:
  store i64 1, i64* %ptr_res
  br label %L63
L63:
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
  br i1 %r5, label %L64, label %L66
L64:
  ret i64 1
  br label %L66
L66:
  %r6 = load i64, i64* %ptr_code
  %r7 = call i64 @_eq(i64 %r6, i64 9)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L67, label %L69
L67:
  ret i64 1
  br label %L69
L69:
  %r9 = load i64, i64* %ptr_code
  %r10 = call i64 @_eq(i64 %r9, i64 10)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L70, label %L72
L70:
  ret i64 1
  br label %L72
L72:
  %r12 = load i64, i64* %ptr_code
  %r13 = call i64 @_eq(i64 %r12, i64 13)
  %r14 = icmp ne i64 %r13, 0
  br i1 %r14, label %L73, label %L75
L73:
  ret i64 1
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
  br i1 %r16, label %L79, label %L81
L79:
  %r17 = load i64, i64* %ptr_entry
  %r18 = getelementptr [4 x i8], [4 x i8]* @.str.8, i64 0, i64 0
  %r19 = ptrtoint i8* %r18 to i64
  %r20 = call i64 @_get(i64 %r17, i64 %r19)
  ret i64 %r20
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
  br i1 %r13, label %L88, label %L90
L88:
  ret i64 1
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
  %r1 = getelementptr [11 x i8], [11 x i8]* @.str.16, i64 0, i64 0
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
  br i1 %r52, label %L106, label %L108
L106:
  store i64 0, i64* %ptr_run_cmt
  br label %L108
L108:
  %r53 = load i64, i64* %ptr_run_cmt
  %r54 = icmp ne i64 %r53, 0
  br i1 %r54, label %L109, label %L111
L109:
  %r55 = load i64, i64* %ptr_src
  %r56 = load i64, i64* %ptr_i
  %r57 = call i64 @pars(i64 %r55, i64 %r56, i64 1)
  store i64 %r57, i64* %ptr_loop_c
  %r58 = load i64, i64* %ptr_loop_c
  %r59 = call i64 @codex(i64 %r58)
  %r60 = call i64 @_eq(i64 %r59, i64 10)
  %r61 = icmp ne i64 %r60, 0
  br i1 %r61, label %L112, label %L114
L112:
  store i64 0, i64* %ptr_run_cmt
  br label %L114
L114:
  %r62 = load i64, i64* %ptr_run_cmt
  %r63 = icmp ne i64 %r62, 0
  br i1 %r63, label %L115, label %L117
L115:
  %r64 = load i64, i64* %ptr_i
  %r65 = call i64 @_add(i64 %r64, i64 1)
  store i64 %r65, i64* %ptr_i
  br label %L117
L117:
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
  br i1 %r79, label %L124, label %L126
L124:
  store i64 0, i64* %ptr_run_blk
  br label %L126
L126:
  %r80 = load i64, i64* %ptr_run_blk
  %r81 = icmp ne i64 %r80, 0
  br i1 %r81, label %L127, label %L129
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
  br i1 %r96, label %L130, label %L132
L130:
  %r97 = load i64, i64* %ptr_i
  %r98 = call i64 @_add(i64 %r97, i64 2)
  store i64 %r98, i64* %ptr_i
  store i64 0, i64* %ptr_run_blk
  br label %L132
L132:
  %r99 = load i64, i64* %ptr_run_blk
  %r100 = icmp ne i64 %r99, 0
  br i1 %r100, label %L133, label %L135
L133:
  %r101 = load i64, i64* %ptr_i
  %r102 = call i64 @_add(i64 %r101, i64 1)
  store i64 %r102, i64* %ptr_i
  br label %L135
L135:
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
  br i1 %r125, label %L142, label %L144
L142:
  store i64 0, i64* %ptr_run_str
  br label %L144
L144:
  %r126 = load i64, i64* %ptr_run_str
  %r127 = icmp ne i64 %r126, 0
  br i1 %r127, label %L145, label %L147
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
  br i1 %r135, label %L148, label %L150
L148:
  store i64 0, i64* %ptr_run_str
  br label %L150
L150:
  %r136 = load i64, i64* %ptr_run_str
  %r137 = icmp ne i64 %r136, 0
  br i1 %r137, label %L151, label %L153
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
L153:
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
  br i1 %r204, label %L172, label %L174
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
  br i1 %r213, label %L175, label %L177
L175:
  store i64 1, i64* %ptr_is_hex
  br label %L177
L177:
  %r214 = load i64, i64* %ptr_next_char
  %r215 = getelementptr [2 x i8], [2 x i8]* @.str.41, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = call i64 @_eq(i64 %r214, i64 %r216)
  %r218 = icmp ne i64 %r217, 0
  br i1 %r218, label %L178, label %L180
L178:
  store i64 1, i64* %ptr_is_hex
  br label %L180
L180:
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
  br i1 %r230, label %L187, label %L189
L187:
  store i64 0, i64* %ptr_run_hex
  br label %L189
L189:
  %r231 = load i64, i64* %ptr_run_hex
  %r232 = icmp ne i64 %r231, 0
  br i1 %r232, label %L190, label %L192
L190:
  %r233 = load i64, i64* %ptr_src
  %r234 = load i64, i64* %ptr_i
  %r235 = call i64 @pars(i64 %r233, i64 %r234, i64 1)
  store i64 %r235, i64* %ptr_loop_c
  %r236 = load i64, i64* %ptr_loop_c
  %r237 = call i64 @is_alnum(i64 %r236)
  %r238 = call i64 @_eq(i64 %r237, i64 0)
  %r239 = icmp ne i64 %r238, 0
  br i1 %r239, label %L193, label %L195
L193:
  store i64 0, i64* %ptr_run_hex
  br label %L195
L195:
  %r240 = load i64, i64* %ptr_run_hex
  %r241 = icmp ne i64 %r240, 0
  br i1 %r241, label %L196, label %L198
L196:
  %r242 = load i64, i64* %ptr_i
  %r243 = call i64 @_add(i64 %r242, i64 1)
  store i64 %r243, i64* %ptr_i
  br label %L198
L198:
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
  br i1 %r262, label %L202, label %L204
L202:
  store i64 0, i64* %ptr_run_num
  br label %L204
L204:
  %r263 = load i64, i64* %ptr_run_num
  %r264 = icmp ne i64 %r263, 0
  br i1 %r264, label %L205, label %L207
L205:
  %r265 = load i64, i64* %ptr_src
  %r266 = load i64, i64* %ptr_i
  %r267 = call i64 @pars(i64 %r265, i64 %r266, i64 1)
  store i64 %r267, i64* %ptr_loop_c
  store i64 0, i64* %ptr_keep
  %r268 = load i64, i64* %ptr_loop_c
  %r269 = call i64 @is_digit(i64 %r268)
  %r270 = icmp ne i64 %r269, 0
  br i1 %r270, label %L208, label %L210
L208:
  store i64 1, i64* %ptr_keep
  br label %L210
L210:
  %r271 = load i64, i64* %ptr_loop_c
  %r272 = getelementptr [2 x i8], [2 x i8]* @.str.42, i64 0, i64 0
  %r273 = ptrtoint i8* %r272 to i64
  %r274 = call i64 @_eq(i64 %r271, i64 %r273)
  %r275 = icmp ne i64 %r274, 0
  br i1 %r275, label %L211, label %L213
L211:
  store i64 1, i64* %ptr_keep
  br label %L213
L213:
  %r276 = load i64, i64* %ptr_keep
  %r277 = call i64 @_eq(i64 %r276, i64 0)
  %r278 = icmp ne i64 %r277, 0
  br i1 %r278, label %L214, label %L216
L214:
  store i64 0, i64* %ptr_run_num
  br label %L216
L216:
  %r279 = load i64, i64* %ptr_run_num
  %r280 = icmp ne i64 %r279, 0
  br i1 %r280, label %L217, label %L219
L217:
  %r281 = load i64, i64* %ptr_i
  %r282 = call i64 @_add(i64 %r281, i64 1)
  store i64 %r282, i64* %ptr_i
  br label %L219
L219:
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
  br i1 %r303, label %L226, label %L228
L226:
  store i64 0, i64* %ptr_run_id
  br label %L228
L228:
  %r304 = load i64, i64* %ptr_run_id
  %r305 = icmp ne i64 %r304, 0
  br i1 %r305, label %L229, label %L231
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
  br i1 %r314, label %L232, label %L234
L232:
  %r315 = load i64, i64* %ptr_lcode
  %r317 = icmp sle i64 %r315, 57
  %r316 = zext i1 %r317 to i64
  %r318 = icmp ne i64 %r316, 0
  br i1 %r318, label %L235, label %L237
L235:
  store i64 1, i64* %ptr_ok
  br label %L237
L237:
  br label %L234
L234:
  %r319 = load i64, i64* %ptr_lcode
  %r321 = icmp sge i64 %r319, 65
  %r320 = zext i1 %r321 to i64
  %r322 = icmp ne i64 %r320, 0
  br i1 %r322, label %L238, label %L240
L238:
  %r323 = load i64, i64* %ptr_lcode
  %r325 = icmp sle i64 %r323, 90
  %r324 = zext i1 %r325 to i64
  %r326 = icmp ne i64 %r324, 0
  br i1 %r326, label %L241, label %L243
L241:
  store i64 1, i64* %ptr_ok
  br label %L243
L243:
  br label %L240
L240:
  %r327 = load i64, i64* %ptr_lcode
  %r329 = icmp sge i64 %r327, 97
  %r328 = zext i1 %r329 to i64
  %r330 = icmp ne i64 %r328, 0
  br i1 %r330, label %L244, label %L246
L244:
  %r331 = load i64, i64* %ptr_lcode
  %r333 = icmp sle i64 %r331, 122
  %r332 = zext i1 %r333 to i64
  %r334 = icmp ne i64 %r332, 0
  br i1 %r334, label %L247, label %L249
L247:
  store i64 1, i64* %ptr_ok
  br label %L249
L249:
  br label %L246
L246:
  %r335 = load i64, i64* %ptr_lcode
  %r336 = call i64 @_eq(i64 %r335, i64 95)
  %r337 = icmp ne i64 %r336, 0
  br i1 %r337, label %L250, label %L252
L250:
  store i64 1, i64* %ptr_ok
  br label %L252
L252:
  %r338 = load i64, i64* %ptr_ok
  %r339 = call i64 @_eq(i64 %r338, i64 0)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L253, label %L255
L253:
  store i64 0, i64* %ptr_run_id
  br label %L255
L255:
  %r341 = load i64, i64* %ptr_run_id
  %r342 = icmp ne i64 %r341, 0
  br i1 %r342, label %L256, label %L258
L256:
  %r343 = load i64, i64* %ptr_i
  %r344 = call i64 @_add(i64 %r343, i64 1)
  store i64 %r344, i64* %ptr_i
  br label %L258
L258:
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
  br i1 %r355, label %L259, label %L261
L259:
  store i64 5, i64* %ptr_type
  br label %L261
L261:
  %r356 = load i64, i64* %ptr_txt
  %r357 = getelementptr [5 x i8], [5 x i8]* @.str.44, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_eq(i64 %r356, i64 %r358)
  %r360 = icmp ne i64 %r359, 0
  br i1 %r360, label %L262, label %L264
L262:
  store i64 5, i64* %ptr_type
  br label %L264
L264:
  %r361 = load i64, i64* %ptr_txt
  %r362 = getelementptr [6 x i8], [6 x i8]* @.str.45, i64 0, i64 0
  %r363 = ptrtoint i8* %r362 to i64
  %r364 = call i64 @_eq(i64 %r361, i64 %r363)
  %r365 = icmp ne i64 %r364, 0
  br i1 %r365, label %L265, label %L267
L265:
  store i64 5, i64* %ptr_type
  br label %L267
L267:
  %r366 = load i64, i64* %ptr_txt
  %r367 = getelementptr [7 x i8], [7 x i8]* @.str.46, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_eq(i64 %r366, i64 %r368)
  %r370 = icmp ne i64 %r369, 0
  br i1 %r370, label %L268, label %L270
L268:
  store i64 6, i64* %ptr_type
  br label %L270
L270:
  %r371 = load i64, i64* %ptr_txt
  %r372 = getelementptr [8 x i8], [8 x i8]* @.str.47, i64 0, i64 0
  %r373 = ptrtoint i8* %r372 to i64
  %r374 = call i64 @_eq(i64 %r371, i64 %r373)
  %r375 = icmp ne i64 %r374, 0
  br i1 %r375, label %L271, label %L273
L271:
  store i64 6, i64* %ptr_type
  br label %L273
L273:
  %r376 = load i64, i64* %ptr_txt
  %r377 = getelementptr [10 x i8], [10 x i8]* @.str.48, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_eq(i64 %r376, i64 %r378)
  %r380 = icmp ne i64 %r379, 0
  br i1 %r380, label %L274, label %L276
L274:
  store i64 6, i64* %ptr_type
  br label %L276
L276:
  %r381 = load i64, i64* %ptr_txt
  %r382 = getelementptr [3 x i8], [3 x i8]* @.str.49, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_eq(i64 %r381, i64 %r383)
  %r385 = icmp ne i64 %r384, 0
  br i1 %r385, label %L277, label %L279
L277:
  store i64 7, i64* %ptr_type
  br label %L279
L279:
  %r386 = load i64, i64* %ptr_txt
  %r387 = getelementptr [7 x i8], [7 x i8]* @.str.50, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = call i64 @_eq(i64 %r386, i64 %r388)
  %r390 = icmp ne i64 %r389, 0
  br i1 %r390, label %L280, label %L282
L280:
  store i64 8, i64* %ptr_type
  br label %L282
L282:
  %r391 = load i64, i64* %ptr_txt
  %r392 = getelementptr [4 x i8], [4 x i8]* @.str.51, i64 0, i64 0
  %r393 = ptrtoint i8* %r392 to i64
  %r394 = call i64 @_eq(i64 %r391, i64 %r393)
  %r395 = icmp ne i64 %r394, 0
  br i1 %r395, label %L283, label %L285
L283:
  store i64 9, i64* %ptr_type
  br label %L285
L285:
  %r396 = load i64, i64* %ptr_txt
  %r397 = getelementptr [5 x i8], [5 x i8]* @.str.52, i64 0, i64 0
  %r398 = ptrtoint i8* %r397 to i64
  %r399 = call i64 @_eq(i64 %r396, i64 %r398)
  %r400 = icmp ne i64 %r399, 0
  br i1 %r400, label %L286, label %L288
L286:
  store i64 10, i64* %ptr_type
  br label %L288
L288:
  %r401 = load i64, i64* %ptr_txt
  %r402 = getelementptr [6 x i8], [6 x i8]* @.str.53, i64 0, i64 0
  %r403 = ptrtoint i8* %r402 to i64
  %r404 = call i64 @_eq(i64 %r401, i64 %r403)
  %r405 = icmp ne i64 %r404, 0
  br i1 %r405, label %L289, label %L291
L289:
  store i64 11, i64* %ptr_type
  br label %L291
L291:
  %r406 = load i64, i64* %ptr_txt
  %r407 = getelementptr [10 x i8], [10 x i8]* @.str.54, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = call i64 @_eq(i64 %r406, i64 %r408)
  %r410 = icmp ne i64 %r409, 0
  br i1 %r410, label %L292, label %L294
L292:
  store i64 12, i64* %ptr_type
  br label %L294
L294:
  %r411 = load i64, i64* %ptr_txt
  %r412 = getelementptr [8 x i8], [8 x i8]* @.str.55, i64 0, i64 0
  %r413 = ptrtoint i8* %r412 to i64
  %r414 = call i64 @_eq(i64 %r411, i64 %r413)
  %r415 = icmp ne i64 %r414, 0
  br i1 %r415, label %L295, label %L297
L295:
  store i64 13, i64* %ptr_type
  br label %L297
L297:
  %r416 = load i64, i64* %ptr_txt
  %r417 = getelementptr [10 x i8], [10 x i8]* @.str.56, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  %r419 = call i64 @_eq(i64 %r416, i64 %r418)
  %r420 = icmp ne i64 %r419, 0
  br i1 %r420, label %L298, label %L300
L298:
  store i64 20, i64* %ptr_type
  br label %L300
L300:
  %r421 = load i64, i64* %ptr_txt
  %r422 = getelementptr [9 x i8], [9 x i8]* @.str.57, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_eq(i64 %r421, i64 %r423)
  %r425 = icmp ne i64 %r424, 0
  br i1 %r425, label %L301, label %L303
L301:
  store i64 35, i64* %ptr_type
  br label %L303
L303:
  %r426 = load i64, i64* %ptr_txt
  %r427 = getelementptr [9 x i8], [9 x i8]* @.str.58, i64 0, i64 0
  %r428 = ptrtoint i8* %r427 to i64
  %r429 = call i64 @_eq(i64 %r426, i64 %r428)
  %r430 = icmp ne i64 %r429, 0
  br i1 %r430, label %L304, label %L306
L304:
  store i64 36, i64* %ptr_type
  br label %L306
L306:
  %r431 = load i64, i64* %ptr_txt
  %r432 = getelementptr [4 x i8], [4 x i8]* @.str.59, i64 0, i64 0
  %r433 = ptrtoint i8* %r432 to i64
  %r434 = call i64 @_eq(i64 %r431, i64 %r433)
  %r435 = icmp ne i64 %r434, 0
  br i1 %r435, label %L307, label %L309
L307:
  store i64 37, i64* %ptr_type
  %r436 = getelementptr [2 x i8], [2 x i8]* @.str.60, i64 0, i64 0
  %r437 = ptrtoint i8* %r436 to i64
  store i64 %r437, i64* %ptr_txt
  br label %L309
L309:
  %r438 = load i64, i64* %ptr_txt
  %r439 = getelementptr [3 x i8], [3 x i8]* @.str.61, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  %r441 = call i64 @_eq(i64 %r438, i64 %r440)
  %r442 = icmp ne i64 %r441, 0
  br i1 %r442, label %L310, label %L312
L310:
  store i64 33, i64* %ptr_type
  br label %L312
L312:
  %r443 = load i64, i64* %ptr_txt
  %r444 = getelementptr [4 x i8], [4 x i8]* @.str.62, i64 0, i64 0
  %r445 = ptrtoint i8* %r444 to i64
  %r446 = call i64 @_eq(i64 %r443, i64 %r445)
  %r447 = icmp ne i64 %r446, 0
  br i1 %r447, label %L313, label %L315
L313:
  store i64 34, i64* %ptr_type
  br label %L315
L315:
  %r448 = load i64, i64* %ptr_txt
  %r449 = getelementptr [6 x i8], [6 x i8]* @.str.63, i64 0, i64 0
  %r450 = ptrtoint i8* %r449 to i64
  %r451 = call i64 @_eq(i64 %r448, i64 %r450)
  %r452 = icmp ne i64 %r451, 0
  br i1 %r452, label %L316, label %L318
L316:
  store i64 1, i64* %ptr_type
  %r453 = getelementptr [2 x i8], [2 x i8]* @.str.64, i64 0, i64 0
  %r454 = ptrtoint i8* %r453 to i64
  store i64 %r454, i64* %ptr_txt
  br label %L318
L318:
  %r455 = load i64, i64* %ptr_txt
  %r456 = getelementptr [7 x i8], [7 x i8]* @.str.65, i64 0, i64 0
  %r457 = ptrtoint i8* %r456 to i64
  %r458 = call i64 @_eq(i64 %r455, i64 %r457)
  %r459 = icmp ne i64 %r458, 0
  br i1 %r459, label %L319, label %L321
L319:
  store i64 1, i64* %ptr_type
  %r460 = getelementptr [2 x i8], [2 x i8]* @.str.66, i64 0, i64 0
  %r461 = ptrtoint i8* %r460 to i64
  store i64 %r461, i64* %ptr_txt
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
  br i1 %r470, label %L322, label %L324
L322:
  %r471 = load i64, i64* @TOK_LPAREN
  store i64 %r471, i64* %ptr_type
  br label %L324
L324:
  %r472 = load i64, i64* %ptr_c
  %r473 = getelementptr [2 x i8], [2 x i8]* @.str.68, i64 0, i64 0
  %r474 = ptrtoint i8* %r473 to i64
  %r475 = call i64 @_eq(i64 %r472, i64 %r474)
  %r476 = icmp ne i64 %r475, 0
  br i1 %r476, label %L325, label %L327
L325:
  %r477 = load i64, i64* @TOK_RPAREN
  store i64 %r477, i64* %ptr_type
  br label %L327
L327:
  %r478 = load i64, i64* %ptr_c
  %r479 = getelementptr [2 x i8], [2 x i8]* @.str.69, i64 0, i64 0
  %r480 = ptrtoint i8* %r479 to i64
  %r481 = call i64 @_eq(i64 %r478, i64 %r480)
  %r482 = icmp ne i64 %r481, 0
  br i1 %r482, label %L328, label %L330
L328:
  %r483 = load i64, i64* @TOK_LBRACE
  store i64 %r483, i64* %ptr_type
  br label %L330
L330:
  %r484 = load i64, i64* %ptr_c
  %r485 = getelementptr [2 x i8], [2 x i8]* @.str.70, i64 0, i64 0
  %r486 = ptrtoint i8* %r485 to i64
  %r487 = call i64 @_eq(i64 %r484, i64 %r486)
  %r488 = icmp ne i64 %r487, 0
  br i1 %r488, label %L331, label %L333
L331:
  %r489 = load i64, i64* @TOK_RBRACE
  store i64 %r489, i64* %ptr_type
  br label %L333
L333:
  %r490 = load i64, i64* %ptr_c
  %r491 = getelementptr [2 x i8], [2 x i8]* @.str.71, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_eq(i64 %r490, i64 %r492)
  %r494 = icmp ne i64 %r493, 0
  br i1 %r494, label %L334, label %L336
L334:
  %r495 = load i64, i64* @TOK_LBRACKET
  store i64 %r495, i64* %ptr_type
  br label %L336
L336:
  %r496 = load i64, i64* %ptr_c
  %r497 = getelementptr [2 x i8], [2 x i8]* @.str.72, i64 0, i64 0
  %r498 = ptrtoint i8* %r497 to i64
  %r499 = call i64 @_eq(i64 %r496, i64 %r498)
  %r500 = icmp ne i64 %r499, 0
  br i1 %r500, label %L337, label %L339
L337:
  %r501 = load i64, i64* @TOK_RBRACKET
  store i64 %r501, i64* %ptr_type
  br label %L339
L339:
  %r502 = load i64, i64* %ptr_c
  %r503 = getelementptr [2 x i8], [2 x i8]* @.str.73, i64 0, i64 0
  %r504 = ptrtoint i8* %r503 to i64
  %r505 = call i64 @_eq(i64 %r502, i64 %r504)
  %r506 = icmp ne i64 %r505, 0
  br i1 %r506, label %L340, label %L342
L340:
  %r507 = load i64, i64* @TOK_COLON
  store i64 %r507, i64* %ptr_type
  br label %L342
L342:
  %r508 = load i64, i64* %ptr_c
  %r509 = getelementptr [2 x i8], [2 x i8]* @.str.74, i64 0, i64 0
  %r510 = ptrtoint i8* %r509 to i64
  %r511 = call i64 @_eq(i64 %r508, i64 %r510)
  %r512 = icmp ne i64 %r511, 0
  br i1 %r512, label %L343, label %L345
L343:
  %r513 = load i64, i64* @TOK_CARET
  store i64 %r513, i64* %ptr_type
  br label %L345
L345:
  %r514 = load i64, i64* %ptr_c
  %r515 = getelementptr [2 x i8], [2 x i8]* @.str.75, i64 0, i64 0
  %r516 = ptrtoint i8* %r515 to i64
  %r517 = call i64 @_eq(i64 %r514, i64 %r516)
  %r518 = icmp ne i64 %r517, 0
  br i1 %r518, label %L346, label %L348
L346:
  %r519 = load i64, i64* @TOK_DOT
  store i64 %r519, i64* %ptr_type
  br label %L348
L348:
  %r520 = load i64, i64* %ptr_c
  %r521 = getelementptr [2 x i8], [2 x i8]* @.str.76, i64 0, i64 0
  %r522 = ptrtoint i8* %r521 to i64
  %r523 = call i64 @_eq(i64 %r520, i64 %r522)
  %r524 = icmp ne i64 %r523, 0
  br i1 %r524, label %L349, label %L351
L349:
  %r525 = load i64, i64* @TOK_COMMA
  store i64 %r525, i64* %ptr_type
  br label %L351
L351:
  %r526 = load i64, i64* %ptr_type
  %r527 = call i64 @_eq(i64 %r526, i64 0)
  %r528 = icmp ne i64 %r527, 0
  br i1 %r528, label %L352, label %L354
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
  br i1 %r538, label %L355, label %L357
L355:
  %r539 = load i64, i64* %ptr_next
  %r540 = getelementptr [2 x i8], [2 x i8]* @.str.78, i64 0, i64 0
  %r541 = ptrtoint i8* %r540 to i64
  %r542 = call i64 @_eq(i64 %r539, i64 %r541)
  %r543 = icmp ne i64 %r542, 0
  br i1 %r543, label %L358, label %L360
L358:
  %r544 = load i64, i64* @TOK_ARROW
  store i64 %r544, i64* %ptr_type
  %r545 = getelementptr [3 x i8], [3 x i8]* @.str.79, i64 0, i64 0
  %r546 = ptrtoint i8* %r545 to i64
  store i64 %r546, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L360
L360:
  br label %L357
L357:
  %r547 = load i64, i64* %ptr_c
  %r548 = getelementptr [2 x i8], [2 x i8]* @.str.80, i64 0, i64 0
  %r549 = ptrtoint i8* %r548 to i64
  %r550 = call i64 @_eq(i64 %r547, i64 %r549)
  %r551 = icmp ne i64 %r550, 0
  br i1 %r551, label %L361, label %L363
L361:
  %r552 = load i64, i64* %ptr_next
  %r553 = getelementptr [2 x i8], [2 x i8]* @.str.81, i64 0, i64 0
  %r554 = ptrtoint i8* %r553 to i64
  %r555 = call i64 @_eq(i64 %r552, i64 %r554)
  %r556 = icmp ne i64 %r555, 0
  br i1 %r556, label %L364, label %L366
L364:
  %r557 = getelementptr [3 x i8], [3 x i8]* @.str.82, i64 0, i64 0
  %r558 = ptrtoint i8* %r557 to i64
  store i64 %r558, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L366
L366:
  br label %L363
L363:
  %r559 = load i64, i64* %ptr_c
  %r560 = getelementptr [2 x i8], [2 x i8]* @.str.83, i64 0, i64 0
  %r561 = ptrtoint i8* %r560 to i64
  %r562 = call i64 @_eq(i64 %r559, i64 %r561)
  %r563 = icmp ne i64 %r562, 0
  br i1 %r563, label %L367, label %L369
L367:
  %r564 = load i64, i64* %ptr_next
  %r565 = getelementptr [2 x i8], [2 x i8]* @.str.84, i64 0, i64 0
  %r566 = ptrtoint i8* %r565 to i64
  %r567 = call i64 @_eq(i64 %r564, i64 %r566)
  %r568 = icmp ne i64 %r567, 0
  br i1 %r568, label %L370, label %L372
L370:
  %r569 = getelementptr [3 x i8], [3 x i8]* @.str.85, i64 0, i64 0
  %r570 = ptrtoint i8* %r569 to i64
  store i64 %r570, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L372
L372:
  br label %L369
L369:
  %r571 = load i64, i64* %ptr_c
  %r572 = getelementptr [2 x i8], [2 x i8]* @.str.86, i64 0, i64 0
  %r573 = ptrtoint i8* %r572 to i64
  %r574 = call i64 @_eq(i64 %r571, i64 %r573)
  %r575 = icmp ne i64 %r574, 0
  br i1 %r575, label %L373, label %L375
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
  br i1 %r599, label %L382, label %L384
L382:
  %r600 = load i64, i64* @TOK_OP
  store i64 %r600, i64* %ptr_type
  %r601 = getelementptr [3 x i8], [3 x i8]* @.str.92, i64 0, i64 0
  %r602 = ptrtoint i8* %r601 to i64
  store i64 %r602, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L384
L384:
  br label %L378
L378:
  br label %L375
L375:
  %r603 = load i64, i64* %ptr_c
  %r604 = getelementptr [2 x i8], [2 x i8]* @.str.93, i64 0, i64 0
  %r605 = ptrtoint i8* %r604 to i64
  %r606 = call i64 @_eq(i64 %r603, i64 %r605)
  %r607 = icmp ne i64 %r606, 0
  br i1 %r607, label %L385, label %L387
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
  br i1 %r631, label %L394, label %L396
L394:
  %r632 = load i64, i64* @TOK_OP
  store i64 %r632, i64* %ptr_type
  %r633 = getelementptr [3 x i8], [3 x i8]* @.str.99, i64 0, i64 0
  %r634 = ptrtoint i8* %r633 to i64
  store i64 %r634, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L396
L396:
  br label %L390
L390:
  br label %L387
L387:
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
  br i1 %r6, label %L397, label %L399
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
  br i1 %r9, label %L400, label %L402
L400:
  %r10 = load i64, i64* @p_pos
  %r11 = call i64 @_add(i64 %r10, i64 1)
  store i64 %r11, i64* @p_pos
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
  br i1 %r8, label %L403, label %L405
L403:
  %r9 = call i64 @advance()
  ret i64 1
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
  br i1 %r3, label %L406, label %L408
L406:
  ret i64 1
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
  br i1 %r4, label %L409, label %L411
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
L411:
  %r15 = load i64, i64* @TOK_STRING
  %r16 = call i64 @consume(i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L412, label %L414
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
L414:
  %r28 = load i64, i64* @TOK_IDENT
  %r29 = call i64 @consume(i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L415, label %L417
L415:
  %r31 = load i64, i64* %ptr_t
  %r32 = getelementptr [5 x i8], [5 x i8]* @.str.116, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_get(i64 %r31, i64 %r33)
  store i64 %r34, i64* %ptr_name
  %r35 = load i64, i64* @TOK_LPAREN
  %r36 = call i64 @consume(i64 %r35)
  %r37 = icmp ne i64 %r36, 0
  br i1 %r37, label %L418, label %L420
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
  br i1 %r46, label %L421, label %L423
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
L417:
  %r73 = load i64, i64* @TOK_LPAREN
  %r74 = call i64 @consume(i64 %r73)
  %r75 = icmp ne i64 %r74, 0
  br i1 %r75, label %L427, label %L429
L427:
  %r76 = call i64 @parse_expr()
  store i64 %r76, i64* %ptr_expr
  %r77 = load i64, i64* @TOK_RPAREN
  %r78 = call i64 @expect(i64 %r77)
  %r79 = load i64, i64* %ptr_expr
  ret i64 %r79
  br label %L429
L429:
  %r80 = load i64, i64* @TOK_LBRACKET
  %r81 = call i64 @consume(i64 %r80)
  %r82 = icmp ne i64 %r81, 0
  br i1 %r82, label %L430, label %L432
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
  br i1 %r91, label %L433, label %L435
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
L432:
  %r108 = load i64, i64* @TOK_LBRACE
  %r109 = call i64 @consume(i64 %r108)
  %r110 = icmp ne i64 %r109, 0
  br i1 %r110, label %L439, label %L441
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
  br i1 %r160, label %L445, label %L447
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
  br i1 %r198, label %L448, label %L450
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
L450:
  %r222 = load i64, i64* %ptr_t
  %r223 = getelementptr [5 x i8], [5 x i8]* @.str.153, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = call i64 @_get(i64 %r222, i64 %r224)
  %r226 = load i64, i64* @TOK_EOF
  %r228 = call i64 @_eq(i64 %r225, i64 %r226)
  %r227 = xor i64 %r228, 1
  %r229 = icmp ne i64 %r227, 0
  br i1 %r229, label %L451, label %L453
L451:
  %r230 = call i64 @advance()
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
  br i1 %r11, label %L466, label %L468
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
  br i1 %r20, label %L469, label %L471
L469:
  store i64 1, i64* %ptr_is_op
  br label %L471
L471:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.169, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L472, label %L474
L472:
  store i64 1, i64* %ptr_is_op
  br label %L474
L474:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.170, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L475, label %L477
L475:
  store i64 1, i64* %ptr_is_op
  br label %L477
L477:
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
  br i1 %r11, label %L484, label %L486
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
  br i1 %r20, label %L487, label %L489
L487:
  store i64 1, i64* %ptr_is_op
  br label %L489
L489:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.179, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L490, label %L492
L490:
  store i64 1, i64* %ptr_is_op
  br label %L492
L492:
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
  br i1 %r15, label %L499, label %L501
L499:
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.187, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L502, label %L504
L502:
  store i64 1, i64* %ptr_is_op
  br label %L504
L504:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.188, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L505, label %L507
L505:
  store i64 1, i64* %ptr_is_op
  br label %L507
L507:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.189, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L508, label %L510
L508:
  store i64 1, i64* %ptr_is_op
  br label %L510
L510:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [4 x i8], [4 x i8]* @.str.190, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L511, label %L513
L511:
  store i64 1, i64* %ptr_is_op
  br label %L513
L513:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [4 x i8], [4 x i8]* @.str.191, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L514, label %L516
L514:
  store i64 1, i64* %ptr_is_op
  br label %L516
L516:
  br label %L501
L501:
  %r41 = load i64, i64* %ptr_t
  %r42 = getelementptr [5 x i8], [5 x i8]* @.str.192, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_get(i64 %r41, i64 %r43)
  %r45 = load i64, i64* @TOK_IDENT
  %r46 = call i64 @_eq(i64 %r44, i64 %r45)
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L517, label %L519
L517:
  %r48 = load i64, i64* %ptr_op
  %r49 = getelementptr [4 x i8], [4 x i8]* @.str.193, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_eq(i64 %r48, i64 %r50)
  %r52 = icmp ne i64 %r51, 0
  br i1 %r52, label %L520, label %L522
L520:
  store i64 1, i64* %ptr_is_op
  %r53 = getelementptr [2 x i8], [2 x i8]* @.str.194, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  store i64 %r54, i64* %ptr_op
  br label %L522
L522:
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
  br i1 %r11, label %L529, label %L531
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
  br i1 %r20, label %L532, label %L534
L532:
  store i64 1, i64* %ptr_is_op
  br label %L534
L534:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [3 x i8], [3 x i8]* @.str.202, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L535, label %L537
L535:
  store i64 1, i64* %ptr_is_op
  br label %L537
L537:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.203, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L538, label %L540
L538:
  store i64 1, i64* %ptr_is_op
  br label %L540
L540:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [2 x i8], [2 x i8]* @.str.204, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L541, label %L543
L541:
  store i64 1, i64* %ptr_is_op
  br label %L543
L543:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [3 x i8], [3 x i8]* @.str.205, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L544, label %L546
L544:
  store i64 1, i64* %ptr_is_op
  br label %L546
L546:
  %r41 = load i64, i64* %ptr_op
  %r42 = getelementptr [3 x i8], [3 x i8]* @.str.206, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_eq(i64 %r41, i64 %r43)
  %r45 = icmp ne i64 %r44, 0
  br i1 %r45, label %L547, label %L549
L547:
  store i64 1, i64* %ptr_is_op
  br label %L549
L549:
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
  br i1 %r18, label %L556, label %L558
L556:
  store i64 1, i64* %ptr_is_op
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
  br i1 %r29, label %L562, label %L564
L562:
  %r30 = getelementptr [4 x i8], [4 x i8]* @.str.216, i64 0, i64 0
  %r31 = ptrtoint i8* %r30 to i64
  store i64 %r31, i64* %ptr_op
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
  br i1 %r31, label %L571, label %L573
L571:
  %r32 = load i64, i64* @STMT_CONST
  store i64 %r32, i64* %ptr_stmt_type
  %r33 = load i64, i64* @TOK_CONST
  %r34 = call i64 @consume(i64 %r33)
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
  br i1 %r39, label %L574, label %L576
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
L576:
  %r62 = load i64, i64* @TOK_PRINT
  %r63 = call i64 @consume(i64 %r62)
  %r64 = icmp ne i64 %r63, 0
  br i1 %r64, label %L577, label %L579
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
L579:
  %r79 = load i64, i64* @TOK_IF
  %r80 = call i64 @consume(i64 %r79)
  %r81 = icmp ne i64 %r80, 0
  br i1 %r81, label %L580, label %L582
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
  %r98 = call i64 @peek()
  %r99 = getelementptr [5 x i8], [5 x i8]* @.str.232, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_get(i64 %r98, i64 %r100)
  %r102 = load i64, i64* @TOK_CARET
  %r103 = call i64 @_eq(i64 %r101, i64 %r102)
  %r104 = icmp ne i64 %r103, 0
  br i1 %r104, label %L586, label %L588
L586:
  %r105 = call i64 @advance()
  br label %L583
L588:
  %r106 = call i64 @parse_stmt()
  %r107 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r107, i64 %r106)
  br label %L583
L585:
  %r108 = load i64, i64* @TOK_RBRACE
  %r109 = call i64 @expect(i64 %r108)
  %r110 = call i64 @_list_new()
  store i64 %r110, i64* %ptr_else_body
  %r111 = load i64, i64* @TOK_ELSE
  %r112 = call i64 @consume(i64 %r111)
  %r113 = icmp ne i64 %r112, 0
  br i1 %r113, label %L589, label %L591
L589:
  %r114 = call i64 @peek()
  %r115 = getelementptr [5 x i8], [5 x i8]* @.str.233, i64 0, i64 0
  %r116 = ptrtoint i8* %r115 to i64
  %r117 = call i64 @_get(i64 %r114, i64 %r116)
  %r118 = load i64, i64* @TOK_IF
  %r119 = call i64 @_eq(i64 %r117, i64 %r118)
  %r120 = icmp ne i64 %r119, 0
  br i1 %r120, label %L592, label %L593
L592:
  %r121 = call i64 @parse_stmt()
  %r122 = load i64, i64* %ptr_else_body
  call i64 @_append_poly(i64 %r122, i64 %r121)
  br label %L594
L593:
  %r123 = load i64, i64* @TOK_LBRACE
  %r124 = call i64 @expect(i64 %r123)
  br label %L595
L595:
  %r125 = call i64 @peek()
  %r126 = getelementptr [5 x i8], [5 x i8]* @.str.234, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = load i64, i64* @TOK_RBRACE
  %r131 = call i64 @_eq(i64 %r128, i64 %r129)
  %r130 = xor i64 %r131, 1
  %r132 = icmp ne i64 %r130, 0
  br i1 %r132, label %L596, label %L597
L596:
  %r133 = call i64 @peek()
  %r134 = getelementptr [5 x i8], [5 x i8]* @.str.235, i64 0, i64 0
  %r135 = ptrtoint i8* %r134 to i64
  %r136 = call i64 @_get(i64 %r133, i64 %r135)
  %r137 = load i64, i64* @TOK_CARET
  %r138 = call i64 @_eq(i64 %r136, i64 %r137)
  %r139 = icmp ne i64 %r138, 0
  br i1 %r139, label %L598, label %L600
L598:
  %r140 = call i64 @advance()
  br label %L595
L600:
  %r141 = call i64 @parse_stmt()
  %r142 = load i64, i64* %ptr_else_body
  call i64 @_append_poly(i64 %r142, i64 %r141)
  br label %L595
L597:
  %r143 = load i64, i64* @TOK_RBRACE
  %r144 = call i64 @expect(i64 %r143)
  br label %L594
L594:
  br label %L591
L591:
  %r145 = call i64 @_map_new()
  %r146 = getelementptr [5 x i8], [5 x i8]* @.str.236, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = load i64, i64* @STMT_IF
  call i64 @_map_set(i64 %r145, i64 %r147, i64 %r148)
  %r149 = getelementptr [5 x i8], [5 x i8]* @.str.237, i64 0, i64 0
  %r150 = ptrtoint i8* %r149 to i64
  %r151 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r145, i64 %r150, i64 %r151)
  %r152 = getelementptr [5 x i8], [5 x i8]* @.str.238, i64 0, i64 0
  %r153 = ptrtoint i8* %r152 to i64
  %r154 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r145, i64 %r153, i64 %r154)
  %r155 = getelementptr [5 x i8], [5 x i8]* @.str.239, i64 0, i64 0
  %r156 = ptrtoint i8* %r155 to i64
  %r157 = load i64, i64* %ptr_else_body
  call i64 @_map_set(i64 %r145, i64 %r156, i64 %r157)
  ret i64 %r145
  br label %L582
L582:
  %r158 = load i64, i64* @TOK_WHILE
  %r159 = call i64 @consume(i64 %r158)
  %r160 = icmp ne i64 %r159, 0
  br i1 %r160, label %L601, label %L603
L601:
  %r161 = load i64, i64* @TOK_LPAREN
  %r162 = call i64 @expect(i64 %r161)
  %r163 = call i64 @parse_expr()
  store i64 %r163, i64* %ptr_cond
  %r164 = load i64, i64* @TOK_RPAREN
  %r165 = call i64 @expect(i64 %r164)
  %r166 = load i64, i64* @TOK_LBRACE
  %r167 = call i64 @expect(i64 %r166)
  %r168 = call i64 @_list_new()
  store i64 %r168, i64* %ptr_body
  br label %L604
L604:
  %r169 = call i64 @peek()
  %r170 = getelementptr [5 x i8], [5 x i8]* @.str.240, i64 0, i64 0
  %r171 = ptrtoint i8* %r170 to i64
  %r172 = call i64 @_get(i64 %r169, i64 %r171)
  %r173 = load i64, i64* @TOK_RBRACE
  %r175 = call i64 @_eq(i64 %r172, i64 %r173)
  %r174 = xor i64 %r175, 1
  %r176 = icmp ne i64 %r174, 0
  br i1 %r176, label %L605, label %L606
L605:
  %r177 = call i64 @parse_stmt()
  %r178 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r178, i64 %r177)
  br label %L604
L606:
  %r179 = load i64, i64* @TOK_RBRACE
  %r180 = call i64 @expect(i64 %r179)
  %r181 = call i64 @_map_new()
  %r182 = getelementptr [5 x i8], [5 x i8]* @.str.241, i64 0, i64 0
  %r183 = ptrtoint i8* %r182 to i64
  %r184 = load i64, i64* @STMT_WHILE
  call i64 @_map_set(i64 %r181, i64 %r183, i64 %r184)
  %r185 = getelementptr [5 x i8], [5 x i8]* @.str.242, i64 0, i64 0
  %r186 = ptrtoint i8* %r185 to i64
  %r187 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r181, i64 %r186, i64 %r187)
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.243, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r181, i64 %r189, i64 %r190)
  ret i64 %r181
  br label %L603
L603:
  %r191 = load i64, i64* @TOK_OPUS
  %r192 = call i64 @consume(i64 %r191)
  %r193 = icmp ne i64 %r192, 0
  br i1 %r193, label %L607, label %L609
L607:
  %r194 = call i64 @advance()
  store i64 %r194, i64* %ptr_name
  %r195 = load i64, i64* @TOK_LPAREN
  %r196 = call i64 @expect(i64 %r195)
  %r197 = call i64 @_list_new()
  store i64 %r197, i64* %ptr_params
  %r198 = call i64 @peek()
  %r199 = getelementptr [5 x i8], [5 x i8]* @.str.244, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  %r202 = load i64, i64* @TOK_RPAREN
  %r204 = call i64 @_eq(i64 %r201, i64 %r202)
  %r203 = xor i64 %r204, 1
  %r205 = icmp ne i64 %r203, 0
  br i1 %r205, label %L610, label %L612
L610:
  %r206 = call i64 @advance()
  store i64 %r206, i64* %ptr_p
  %r207 = load i64, i64* %ptr_p
  %r208 = getelementptr [5 x i8], [5 x i8]* @.str.245, i64 0, i64 0
  %r209 = ptrtoint i8* %r208 to i64
  %r210 = call i64 @_get(i64 %r207, i64 %r209)
  %r211 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r211, i64 %r210)
  br label %L613
L613:
  %r212 = load i64, i64* @TOK_COMMA
  %r213 = call i64 @consume(i64 %r212)
  %r214 = icmp ne i64 %r213, 0
  br i1 %r214, label %L614, label %L615
L614:
  %r215 = call i64 @advance()
  store i64 %r215, i64* %ptr_p
  %r216 = load i64, i64* %ptr_p
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.246, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_get(i64 %r216, i64 %r218)
  %r220 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r220, i64 %r219)
  br label %L613
L615:
  br label %L612
L612:
  %r221 = load i64, i64* @TOK_RPAREN
  %r222 = call i64 @expect(i64 %r221)
  %r223 = load i64, i64* @TOK_LBRACE
  %r224 = call i64 @expect(i64 %r223)
  %r225 = call i64 @_list_new()
  store i64 %r225, i64* %ptr_body
  br label %L616
L616:
  %r226 = call i64 @peek()
  %r227 = getelementptr [5 x i8], [5 x i8]* @.str.247, i64 0, i64 0
  %r228 = ptrtoint i8* %r227 to i64
  %r229 = call i64 @_get(i64 %r226, i64 %r228)
  %r230 = load i64, i64* @TOK_RBRACE
  %r232 = call i64 @_eq(i64 %r229, i64 %r230)
  %r231 = xor i64 %r232, 1
  %r233 = icmp ne i64 %r231, 0
  br i1 %r233, label %L617, label %L618
L617:
  %r234 = call i64 @parse_stmt()
  %r235 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r235, i64 %r234)
  br label %L616
L618:
  %r236 = load i64, i64* @TOK_RBRACE
  %r237 = call i64 @expect(i64 %r236)
  %r238 = call i64 @_map_new()
  %r239 = getelementptr [5 x i8], [5 x i8]* @.str.248, i64 0, i64 0
  %r240 = ptrtoint i8* %r239 to i64
  %r241 = load i64, i64* @STMT_FUNC
  call i64 @_map_set(i64 %r238, i64 %r240, i64 %r241)
  %r242 = getelementptr [5 x i8], [5 x i8]* @.str.249, i64 0, i64 0
  %r243 = ptrtoint i8* %r242 to i64
  %r244 = load i64, i64* %ptr_name
  %r245 = getelementptr [5 x i8], [5 x i8]* @.str.250, i64 0, i64 0
  %r246 = ptrtoint i8* %r245 to i64
  %r247 = call i64 @_get(i64 %r244, i64 %r246)
  call i64 @_map_set(i64 %r238, i64 %r243, i64 %r247)
  %r248 = getelementptr [7 x i8], [7 x i8]* @.str.251, i64 0, i64 0
  %r249 = ptrtoint i8* %r248 to i64
  %r250 = load i64, i64* %ptr_params
  call i64 @_map_set(i64 %r238, i64 %r249, i64 %r250)
  %r251 = getelementptr [5 x i8], [5 x i8]* @.str.252, i64 0, i64 0
  %r252 = ptrtoint i8* %r251 to i64
  %r253 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r238, i64 %r252, i64 %r253)
  ret i64 %r238
  br label %L609
L609:
  %r254 = load i64, i64* @TOK_REDDO
  %r255 = call i64 @consume(i64 %r254)
  %r256 = icmp ne i64 %r255, 0
  br i1 %r256, label %L619, label %L621
L619:
  %r257 = call i64 @parse_expr()
  store i64 %r257, i64* %ptr_val
  %r258 = load i64, i64* @TOK_CARET
  %r259 = call i64 @expect(i64 %r258)
  %r260 = call i64 @_map_new()
  %r261 = getelementptr [5 x i8], [5 x i8]* @.str.253, i64 0, i64 0
  %r262 = ptrtoint i8* %r261 to i64
  %r263 = load i64, i64* @STMT_RETURN
  call i64 @_map_set(i64 %r260, i64 %r262, i64 %r263)
  %r264 = getelementptr [4 x i8], [4 x i8]* @.str.254, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r260, i64 %r265, i64 %r266)
  ret i64 %r260
  br label %L621
L621:
  %r267 = load i64, i64* @TOK_BREAK
  %r268 = call i64 @consume(i64 %r267)
  %r269 = icmp ne i64 %r268, 0
  br i1 %r269, label %L622, label %L624
L622:
  %r270 = load i64, i64* @TOK_CARET
  %r271 = call i64 @expect(i64 %r270)
  %r272 = call i64 @_map_new()
  %r273 = getelementptr [5 x i8], [5 x i8]* @.str.255, i64 0, i64 0
  %r274 = ptrtoint i8* %r273 to i64
  %r275 = load i64, i64* @STMT_BREAK
  call i64 @_map_set(i64 %r272, i64 %r274, i64 %r275)
  ret i64 %r272
  br label %L624
L624:
  %r276 = load i64, i64* @TOK_CONTINUE
  %r277 = call i64 @consume(i64 %r276)
  %r278 = icmp ne i64 %r277, 0
  br i1 %r278, label %L625, label %L627
L625:
  %r279 = load i64, i64* @TOK_CARET
  %r280 = call i64 @expect(i64 %r279)
  %r281 = call i64 @_map_new()
  %r282 = getelementptr [5 x i8], [5 x i8]* @.str.256, i64 0, i64 0
  %r283 = ptrtoint i8* %r282 to i64
  %r284 = load i64, i64* @STMT_CONTINUE
  call i64 @_map_set(i64 %r281, i64 %r283, i64 %r284)
  ret i64 %r281
  br label %L627
L627:
  %r285 = load i64, i64* @TOK_IMPORT
  %r286 = call i64 @consume(i64 %r285)
  %r287 = icmp ne i64 %r286, 0
  br i1 %r287, label %L628, label %L630
L628:
  %r288 = load i64, i64* @TOK_LPAREN
  %r289 = call i64 @expect(i64 %r288)
  %r290 = call i64 @parse_expr()
  store i64 %r290, i64* %ptr_path
  %r291 = load i64, i64* @TOK_RPAREN
  %r292 = call i64 @expect(i64 %r291)
  %r293 = load i64, i64* @TOK_CARET
  %r294 = call i64 @expect(i64 %r293)
  %r295 = call i64 @_map_new()
  %r296 = getelementptr [5 x i8], [5 x i8]* @.str.257, i64 0, i64 0
  %r297 = ptrtoint i8* %r296 to i64
  %r298 = load i64, i64* @STMT_IMPORT
  call i64 @_map_set(i64 %r295, i64 %r297, i64 %r298)
  %r299 = getelementptr [4 x i8], [4 x i8]* @.str.258, i64 0, i64 0
  %r300 = ptrtoint i8* %r299 to i64
  %r301 = load i64, i64* %ptr_path
  call i64 @_map_set(i64 %r295, i64 %r300, i64 %r301)
  ret i64 %r295
  br label %L630
L630:
  %r302 = load i64, i64* %ptr_t
  %r303 = getelementptr [5 x i8], [5 x i8]* @.str.259, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_get(i64 %r302, i64 %r304)
  %r306 = load i64, i64* @TOK_IDENT
  %r307 = call i64 @_eq(i64 %r305, i64 %r306)
  %r308 = icmp ne i64 %r307, 0
  br i1 %r308, label %L631, label %L633
L631:
  %r309 = load i64, i64* @p_pos
  %r310 = call i64 @_add(i64 %r309, i64 1)
  store i64 %r310, i64* %ptr_next_idx
  %r311 = load i64, i64* %ptr_next_idx
  %r312 = load i64, i64* @global_tokens
  %r313 = call i64 @mensura(i64 %r312)
  %r315 = icmp sge i64 %r311, %r313
  %r314 = zext i1 %r315 to i64
  %r316 = icmp ne i64 %r314, 0
  br i1 %r316, label %L634, label %L636
L634:
  %r317 = getelementptr [15 x i8], [15 x i8]* @.str.260, i64 0, i64 0
  %r318 = ptrtoint i8* %r317 to i64
  %r319 = call i64 @error_report(i64 %r318)
  %r320 = call i64 @_map_new()
  %r321 = getelementptr [5 x i8], [5 x i8]* @.str.261, i64 0, i64 0
  %r322 = ptrtoint i8* %r321 to i64
  %r323 = sub i64 0, 1
  call i64 @_map_set(i64 %r320, i64 %r322, i64 %r323)
  ret i64 %r320
  br label %L636
L636:
  %r324 = load i64, i64* @global_tokens
  %r325 = load i64, i64* %ptr_next_idx
  %r326 = call i64 @_get(i64 %r324, i64 %r325)
  store i64 %r326, i64* %ptr_next
  %r327 = load i64, i64* %ptr_next
  %r328 = getelementptr [5 x i8], [5 x i8]* @.str.262, i64 0, i64 0
  %r329 = ptrtoint i8* %r328 to i64
  %r330 = call i64 @_get(i64 %r327, i64 %r329)
  %r331 = load i64, i64* @TOK_ARROW
  %r332 = call i64 @_eq(i64 %r330, i64 %r331)
  %r333 = icmp ne i64 %r332, 0
  br i1 %r333, label %L637, label %L639
L637:
  %r334 = call i64 @advance()
  store i64 %r334, i64* %ptr_name
  %r335 = call i64 @advance()
  %r336 = call i64 @parse_expr()
  store i64 %r336, i64* %ptr_val
  %r337 = load i64, i64* @TOK_CARET
  %r338 = call i64 @expect(i64 %r337)
  %r339 = call i64 @_map_new()
  %r340 = getelementptr [5 x i8], [5 x i8]* @.str.263, i64 0, i64 0
  %r341 = ptrtoint i8* %r340 to i64
  %r342 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r339, i64 %r341, i64 %r342)
  %r343 = getelementptr [5 x i8], [5 x i8]* @.str.264, i64 0, i64 0
  %r344 = ptrtoint i8* %r343 to i64
  %r345 = load i64, i64* %ptr_name
  %r346 = getelementptr [5 x i8], [5 x i8]* @.str.265, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = call i64 @_get(i64 %r345, i64 %r347)
  call i64 @_map_set(i64 %r339, i64 %r344, i64 %r348)
  %r349 = getelementptr [4 x i8], [4 x i8]* @.str.266, i64 0, i64 0
  %r350 = ptrtoint i8* %r349 to i64
  %r351 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r339, i64 %r350, i64 %r351)
  ret i64 %r339
  br label %L639
L639:
  %r352 = load i64, i64* %ptr_next
  %r353 = getelementptr [5 x i8], [5 x i8]* @.str.267, i64 0, i64 0
  %r354 = ptrtoint i8* %r353 to i64
  %r355 = call i64 @_get(i64 %r352, i64 %r354)
  %r356 = load i64, i64* @TOK_APPEND
  %r357 = call i64 @_eq(i64 %r355, i64 %r356)
  %r358 = icmp ne i64 %r357, 0
  br i1 %r358, label %L640, label %L642
L640:
  %r359 = call i64 @advance()
  store i64 %r359, i64* %ptr_name
  %r360 = call i64 @advance()
  %r361 = call i64 @parse_expr()
  store i64 %r361, i64* %ptr_val
  %r362 = load i64, i64* @TOK_CARET
  %r363 = call i64 @expect(i64 %r362)
  %r364 = call i64 @_map_new()
  %r365 = getelementptr [5 x i8], [5 x i8]* @.str.268, i64 0, i64 0
  %r366 = ptrtoint i8* %r365 to i64
  %r367 = load i64, i64* @STMT_APPEND
  call i64 @_map_set(i64 %r364, i64 %r366, i64 %r367)
  %r368 = getelementptr [5 x i8], [5 x i8]* @.str.269, i64 0, i64 0
  %r369 = ptrtoint i8* %r368 to i64
  %r370 = load i64, i64* %ptr_name
  %r371 = getelementptr [5 x i8], [5 x i8]* @.str.270, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_get(i64 %r370, i64 %r372)
  call i64 @_map_set(i64 %r364, i64 %r369, i64 %r373)
  %r374 = getelementptr [4 x i8], [4 x i8]* @.str.271, i64 0, i64 0
  %r375 = ptrtoint i8* %r374 to i64
  %r376 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r364, i64 %r375, i64 %r376)
  ret i64 %r364
  br label %L642
L642:
  %r377 = load i64, i64* %ptr_next
  %r378 = getelementptr [5 x i8], [5 x i8]* @.str.272, i64 0, i64 0
  %r379 = ptrtoint i8* %r378 to i64
  %r380 = call i64 @_get(i64 %r377, i64 %r379)
  %r381 = load i64, i64* @TOK_LBRACKET
  %r382 = call i64 @_eq(i64 %r380, i64 %r381)
  %r383 = icmp ne i64 %r382, 0
  br i1 %r383, label %L643, label %L645
L643:
  %r384 = call i64 @parse_expr()
  store i64 %r384, i64* %ptr_lhs
  %r385 = load i64, i64* @TOK_ARROW
  %r386 = call i64 @consume(i64 %r385)
  %r387 = icmp ne i64 %r386, 0
  br i1 %r387, label %L646, label %L648
L646:
  %r388 = call i64 @parse_expr()
  store i64 %r388, i64* %ptr_val
  %r389 = load i64, i64* @TOK_CARET
  %r390 = call i64 @expect(i64 %r389)
  %r391 = load i64, i64* %ptr_lhs
  %r392 = getelementptr [5 x i8], [5 x i8]* @.str.273, i64 0, i64 0
  %r393 = ptrtoint i8* %r392 to i64
  %r394 = call i64 @_get(i64 %r391, i64 %r393)
  %r395 = load i64, i64* @EXPR_INDEX
  %r396 = call i64 @_eq(i64 %r394, i64 %r395)
  %r397 = icmp ne i64 %r396, 0
  br i1 %r397, label %L649, label %L651
L649:
  %r398 = load i64, i64* %ptr_lhs
  %r399 = getelementptr [4 x i8], [4 x i8]* @.str.274, i64 0, i64 0
  %r400 = ptrtoint i8* %r399 to i64
  %r401 = call i64 @_get(i64 %r398, i64 %r400)
  store i64 %r401, i64* %ptr_arr_nm
  %r402 = call i64 @_map_new()
  %r403 = getelementptr [5 x i8], [5 x i8]* @.str.275, i64 0, i64 0
  %r404 = ptrtoint i8* %r403 to i64
  %r405 = load i64, i64* @STMT_SET_INDEX
  call i64 @_map_set(i64 %r402, i64 %r404, i64 %r405)
  %r406 = getelementptr [5 x i8], [5 x i8]* @.str.276, i64 0, i64 0
  %r407 = ptrtoint i8* %r406 to i64
  %r408 = load i64, i64* %ptr_arr_nm
  %r409 = getelementptr [5 x i8], [5 x i8]* @.str.277, i64 0, i64 0
  %r410 = ptrtoint i8* %r409 to i64
  %r411 = call i64 @_get(i64 %r408, i64 %r410)
  call i64 @_map_set(i64 %r402, i64 %r407, i64 %r411)
  %r412 = getelementptr [4 x i8], [4 x i8]* @.str.278, i64 0, i64 0
  %r413 = ptrtoint i8* %r412 to i64
  %r414 = load i64, i64* %ptr_lhs
  %r415 = getelementptr [4 x i8], [4 x i8]* @.str.279, i64 0, i64 0
  %r416 = ptrtoint i8* %r415 to i64
  %r417 = call i64 @_get(i64 %r414, i64 %r416)
  call i64 @_map_set(i64 %r402, i64 %r413, i64 %r417)
  %r418 = getelementptr [4 x i8], [4 x i8]* @.str.280, i64 0, i64 0
  %r419 = ptrtoint i8* %r418 to i64
  %r420 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r402, i64 %r419, i64 %r420)
  ret i64 %r402
  br label %L651
L651:
  br label %L648
L648:
  br label %L645
L645:
  %r421 = load i64, i64* %ptr_next
  %r422 = getelementptr [5 x i8], [5 x i8]* @.str.281, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_get(i64 %r421, i64 %r423)
  %r425 = load i64, i64* @TOK_LPAREN
  %r426 = call i64 @_eq(i64 %r424, i64 %r425)
  %r427 = icmp ne i64 %r426, 0
  br i1 %r427, label %L652, label %L654
L652:
  %r428 = call i64 @parse_expr()
  store i64 %r428, i64* %ptr_expr
  %r429 = load i64, i64* @TOK_CARET
  %r430 = call i64 @expect(i64 %r429)
  %r431 = call i64 @_map_new()
  %r432 = getelementptr [5 x i8], [5 x i8]* @.str.282, i64 0, i64 0
  %r433 = ptrtoint i8* %r432 to i64
  %r434 = load i64, i64* @STMT_EXPR
  call i64 @_map_set(i64 %r431, i64 %r433, i64 %r434)
  %r435 = getelementptr [5 x i8], [5 x i8]* @.str.283, i64 0, i64 0
  %r436 = ptrtoint i8* %r435 to i64
  %r437 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r431, i64 %r436, i64 %r437)
  ret i64 %r431
  br label %L654
L654:
  br label %L633
L633:
  %r438 = load i64, i64* %ptr_t
  %r439 = getelementptr [5 x i8], [5 x i8]* @.str.284, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  %r441 = call i64 @_get(i64 %r438, i64 %r440)
  %r442 = load i64, i64* @TOK_EOF
  %r444 = call i64 @_eq(i64 %r441, i64 %r442)
  %r443 = xor i64 %r444, 1
  %r445 = icmp ne i64 %r443, 0
  br i1 %r445, label %L655, label %L657
L655:
  %r446 = call i64 @advance()
  br label %L657
L657:
  %r447 = call i64 @_map_new()
  %r448 = getelementptr [5 x i8], [5 x i8]* @.str.285, i64 0, i64 0
  %r449 = ptrtoint i8* %r448 to i64
  %r450 = sub i64 0, 1
  call i64 @_map_set(i64 %r447, i64 %r449, i64 %r450)
  ret i64 %r447
  ret i64 0
}
define i64 @next_reg() {
  %r1 = load i64, i64* @reg_count
  %r2 = call i64 @_add(i64 %r1, i64 1)
  store i64 %r2, i64* @reg_count
  %r3 = getelementptr [3 x i8], [3 x i8]* @.str.286, i64 0, i64 0
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
  %r3 = getelementptr [2 x i8], [2 x i8]* @.str.287, i64 0, i64 0
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
  %r2 = getelementptr [3 x i8], [3 x i8]* @.str.288, i64 0, i64 0
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
  %r1 = getelementptr [1 x i8], [1 x i8]* @.str.289, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  store i64 %r2, i64* %ptr_out
  %r3 = load i64, i64* %ptr_s
  %r4 = call i64 @mensura(i64 %r3)
  store i64 %r4, i64* %ptr_len
  store i64 0, i64* %ptr_i
  br label %L658
L658:
  %r5 = load i64, i64* %ptr_i
  %r6 = load i64, i64* %ptr_len
  %r8 = icmp slt i64 %r5, %r6
  %r7 = zext i1 %r8 to i64
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L659, label %L660
L659:
  %r10 = load i64, i64* %ptr_s
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @pars(i64 %r10, i64 %r11, i64 1)
  store i64 %r12, i64* %ptr_c
  %r13 = load i64, i64* %ptr_c
  %r14 = getelementptr [2 x i8], [2 x i8]* @.str.290, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_eq(i64 %r13, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L661, label %L662
L661:
  %r18 = load i64, i64* %ptr_out
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.291, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  store i64 %r21, i64* %ptr_out
  br label %L663
L662:
  %r22 = load i64, i64* %ptr_c
  %r23 = getelementptr [2 x i8], [2 x i8]* @.str.292, i64 0, i64 0
  %r24 = ptrtoint i8* %r23 to i64
  %r25 = call i64 @_eq(i64 %r22, i64 %r24)
  %r26 = icmp ne i64 %r25, 0
  br i1 %r26, label %L664, label %L665
L664:
  %r27 = load i64, i64* %ptr_out
  %r28 = getelementptr [4 x i8], [4 x i8]* @.str.293, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = call i64 @_add(i64 %r27, i64 %r29)
  store i64 %r30, i64* %ptr_out
  br label %L666
L665:
  %r31 = load i64, i64* %ptr_c
  %r32 = call i64 @codex(i64 %r31)
  %r33 = call i64 @_eq(i64 %r32, i64 10)
  %r34 = icmp ne i64 %r33, 0
  br i1 %r34, label %L667, label %L668
L667:
  %r35 = load i64, i64* %ptr_out
  %r36 = getelementptr [4 x i8], [4 x i8]* @.str.294, i64 0, i64 0
  %r37 = ptrtoint i8* %r36 to i64
  %r38 = call i64 @_add(i64 %r35, i64 %r37)
  store i64 %r38, i64* %ptr_out
  br label %L669
L668:
  %r39 = load i64, i64* %ptr_out
  %r40 = load i64, i64* %ptr_c
  %r41 = call i64 @_add(i64 %r39, i64 %r40)
  store i64 %r41, i64* %ptr_out
  br label %L669
L669:
  br label %L666
L666:
  br label %L663
L663:
  %r42 = load i64, i64* %ptr_i
  %r43 = call i64 @_add(i64 %r42, i64 1)
  store i64 %r43, i64* %ptr_i
  br label %L658
L660:
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
  %r3 = getelementptr [7 x i8], [7 x i8]* @.str.295, i64 0, i64 0
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
  %r14 = getelementptr [35 x i8], [35 x i8]* @.str.296, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_add(i64 %r13, i64 %r15)
  %r17 = load i64, i64* %ptr_len
  %r18 = call i64 @int_to_str(i64 %r17)
  %r19 = call i64 @_add(i64 %r16, i64 %r18)
  %r20 = getelementptr [10 x i8], [10 x i8]* @.str.297, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_add(i64 %r19, i64 %r21)
  %r23 = load i64, i64* %ptr_safe_txt
  %r24 = call i64 @_add(i64 %r22, i64 %r23)
  %r25 = getelementptr [14 x i8], [14 x i8]* @.str.298, i64 0, i64 0
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
  br i1 %r8, label %L670, label %L672
L670:
  %r9 = load i64, i64* %ptr_ptr
  ret i64 %r9
  br label %L672
L672:
  %r10 = load i64, i64* @global_map
  %r11 = load i64, i64* %ptr_name
  %r12 = call i64 @_get(i64 %r10, i64 %r11)
  store i64 %r12, i64* %ptr_ptr
  %r13 = load i64, i64* %ptr_ptr
  %r14 = call i64 @mensura(i64 %r13)
  %r16 = icmp sgt i64 %r14, 0
  %r15 = zext i1 %r16 to i64
  %r17 = icmp ne i64 %r15, 0
  br i1 %r17, label %L673, label %L675
L673:
  %r18 = load i64, i64* %ptr_ptr
  ret i64 %r18
  br label %L675
L675:
  %r19 = getelementptr [1 x i8], [1 x i8]* @.str.299, i64 0, i64 0
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
  %ptr_sz_reg = alloca i64
  %ptr_off_reg = alloca i64
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
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.300, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @EXPR_INT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L676, label %L678
L676:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.301, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  ret i64 %r11
  br label %L678
L678:
  %r12 = load i64, i64* %ptr_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.302, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_VAR
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L679, label %L681
L679:
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [5 x i8], [5 x i8]* @.str.303, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @get_var_ptr(i64 %r22)
  store i64 %r23, i64* %ptr_ptr
  %r24 = load i64, i64* %ptr_ptr
  %r25 = call i64 @mensura(i64 %r24)
  %r26 = call i64 @_eq(i64 %r25, i64 0)
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L682, label %L684
L682:
  %r28 = getelementptr [33 x i8], [33 x i8]* @.str.304, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_node
  %r31 = getelementptr [5 x i8], [5 x i8]* @.str.305, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = call i64 @_get(i64 %r30, i64 %r32)
  %r34 = call i64 @_add(i64 %r29, i64 %r33)
  %r35 = getelementptr [2 x i8], [2 x i8]* @.str.306, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  call i64 @print_any(i64 %r37)
  %r38 = getelementptr [2 x i8], [2 x i8]* @.str.307, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  ret i64 %r39
  br label %L684
L684:
  %r40 = call i64 @next_reg()
  store i64 %r40, i64* %ptr_res
  %r41 = load i64, i64* %ptr_res
  %r42 = getelementptr [19 x i8], [19 x i8]* @.str.308, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_add(i64 %r41, i64 %r43)
  %r45 = load i64, i64* %ptr_ptr
  %r46 = call i64 @_add(i64 %r44, i64 %r45)
  %r47 = call i64 @emit(i64 %r46)
  %r48 = load i64, i64* %ptr_res
  ret i64 %r48
  br label %L681
L681:
  %r49 = load i64, i64* %ptr_node
  %r50 = getelementptr [5 x i8], [5 x i8]* @.str.309, i64 0, i64 0
  %r51 = ptrtoint i8* %r50 to i64
  %r52 = call i64 @_get(i64 %r49, i64 %r51)
  %r53 = load i64, i64* @EXPR_STRING
  %r54 = call i64 @_eq(i64 %r52, i64 %r53)
  %r55 = icmp ne i64 %r54, 0
  br i1 %r55, label %L685, label %L687
L685:
  %r56 = load i64, i64* %ptr_node
  %r57 = getelementptr [4 x i8], [4 x i8]* @.str.310, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = call i64 @_get(i64 %r56, i64 %r58)
  %r60 = call i64 @add_global_string(i64 %r59)
  store i64 %r60, i64* %ptr_global_ptr
  %r61 = call i64 @next_reg()
  store i64 %r61, i64* %ptr_res
  %r62 = load i64, i64* %ptr_node
  %r63 = getelementptr [4 x i8], [4 x i8]* @.str.311, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = call i64 @_get(i64 %r62, i64 %r64)
  %r66 = call i64 @mensura(i64 %r65)
  %r67 = call i64 @_add(i64 %r66, i64 1)
  store i64 %r67, i64* %ptr_len
  %r68 = load i64, i64* %ptr_res
  %r69 = getelementptr [19 x i8], [19 x i8]* @.str.312, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = call i64 @_add(i64 %r68, i64 %r70)
  %r72 = load i64, i64* %ptr_len
  %r73 = call i64 @int_to_str(i64 %r72)
  %r74 = call i64 @_add(i64 %r71, i64 %r73)
  %r75 = getelementptr [10 x i8], [10 x i8]* @.str.313, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = call i64 @_add(i64 %r74, i64 %r76)
  %r78 = load i64, i64* %ptr_len
  %r79 = call i64 @int_to_str(i64 %r78)
  %r80 = call i64 @_add(i64 %r77, i64 %r79)
  %r81 = getelementptr [9 x i8], [9 x i8]* @.str.314, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_add(i64 %r80, i64 %r82)
  %r84 = load i64, i64* %ptr_global_ptr
  %r85 = call i64 @_add(i64 %r83, i64 %r84)
  %r86 = getelementptr [15 x i8], [15 x i8]* @.str.315, i64 0, i64 0
  %r87 = ptrtoint i8* %r86 to i64
  %r88 = call i64 @_add(i64 %r85, i64 %r87)
  %r89 = call i64 @emit(i64 %r88)
  %r90 = call i64 @next_reg()
  store i64 %r90, i64* %ptr_cast_res
  %r91 = load i64, i64* %ptr_cast_res
  %r92 = getelementptr [17 x i8], [17 x i8]* @.str.316, i64 0, i64 0
  %r93 = ptrtoint i8* %r92 to i64
  %r94 = call i64 @_add(i64 %r91, i64 %r93)
  %r95 = load i64, i64* %ptr_res
  %r96 = call i64 @_add(i64 %r94, i64 %r95)
  %r97 = getelementptr [8 x i8], [8 x i8]* @.str.317, i64 0, i64 0
  %r98 = ptrtoint i8* %r97 to i64
  %r99 = call i64 @_add(i64 %r96, i64 %r98)
  %r100 = call i64 @emit(i64 %r99)
  %r101 = load i64, i64* %ptr_cast_res
  ret i64 %r101
  br label %L687
L687:
  %r102 = load i64, i64* %ptr_node
  %r103 = getelementptr [5 x i8], [5 x i8]* @.str.318, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @_get(i64 %r102, i64 %r104)
  %r106 = load i64, i64* @EXPR_BINARY
  %r107 = call i64 @_eq(i64 %r105, i64 %r106)
  %r108 = icmp ne i64 %r107, 0
  br i1 %r108, label %L688, label %L690
L688:
  %r109 = load i64, i64* %ptr_node
  %r110 = getelementptr [5 x i8], [5 x i8]* @.str.319, i64 0, i64 0
  %r111 = ptrtoint i8* %r110 to i64
  %r112 = call i64 @_get(i64 %r109, i64 %r111)
  %r113 = call i64 @compile_expr(i64 %r112)
  store i64 %r113, i64* %ptr_lhs
  %r114 = load i64, i64* %ptr_node
  %r115 = getelementptr [6 x i8], [6 x i8]* @.str.320, i64 0, i64 0
  %r116 = ptrtoint i8* %r115 to i64
  %r117 = call i64 @_get(i64 %r114, i64 %r116)
  %r118 = call i64 @compile_expr(i64 %r117)
  store i64 %r118, i64* %ptr_rhs
  %r119 = load i64, i64* %ptr_node
  %r120 = getelementptr [3 x i8], [3 x i8]* @.str.321, i64 0, i64 0
  %r121 = ptrtoint i8* %r120 to i64
  %r122 = call i64 @_get(i64 %r119, i64 %r121)
  store i64 %r122, i64* %ptr_op
  %r123 = call i64 @next_reg()
  store i64 %r123, i64* %ptr_res
  store i64 0, i64* %ptr_defined
  %r124 = load i64, i64* %ptr_op
  %r125 = getelementptr [2 x i8], [2 x i8]* @.str.322, i64 0, i64 0
  %r126 = ptrtoint i8* %r125 to i64
  %r127 = call i64 @_eq(i64 %r124, i64 %r126)
  %r128 = icmp ne i64 %r127, 0
  br i1 %r128, label %L691, label %L692
L691:
  %r129 = load i64, i64* %ptr_res
  %r130 = getelementptr [23 x i8], [23 x i8]* @.str.323, i64 0, i64 0
  %r131 = ptrtoint i8* %r130 to i64
  %r132 = call i64 @_add(i64 %r129, i64 %r131)
  %r133 = load i64, i64* %ptr_lhs
  %r134 = call i64 @_add(i64 %r132, i64 %r133)
  %r135 = getelementptr [7 x i8], [7 x i8]* @.str.324, i64 0, i64 0
  %r136 = ptrtoint i8* %r135 to i64
  %r137 = call i64 @_add(i64 %r134, i64 %r136)
  %r138 = load i64, i64* %ptr_rhs
  %r139 = call i64 @_add(i64 %r137, i64 %r138)
  %r140 = getelementptr [2 x i8], [2 x i8]* @.str.325, i64 0, i64 0
  %r141 = ptrtoint i8* %r140 to i64
  %r142 = call i64 @_add(i64 %r139, i64 %r141)
  %r143 = call i64 @emit(i64 %r142)
  store i64 1, i64* %ptr_defined
  br label %L693
L692:
  %r144 = load i64, i64* %ptr_op
  %r145 = getelementptr [2 x i8], [2 x i8]* @.str.326, i64 0, i64 0
  %r146 = ptrtoint i8* %r145 to i64
  %r147 = call i64 @_eq(i64 %r144, i64 %r146)
  %r148 = icmp ne i64 %r147, 0
  br i1 %r148, label %L694, label %L695
L694:
  %r149 = load i64, i64* %ptr_res
  %r150 = getelementptr [12 x i8], [12 x i8]* @.str.327, i64 0, i64 0
  %r151 = ptrtoint i8* %r150 to i64
  %r152 = call i64 @_add(i64 %r149, i64 %r151)
  %r153 = load i64, i64* %ptr_lhs
  %r154 = call i64 @_add(i64 %r152, i64 %r153)
  %r155 = getelementptr [3 x i8], [3 x i8]* @.str.328, i64 0, i64 0
  %r156 = ptrtoint i8* %r155 to i64
  %r157 = call i64 @_add(i64 %r154, i64 %r156)
  %r158 = load i64, i64* %ptr_rhs
  %r159 = call i64 @_add(i64 %r157, i64 %r158)
  %r160 = call i64 @emit(i64 %r159)
  store i64 1, i64* %ptr_defined
  br label %L696
L695:
  %r161 = load i64, i64* %ptr_op
  %r162 = getelementptr [2 x i8], [2 x i8]* @.str.329, i64 0, i64 0
  %r163 = ptrtoint i8* %r162 to i64
  %r164 = call i64 @_eq(i64 %r161, i64 %r163)
  %r165 = icmp ne i64 %r164, 0
  br i1 %r165, label %L697, label %L698
L697:
  %r166 = load i64, i64* %ptr_res
  %r167 = getelementptr [12 x i8], [12 x i8]* @.str.330, i64 0, i64 0
  %r168 = ptrtoint i8* %r167 to i64
  %r169 = call i64 @_add(i64 %r166, i64 %r168)
  %r170 = load i64, i64* %ptr_lhs
  %r171 = call i64 @_add(i64 %r169, i64 %r170)
  %r172 = getelementptr [3 x i8], [3 x i8]* @.str.331, i64 0, i64 0
  %r173 = ptrtoint i8* %r172 to i64
  %r174 = call i64 @_add(i64 %r171, i64 %r173)
  %r175 = load i64, i64* %ptr_rhs
  %r176 = call i64 @_add(i64 %r174, i64 %r175)
  %r177 = call i64 @emit(i64 %r176)
  store i64 1, i64* %ptr_defined
  br label %L699
L698:
  %r178 = load i64, i64* %ptr_op
  %r179 = getelementptr [2 x i8], [2 x i8]* @.str.332, i64 0, i64 0
  %r180 = ptrtoint i8* %r179 to i64
  %r181 = call i64 @_eq(i64 %r178, i64 %r180)
  %r182 = icmp ne i64 %r181, 0
  br i1 %r182, label %L700, label %L701
L700:
  %r183 = load i64, i64* %ptr_res
  %r184 = getelementptr [13 x i8], [13 x i8]* @.str.333, i64 0, i64 0
  %r185 = ptrtoint i8* %r184 to i64
  %r186 = call i64 @_add(i64 %r183, i64 %r185)
  %r187 = load i64, i64* %ptr_lhs
  %r188 = call i64 @_add(i64 %r186, i64 %r187)
  %r189 = getelementptr [3 x i8], [3 x i8]* @.str.334, i64 0, i64 0
  %r190 = ptrtoint i8* %r189 to i64
  %r191 = call i64 @_add(i64 %r188, i64 %r190)
  %r192 = load i64, i64* %ptr_rhs
  %r193 = call i64 @_add(i64 %r191, i64 %r192)
  %r194 = call i64 @emit(i64 %r193)
  store i64 1, i64* %ptr_defined
  br label %L702
L701:
  %r195 = load i64, i64* %ptr_op
  %r196 = getelementptr [2 x i8], [2 x i8]* @.str.335, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = call i64 @_eq(i64 %r195, i64 %r197)
  %r199 = icmp ne i64 %r198, 0
  br i1 %r199, label %L703, label %L704
L703:
  %r200 = load i64, i64* %ptr_res
  %r201 = getelementptr [13 x i8], [13 x i8]* @.str.336, i64 0, i64 0
  %r202 = ptrtoint i8* %r201 to i64
  %r203 = call i64 @_add(i64 %r200, i64 %r202)
  %r204 = load i64, i64* %ptr_lhs
  %r205 = call i64 @_add(i64 %r203, i64 %r204)
  %r206 = getelementptr [3 x i8], [3 x i8]* @.str.337, i64 0, i64 0
  %r207 = ptrtoint i8* %r206 to i64
  %r208 = call i64 @_add(i64 %r205, i64 %r207)
  %r209 = load i64, i64* %ptr_rhs
  %r210 = call i64 @_add(i64 %r208, i64 %r209)
  %r211 = call i64 @emit(i64 %r210)
  store i64 1, i64* %ptr_defined
  br label %L705
L704:
  %r212 = load i64, i64* %ptr_op
  %r213 = getelementptr [2 x i8], [2 x i8]* @.str.338, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  %r215 = call i64 @_eq(i64 %r212, i64 %r214)
  %r216 = icmp ne i64 %r215, 0
  br i1 %r216, label %L706, label %L707
L706:
  %r217 = load i64, i64* %ptr_res
  %r218 = getelementptr [12 x i8], [12 x i8]* @.str.339, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @_add(i64 %r217, i64 %r219)
  %r221 = load i64, i64* %ptr_lhs
  %r222 = call i64 @_add(i64 %r220, i64 %r221)
  %r223 = getelementptr [3 x i8], [3 x i8]* @.str.340, i64 0, i64 0
  %r224 = ptrtoint i8* %r223 to i64
  %r225 = call i64 @_add(i64 %r222, i64 %r224)
  %r226 = load i64, i64* %ptr_rhs
  %r227 = call i64 @_add(i64 %r225, i64 %r226)
  %r228 = call i64 @emit(i64 %r227)
  store i64 1, i64* %ptr_defined
  br label %L708
L707:
  %r229 = load i64, i64* %ptr_op
  %r230 = getelementptr [2 x i8], [2 x i8]* @.str.341, i64 0, i64 0
  %r231 = ptrtoint i8* %r230 to i64
  %r232 = call i64 @_eq(i64 %r229, i64 %r231)
  %r233 = icmp ne i64 %r232, 0
  br i1 %r233, label %L709, label %L710
L709:
  %r234 = load i64, i64* %ptr_res
  %r235 = getelementptr [11 x i8], [11 x i8]* @.str.342, i64 0, i64 0
  %r236 = ptrtoint i8* %r235 to i64
  %r237 = call i64 @_add(i64 %r234, i64 %r236)
  %r238 = load i64, i64* %ptr_lhs
  %r239 = call i64 @_add(i64 %r237, i64 %r238)
  %r240 = getelementptr [3 x i8], [3 x i8]* @.str.343, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_add(i64 %r239, i64 %r241)
  %r243 = load i64, i64* %ptr_rhs
  %r244 = call i64 @_add(i64 %r242, i64 %r243)
  %r245 = call i64 @emit(i64 %r244)
  store i64 1, i64* %ptr_defined
  br label %L711
L710:
  %r246 = load i64, i64* %ptr_op
  %r247 = getelementptr [2 x i8], [2 x i8]* @.str.344, i64 0, i64 0
  %r248 = ptrtoint i8* %r247 to i64
  %r249 = call i64 @_eq(i64 %r246, i64 %r248)
  %r250 = icmp ne i64 %r249, 0
  br i1 %r250, label %L712, label %L713
L712:
  %r251 = load i64, i64* %ptr_res
  %r252 = getelementptr [12 x i8], [12 x i8]* @.str.345, i64 0, i64 0
  %r253 = ptrtoint i8* %r252 to i64
  %r254 = call i64 @_add(i64 %r251, i64 %r253)
  %r255 = load i64, i64* %ptr_lhs
  %r256 = call i64 @_add(i64 %r254, i64 %r255)
  %r257 = getelementptr [3 x i8], [3 x i8]* @.str.346, i64 0, i64 0
  %r258 = ptrtoint i8* %r257 to i64
  %r259 = call i64 @_add(i64 %r256, i64 %r258)
  %r260 = load i64, i64* %ptr_rhs
  %r261 = call i64 @_add(i64 %r259, i64 %r260)
  %r262 = call i64 @emit(i64 %r261)
  store i64 1, i64* %ptr_defined
  br label %L714
L713:
  %r263 = load i64, i64* %ptr_op
  %r264 = getelementptr [4 x i8], [4 x i8]* @.str.347, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = call i64 @_eq(i64 %r263, i64 %r265)
  %r267 = icmp ne i64 %r266, 0
  br i1 %r267, label %L715, label %L716
L715:
  %r268 = load i64, i64* %ptr_res
  %r269 = getelementptr [12 x i8], [12 x i8]* @.str.348, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @_add(i64 %r268, i64 %r270)
  %r272 = load i64, i64* %ptr_lhs
  %r273 = call i64 @_add(i64 %r271, i64 %r272)
  %r274 = getelementptr [3 x i8], [3 x i8]* @.str.349, i64 0, i64 0
  %r275 = ptrtoint i8* %r274 to i64
  %r276 = call i64 @_add(i64 %r273, i64 %r275)
  %r277 = load i64, i64* %ptr_rhs
  %r278 = call i64 @_add(i64 %r276, i64 %r277)
  %r279 = call i64 @emit(i64 %r278)
  store i64 1, i64* %ptr_defined
  br label %L717
L716:
  %r280 = load i64, i64* %ptr_op
  %r281 = getelementptr [2 x i8], [2 x i8]* @.str.350, i64 0, i64 0
  %r282 = ptrtoint i8* %r281 to i64
  %r283 = call i64 @_eq(i64 %r280, i64 %r282)
  %r284 = icmp ne i64 %r283, 0
  br i1 %r284, label %L718, label %L719
L718:
  %r285 = load i64, i64* %ptr_res
  %r286 = getelementptr [12 x i8], [12 x i8]* @.str.351, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = call i64 @_add(i64 %r285, i64 %r287)
  %r289 = load i64, i64* %ptr_lhs
  %r290 = call i64 @_add(i64 %r288, i64 %r289)
  %r291 = getelementptr [5 x i8], [5 x i8]* @.str.352, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_add(i64 %r290, i64 %r292)
  %r294 = call i64 @emit(i64 %r293)
  store i64 1, i64* %ptr_defined
  br label %L720
L719:
  %r295 = load i64, i64* %ptr_op
  %r296 = getelementptr [4 x i8], [4 x i8]* @.str.353, i64 0, i64 0
  %r297 = ptrtoint i8* %r296 to i64
  %r298 = call i64 @_eq(i64 %r295, i64 %r297)
  %r299 = icmp ne i64 %r298, 0
  br i1 %r299, label %L721, label %L722
L721:
  %r300 = load i64, i64* %ptr_res
  %r301 = getelementptr [12 x i8], [12 x i8]* @.str.354, i64 0, i64 0
  %r302 = ptrtoint i8* %r301 to i64
  %r303 = call i64 @_add(i64 %r300, i64 %r302)
  %r304 = load i64, i64* %ptr_lhs
  %r305 = call i64 @_add(i64 %r303, i64 %r304)
  %r306 = getelementptr [3 x i8], [3 x i8]* @.str.355, i64 0, i64 0
  %r307 = ptrtoint i8* %r306 to i64
  %r308 = call i64 @_add(i64 %r305, i64 %r307)
  %r309 = load i64, i64* %ptr_rhs
  %r310 = call i64 @_add(i64 %r308, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  store i64 1, i64* %ptr_defined
  br label %L723
L722:
  %r312 = load i64, i64* %ptr_op
  %r313 = getelementptr [4 x i8], [4 x i8]* @.str.356, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_eq(i64 %r312, i64 %r314)
  %r316 = icmp ne i64 %r315, 0
  br i1 %r316, label %L724, label %L725
L724:
  %r317 = load i64, i64* %ptr_res
  %r318 = getelementptr [13 x i8], [13 x i8]* @.str.357, i64 0, i64 0
  %r319 = ptrtoint i8* %r318 to i64
  %r320 = call i64 @_add(i64 %r317, i64 %r319)
  %r321 = load i64, i64* %ptr_lhs
  %r322 = call i64 @_add(i64 %r320, i64 %r321)
  %r323 = getelementptr [3 x i8], [3 x i8]* @.str.358, i64 0, i64 0
  %r324 = ptrtoint i8* %r323 to i64
  %r325 = call i64 @_add(i64 %r322, i64 %r324)
  %r326 = load i64, i64* %ptr_rhs
  %r327 = call i64 @_add(i64 %r325, i64 %r326)
  %r328 = call i64 @emit(i64 %r327)
  store i64 1, i64* %ptr_defined
  br label %L726
L725:
  %r329 = load i64, i64* %ptr_op
  %r330 = getelementptr [3 x i8], [3 x i8]* @.str.359, i64 0, i64 0
  %r331 = ptrtoint i8* %r330 to i64
  %r332 = call i64 @_eq(i64 %r329, i64 %r331)
  %r333 = icmp ne i64 %r332, 0
  br i1 %r333, label %L727, label %L728
L727:
  %r334 = load i64, i64* %ptr_res
  %r335 = getelementptr [12 x i8], [12 x i8]* @.str.360, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_add(i64 %r334, i64 %r336)
  %r338 = load i64, i64* %ptr_lhs
  %r339 = call i64 @_add(i64 %r337, i64 %r338)
  %r340 = getelementptr [3 x i8], [3 x i8]* @.str.361, i64 0, i64 0
  %r341 = ptrtoint i8* %r340 to i64
  %r342 = call i64 @_add(i64 %r339, i64 %r341)
  %r343 = load i64, i64* %ptr_rhs
  %r344 = call i64 @_add(i64 %r342, i64 %r343)
  %r345 = call i64 @emit(i64 %r344)
  store i64 1, i64* %ptr_defined
  br label %L729
L728:
  %r346 = load i64, i64* %ptr_op
  %r347 = getelementptr [4 x i8], [4 x i8]* @.str.362, i64 0, i64 0
  %r348 = ptrtoint i8* %r347 to i64
  %r349 = call i64 @_eq(i64 %r346, i64 %r348)
  %r350 = icmp ne i64 %r349, 0
  br i1 %r350, label %L730, label %L732
L730:
  %r351 = load i64, i64* %ptr_res
  %r352 = getelementptr [11 x i8], [11 x i8]* @.str.363, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_add(i64 %r351, i64 %r353)
  %r355 = load i64, i64* %ptr_lhs
  %r356 = call i64 @_add(i64 %r354, i64 %r355)
  %r357 = getelementptr [3 x i8], [3 x i8]* @.str.364, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_add(i64 %r356, i64 %r358)
  %r360 = load i64, i64* %ptr_rhs
  %r361 = call i64 @_add(i64 %r359, i64 %r360)
  %r362 = call i64 @emit(i64 %r361)
  store i64 1, i64* %ptr_defined
  br label %L732
L732:
  br label %L729
L729:
  br label %L726
L726:
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
  %r363 = load i64, i64* %ptr_defined
  %r364 = call i64 @_eq(i64 %r363, i64 0)
  %r365 = icmp ne i64 %r364, 0
  br i1 %r365, label %L733, label %L735
L733:
  %r366 = load i64, i64* %ptr_op
  %r367 = getelementptr [3 x i8], [3 x i8]* @.str.365, i64 0, i64 0
  %r368 = ptrtoint i8* %r367 to i64
  %r369 = call i64 @_eq(i64 %r366, i64 %r368)
  %r370 = icmp ne i64 %r369, 0
  br i1 %r370, label %L736, label %L737
L736:
  %r371 = load i64, i64* %ptr_res
  %r372 = getelementptr [22 x i8], [22 x i8]* @.str.366, i64 0, i64 0
  %r373 = ptrtoint i8* %r372 to i64
  %r374 = call i64 @_add(i64 %r371, i64 %r373)
  %r375 = load i64, i64* %ptr_lhs
  %r376 = call i64 @_add(i64 %r374, i64 %r375)
  %r377 = getelementptr [7 x i8], [7 x i8]* @.str.367, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_rhs
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  %r382 = getelementptr [2 x i8], [2 x i8]* @.str.368, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_add(i64 %r381, i64 %r383)
  %r385 = call i64 @emit(i64 %r384)
  br label %L738
L737:
  %r386 = load i64, i64* %ptr_op
  %r387 = getelementptr [3 x i8], [3 x i8]* @.str.369, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = call i64 @_eq(i64 %r386, i64 %r388)
  %r390 = icmp ne i64 %r389, 0
  br i1 %r390, label %L739, label %L740
L739:
  %r391 = call i64 @next_reg()
  store i64 %r391, i64* %ptr_tmp
  %r392 = load i64, i64* %ptr_tmp
  %r393 = getelementptr [22 x i8], [22 x i8]* @.str.370, i64 0, i64 0
  %r394 = ptrtoint i8* %r393 to i64
  %r395 = call i64 @_add(i64 %r392, i64 %r394)
  %r396 = load i64, i64* %ptr_lhs
  %r397 = call i64 @_add(i64 %r395, i64 %r396)
  %r398 = getelementptr [7 x i8], [7 x i8]* @.str.371, i64 0, i64 0
  %r399 = ptrtoint i8* %r398 to i64
  %r400 = call i64 @_add(i64 %r397, i64 %r399)
  %r401 = load i64, i64* %ptr_rhs
  %r402 = call i64 @_add(i64 %r400, i64 %r401)
  %r403 = getelementptr [2 x i8], [2 x i8]* @.str.372, i64 0, i64 0
  %r404 = ptrtoint i8* %r403 to i64
  %r405 = call i64 @_add(i64 %r402, i64 %r404)
  %r406 = call i64 @emit(i64 %r405)
  %r407 = load i64, i64* %ptr_res
  %r408 = getelementptr [12 x i8], [12 x i8]* @.str.373, i64 0, i64 0
  %r409 = ptrtoint i8* %r408 to i64
  %r410 = call i64 @_add(i64 %r407, i64 %r409)
  %r411 = load i64, i64* %ptr_tmp
  %r412 = call i64 @_add(i64 %r410, i64 %r411)
  %r413 = getelementptr [4 x i8], [4 x i8]* @.str.374, i64 0, i64 0
  %r414 = ptrtoint i8* %r413 to i64
  %r415 = call i64 @_add(i64 %r412, i64 %r414)
  %r416 = call i64 @emit(i64 %r415)
  br label %L741
L740:
  %r417 = getelementptr [1 x i8], [1 x i8]* @.str.375, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  store i64 %r418, i64* %ptr_cmp
  %r419 = load i64, i64* %ptr_op
  %r420 = getelementptr [2 x i8], [2 x i8]* @.str.376, i64 0, i64 0
  %r421 = ptrtoint i8* %r420 to i64
  %r422 = call i64 @_eq(i64 %r419, i64 %r421)
  %r423 = icmp ne i64 %r422, 0
  br i1 %r423, label %L742, label %L743
L742:
  %r424 = getelementptr [4 x i8], [4 x i8]* @.str.377, i64 0, i64 0
  %r425 = ptrtoint i8* %r424 to i64
  store i64 %r425, i64* %ptr_cmp
  br label %L744
L743:
  %r426 = load i64, i64* %ptr_op
  %r427 = getelementptr [2 x i8], [2 x i8]* @.str.378, i64 0, i64 0
  %r428 = ptrtoint i8* %r427 to i64
  %r429 = call i64 @_eq(i64 %r426, i64 %r428)
  %r430 = icmp ne i64 %r429, 0
  br i1 %r430, label %L745, label %L746
L745:
  %r431 = getelementptr [4 x i8], [4 x i8]* @.str.379, i64 0, i64 0
  %r432 = ptrtoint i8* %r431 to i64
  store i64 %r432, i64* %ptr_cmp
  br label %L747
L746:
  %r433 = load i64, i64* %ptr_op
  %r434 = getelementptr [3 x i8], [3 x i8]* @.str.380, i64 0, i64 0
  %r435 = ptrtoint i8* %r434 to i64
  %r436 = call i64 @_eq(i64 %r433, i64 %r435)
  %r437 = icmp ne i64 %r436, 0
  br i1 %r437, label %L748, label %L749
L748:
  %r438 = getelementptr [4 x i8], [4 x i8]* @.str.381, i64 0, i64 0
  %r439 = ptrtoint i8* %r438 to i64
  store i64 %r439, i64* %ptr_cmp
  br label %L750
L749:
  %r440 = load i64, i64* %ptr_op
  %r441 = getelementptr [3 x i8], [3 x i8]* @.str.382, i64 0, i64 0
  %r442 = ptrtoint i8* %r441 to i64
  %r443 = call i64 @_eq(i64 %r440, i64 %r442)
  %r444 = icmp ne i64 %r443, 0
  br i1 %r444, label %L751, label %L753
L751:
  %r445 = getelementptr [4 x i8], [4 x i8]* @.str.383, i64 0, i64 0
  %r446 = ptrtoint i8* %r445 to i64
  store i64 %r446, i64* %ptr_cmp
  br label %L753
L753:
  br label %L750
L750:
  br label %L747
L747:
  br label %L744
L744:
  %r447 = load i64, i64* %ptr_cmp
  %r448 = call i64 @mensura(i64 %r447)
  %r450 = icmp sgt i64 %r448, 0
  %r449 = zext i1 %r450 to i64
  %r451 = icmp ne i64 %r449, 0
  br i1 %r451, label %L754, label %L755
L754:
  %r452 = call i64 @next_reg()
  store i64 %r452, i64* %ptr_b
  %r453 = load i64, i64* %ptr_b
  %r454 = getelementptr [9 x i8], [9 x i8]* @.str.384, i64 0, i64 0
  %r455 = ptrtoint i8* %r454 to i64
  %r456 = call i64 @_add(i64 %r453, i64 %r455)
  %r457 = load i64, i64* %ptr_cmp
  %r458 = call i64 @_add(i64 %r456, i64 %r457)
  %r459 = getelementptr [6 x i8], [6 x i8]* @.str.385, i64 0, i64 0
  %r460 = ptrtoint i8* %r459 to i64
  %r461 = call i64 @_add(i64 %r458, i64 %r460)
  %r462 = load i64, i64* %ptr_lhs
  %r463 = call i64 @_add(i64 %r461, i64 %r462)
  %r464 = getelementptr [3 x i8], [3 x i8]* @.str.386, i64 0, i64 0
  %r465 = ptrtoint i8* %r464 to i64
  %r466 = call i64 @_add(i64 %r463, i64 %r465)
  %r467 = load i64, i64* %ptr_rhs
  %r468 = call i64 @_add(i64 %r466, i64 %r467)
  %r469 = call i64 @emit(i64 %r468)
  %r470 = load i64, i64* %ptr_res
  %r471 = getelementptr [12 x i8], [12 x i8]* @.str.387, i64 0, i64 0
  %r472 = ptrtoint i8* %r471 to i64
  %r473 = call i64 @_add(i64 %r470, i64 %r472)
  %r474 = load i64, i64* %ptr_b
  %r475 = call i64 @_add(i64 %r473, i64 %r474)
  %r476 = getelementptr [8 x i8], [8 x i8]* @.str.388, i64 0, i64 0
  %r477 = ptrtoint i8* %r476 to i64
  %r478 = call i64 @_add(i64 %r475, i64 %r477)
  %r479 = call i64 @emit(i64 %r478)
  br label %L756
L755:
  %r480 = load i64, i64* %ptr_res
  %r481 = getelementptr [16 x i8], [16 x i8]* @.str.389, i64 0, i64 0
  %r482 = ptrtoint i8* %r481 to i64
  %r483 = call i64 @_add(i64 %r480, i64 %r482)
  %r484 = call i64 @emit(i64 %r483)
  br label %L756
L756:
  br label %L741
L741:
  br label %L738
L738:
  br label %L735
L735:
  %r485 = load i64, i64* %ptr_res
  ret i64 %r485
  br label %L690
L690:
  %r486 = load i64, i64* %ptr_node
  %r487 = getelementptr [5 x i8], [5 x i8]* @.str.390, i64 0, i64 0
  %r488 = ptrtoint i8* %r487 to i64
  %r489 = call i64 @_get(i64 %r486, i64 %r488)
  %r490 = load i64, i64* @EXPR_LIST
  %r491 = call i64 @_eq(i64 %r489, i64 %r490)
  %r492 = icmp ne i64 %r491, 0
  br i1 %r492, label %L757, label %L759
L757:
  %r493 = call i64 @next_reg()
  store i64 %r493, i64* %ptr_res
  %r494 = load i64, i64* %ptr_res
  %r495 = getelementptr [25 x i8], [25 x i8]* @.str.391, i64 0, i64 0
  %r496 = ptrtoint i8* %r495 to i64
  %r497 = call i64 @_add(i64 %r494, i64 %r496)
  %r498 = call i64 @emit(i64 %r497)
  %r499 = load i64, i64* %ptr_node
  %r500 = getelementptr [6 x i8], [6 x i8]* @.str.392, i64 0, i64 0
  %r501 = ptrtoint i8* %r500 to i64
  %r502 = call i64 @_get(i64 %r499, i64 %r501)
  store i64 %r502, i64* %ptr_items
  store i64 0, i64* %ptr_i
  br label %L760
L760:
  %r503 = load i64, i64* %ptr_i
  %r504 = load i64, i64* %ptr_items
  %r505 = call i64 @mensura(i64 %r504)
  %r507 = icmp slt i64 %r503, %r505
  %r506 = zext i1 %r507 to i64
  %r508 = icmp ne i64 %r506, 0
  br i1 %r508, label %L761, label %L762
L761:
  %r509 = load i64, i64* %ptr_items
  %r510 = load i64, i64* %ptr_i
  %r511 = call i64 @_get(i64 %r509, i64 %r510)
  %r512 = call i64 @compile_expr(i64 %r511)
  store i64 %r512, i64* %ptr_val
  %r513 = getelementptr [26 x i8], [26 x i8]* @.str.393, i64 0, i64 0
  %r514 = ptrtoint i8* %r513 to i64
  %r515 = load i64, i64* %ptr_res
  %r516 = call i64 @_add(i64 %r514, i64 %r515)
  %r517 = getelementptr [7 x i8], [7 x i8]* @.str.394, i64 0, i64 0
  %r518 = ptrtoint i8* %r517 to i64
  %r519 = call i64 @_add(i64 %r516, i64 %r518)
  %r520 = load i64, i64* %ptr_val
  %r521 = call i64 @_add(i64 %r519, i64 %r520)
  %r522 = getelementptr [2 x i8], [2 x i8]* @.str.395, i64 0, i64 0
  %r523 = ptrtoint i8* %r522 to i64
  %r524 = call i64 @_add(i64 %r521, i64 %r523)
  %r525 = call i64 @emit(i64 %r524)
  %r526 = load i64, i64* %ptr_i
  %r527 = call i64 @_add(i64 %r526, i64 1)
  store i64 %r527, i64* %ptr_i
  br label %L760
L762:
  %r528 = load i64, i64* %ptr_res
  ret i64 %r528
  br label %L759
L759:
  %r529 = load i64, i64* %ptr_node
  %r530 = getelementptr [5 x i8], [5 x i8]* @.str.396, i64 0, i64 0
  %r531 = ptrtoint i8* %r530 to i64
  %r532 = call i64 @_get(i64 %r529, i64 %r531)
  %r533 = load i64, i64* @EXPR_MAP
  %r534 = call i64 @_eq(i64 %r532, i64 %r533)
  %r535 = icmp ne i64 %r534, 0
  br i1 %r535, label %L763, label %L765
L763:
  %r536 = call i64 @next_reg()
  store i64 %r536, i64* %ptr_res
  %r537 = load i64, i64* %ptr_res
  %r538 = getelementptr [24 x i8], [24 x i8]* @.str.397, i64 0, i64 0
  %r539 = ptrtoint i8* %r538 to i64
  %r540 = call i64 @_add(i64 %r537, i64 %r539)
  %r541 = call i64 @emit(i64 %r540)
  %r542 = load i64, i64* %ptr_node
  %r543 = getelementptr [5 x i8], [5 x i8]* @.str.398, i64 0, i64 0
  %r544 = ptrtoint i8* %r543 to i64
  %r545 = call i64 @_get(i64 %r542, i64 %r544)
  store i64 %r545, i64* %ptr_keys
  %r546 = load i64, i64* %ptr_node
  %r547 = getelementptr [5 x i8], [5 x i8]* @.str.399, i64 0, i64 0
  %r548 = ptrtoint i8* %r547 to i64
  %r549 = call i64 @_get(i64 %r546, i64 %r548)
  store i64 %r549, i64* %ptr_vals
  store i64 0, i64* %ptr_i
  br label %L766
L766:
  %r550 = load i64, i64* %ptr_i
  %r551 = load i64, i64* %ptr_keys
  %r552 = call i64 @mensura(i64 %r551)
  %r554 = icmp slt i64 %r550, %r552
  %r553 = zext i1 %r554 to i64
  %r555 = icmp ne i64 %r553, 0
  br i1 %r555, label %L767, label %L768
L767:
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
  %r566 = getelementptr [19 x i8], [19 x i8]* @.str.400, i64 0, i64 0
  %r567 = ptrtoint i8* %r566 to i64
  %r568 = call i64 @_add(i64 %r565, i64 %r567)
  %r569 = load i64, i64* %ptr_len
  %r570 = call i64 @int_to_str(i64 %r569)
  %r571 = call i64 @_add(i64 %r568, i64 %r570)
  %r572 = getelementptr [10 x i8], [10 x i8]* @.str.401, i64 0, i64 0
  %r573 = ptrtoint i8* %r572 to i64
  %r574 = call i64 @_add(i64 %r571, i64 %r573)
  %r575 = load i64, i64* %ptr_len
  %r576 = call i64 @int_to_str(i64 %r575)
  %r577 = call i64 @_add(i64 %r574, i64 %r576)
  %r578 = getelementptr [9 x i8], [9 x i8]* @.str.402, i64 0, i64 0
  %r579 = ptrtoint i8* %r578 to i64
  %r580 = call i64 @_add(i64 %r577, i64 %r579)
  %r581 = load i64, i64* %ptr_key_ptr
  %r582 = call i64 @_add(i64 %r580, i64 %r581)
  %r583 = getelementptr [15 x i8], [15 x i8]* @.str.403, i64 0, i64 0
  %r584 = ptrtoint i8* %r583 to i64
  %r585 = call i64 @_add(i64 %r582, i64 %r584)
  %r586 = call i64 @emit(i64 %r585)
  %r587 = call i64 @next_reg()
  store i64 %r587, i64* %ptr_key_int
  %r588 = load i64, i64* %ptr_key_int
  %r589 = getelementptr [17 x i8], [17 x i8]* @.str.404, i64 0, i64 0
  %r590 = ptrtoint i8* %r589 to i64
  %r591 = call i64 @_add(i64 %r588, i64 %r590)
  %r592 = load i64, i64* %ptr_key_reg
  %r593 = call i64 @_add(i64 %r591, i64 %r592)
  %r594 = getelementptr [8 x i8], [8 x i8]* @.str.405, i64 0, i64 0
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
  %r603 = getelementptr [24 x i8], [24 x i8]* @.str.406, i64 0, i64 0
  %r604 = ptrtoint i8* %r603 to i64
  %r605 = load i64, i64* %ptr_res
  %r606 = call i64 @_add(i64 %r604, i64 %r605)
  %r607 = getelementptr [7 x i8], [7 x i8]* @.str.407, i64 0, i64 0
  %r608 = ptrtoint i8* %r607 to i64
  %r609 = call i64 @_add(i64 %r606, i64 %r608)
  %r610 = load i64, i64* %ptr_key_int
  %r611 = call i64 @_add(i64 %r609, i64 %r610)
  %r612 = getelementptr [7 x i8], [7 x i8]* @.str.408, i64 0, i64 0
  %r613 = ptrtoint i8* %r612 to i64
  %r614 = call i64 @_add(i64 %r611, i64 %r613)
  %r615 = load i64, i64* %ptr_val_reg
  %r616 = call i64 @_add(i64 %r614, i64 %r615)
  %r617 = getelementptr [2 x i8], [2 x i8]* @.str.409, i64 0, i64 0
  %r618 = ptrtoint i8* %r617 to i64
  %r619 = call i64 @_add(i64 %r616, i64 %r618)
  %r620 = call i64 @emit(i64 %r619)
  %r621 = load i64, i64* %ptr_i
  %r622 = call i64 @_add(i64 %r621, i64 1)
  store i64 %r622, i64* %ptr_i
  br label %L766
L768:
  %r623 = load i64, i64* %ptr_res
  ret i64 %r623
  br label %L765
L765:
  %r624 = load i64, i64* %ptr_node
  %r625 = getelementptr [5 x i8], [5 x i8]* @.str.410, i64 0, i64 0
  %r626 = ptrtoint i8* %r625 to i64
  %r627 = call i64 @_get(i64 %r624, i64 %r626)
  %r628 = load i64, i64* @EXPR_INDEX
  %r629 = call i64 @_eq(i64 %r627, i64 %r628)
  %r630 = load i64, i64* %ptr_node
  %r631 = getelementptr [5 x i8], [5 x i8]* @.str.411, i64 0, i64 0
  %r632 = ptrtoint i8* %r631 to i64
  %r633 = call i64 @_get(i64 %r630, i64 %r632)
  %r634 = load i64, i64* @EXPR_GET
  %r635 = call i64 @_eq(i64 %r633, i64 %r634)
  %r636 = or i64 %r629, %r635
  %r637 = icmp ne i64 %r636, 0
  br i1 %r637, label %L769, label %L771
L769:
  %r638 = call i64 @_map_new()
  store i64 %r638, i64* %ptr_obj_node
  %r639 = call i64 @_map_new()
  store i64 %r639, i64* %ptr_idx_node
  %r640 = load i64, i64* %ptr_node
  %r641 = getelementptr [5 x i8], [5 x i8]* @.str.412, i64 0, i64 0
  %r642 = ptrtoint i8* %r641 to i64
  %r643 = call i64 @_get(i64 %r640, i64 %r642)
  %r644 = load i64, i64* @EXPR_INDEX
  %r645 = call i64 @_eq(i64 %r643, i64 %r644)
  %r646 = icmp ne i64 %r645, 0
  br i1 %r646, label %L772, label %L773
L772:
  %r647 = load i64, i64* %ptr_node
  %r648 = getelementptr [4 x i8], [4 x i8]* @.str.413, i64 0, i64 0
  %r649 = ptrtoint i8* %r648 to i64
  %r650 = call i64 @_get(i64 %r647, i64 %r649)
  store i64 %r650, i64* %ptr_obj_node
  %r651 = load i64, i64* %ptr_node
  %r652 = getelementptr [4 x i8], [4 x i8]* @.str.414, i64 0, i64 0
  %r653 = ptrtoint i8* %r652 to i64
  %r654 = call i64 @_get(i64 %r651, i64 %r653)
  store i64 %r654, i64* %ptr_idx_node
  br label %L774
L773:
  %r655 = load i64, i64* %ptr_node
  %r656 = getelementptr [4 x i8], [4 x i8]* @.str.415, i64 0, i64 0
  %r657 = ptrtoint i8* %r656 to i64
  %r658 = call i64 @_get(i64 %r655, i64 %r657)
  store i64 %r658, i64* %ptr_obj_node
  %r659 = call i64 @_map_new()
  %r660 = getelementptr [5 x i8], [5 x i8]* @.str.416, i64 0, i64 0
  %r661 = ptrtoint i8* %r660 to i64
  %r662 = load i64, i64* @EXPR_STRING
  call i64 @_map_set(i64 %r659, i64 %r661, i64 %r662)
  %r663 = getelementptr [4 x i8], [4 x i8]* @.str.417, i64 0, i64 0
  %r664 = ptrtoint i8* %r663 to i64
  %r665 = load i64, i64* %ptr_node
  %r666 = getelementptr [5 x i8], [5 x i8]* @.str.418, i64 0, i64 0
  %r667 = ptrtoint i8* %r666 to i64
  %r668 = call i64 @_get(i64 %r665, i64 %r667)
  call i64 @_map_set(i64 %r659, i64 %r664, i64 %r668)
  store i64 %r659, i64* %ptr_idx_node
  br label %L774
L774:
  %r669 = load i64, i64* %ptr_obj_node
  %r670 = call i64 @compile_expr(i64 %r669)
  store i64 %r670, i64* %ptr_obj_reg
  %r671 = load i64, i64* %ptr_idx_node
  %r672 = call i64 @compile_expr(i64 %r671)
  store i64 %r672, i64* %ptr_idx_reg
  %r673 = call i64 @next_reg()
  store i64 %r673, i64* %ptr_res
  %r674 = load i64, i64* %ptr_res
  %r675 = getelementptr [23 x i8], [23 x i8]* @.str.419, i64 0, i64 0
  %r676 = ptrtoint i8* %r675 to i64
  %r677 = call i64 @_add(i64 %r674, i64 %r676)
  %r678 = load i64, i64* %ptr_obj_reg
  %r679 = call i64 @_add(i64 %r677, i64 %r678)
  %r680 = getelementptr [7 x i8], [7 x i8]* @.str.420, i64 0, i64 0
  %r681 = ptrtoint i8* %r680 to i64
  %r682 = call i64 @_add(i64 %r679, i64 %r681)
  %r683 = load i64, i64* %ptr_idx_reg
  %r684 = call i64 @_add(i64 %r682, i64 %r683)
  %r685 = getelementptr [2 x i8], [2 x i8]* @.str.421, i64 0, i64 0
  %r686 = ptrtoint i8* %r685 to i64
  %r687 = call i64 @_add(i64 %r684, i64 %r686)
  %r688 = call i64 @emit(i64 %r687)
  %r689 = load i64, i64* %ptr_res
  ret i64 %r689
  br label %L771
L771:
  %r690 = load i64, i64* %ptr_node
  %r691 = getelementptr [5 x i8], [5 x i8]* @.str.422, i64 0, i64 0
  %r692 = ptrtoint i8* %r691 to i64
  %r693 = call i64 @_get(i64 %r690, i64 %r692)
  %r694 = load i64, i64* @EXPR_CALL
  %r695 = call i64 @_eq(i64 %r693, i64 %r694)
  %r696 = icmp ne i64 %r695, 0
  br i1 %r696, label %L775, label %L777
L775:
  %r697 = load i64, i64* %ptr_node
  %r698 = getelementptr [5 x i8], [5 x i8]* @.str.423, i64 0, i64 0
  %r699 = ptrtoint i8* %r698 to i64
  %r700 = call i64 @_get(i64 %r697, i64 %r699)
  store i64 %r700, i64* %ptr_name
  %r701 = load i64, i64* %ptr_name
  %r702 = getelementptr [5 x i8], [5 x i8]* @.str.424, i64 0, i64 0
  %r703 = ptrtoint i8* %r702 to i64
  %r704 = call i64 @_eq(i64 %r701, i64 %r703)
  %r705 = icmp ne i64 %r704, 0
  br i1 %r705, label %L778, label %L780
L778:
  %r706 = getelementptr [12 x i8], [12 x i8]* @.str.425, i64 0, i64 0
  %r707 = ptrtoint i8* %r706 to i64
  store i64 %r707, i64* %ptr_name
  br label %L780
L780:
  %r708 = load i64, i64* %ptr_name
  %r709 = getelementptr [4 x i8], [4 x i8]* @.str.426, i64 0, i64 0
  %r710 = ptrtoint i8* %r709 to i64
  %r711 = call i64 @_eq(i64 %r708, i64 %r710)
  %r712 = icmp ne i64 %r711, 0
  br i1 %r712, label %L781, label %L783
L781:
  %r713 = getelementptr [9 x i8], [9 x i8]* @.str.427, i64 0, i64 0
  %r714 = ptrtoint i8* %r713 to i64
  store i64 %r714, i64* %ptr_name
  br label %L783
L783:
  %r715 = load i64, i64* %ptr_name
  %r716 = getelementptr [9 x i8], [9 x i8]* @.str.428, i64 0, i64 0
  %r717 = ptrtoint i8* %r716 to i64
  %r718 = call i64 @_eq(i64 %r715, i64 %r717)
  %r719 = icmp ne i64 %r718, 0
  br i1 %r719, label %L784, label %L786
L784:
  %r720 = load i64, i64* %ptr_node
  %r721 = getelementptr [5 x i8], [5 x i8]* @.str.429, i64 0, i64 0
  %r722 = ptrtoint i8* %r721 to i64
  %r723 = call i64 @_get(i64 %r720, i64 %r722)
  %r724 = call i64 @_get(i64 %r723, i64 0)
  %r725 = call i64 @compile_expr(i64 %r724)
  store i64 %r725, i64* %ptr_addr_reg
  %r726 = call i64 @next_reg()
  store i64 %r726, i64* %ptr_ptr_reg
  %r727 = load i64, i64* %ptr_ptr_reg
  %r728 = getelementptr [17 x i8], [17 x i8]* @.str.430, i64 0, i64 0
  %r729 = ptrtoint i8* %r728 to i64
  %r730 = call i64 @_add(i64 %r727, i64 %r729)
  %r731 = load i64, i64* %ptr_addr_reg
  %r732 = call i64 @_add(i64 %r730, i64 %r731)
  %r733 = getelementptr [8 x i8], [8 x i8]* @.str.431, i64 0, i64 0
  %r734 = ptrtoint i8* %r733 to i64
  %r735 = call i64 @_add(i64 %r732, i64 %r734)
  %r736 = call i64 @emit(i64 %r735)
  %r737 = call i64 @next_reg()
  store i64 %r737, i64* %ptr_val_reg
  %r738 = load i64, i64* %ptr_val_reg
  %r739 = getelementptr [17 x i8], [17 x i8]* @.str.432, i64 0, i64 0
  %r740 = ptrtoint i8* %r739 to i64
  %r741 = call i64 @_add(i64 %r738, i64 %r740)
  %r742 = load i64, i64* %ptr_ptr_reg
  %r743 = call i64 @_add(i64 %r741, i64 %r742)
  %r744 = call i64 @emit(i64 %r743)
  %r745 = call i64 @next_reg()
  store i64 %r745, i64* %ptr_mem_res
  %r746 = load i64, i64* %ptr_mem_res
  %r747 = getelementptr [12 x i8], [12 x i8]* @.str.433, i64 0, i64 0
  %r748 = ptrtoint i8* %r747 to i64
  %r749 = call i64 @_add(i64 %r746, i64 %r748)
  %r750 = load i64, i64* %ptr_val_reg
  %r751 = call i64 @_add(i64 %r749, i64 %r750)
  %r752 = getelementptr [8 x i8], [8 x i8]* @.str.434, i64 0, i64 0
  %r753 = ptrtoint i8* %r752 to i64
  %r754 = call i64 @_add(i64 %r751, i64 %r753)
  %r755 = call i64 @emit(i64 %r754)
  %r756 = load i64, i64* %ptr_mem_res
  ret i64 %r756
  br label %L786
L786:
  %r757 = load i64, i64* %ptr_name
  %r758 = getelementptr [11 x i8], [11 x i8]* @.str.435, i64 0, i64 0
  %r759 = ptrtoint i8* %r758 to i64
  %r760 = call i64 @_eq(i64 %r757, i64 %r759)
  %r761 = icmp ne i64 %r760, 0
  br i1 %r761, label %L787, label %L789
L787:
  %r762 = load i64, i64* %ptr_node
  %r763 = getelementptr [5 x i8], [5 x i8]* @.str.436, i64 0, i64 0
  %r764 = ptrtoint i8* %r763 to i64
  %r765 = call i64 @_get(i64 %r762, i64 %r764)
  %r766 = call i64 @_get(i64 %r765, i64 0)
  %r767 = call i64 @compile_expr(i64 %r766)
  store i64 %r767, i64* %ptr_addr_reg
  %r768 = load i64, i64* %ptr_node
  %r769 = getelementptr [5 x i8], [5 x i8]* @.str.437, i64 0, i64 0
  %r770 = ptrtoint i8* %r769 to i64
  %r771 = call i64 @_get(i64 %r768, i64 %r770)
  %r772 = call i64 @_get(i64 %r771, i64 1)
  %r773 = call i64 @compile_expr(i64 %r772)
  store i64 %r773, i64* %ptr_val_reg
  %r774 = call i64 @next_reg()
  store i64 %r774, i64* %ptr_ptr_reg
  %r775 = load i64, i64* %ptr_ptr_reg
  %r776 = getelementptr [17 x i8], [17 x i8]* @.str.438, i64 0, i64 0
  %r777 = ptrtoint i8* %r776 to i64
  %r778 = call i64 @_add(i64 %r775, i64 %r777)
  %r779 = load i64, i64* %ptr_addr_reg
  %r780 = call i64 @_add(i64 %r778, i64 %r779)
  %r781 = getelementptr [8 x i8], [8 x i8]* @.str.439, i64 0, i64 0
  %r782 = ptrtoint i8* %r781 to i64
  %r783 = call i64 @_add(i64 %r780, i64 %r782)
  %r784 = call i64 @emit(i64 %r783)
  %r785 = call i64 @next_reg()
  store i64 %r785, i64* %ptr_trunc_reg
  %r786 = load i64, i64* %ptr_trunc_reg
  %r787 = getelementptr [14 x i8], [14 x i8]* @.str.440, i64 0, i64 0
  %r788 = ptrtoint i8* %r787 to i64
  %r789 = call i64 @_add(i64 %r786, i64 %r788)
  %r790 = load i64, i64* %ptr_val_reg
  %r791 = call i64 @_add(i64 %r789, i64 %r790)
  %r792 = getelementptr [7 x i8], [7 x i8]* @.str.441, i64 0, i64 0
  %r793 = ptrtoint i8* %r792 to i64
  %r794 = call i64 @_add(i64 %r791, i64 %r793)
  %r795 = call i64 @emit(i64 %r794)
  %r796 = getelementptr [10 x i8], [10 x i8]* @.str.442, i64 0, i64 0
  %r797 = ptrtoint i8* %r796 to i64
  %r798 = load i64, i64* %ptr_trunc_reg
  %r799 = call i64 @_add(i64 %r797, i64 %r798)
  %r800 = getelementptr [7 x i8], [7 x i8]* @.str.443, i64 0, i64 0
  %r801 = ptrtoint i8* %r800 to i64
  %r802 = call i64 @_add(i64 %r799, i64 %r801)
  %r803 = load i64, i64* %ptr_ptr_reg
  %r804 = call i64 @_add(i64 %r802, i64 %r803)
  %r805 = call i64 @emit(i64 %r804)
  %r806 = getelementptr [2 x i8], [2 x i8]* @.str.444, i64 0, i64 0
  %r807 = ptrtoint i8* %r806 to i64
  ret i64 %r807
  br label %L789
L789:
  %r808 = load i64, i64* %ptr_name
  %r809 = getelementptr [10 x i8], [10 x i8]* @.str.445, i64 0, i64 0
  %r810 = ptrtoint i8* %r809 to i64
  %r811 = call i64 @_eq(i64 %r808, i64 %r810)
  %r812 = icmp ne i64 %r811, 0
  br i1 %r812, label %L790, label %L792
L790:
  %r813 = load i64, i64* %ptr_node
  %r814 = getelementptr [5 x i8], [5 x i8]* @.str.446, i64 0, i64 0
  %r815 = ptrtoint i8* %r814 to i64
  %r816 = call i64 @_get(i64 %r813, i64 %r815)
  %r817 = call i64 @_get(i64 %r816, i64 0)
  %r818 = call i64 @compile_expr(i64 %r817)
  store i64 %r818, i64* %ptr_sz_reg
  %r819 = call i64 @next_reg()
  store i64 %r819, i64* %ptr_res
  %r820 = load i64, i64* %ptr_res
  %r821 = getelementptr [25 x i8], [25 x i8]* @.str.447, i64 0, i64 0
  %r822 = ptrtoint i8* %r821 to i64
  %r823 = call i64 @_add(i64 %r820, i64 %r822)
  %r824 = load i64, i64* %ptr_sz_reg
  %r825 = call i64 @_add(i64 %r823, i64 %r824)
  %r826 = getelementptr [2 x i8], [2 x i8]* @.str.448, i64 0, i64 0
  %r827 = ptrtoint i8* %r826 to i64
  %r828 = call i64 @_add(i64 %r825, i64 %r827)
  %r829 = call i64 @emit(i64 %r828)
  %r830 = load i64, i64* %ptr_res
  ret i64 %r830
  br label %L792
L792:
  %r831 = load i64, i64* %ptr_name
  %r832 = getelementptr [8 x i8], [8 x i8]* @.str.449, i64 0, i64 0
  %r833 = ptrtoint i8* %r832 to i64
  %r834 = call i64 @_eq(i64 %r831, i64 %r833)
  %r835 = icmp ne i64 %r834, 0
  br i1 %r835, label %L793, label %L795
L793:
  %r836 = load i64, i64* %ptr_node
  %r837 = getelementptr [5 x i8], [5 x i8]* @.str.450, i64 0, i64 0
  %r838 = ptrtoint i8* %r837 to i64
  %r839 = call i64 @_get(i64 %r836, i64 %r838)
  %r840 = call i64 @_get(i64 %r839, i64 0)
  %r841 = call i64 @compile_expr(i64 %r840)
  store i64 %r841, i64* %ptr_ptr_reg
  %r842 = load i64, i64* %ptr_node
  %r843 = getelementptr [5 x i8], [5 x i8]* @.str.451, i64 0, i64 0
  %r844 = ptrtoint i8* %r843 to i64
  %r845 = call i64 @_get(i64 %r842, i64 %r844)
  %r846 = call i64 @_get(i64 %r845, i64 1)
  %r847 = call i64 @compile_expr(i64 %r846)
  store i64 %r847, i64* %ptr_off_reg
  %r848 = call i64 @next_reg()
  store i64 %r848, i64* %ptr_res
  %r849 = load i64, i64* %ptr_res
  %r850 = getelementptr [12 x i8], [12 x i8]* @.str.452, i64 0, i64 0
  %r851 = ptrtoint i8* %r850 to i64
  %r852 = call i64 @_add(i64 %r849, i64 %r851)
  %r853 = load i64, i64* %ptr_ptr_reg
  %r854 = call i64 @_add(i64 %r852, i64 %r853)
  %r855 = getelementptr [3 x i8], [3 x i8]* @.str.453, i64 0, i64 0
  %r856 = ptrtoint i8* %r855 to i64
  %r857 = call i64 @_add(i64 %r854, i64 %r856)
  %r858 = load i64, i64* %ptr_off_reg
  %r859 = call i64 @_add(i64 %r857, i64 %r858)
  %r860 = call i64 @emit(i64 %r859)
  %r861 = load i64, i64* %ptr_res
  ret i64 %r861
  br label %L795
L795:
  %r862 = load i64, i64* %ptr_name
  %r863 = getelementptr [16 x i8], [16 x i8]* @.str.454, i64 0, i64 0
  %r864 = ptrtoint i8* %r863 to i64
  %r865 = call i64 @_eq(i64 %r862, i64 %r864)
  %r866 = icmp ne i64 %r865, 0
  br i1 %r866, label %L796, label %L798
L796:
  %r867 = load i64, i64* %ptr_node
  %r868 = getelementptr [5 x i8], [5 x i8]* @.str.455, i64 0, i64 0
  %r869 = ptrtoint i8* %r868 to i64
  %r870 = call i64 @_get(i64 %r867, i64 %r869)
  store i64 %r870, i64* %ptr_args
  %r871 = getelementptr [2 x i8], [2 x i8]* @.str.456, i64 0, i64 0
  %r872 = ptrtoint i8* %r871 to i64
  store i64 %r872, i64* %ptr_a0
  %r873 = load i64, i64* %ptr_args
  %r874 = call i64 @mensura(i64 %r873)
  %r876 = icmp sgt i64 %r874, 0
  %r875 = zext i1 %r876 to i64
  %r877 = icmp ne i64 %r875, 0
  br i1 %r877, label %L799, label %L801
L799:
  %r878 = load i64, i64* %ptr_args
  %r879 = call i64 @_get(i64 %r878, i64 0)
  %r880 = call i64 @compile_expr(i64 %r879)
  store i64 %r880, i64* %ptr_a0
  br label %L801
L801:
  %r881 = getelementptr [2 x i8], [2 x i8]* @.str.457, i64 0, i64 0
  %r882 = ptrtoint i8* %r881 to i64
  store i64 %r882, i64* %ptr_a1
  %r883 = load i64, i64* %ptr_args
  %r884 = call i64 @mensura(i64 %r883)
  %r886 = icmp sgt i64 %r884, 1
  %r885 = zext i1 %r886 to i64
  %r887 = icmp ne i64 %r885, 0
  br i1 %r887, label %L802, label %L804
L802:
  %r888 = load i64, i64* %ptr_args
  %r889 = call i64 @_get(i64 %r888, i64 1)
  %r890 = call i64 @compile_expr(i64 %r889)
  store i64 %r890, i64* %ptr_a1
  br label %L804
L804:
  %r891 = getelementptr [2 x i8], [2 x i8]* @.str.458, i64 0, i64 0
  %r892 = ptrtoint i8* %r891 to i64
  store i64 %r892, i64* %ptr_a2
  %r893 = load i64, i64* %ptr_args
  %r894 = call i64 @mensura(i64 %r893)
  %r896 = icmp sgt i64 %r894, 2
  %r895 = zext i1 %r896 to i64
  %r897 = icmp ne i64 %r895, 0
  br i1 %r897, label %L805, label %L807
L805:
  %r898 = load i64, i64* %ptr_args
  %r899 = call i64 @_get(i64 %r898, i64 2)
  %r900 = call i64 @compile_expr(i64 %r899)
  store i64 %r900, i64* %ptr_a2
  br label %L807
L807:
  %r901 = getelementptr [2 x i8], [2 x i8]* @.str.459, i64 0, i64 0
  %r902 = ptrtoint i8* %r901 to i64
  store i64 %r902, i64* %ptr_a3
  %r903 = load i64, i64* %ptr_args
  %r904 = call i64 @mensura(i64 %r903)
  %r906 = icmp sgt i64 %r904, 3
  %r905 = zext i1 %r906 to i64
  %r907 = icmp ne i64 %r905, 0
  br i1 %r907, label %L808, label %L810
L808:
  %r908 = load i64, i64* %ptr_args
  %r909 = call i64 @_get(i64 %r908, i64 3)
  %r910 = call i64 @compile_expr(i64 %r909)
  store i64 %r910, i64* %ptr_a3
  br label %L810
L810:
  %r911 = getelementptr [2 x i8], [2 x i8]* @.str.460, i64 0, i64 0
  %r912 = ptrtoint i8* %r911 to i64
  store i64 %r912, i64* %ptr_a4
  %r913 = load i64, i64* %ptr_args
  %r914 = call i64 @mensura(i64 %r913)
  %r916 = icmp sgt i64 %r914, 4
  %r915 = zext i1 %r916 to i64
  %r917 = icmp ne i64 %r915, 0
  br i1 %r917, label %L811, label %L813
L811:
  %r918 = load i64, i64* %ptr_args
  %r919 = call i64 @_get(i64 %r918, i64 4)
  %r920 = call i64 @compile_expr(i64 %r919)
  store i64 %r920, i64* %ptr_a4
  br label %L813
L813:
  %r921 = getelementptr [2 x i8], [2 x i8]* @.str.461, i64 0, i64 0
  %r922 = ptrtoint i8* %r921 to i64
  store i64 %r922, i64* %ptr_a5
  %r923 = load i64, i64* %ptr_args
  %r924 = call i64 @mensura(i64 %r923)
  %r926 = icmp sgt i64 %r924, 5
  %r925 = zext i1 %r926 to i64
  %r927 = icmp ne i64 %r925, 0
  br i1 %r927, label %L814, label %L816
L814:
  %r928 = load i64, i64* %ptr_args
  %r929 = call i64 @_get(i64 %r928, i64 5)
  %r930 = call i64 @compile_expr(i64 %r929)
  store i64 %r930, i64* %ptr_a5
  br label %L816
L816:
  %r931 = getelementptr [2 x i8], [2 x i8]* @.str.462, i64 0, i64 0
  %r932 = ptrtoint i8* %r931 to i64
  store i64 %r932, i64* %ptr_a6
  %r933 = load i64, i64* %ptr_args
  %r934 = call i64 @mensura(i64 %r933)
  %r936 = icmp sgt i64 %r934, 6
  %r935 = zext i1 %r936 to i64
  %r937 = icmp ne i64 %r935, 0
  br i1 %r937, label %L817, label %L819
L817:
  %r938 = load i64, i64* %ptr_args
  %r939 = call i64 @_get(i64 %r938, i64 6)
  %r940 = call i64 @compile_expr(i64 %r939)
  store i64 %r940, i64* %ptr_a6
  br label %L819
L819:
  %r941 = call i64 @next_reg()
  store i64 %r941, i64* %ptr_res
  %r942 = load i64, i64* %ptr_res
  %r943 = getelementptr [27 x i8], [27 x i8]* @.str.463, i64 0, i64 0
  %r944 = ptrtoint i8* %r943 to i64
  %r945 = call i64 @_add(i64 %r942, i64 %r944)
  %r946 = load i64, i64* %ptr_a0
  %r947 = call i64 @_add(i64 %r945, i64 %r946)
  %r948 = getelementptr [7 x i8], [7 x i8]* @.str.464, i64 0, i64 0
  %r949 = ptrtoint i8* %r948 to i64
  %r950 = call i64 @_add(i64 %r947, i64 %r949)
  %r951 = load i64, i64* %ptr_a1
  %r952 = call i64 @_add(i64 %r950, i64 %r951)
  %r953 = getelementptr [7 x i8], [7 x i8]* @.str.465, i64 0, i64 0
  %r954 = ptrtoint i8* %r953 to i64
  %r955 = call i64 @_add(i64 %r952, i64 %r954)
  %r956 = load i64, i64* %ptr_a2
  %r957 = call i64 @_add(i64 %r955, i64 %r956)
  %r958 = getelementptr [7 x i8], [7 x i8]* @.str.466, i64 0, i64 0
  %r959 = ptrtoint i8* %r958 to i64
  %r960 = call i64 @_add(i64 %r957, i64 %r959)
  %r961 = load i64, i64* %ptr_a3
  %r962 = call i64 @_add(i64 %r960, i64 %r961)
  %r963 = getelementptr [7 x i8], [7 x i8]* @.str.467, i64 0, i64 0
  %r964 = ptrtoint i8* %r963 to i64
  %r965 = call i64 @_add(i64 %r962, i64 %r964)
  %r966 = load i64, i64* %ptr_a4
  %r967 = call i64 @_add(i64 %r965, i64 %r966)
  %r968 = getelementptr [7 x i8], [7 x i8]* @.str.468, i64 0, i64 0
  %r969 = ptrtoint i8* %r968 to i64
  %r970 = call i64 @_add(i64 %r967, i64 %r969)
  %r971 = load i64, i64* %ptr_a5
  %r972 = call i64 @_add(i64 %r970, i64 %r971)
  %r973 = getelementptr [7 x i8], [7 x i8]* @.str.469, i64 0, i64 0
  %r974 = ptrtoint i8* %r973 to i64
  %r975 = call i64 @_add(i64 %r972, i64 %r974)
  %r976 = load i64, i64* %ptr_a6
  %r977 = call i64 @_add(i64 %r975, i64 %r976)
  %r978 = getelementptr [2 x i8], [2 x i8]* @.str.470, i64 0, i64 0
  %r979 = ptrtoint i8* %r978 to i64
  %r980 = call i64 @_add(i64 %r977, i64 %r979)
  %r981 = call i64 @emit(i64 %r980)
  %r982 = load i64, i64* %ptr_res
  ret i64 %r982
  br label %L798
L798:
  %r983 = load i64, i64* %ptr_name
  %r984 = getelementptr [18 x i8], [18 x i8]* @.str.471, i64 0, i64 0
  %r985 = ptrtoint i8* %r984 to i64
  %r986 = call i64 @_eq(i64 %r983, i64 %r985)
  %r987 = icmp ne i64 %r986, 0
  br i1 %r987, label %L820, label %L822
L820:
  %r988 = load i64, i64* %ptr_node
  %r989 = getelementptr [5 x i8], [5 x i8]* @.str.472, i64 0, i64 0
  %r990 = ptrtoint i8* %r989 to i64
  %r991 = call i64 @_get(i64 %r988, i64 %r990)
  %r992 = call i64 @_get(i64 %r991, i64 0)
  %r993 = call i64 @compile_expr(i64 %r992)
  store i64 %r993, i64* %ptr_arg_idx
  %r994 = call i64 @next_reg()
  store i64 %r994, i64* %ptr_res
  %r995 = load i64, i64* %ptr_res
  %r996 = getelementptr [28 x i8], [28 x i8]* @.str.473, i64 0, i64 0
  %r997 = ptrtoint i8* %r996 to i64
  %r998 = call i64 @_add(i64 %r995, i64 %r997)
  %r999 = load i64, i64* %ptr_arg_idx
  %r1000 = call i64 @_add(i64 %r998, i64 %r999)
  %r1001 = getelementptr [2 x i8], [2 x i8]* @.str.474, i64 0, i64 0
  %r1002 = ptrtoint i8* %r1001 to i64
  %r1003 = call i64 @_add(i64 %r1000, i64 %r1002)
  %r1004 = call i64 @emit(i64 %r1003)
  %r1005 = load i64, i64* %ptr_res
  ret i64 %r1005
  br label %L822
L822:
  %r1006 = load i64, i64* %ptr_node
  %r1007 = getelementptr [5 x i8], [5 x i8]* @.str.475, i64 0, i64 0
  %r1008 = ptrtoint i8* %r1007 to i64
  %r1009 = call i64 @_get(i64 %r1006, i64 %r1008)
  store i64 %r1009, i64* %ptr_args
  %r1010 = getelementptr [1 x i8], [1 x i8]* @.str.476, i64 0, i64 0
  %r1011 = ptrtoint i8* %r1010 to i64
  store i64 %r1011, i64* %ptr_arg_str
  store i64 0, i64* %ptr_i
  br label %L823
L823:
  %r1012 = load i64, i64* %ptr_i
  %r1013 = load i64, i64* %ptr_args
  %r1014 = call i64 @mensura(i64 %r1013)
  %r1016 = icmp slt i64 %r1012, %r1014
  %r1015 = zext i1 %r1016 to i64
  %r1017 = icmp ne i64 %r1015, 0
  br i1 %r1017, label %L824, label %L825
L824:
  %r1018 = load i64, i64* %ptr_args
  %r1019 = load i64, i64* %ptr_i
  %r1020 = call i64 @_get(i64 %r1018, i64 %r1019)
  %r1021 = call i64 @compile_expr(i64 %r1020)
  store i64 %r1021, i64* %ptr_val
  %r1022 = load i64, i64* %ptr_arg_str
  %r1023 = getelementptr [5 x i8], [5 x i8]* @.str.477, i64 0, i64 0
  %r1024 = ptrtoint i8* %r1023 to i64
  %r1025 = call i64 @_add(i64 %r1022, i64 %r1024)
  %r1026 = load i64, i64* %ptr_val
  %r1027 = call i64 @_add(i64 %r1025, i64 %r1026)
  store i64 %r1027, i64* %ptr_arg_str
  %r1028 = load i64, i64* %ptr_i
  %r1029 = load i64, i64* %ptr_args
  %r1030 = call i64 @mensura(i64 %r1029)
  %r1031 = sub i64 %r1030, 1
  %r1033 = icmp slt i64 %r1028, %r1031
  %r1032 = zext i1 %r1033 to i64
  %r1034 = icmp ne i64 %r1032, 0
  br i1 %r1034, label %L826, label %L828
L826:
  %r1035 = load i64, i64* %ptr_arg_str
  %r1036 = getelementptr [3 x i8], [3 x i8]* @.str.478, i64 0, i64 0
  %r1037 = ptrtoint i8* %r1036 to i64
  %r1038 = call i64 @_add(i64 %r1035, i64 %r1037)
  store i64 %r1038, i64* %ptr_arg_str
  br label %L828
L828:
  %r1039 = load i64, i64* %ptr_i
  %r1040 = call i64 @_add(i64 %r1039, i64 1)
  store i64 %r1040, i64* %ptr_i
  br label %L823
L825:
  %r1041 = call i64 @next_reg()
  store i64 %r1041, i64* %ptr_res
  %r1042 = load i64, i64* %ptr_name
  %r1043 = getelementptr [7 x i8], [7 x i8]* @.str.479, i64 0, i64 0
  %r1044 = ptrtoint i8* %r1043 to i64
  %r1045 = call i64 @_eq(i64 %r1042, i64 %r1044)
  %r1046 = icmp ne i64 %r1045, 0
  br i1 %r1046, label %L829, label %L830
L829:
  %r1047 = load i64, i64* %ptr_res
  %r1048 = getelementptr [28 x i8], [28 x i8]* @.str.480, i64 0, i64 0
  %r1049 = ptrtoint i8* %r1048 to i64
  %r1050 = call i64 @_add(i64 %r1047, i64 %r1049)
  %r1051 = load i64, i64* %ptr_arg_str
  %r1052 = call i64 @_add(i64 %r1050, i64 %r1051)
  %r1053 = getelementptr [2 x i8], [2 x i8]* @.str.481, i64 0, i64 0
  %r1054 = ptrtoint i8* %r1053 to i64
  %r1055 = call i64 @_add(i64 %r1052, i64 %r1054)
  %r1056 = call i64 @emit(i64 %r1055)
  br label %L831
L830:
  %r1057 = load i64, i64* %ptr_res
  %r1058 = getelementptr [14 x i8], [14 x i8]* @.str.482, i64 0, i64 0
  %r1059 = ptrtoint i8* %r1058 to i64
  %r1060 = call i64 @_add(i64 %r1057, i64 %r1059)
  %r1061 = load i64, i64* %ptr_name
  %r1062 = call i64 @_add(i64 %r1060, i64 %r1061)
  %r1063 = getelementptr [2 x i8], [2 x i8]* @.str.483, i64 0, i64 0
  %r1064 = ptrtoint i8* %r1063 to i64
  %r1065 = call i64 @_add(i64 %r1062, i64 %r1064)
  %r1066 = load i64, i64* %ptr_arg_str
  %r1067 = call i64 @_add(i64 %r1065, i64 %r1066)
  %r1068 = getelementptr [2 x i8], [2 x i8]* @.str.484, i64 0, i64 0
  %r1069 = ptrtoint i8* %r1068 to i64
  %r1070 = call i64 @_add(i64 %r1067, i64 %r1069)
  %r1071 = call i64 @emit(i64 %r1070)
  br label %L831
L831:
  %r1072 = load i64, i64* %ptr_res
  ret i64 %r1072
  br label %L777
L777:
  %r1073 = getelementptr [2 x i8], [2 x i8]* @.str.485, i64 0, i64 0
  %r1074 = ptrtoint i8* %r1073 to i64
  ret i64 %r1074
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
  %ptr_has_else = alloca i64
  %ptr_l_cond = alloca i64
  %ptr_l_body = alloca i64
  %ptr_extract_dummy = alloca i64
  %ptr_popped_cond = alloca i64
  %ptr_i = alloca i64
  %ptr_popped_end = alloca i64
  %r1 = load i64, i64* %ptr_node
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.486, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @STMT_IMPORT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L832, label %L834
L832:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.487, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  store i64 %r11, i64* %ptr_path_node
  %r12 = load i64, i64* %ptr_path_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.488, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_STRING
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L835, label %L837
L835:
  %r19 = load i64, i64* %ptr_path_node
  %r20 = getelementptr [4 x i8], [4 x i8]* @.str.489, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @revelare(i64 %r22)
  store i64 %r23, i64* %ptr_f_src
  %r24 = load i64, i64* %ptr_f_src
  %r25 = call i64 @mensura(i64 %r24)
  %r27 = icmp sgt i64 %r25, 0
  %r26 = zext i1 %r27 to i64
  %r28 = icmp ne i64 %r26, 0
  br i1 %r28, label %L838, label %L839
L838:
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
  br label %L841
L841:
  %r34 = call i64 @peek()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.490, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_get(i64 %r34, i64 %r36)
  %r38 = load i64, i64* @TOK_EOF
  %r40 = call i64 @_eq(i64 %r37, i64 %r38)
  %r39 = xor i64 %r40, 1
  %r41 = icmp ne i64 %r39, 0
  br i1 %r41, label %L842, label %L843
L842:
  %r42 = call i64 @peek()
  %r43 = getelementptr [5 x i8], [5 x i8]* @.str.491, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = call i64 @_get(i64 %r42, i64 %r44)
  %r46 = load i64, i64* @TOK_CARET
  %r47 = call i64 @_eq(i64 %r45, i64 %r46)
  %r48 = icmp ne i64 %r47, 0
  br i1 %r48, label %L844, label %L845
L844:
  %r49 = call i64 @advance()
  br label %L846
L845:
  %r50 = call i64 @parse_stmt()
  %r51 = load i64, i64* %ptr_link_stmts
  call i64 @_append_poly(i64 %r51, i64 %r50)
  br label %L846
L846:
  br label %L841
L843:
  %r52 = load i64, i64* %ptr_link_stmts
  %r53 = call i64 @compile_block(i64 %r52)
  %r54 = load i64, i64* %ptr_old_tokens
  store i64 %r54, i64* @global_tokens
  %r55 = load i64, i64* %ptr_old_pos
  store i64 %r55, i64* @p_pos
  br label %L840
L839:
  %r56 = getelementptr [41 x i8], [41 x i8]* @.str.492, i64 0, i64 0
  %r57 = ptrtoint i8* %r56 to i64
  %r58 = load i64, i64* %ptr_path_node
  %r59 = getelementptr [4 x i8], [4 x i8]* @.str.493, i64 0, i64 0
  %r60 = ptrtoint i8* %r59 to i64
  %r61 = call i64 @_get(i64 %r58, i64 %r60)
  %r62 = call i64 @_add(i64 %r57, i64 %r61)
  call i64 @print_any(i64 %r62)
  br label %L840
L840:
  br label %L837
L837:
  br label %L834
L834:
  %r63 = load i64, i64* %ptr_node
  %r64 = getelementptr [5 x i8], [5 x i8]* @.str.494, i64 0, i64 0
  %r65 = ptrtoint i8* %r64 to i64
  %r66 = call i64 @_get(i64 %r63, i64 %r65)
  %r67 = load i64, i64* @STMT_LET
  %r68 = call i64 @_eq(i64 %r66, i64 %r67)
  %r69 = icmp ne i64 %r68, 0
  br i1 %r69, label %L847, label %L849
L847:
  %r70 = load i64, i64* %ptr_node
  %r71 = getelementptr [4 x i8], [4 x i8]* @.str.495, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_get(i64 %r70, i64 %r72)
  %r74 = call i64 @compile_expr(i64 %r73)
  store i64 %r74, i64* %ptr_val
  %r75 = load i64, i64* @var_map
  %r76 = load i64, i64* %ptr_node
  %r77 = getelementptr [5 x i8], [5 x i8]* @.str.496, i64 0, i64 0
  %r78 = ptrtoint i8* %r77 to i64
  %r79 = call i64 @_get(i64 %r76, i64 %r78)
  %r80 = call i64 @_get(i64 %r75, i64 %r79)
  store i64 %r80, i64* %ptr_ptr
  %r81 = load i64, i64* %ptr_ptr
  %r82 = call i64 @mensura(i64 %r81)
  %r83 = call i64 @_eq(i64 %r82, i64 0)
  %r84 = icmp ne i64 %r83, 0
  br i1 %r84, label %L850, label %L852
L850:
  %r85 = getelementptr [6 x i8], [6 x i8]* @.str.497, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = load i64, i64* %ptr_node
  %r88 = getelementptr [5 x i8], [5 x i8]* @.str.498, i64 0, i64 0
  %r89 = ptrtoint i8* %r88 to i64
  %r90 = call i64 @_get(i64 %r87, i64 %r89)
  %r91 = call i64 @_add(i64 %r86, i64 %r90)
  store i64 %r91, i64* %ptr_ptr
  %r92 = load i64, i64* %ptr_ptr
  %r93 = getelementptr [14 x i8], [14 x i8]* @.str.499, i64 0, i64 0
  %r94 = ptrtoint i8* %r93 to i64
  %r95 = call i64 @_add(i64 %r92, i64 %r94)
  %r96 = call i64 @emit(i64 %r95)
  %r97 = load i64, i64* %ptr_ptr
  %r98 = load i64, i64* %ptr_node
  %r99 = getelementptr [5 x i8], [5 x i8]* @.str.500, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_get(i64 %r98, i64 %r100)
  %r102 = load i64, i64* @var_map
  call i64 @_set(i64 %r102, i64 %r101, i64 %r97)
  br label %L852
L852:
  %r103 = getelementptr [11 x i8], [11 x i8]* @.str.501, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = load i64, i64* %ptr_val
  %r106 = call i64 @_add(i64 %r104, i64 %r105)
  %r107 = getelementptr [8 x i8], [8 x i8]* @.str.502, i64 0, i64 0
  %r108 = ptrtoint i8* %r107 to i64
  %r109 = call i64 @_add(i64 %r106, i64 %r108)
  %r110 = load i64, i64* %ptr_ptr
  %r111 = call i64 @_add(i64 %r109, i64 %r110)
  %r112 = call i64 @emit(i64 %r111)
  br label %L849
L849:
  %r113 = load i64, i64* %ptr_node
  %r114 = getelementptr [5 x i8], [5 x i8]* @.str.503, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_get(i64 %r113, i64 %r115)
  %r117 = load i64, i64* @STMT_SET_INDEX
  %r118 = call i64 @_eq(i64 %r116, i64 %r117)
  %r119 = icmp ne i64 %r118, 0
  br i1 %r119, label %L853, label %L855
L853:
  %r120 = load i64, i64* %ptr_node
  %r121 = getelementptr [4 x i8], [4 x i8]* @.str.504, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = call i64 @_get(i64 %r120, i64 %r122)
  %r124 = call i64 @compile_expr(i64 %r123)
  store i64 %r124, i64* %ptr_val
  %r125 = load i64, i64* %ptr_node
  %r126 = getelementptr [4 x i8], [4 x i8]* @.str.505, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = call i64 @compile_expr(i64 %r128)
  store i64 %r129, i64* %ptr_idx
  %r130 = load i64, i64* %ptr_node
  %r131 = getelementptr [5 x i8], [5 x i8]* @.str.506, i64 0, i64 0
  %r132 = ptrtoint i8* %r131 to i64
  %r133 = call i64 @_get(i64 %r130, i64 %r132)
  %r134 = call i64 @get_var_ptr(i64 %r133)
  store i64 %r134, i64* %ptr_list_ptr
  %r135 = load i64, i64* %ptr_list_ptr
  %r136 = call i64 @mensura(i64 %r135)
  %r137 = call i64 @_eq(i64 %r136, i64 0)
  %r138 = icmp ne i64 %r137, 0
  br i1 %r138, label %L856, label %L857
L856:
  %r139 = getelementptr [46 x i8], [46 x i8]* @.str.507, i64 0, i64 0
  %r140 = ptrtoint i8* %r139 to i64
  %r141 = load i64, i64* %ptr_node
  %r142 = getelementptr [5 x i8], [5 x i8]* @.str.508, i64 0, i64 0
  %r143 = ptrtoint i8* %r142 to i64
  %r144 = call i64 @_get(i64 %r141, i64 %r143)
  %r145 = call i64 @_add(i64 %r140, i64 %r144)
  %r146 = getelementptr [2 x i8], [2 x i8]* @.str.509, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = call i64 @_add(i64 %r145, i64 %r147)
  call i64 @print_any(i64 %r148)
  br label %L858
L857:
  %r149 = call i64 @next_reg()
  store i64 %r149, i64* %ptr_list_reg
  %r150 = load i64, i64* %ptr_list_reg
  %r151 = getelementptr [19 x i8], [19 x i8]* @.str.510, i64 0, i64 0
  %r152 = ptrtoint i8* %r151 to i64
  %r153 = call i64 @_add(i64 %r150, i64 %r152)
  %r154 = load i64, i64* %ptr_list_ptr
  %r155 = call i64 @_add(i64 %r153, i64 %r154)
  %r156 = call i64 @emit(i64 %r155)
  %r157 = getelementptr [20 x i8], [20 x i8]* @.str.511, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = load i64, i64* %ptr_list_reg
  %r160 = call i64 @_add(i64 %r158, i64 %r159)
  %r161 = getelementptr [7 x i8], [7 x i8]* @.str.512, i64 0, i64 0
  %r162 = ptrtoint i8* %r161 to i64
  %r163 = call i64 @_add(i64 %r160, i64 %r162)
  %r164 = load i64, i64* %ptr_idx
  %r165 = call i64 @_add(i64 %r163, i64 %r164)
  %r166 = getelementptr [7 x i8], [7 x i8]* @.str.513, i64 0, i64 0
  %r167 = ptrtoint i8* %r166 to i64
  %r168 = call i64 @_add(i64 %r165, i64 %r167)
  %r169 = load i64, i64* %ptr_val
  %r170 = call i64 @_add(i64 %r168, i64 %r169)
  %r171 = getelementptr [2 x i8], [2 x i8]* @.str.514, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_add(i64 %r170, i64 %r172)
  %r174 = call i64 @emit(i64 %r173)
  br label %L858
L858:
  br label %L855
L855:
  %r175 = load i64, i64* %ptr_node
  %r176 = getelementptr [5 x i8], [5 x i8]* @.str.515, i64 0, i64 0
  %r177 = ptrtoint i8* %r176 to i64
  %r178 = call i64 @_get(i64 %r175, i64 %r177)
  %r179 = load i64, i64* @STMT_ASSIGN
  %r180 = call i64 @_eq(i64 %r178, i64 %r179)
  %r181 = icmp ne i64 %r180, 0
  br i1 %r181, label %L859, label %L861
L859:
  %r182 = load i64, i64* %ptr_node
  %r183 = getelementptr [4 x i8], [4 x i8]* @.str.516, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_get(i64 %r182, i64 %r184)
  %r186 = call i64 @compile_expr(i64 %r185)
  store i64 %r186, i64* %ptr_val
  %r187 = load i64, i64* %ptr_node
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.517, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = call i64 @_get(i64 %r187, i64 %r189)
  %r191 = call i64 @get_var_ptr(i64 %r190)
  store i64 %r191, i64* %ptr_ptr
  %r192 = load i64, i64* %ptr_ptr
  %r193 = call i64 @mensura(i64 %r192)
  %r194 = call i64 @_eq(i64 %r193, i64 0)
  %r195 = icmp ne i64 %r194, 0
  br i1 %r195, label %L862, label %L863
L862:
  %r196 = getelementptr [47 x i8], [47 x i8]* @.str.518, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = load i64, i64* %ptr_node
  %r199 = getelementptr [5 x i8], [5 x i8]* @.str.519, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  %r202 = call i64 @_add(i64 %r197, i64 %r201)
  %r203 = getelementptr [2 x i8], [2 x i8]* @.str.520, i64 0, i64 0
  %r204 = ptrtoint i8* %r203 to i64
  %r205 = call i64 @_add(i64 %r202, i64 %r204)
  call i64 @print_any(i64 %r205)
  br label %L864
L863:
  %r206 = getelementptr [11 x i8], [11 x i8]* @.str.521, i64 0, i64 0
  %r207 = ptrtoint i8* %r206 to i64
  %r208 = load i64, i64* %ptr_val
  %r209 = call i64 @_add(i64 %r207, i64 %r208)
  %r210 = getelementptr [8 x i8], [8 x i8]* @.str.522, i64 0, i64 0
  %r211 = ptrtoint i8* %r210 to i64
  %r212 = call i64 @_add(i64 %r209, i64 %r211)
  %r213 = load i64, i64* %ptr_ptr
  %r214 = call i64 @_add(i64 %r212, i64 %r213)
  %r215 = call i64 @emit(i64 %r214)
  br label %L864
L864:
  br label %L861
L861:
  %r216 = load i64, i64* %ptr_node
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.523, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_get(i64 %r216, i64 %r218)
  %r220 = load i64, i64* @STMT_APPEND
  %r221 = call i64 @_eq(i64 %r219, i64 %r220)
  %r222 = icmp ne i64 %r221, 0
  br i1 %r222, label %L865, label %L867
L865:
  %r223 = load i64, i64* %ptr_node
  %r224 = getelementptr [4 x i8], [4 x i8]* @.str.524, i64 0, i64 0
  %r225 = ptrtoint i8* %r224 to i64
  %r226 = call i64 @_get(i64 %r223, i64 %r225)
  %r227 = call i64 @compile_expr(i64 %r226)
  store i64 %r227, i64* %ptr_val
  %r228 = load i64, i64* %ptr_node
  %r229 = getelementptr [5 x i8], [5 x i8]* @.str.525, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @_get(i64 %r228, i64 %r230)
  %r232 = call i64 @get_var_ptr(i64 %r231)
  store i64 %r232, i64* %ptr_list_ptr
  %r233 = load i64, i64* %ptr_list_ptr
  %r234 = call i64 @mensura(i64 %r233)
  %r235 = call i64 @_eq(i64 %r234, i64 0)
  %r236 = icmp ne i64 %r235, 0
  br i1 %r236, label %L868, label %L869
L868:
  %r237 = getelementptr [43 x i8], [43 x i8]* @.str.526, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = load i64, i64* %ptr_node
  %r240 = getelementptr [5 x i8], [5 x i8]* @.str.527, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_get(i64 %r239, i64 %r241)
  %r243 = call i64 @_add(i64 %r238, i64 %r242)
  %r244 = getelementptr [2 x i8], [2 x i8]* @.str.528, i64 0, i64 0
  %r245 = ptrtoint i8* %r244 to i64
  %r246 = call i64 @_add(i64 %r243, i64 %r245)
  call i64 @print_any(i64 %r246)
  br label %L870
L869:
  %r247 = call i64 @next_reg()
  store i64 %r247, i64* %ptr_list_reg
  %r248 = load i64, i64* %ptr_list_reg
  %r249 = getelementptr [19 x i8], [19 x i8]* @.str.529, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = call i64 @_add(i64 %r248, i64 %r250)
  %r252 = load i64, i64* %ptr_list_ptr
  %r253 = call i64 @_add(i64 %r251, i64 %r252)
  %r254 = call i64 @emit(i64 %r253)
  %r255 = getelementptr [28 x i8], [28 x i8]* @.str.530, i64 0, i64 0
  %r256 = ptrtoint i8* %r255 to i64
  %r257 = load i64, i64* %ptr_list_reg
  %r258 = call i64 @_add(i64 %r256, i64 %r257)
  %r259 = getelementptr [7 x i8], [7 x i8]* @.str.531, i64 0, i64 0
  %r260 = ptrtoint i8* %r259 to i64
  %r261 = call i64 @_add(i64 %r258, i64 %r260)
  %r262 = load i64, i64* %ptr_val
  %r263 = call i64 @_add(i64 %r261, i64 %r262)
  %r264 = getelementptr [2 x i8], [2 x i8]* @.str.532, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = call i64 @_add(i64 %r263, i64 %r265)
  %r267 = call i64 @emit(i64 %r266)
  br label %L870
L870:
  br label %L867
L867:
  %r268 = load i64, i64* %ptr_node
  %r269 = getelementptr [5 x i8], [5 x i8]* @.str.533, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @_get(i64 %r268, i64 %r270)
  %r272 = load i64, i64* @STMT_PRINT
  %r273 = call i64 @_eq(i64 %r271, i64 %r272)
  %r274 = icmp ne i64 %r273, 0
  br i1 %r274, label %L871, label %L873
L871:
  %r275 = getelementptr [29 x i8], [29 x i8]* @.str.534, i64 0, i64 0
  %r276 = ptrtoint i8* %r275 to i64
  call i64 @print_any(i64 %r276)
  %r277 = load i64, i64* %ptr_node
  %r278 = getelementptr [4 x i8], [4 x i8]* @.str.535, i64 0, i64 0
  %r279 = ptrtoint i8* %r278 to i64
  %r280 = call i64 @_get(i64 %r277, i64 %r279)
  %r281 = call i64 @compile_expr(i64 %r280)
  store i64 %r281, i64* %ptr_val
  %r282 = getelementptr [25 x i8], [25 x i8]* @.str.536, i64 0, i64 0
  %r283 = ptrtoint i8* %r282 to i64
  %r284 = load i64, i64* %ptr_val
  %r285 = call i64 @_add(i64 %r283, i64 %r284)
  %r286 = getelementptr [2 x i8], [2 x i8]* @.str.537, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = call i64 @_add(i64 %r285, i64 %r287)
  %r289 = call i64 @emit(i64 %r288)
  br label %L873
L873:
  %r290 = load i64, i64* %ptr_node
  %r291 = getelementptr [5 x i8], [5 x i8]* @.str.538, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_get(i64 %r290, i64 %r292)
  %r294 = load i64, i64* @STMT_BREAK
  %r295 = call i64 @_eq(i64 %r293, i64 %r294)
  %r296 = icmp ne i64 %r295, 0
  br i1 %r296, label %L874, label %L876
L874:
  %r297 = load i64, i64* @loop_end_stack
  %r298 = call i64 @mensura(i64 %r297)
  store i64 %r298, i64* %ptr_len
  %r299 = load i64, i64* %ptr_len
  %r301 = icmp sgt i64 %r299, 0
  %r300 = zext i1 %r301 to i64
  %r302 = icmp ne i64 %r300, 0
  br i1 %r302, label %L877, label %L879
L877:
  %r303 = load i64, i64* @loop_end_stack
  %r304 = load i64, i64* %ptr_len
  %r305 = sub i64 %r304, 1
  %r306 = call i64 @_get(i64 %r303, i64 %r305)
  store i64 %r306, i64* %ptr_lbl
  %r307 = getelementptr [11 x i8], [11 x i8]* @.str.539, i64 0, i64 0
  %r308 = ptrtoint i8* %r307 to i64
  %r309 = load i64, i64* %ptr_lbl
  %r310 = call i64 @_add(i64 %r308, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  br label %L879
L879:
  store i64 1, i64* @block_terminated
  br label %L876
L876:
  %r312 = load i64, i64* %ptr_node
  %r313 = getelementptr [5 x i8], [5 x i8]* @.str.540, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_get(i64 %r312, i64 %r314)
  %r316 = load i64, i64* @STMT_CONTINUE
  %r317 = call i64 @_eq(i64 %r315, i64 %r316)
  %r318 = icmp ne i64 %r317, 0
  br i1 %r318, label %L880, label %L882
L880:
  %r319 = load i64, i64* @loop_cond_stack
  %r320 = call i64 @mensura(i64 %r319)
  store i64 %r320, i64* %ptr_len
  %r321 = load i64, i64* %ptr_len
  %r323 = icmp sgt i64 %r321, 0
  %r322 = zext i1 %r323 to i64
  %r324 = icmp ne i64 %r322, 0
  br i1 %r324, label %L883, label %L885
L883:
  %r325 = load i64, i64* @loop_cond_stack
  %r326 = load i64, i64* %ptr_len
  %r327 = sub i64 %r326, 1
  %r328 = call i64 @_get(i64 %r325, i64 %r327)
  store i64 %r328, i64* %ptr_lbl
  %r329 = getelementptr [11 x i8], [11 x i8]* @.str.541, i64 0, i64 0
  %r330 = ptrtoint i8* %r329 to i64
  %r331 = load i64, i64* %ptr_lbl
  %r332 = call i64 @_add(i64 %r330, i64 %r331)
  %r333 = call i64 @emit(i64 %r332)
  br label %L885
L885:
  store i64 1, i64* @block_terminated
  br label %L882
L882:
  %r334 = load i64, i64* %ptr_node
  %r335 = getelementptr [5 x i8], [5 x i8]* @.str.542, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_get(i64 %r334, i64 %r336)
  %r338 = load i64, i64* @STMT_RETURN
  %r339 = call i64 @_eq(i64 %r337, i64 %r338)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L886, label %L888
L886:
  %r341 = load i64, i64* %ptr_node
  %r342 = getelementptr [4 x i8], [4 x i8]* @.str.543, i64 0, i64 0
  %r343 = ptrtoint i8* %r342 to i64
  %r344 = call i64 @_get(i64 %r341, i64 %r343)
  %r345 = call i64 @compile_expr(i64 %r344)
  store i64 %r345, i64* %ptr_val
  %r346 = getelementptr [9 x i8], [9 x i8]* @.str.544, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = load i64, i64* %ptr_val
  %r349 = call i64 @_add(i64 %r347, i64 %r348)
  %r350 = call i64 @emit(i64 %r349)
  br label %L888
L888:
  %r351 = load i64, i64* %ptr_node
  %r352 = getelementptr [5 x i8], [5 x i8]* @.str.545, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_get(i64 %r351, i64 %r353)
  %r355 = load i64, i64* @STMT_EXPR
  %r356 = call i64 @_eq(i64 %r354, i64 %r355)
  %r357 = icmp ne i64 %r356, 0
  br i1 %r357, label %L889, label %L891
L889:
  %r358 = load i64, i64* %ptr_node
  %r359 = getelementptr [5 x i8], [5 x i8]* @.str.546, i64 0, i64 0
  %r360 = ptrtoint i8* %r359 to i64
  %r361 = call i64 @_get(i64 %r358, i64 %r360)
  %r362 = call i64 @compile_expr(i64 %r361)
  br label %L891
L891:
  %r363 = load i64, i64* %ptr_node
  %r364 = getelementptr [5 x i8], [5 x i8]* @.str.547, i64 0, i64 0
  %r365 = ptrtoint i8* %r364 to i64
  %r366 = call i64 @_get(i64 %r363, i64 %r365)
  %r367 = load i64, i64* @STMT_IF
  %r368 = call i64 @_eq(i64 %r366, i64 %r367)
  %r369 = icmp ne i64 %r368, 0
  br i1 %r369, label %L892, label %L894
L892:
  %r370 = load i64, i64* %ptr_node
  %r371 = getelementptr [5 x i8], [5 x i8]* @.str.548, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_get(i64 %r370, i64 %r372)
  %r374 = call i64 @compile_expr(i64 %r373)
  store i64 %r374, i64* %ptr_cond
  %r375 = call i64 @next_reg()
  store i64 %r375, i64* %ptr_bool
  %r376 = load i64, i64* %ptr_bool
  %r377 = getelementptr [16 x i8], [16 x i8]* @.str.549, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_cond
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  %r382 = getelementptr [4 x i8], [4 x i8]* @.str.550, i64 0, i64 0
  %r383 = ptrtoint i8* %r382 to i64
  %r384 = call i64 @_add(i64 %r381, i64 %r383)
  %r385 = call i64 @emit(i64 %r384)
  %r386 = call i64 @next_label()
  store i64 %r386, i64* %ptr_l_then
  %r387 = call i64 @next_label()
  store i64 %r387, i64* %ptr_l_else
  %r388 = call i64 @next_label()
  store i64 %r388, i64* %ptr_l_end
  %r389 = load i64, i64* %ptr_node
  %r390 = getelementptr [5 x i8], [5 x i8]* @.str.551, i64 0, i64 0
  %r391 = ptrtoint i8* %r390 to i64
  %r392 = call i64 @_get(i64 %r389, i64 %r391)
  %r393 = call i64 @mensura(i64 %r392)
  %r395 = icmp sgt i64 %r393, 0
  %r394 = zext i1 %r395 to i64
  store i64 %r394, i64* %ptr_has_else
  %r396 = load i64, i64* %ptr_has_else
  %r397 = icmp ne i64 %r396, 0
  br i1 %r397, label %L895, label %L896
L895:
  %r398 = getelementptr [7 x i8], [7 x i8]* @.str.552, i64 0, i64 0
  %r399 = ptrtoint i8* %r398 to i64
  %r400 = load i64, i64* %ptr_bool
  %r401 = call i64 @_add(i64 %r399, i64 %r400)
  %r402 = getelementptr [10 x i8], [10 x i8]* @.str.553, i64 0, i64 0
  %r403 = ptrtoint i8* %r402 to i64
  %r404 = call i64 @_add(i64 %r401, i64 %r403)
  %r405 = load i64, i64* %ptr_l_then
  %r406 = call i64 @_add(i64 %r404, i64 %r405)
  %r407 = getelementptr [10 x i8], [10 x i8]* @.str.554, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = call i64 @_add(i64 %r406, i64 %r408)
  %r410 = load i64, i64* %ptr_l_else
  %r411 = call i64 @_add(i64 %r409, i64 %r410)
  %r412 = call i64 @emit(i64 %r411)
  br label %L897
L896:
  %r413 = getelementptr [7 x i8], [7 x i8]* @.str.555, i64 0, i64 0
  %r414 = ptrtoint i8* %r413 to i64
  %r415 = load i64, i64* %ptr_bool
  %r416 = call i64 @_add(i64 %r414, i64 %r415)
  %r417 = getelementptr [10 x i8], [10 x i8]* @.str.556, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  %r419 = call i64 @_add(i64 %r416, i64 %r418)
  %r420 = load i64, i64* %ptr_l_then
  %r421 = call i64 @_add(i64 %r419, i64 %r420)
  %r422 = getelementptr [10 x i8], [10 x i8]* @.str.557, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_add(i64 %r421, i64 %r423)
  %r425 = load i64, i64* %ptr_l_end
  %r426 = call i64 @_add(i64 %r424, i64 %r425)
  %r427 = call i64 @emit(i64 %r426)
  br label %L897
L897:
  %r428 = load i64, i64* %ptr_l_then
  %r429 = getelementptr [2 x i8], [2 x i8]* @.str.558, i64 0, i64 0
  %r430 = ptrtoint i8* %r429 to i64
  %r431 = call i64 @_add(i64 %r428, i64 %r430)
  %r432 = call i64 @emit_raw(i64 %r431)
  store i64 0, i64* @block_terminated
  %r433 = load i64, i64* %ptr_node
  %r434 = getelementptr [5 x i8], [5 x i8]* @.str.559, i64 0, i64 0
  %r435 = ptrtoint i8* %r434 to i64
  %r436 = call i64 @_get(i64 %r433, i64 %r435)
  %r437 = call i64 @compile_block(i64 %r436)
  %r438 = load i64, i64* @block_terminated
  %r439 = call i64 @_eq(i64 %r438, i64 0)
  %r440 = icmp ne i64 %r439, 0
  br i1 %r440, label %L898, label %L900
L898:
  %r441 = getelementptr [11 x i8], [11 x i8]* @.str.560, i64 0, i64 0
  %r442 = ptrtoint i8* %r441 to i64
  %r443 = load i64, i64* %ptr_l_end
  %r444 = call i64 @_add(i64 %r442, i64 %r443)
  %r445 = call i64 @emit(i64 %r444)
  br label %L900
L900:
  %r446 = load i64, i64* %ptr_has_else
  %r447 = icmp ne i64 %r446, 0
  br i1 %r447, label %L901, label %L903
L901:
  %r448 = load i64, i64* %ptr_l_else
  %r449 = getelementptr [2 x i8], [2 x i8]* @.str.561, i64 0, i64 0
  %r450 = ptrtoint i8* %r449 to i64
  %r451 = call i64 @_add(i64 %r448, i64 %r450)
  %r452 = call i64 @emit_raw(i64 %r451)
  store i64 0, i64* @block_terminated
  %r453 = load i64, i64* %ptr_node
  %r454 = getelementptr [5 x i8], [5 x i8]* @.str.562, i64 0, i64 0
  %r455 = ptrtoint i8* %r454 to i64
  %r456 = call i64 @_get(i64 %r453, i64 %r455)
  %r457 = call i64 @compile_block(i64 %r456)
  %r458 = load i64, i64* @block_terminated
  %r459 = call i64 @_eq(i64 %r458, i64 0)
  %r460 = icmp ne i64 %r459, 0
  br i1 %r460, label %L904, label %L906
L904:
  %r461 = getelementptr [11 x i8], [11 x i8]* @.str.563, i64 0, i64 0
  %r462 = ptrtoint i8* %r461 to i64
  %r463 = load i64, i64* %ptr_l_end
  %r464 = call i64 @_add(i64 %r462, i64 %r463)
  %r465 = call i64 @emit(i64 %r464)
  br label %L906
L906:
  br label %L903
L903:
  %r466 = load i64, i64* %ptr_l_end
  %r467 = getelementptr [2 x i8], [2 x i8]* @.str.564, i64 0, i64 0
  %r468 = ptrtoint i8* %r467 to i64
  %r469 = call i64 @_add(i64 %r466, i64 %r468)
  %r470 = call i64 @emit_raw(i64 %r469)
  store i64 0, i64* @block_terminated
  br label %L894
L894:
  %r471 = load i64, i64* %ptr_node
  %r472 = getelementptr [5 x i8], [5 x i8]* @.str.565, i64 0, i64 0
  %r473 = ptrtoint i8* %r472 to i64
  %r474 = call i64 @_get(i64 %r471, i64 %r473)
  %r475 = load i64, i64* @STMT_WHILE
  %r476 = call i64 @_eq(i64 %r474, i64 %r475)
  %r477 = icmp ne i64 %r476, 0
  br i1 %r477, label %L907, label %L909
L907:
  %r478 = call i64 @next_label()
  store i64 %r478, i64* %ptr_l_cond
  %r479 = call i64 @next_label()
  store i64 %r479, i64* %ptr_l_body
  %r480 = call i64 @next_label()
  store i64 %r480, i64* %ptr_l_end
  %r481 = load i64, i64* %ptr_l_cond
  %r482 = load i64, i64* @loop_cond_stack
  call i64 @_append_poly(i64 %r482, i64 %r481)
  %r483 = load i64, i64* %ptr_l_end
  %r484 = load i64, i64* @loop_end_stack
  call i64 @_append_poly(i64 %r484, i64 %r483)
  %r485 = getelementptr [11 x i8], [11 x i8]* @.str.566, i64 0, i64 0
  %r486 = ptrtoint i8* %r485 to i64
  %r487 = load i64, i64* %ptr_l_cond
  %r488 = call i64 @_add(i64 %r486, i64 %r487)
  %r489 = call i64 @emit(i64 %r488)
  %r490 = load i64, i64* %ptr_l_cond
  %r491 = getelementptr [2 x i8], [2 x i8]* @.str.567, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_add(i64 %r490, i64 %r492)
  %r494 = call i64 @emit_raw(i64 %r493)
  %r495 = load i64, i64* %ptr_node
  %r496 = getelementptr [5 x i8], [5 x i8]* @.str.568, i64 0, i64 0
  %r497 = ptrtoint i8* %r496 to i64
  %r498 = call i64 @_get(i64 %r495, i64 %r497)
  %r499 = call i64 @compile_expr(i64 %r498)
  store i64 %r499, i64* %ptr_cond
  %r500 = call i64 @next_reg()
  store i64 %r500, i64* %ptr_bool
  %r501 = load i64, i64* %ptr_bool
  %r502 = getelementptr [16 x i8], [16 x i8]* @.str.569, i64 0, i64 0
  %r503 = ptrtoint i8* %r502 to i64
  %r504 = call i64 @_add(i64 %r501, i64 %r503)
  %r505 = load i64, i64* %ptr_cond
  %r506 = call i64 @_add(i64 %r504, i64 %r505)
  %r507 = getelementptr [4 x i8], [4 x i8]* @.str.570, i64 0, i64 0
  %r508 = ptrtoint i8* %r507 to i64
  %r509 = call i64 @_add(i64 %r506, i64 %r508)
  %r510 = call i64 @emit(i64 %r509)
  %r511 = getelementptr [7 x i8], [7 x i8]* @.str.571, i64 0, i64 0
  %r512 = ptrtoint i8* %r511 to i64
  %r513 = load i64, i64* %ptr_bool
  %r514 = call i64 @_add(i64 %r512, i64 %r513)
  %r515 = getelementptr [10 x i8], [10 x i8]* @.str.572, i64 0, i64 0
  %r516 = ptrtoint i8* %r515 to i64
  %r517 = call i64 @_add(i64 %r514, i64 %r516)
  %r518 = load i64, i64* %ptr_l_body
  %r519 = call i64 @_add(i64 %r517, i64 %r518)
  %r520 = getelementptr [10 x i8], [10 x i8]* @.str.573, i64 0, i64 0
  %r521 = ptrtoint i8* %r520 to i64
  %r522 = call i64 @_add(i64 %r519, i64 %r521)
  %r523 = load i64, i64* %ptr_l_end
  %r524 = call i64 @_add(i64 %r522, i64 %r523)
  %r525 = call i64 @emit(i64 %r524)
  %r526 = load i64, i64* %ptr_l_body
  %r527 = getelementptr [2 x i8], [2 x i8]* @.str.574, i64 0, i64 0
  %r528 = ptrtoint i8* %r527 to i64
  %r529 = call i64 @_add(i64 %r526, i64 %r528)
  %r530 = call i64 @emit_raw(i64 %r529)
  %r531 = load i64, i64* %ptr_node
  %r532 = getelementptr [5 x i8], [5 x i8]* @.str.575, i64 0, i64 0
  %r533 = ptrtoint i8* %r532 to i64
  %r534 = call i64 @_get(i64 %r531, i64 %r533)
  %r535 = call i64 @compile_block(i64 %r534)
  %r536 = getelementptr [11 x i8], [11 x i8]* @.str.576, i64 0, i64 0
  %r537 = ptrtoint i8* %r536 to i64
  %r538 = load i64, i64* %ptr_l_cond
  %r539 = call i64 @_add(i64 %r537, i64 %r538)
  %r540 = call i64 @emit(i64 %r539)
  %r541 = load i64, i64* %ptr_l_end
  %r542 = getelementptr [2 x i8], [2 x i8]* @.str.577, i64 0, i64 0
  %r543 = ptrtoint i8* %r542 to i64
  %r544 = call i64 @_add(i64 %r541, i64 %r543)
  %r545 = call i64 @emit_raw(i64 %r544)
  %r546 = load i64, i64* @loop_cond_stack
  %r547 = call i64 @mensura(i64 %r546)
  store i64 %r547, i64* %ptr_len
  %r548 = getelementptr [1 x i8], [1 x i8]* @.str.578, i64 0, i64 0
  %r549 = ptrtoint i8* %r548 to i64
  store i64 %r549, i64* %ptr_extract_dummy
  %r550 = call i64 @_list_new()
  store i64 %r550, i64* %ptr_popped_cond
  store i64 0, i64* %ptr_i
  br label %L910
L910:
  %r551 = load i64, i64* %ptr_i
  %r552 = load i64, i64* %ptr_len
  %r553 = sub i64 %r552, 1
  %r555 = icmp slt i64 %r551, %r553
  %r554 = zext i1 %r555 to i64
  %r556 = icmp ne i64 %r554, 0
  br i1 %r556, label %L911, label %L912
L911:
  %r557 = load i64, i64* @loop_cond_stack
  %r558 = load i64, i64* %ptr_i
  %r559 = call i64 @_get(i64 %r557, i64 %r558)
  %r560 = load i64, i64* %ptr_popped_cond
  call i64 @_append_poly(i64 %r560, i64 %r559)
  %r561 = load i64, i64* %ptr_i
  %r562 = call i64 @_add(i64 %r561, i64 1)
  store i64 %r562, i64* %ptr_i
  br label %L910
L912:
  %r563 = load i64, i64* %ptr_popped_cond
  store i64 %r563, i64* @loop_cond_stack
  %r564 = call i64 @_list_new()
  store i64 %r564, i64* %ptr_popped_end
  store i64 0, i64* %ptr_i
  br label %L913
L913:
  %r565 = load i64, i64* %ptr_i
  %r566 = load i64, i64* %ptr_len
  %r567 = sub i64 %r566, 1
  %r569 = icmp slt i64 %r565, %r567
  %r568 = zext i1 %r569 to i64
  %r570 = icmp ne i64 %r568, 0
  br i1 %r570, label %L914, label %L915
L914:
  %r571 = load i64, i64* @loop_end_stack
  %r572 = load i64, i64* %ptr_i
  %r573 = call i64 @_get(i64 %r571, i64 %r572)
  %r574 = load i64, i64* %ptr_popped_end
  call i64 @_append_poly(i64 %r574, i64 %r573)
  %r575 = load i64, i64* %ptr_i
  %r576 = call i64 @_add(i64 %r575, i64 1)
  store i64 %r576, i64* %ptr_i
  br label %L913
L915:
  %r577 = load i64, i64* %ptr_popped_end
  store i64 %r577, i64* @loop_end_stack
  br label %L909
L909:
  ret i64 0
}
define i64 @compile_block(i64 %arg_stmts) {
  %ptr_stmts = alloca i64
  store i64 %arg_stmts, i64* %ptr_stmts
  %ptr_i = alloca i64
  store i64 0, i64* %ptr_i
  br label %L916
L916:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L917, label %L918
L917:
  %r7 = load i64, i64* @block_terminated
  %r8 = call i64 @_eq(i64 %r7, i64 0)
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L919, label %L921
L919:
  %r10 = load i64, i64* %ptr_stmts
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @_get(i64 %r10, i64 %r11)
  %r13 = call i64 @compile_stmt(i64 %r12)
  br label %L921
L921:
  %r14 = load i64, i64* %ptr_i
  %r15 = call i64 @_add(i64 %r14, i64 1)
  store i64 %r15, i64* %ptr_i
  br label %L916
L918:
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
  br label %L922
L922:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L923, label %L924
L923:
  %r7 = load i64, i64* %ptr_stmts
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  store i64 %r9, i64* %ptr_s
  %r10 = load i64, i64* %ptr_s
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.579, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = call i64 @_get(i64 %r10, i64 %r12)
  %r14 = load i64, i64* @STMT_LET
  %r15 = call i64 @_eq(i64 %r13, i64 %r14)
  %r16 = icmp ne i64 %r15, 0
  br i1 %r16, label %L925, label %L927
L925:
  %r17 = load i64, i64* %ptr_s
  %r18 = getelementptr [5 x i8], [5 x i8]* @.str.580, i64 0, i64 0
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
  br i1 %r27, label %L928, label %L930
L928:
  %r28 = getelementptr [6 x i8], [6 x i8]* @.str.581, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_nm
  %r31 = call i64 @_add(i64 %r29, i64 %r30)
  store i64 %r31, i64* %ptr_ptr
  %r32 = load i64, i64* %ptr_ptr
  %r33 = getelementptr [14 x i8], [14 x i8]* @.str.582, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_add(i64 %r32, i64 %r34)
  %r36 = call i64 @emit(i64 %r35)
  %r37 = load i64, i64* %ptr_ptr
  %r38 = load i64, i64* %ptr_nm
  %r39 = load i64, i64* @var_map
  call i64 @_set(i64 %r39, i64 %r38, i64 %r37)
  br label %L930
L930:
  br label %L927
L927:
  %r40 = load i64, i64* %ptr_s
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.583, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = call i64 @_get(i64 %r40, i64 %r42)
  %r44 = load i64, i64* @STMT_IF
  %r45 = call i64 @_eq(i64 %r43, i64 %r44)
  %r46 = icmp ne i64 %r45, 0
  br i1 %r46, label %L931, label %L933
L931:
  %r47 = load i64, i64* %ptr_s
  %r48 = getelementptr [5 x i8], [5 x i8]* @.str.584, i64 0, i64 0
  %r49 = ptrtoint i8* %r48 to i64
  %r50 = call i64 @_get(i64 %r47, i64 %r49)
  %r51 = call i64 @scan_for_vars(i64 %r50)
  %r52 = load i64, i64* %ptr_s
  %r53 = getelementptr [5 x i8], [5 x i8]* @.str.585, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = call i64 @_get(i64 %r52, i64 %r54)
  %r56 = call i64 @mensura(i64 %r55)
  %r58 = icmp sgt i64 %r56, 0
  %r57 = zext i1 %r58 to i64
  %r59 = icmp ne i64 %r57, 0
  br i1 %r59, label %L934, label %L936
L934:
  %r60 = load i64, i64* %ptr_s
  %r61 = getelementptr [5 x i8], [5 x i8]* @.str.586, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = call i64 @_get(i64 %r60, i64 %r62)
  %r64 = call i64 @scan_for_vars(i64 %r63)
  br label %L936
L936:
  br label %L933
L933:
  %r65 = load i64, i64* %ptr_s
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.587, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = call i64 @_get(i64 %r65, i64 %r67)
  %r69 = load i64, i64* @STMT_WHILE
  %r70 = call i64 @_eq(i64 %r68, i64 %r69)
  %r71 = icmp ne i64 %r70, 0
  br i1 %r71, label %L937, label %L939
L937:
  %r72 = load i64, i64* %ptr_s
  %r73 = getelementptr [5 x i8], [5 x i8]* @.str.588, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = call i64 @_get(i64 %r72, i64 %r74)
  %r76 = call i64 @scan_for_vars(i64 %r75)
  br label %L939
L939:
  %r77 = load i64, i64* %ptr_i
  %r78 = call i64 @_add(i64 %r77, i64 1)
  store i64 %r78, i64* %ptr_i
  br label %L922
L924:
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
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.589, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  store i64 %r4, i64* %ptr_name
  %r5 = load i64, i64* %ptr_name
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.590, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_eq(i64 %r5, i64 %r7)
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L940, label %L942
L940:
  %r10 = getelementptr [12 x i8], [12 x i8]* @.str.591, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  store i64 %r11, i64* %ptr_name
  br label %L942
L942:
  %r12 = getelementptr [13 x i8], [13 x i8]* @.str.592, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = load i64, i64* %ptr_name
  %r15 = call i64 @_add(i64 %r13, i64 %r14)
  %r16 = getelementptr [2 x i8], [2 x i8]* @.str.593, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  %r18 = call i64 @_add(i64 %r15, i64 %r17)
  store i64 %r18, i64* %ptr_header
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [7 x i8], [7 x i8]* @.str.594, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  store i64 %r22, i64* %ptr_params
  store i64 0, i64* %ptr_i
  %r23 = call i64 @_map_new()
  store i64 %r23, i64* @var_map
  store i64 0, i64* @reg_count
  br label %L943
L943:
  %r24 = load i64, i64* %ptr_i
  %r25 = load i64, i64* %ptr_params
  %r26 = call i64 @mensura(i64 %r25)
  %r28 = icmp slt i64 %r24, %r26
  %r27 = zext i1 %r28 to i64
  %r29 = icmp ne i64 %r27, 0
  br i1 %r29, label %L944, label %L945
L944:
  %r30 = load i64, i64* %ptr_header
  %r31 = getelementptr [10 x i8], [10 x i8]* @.str.595, i64 0, i64 0
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
  br i1 %r44, label %L946, label %L948
L946:
  %r45 = load i64, i64* %ptr_header
  %r46 = getelementptr [3 x i8], [3 x i8]* @.str.596, i64 0, i64 0
  %r47 = ptrtoint i8* %r46 to i64
  %r48 = call i64 @_add(i64 %r45, i64 %r47)
  store i64 %r48, i64* %ptr_header
  br label %L948
L948:
  %r49 = load i64, i64* %ptr_i
  %r50 = call i64 @_add(i64 %r49, i64 1)
  store i64 %r50, i64* %ptr_i
  br label %L943
L945:
  %r51 = load i64, i64* %ptr_header
  %r52 = getelementptr [4 x i8], [4 x i8]* @.str.597, i64 0, i64 0
  %r53 = ptrtoint i8* %r52 to i64
  %r54 = call i64 @_add(i64 %r51, i64 %r53)
  store i64 %r54, i64* %ptr_header
  %r55 = load i64, i64* %ptr_header
  %r56 = call i64 @emit_raw(i64 %r55)
  store i64 0, i64* %ptr_i
  br label %L949
L949:
  %r57 = load i64, i64* %ptr_i
  %r58 = load i64, i64* %ptr_params
  %r59 = call i64 @mensura(i64 %r58)
  %r61 = icmp slt i64 %r57, %r59
  %r60 = zext i1 %r61 to i64
  %r62 = icmp ne i64 %r60, 0
  br i1 %r62, label %L950, label %L951
L950:
  %r63 = load i64, i64* %ptr_params
  %r64 = load i64, i64* %ptr_i
  %r65 = call i64 @_get(i64 %r63, i64 %r64)
  store i64 %r65, i64* %ptr_p
  %r66 = getelementptr [6 x i8], [6 x i8]* @.str.598, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = load i64, i64* %ptr_p
  %r69 = call i64 @_add(i64 %r67, i64 %r68)
  store i64 %r69, i64* %ptr_ptr
  %r70 = load i64, i64* %ptr_ptr
  %r71 = getelementptr [14 x i8], [14 x i8]* @.str.599, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  %r74 = call i64 @emit(i64 %r73)
  %r75 = getelementptr [16 x i8], [16 x i8]* @.str.600, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = load i64, i64* %ptr_p
  %r78 = call i64 @_add(i64 %r76, i64 %r77)
  %r79 = getelementptr [8 x i8], [8 x i8]* @.str.601, i64 0, i64 0
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
  br label %L949
L951:
  %r90 = load i64, i64* %ptr_node
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.602, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = call i64 @scan_for_vars(i64 %r93)
  %r95 = load i64, i64* %ptr_node
  %r96 = getelementptr [5 x i8], [5 x i8]* @.str.603, i64 0, i64 0
  %r97 = ptrtoint i8* %r96 to i64
  %r98 = call i64 @_get(i64 %r95, i64 %r97)
  %r99 = call i64 @compile_block(i64 %r98)
  %r100 = getelementptr [10 x i8], [10 x i8]* @.str.604, i64 0, i64 0
  %r101 = ptrtoint i8* %r100 to i64
  %r102 = call i64 @emit(i64 %r101)
  %r103 = getelementptr [2 x i8], [2 x i8]* @.str.605, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @emit_raw(i64 %r104)
  ret i64 0
}
define i64 @get_llvm_header(i64 %arg_is_freestanding, i64 %arg_is_arm64) {
  %ptr_is_freestanding = alloca i64
  store i64 %arg_is_freestanding, i64* %ptr_is_freestanding
  %ptr_is_arm64 = alloca i64
  store i64 %arg_is_arm64, i64* %ptr_is_arm64
  %ptr_NL = alloca i64
  %ptr_s = alloca i64
  %ptr_arch = alloca i64
  %r1 = call i64 @signum_ex(i64 10)
  store i64 %r1, i64* %ptr_NL
  %r2 = getelementptr [29 x i8], [29 x i8]* @.str.606, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = load i64, i64* %ptr_NL
  %r5 = call i64 @_add(i64 %r3, i64 %r4)
  store i64 %r5, i64* %ptr_s
  %r6 = getelementptr [20 x i8], [20 x i8]* @.str.607, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* %ptr_arch
  %r8 = load i64, i64* %ptr_is_arm64
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L952, label %L954
L952:
  %r10 = getelementptr [22 x i8], [22 x i8]* @.str.608, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  store i64 %r11, i64* %ptr_arch
  br label %L954
L954:
  %r12 = load i64, i64* %ptr_s
  %r13 = getelementptr [18 x i8], [18 x i8]* @.str.609, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_add(i64 %r12, i64 %r14)
  %r16 = load i64, i64* %ptr_arch
  %r17 = call i64 @_add(i64 %r15, i64 %r16)
  %r18 = getelementptr [2 x i8], [2 x i8]* @.str.610, i64 0, i64 0
  %r19 = ptrtoint i8* %r18 to i64
  %r20 = call i64 @_add(i64 %r17, i64 %r19)
  %r21 = load i64, i64* %ptr_NL
  %r22 = call i64 @_add(i64 %r20, i64 %r21)
  store i64 %r22, i64* %ptr_s
  %r23 = load i64, i64* %ptr_is_freestanding
  %r24 = call i64 @_eq(i64 %r23, i64 0)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L955, label %L957
L955:
  %r26 = load i64, i64* %ptr_s
  %r27 = getelementptr [30 x i8], [30 x i8]* @.str.611, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_add(i64 %r26, i64 %r28)
  %r30 = load i64, i64* %ptr_NL
  %r31 = call i64 @_add(i64 %r29, i64 %r30)
  store i64 %r31, i64* %ptr_s
  %r32 = load i64, i64* %ptr_s
  %r33 = getelementptr [36 x i8], [36 x i8]* @.str.612, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_add(i64 %r32, i64 %r34)
  %r36 = load i64, i64* %ptr_NL
  %r37 = call i64 @_add(i64 %r35, i64 %r36)
  store i64 %r37, i64* %ptr_s
  %r38 = load i64, i64* %ptr_s
  %r39 = getelementptr [25 x i8], [25 x i8]* @.str.613, i64 0, i64 0
  %r40 = ptrtoint i8* %r39 to i64
  %r41 = call i64 @_add(i64 %r38, i64 %r40)
  %r42 = load i64, i64* %ptr_NL
  %r43 = call i64 @_add(i64 %r41, i64 %r42)
  store i64 %r43, i64* %ptr_s
  %r44 = load i64, i64* %ptr_s
  %r45 = getelementptr [25 x i8], [25 x i8]* @.str.614, i64 0, i64 0
  %r46 = ptrtoint i8* %r45 to i64
  %r47 = call i64 @_add(i64 %r44, i64 %r46)
  %r48 = load i64, i64* %ptr_NL
  %r49 = call i64 @_add(i64 %r47, i64 %r48)
  store i64 %r49, i64* %ptr_s
  %r50 = load i64, i64* %ptr_s
  %r51 = getelementptr [31 x i8], [31 x i8]* @.str.615, i64 0, i64 0
  %r52 = ptrtoint i8* %r51 to i64
  %r53 = call i64 @_add(i64 %r50, i64 %r52)
  %r54 = load i64, i64* %ptr_NL
  %r55 = call i64 @_add(i64 %r53, i64 %r54)
  store i64 %r55, i64* %ptr_s
  %r56 = load i64, i64* %ptr_s
  %r57 = getelementptr [23 x i8], [23 x i8]* @.str.616, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = call i64 @_add(i64 %r56, i64 %r58)
  %r60 = load i64, i64* %ptr_NL
  %r61 = call i64 @_add(i64 %r59, i64 %r60)
  store i64 %r61, i64* %ptr_s
  %r62 = load i64, i64* %ptr_s
  %r63 = getelementptr [24 x i8], [24 x i8]* @.str.617, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = call i64 @_add(i64 %r62, i64 %r64)
  %r66 = load i64, i64* %ptr_NL
  %r67 = call i64 @_add(i64 %r65, i64 %r66)
  store i64 %r67, i64* %ptr_s
  %r68 = load i64, i64* %ptr_s
  %r69 = getelementptr [29 x i8], [29 x i8]* @.str.618, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = call i64 @_add(i64 %r68, i64 %r70)
  %r72 = load i64, i64* %ptr_NL
  %r73 = call i64 @_add(i64 %r71, i64 %r72)
  store i64 %r73, i64* %ptr_s
  %r74 = load i64, i64* %ptr_s
  %r75 = getelementptr [34 x i8], [34 x i8]* @.str.619, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = call i64 @_add(i64 %r74, i64 %r76)
  %r78 = load i64, i64* %ptr_NL
  %r79 = call i64 @_add(i64 %r77, i64 %r78)
  store i64 %r79, i64* %ptr_s
  %r80 = load i64, i64* %ptr_s
  %r81 = getelementptr [24 x i8], [24 x i8]* @.str.620, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_add(i64 %r80, i64 %r82)
  %r84 = load i64, i64* %ptr_NL
  %r85 = call i64 @_add(i64 %r83, i64 %r84)
  store i64 %r85, i64* %ptr_s
  %r86 = load i64, i64* %ptr_s
  %r87 = getelementptr [39 x i8], [39 x i8]* @.str.621, i64 0, i64 0
  %r88 = ptrtoint i8* %r87 to i64
  %r89 = call i64 @_add(i64 %r86, i64 %r88)
  %r90 = load i64, i64* %ptr_NL
  %r91 = call i64 @_add(i64 %r89, i64 %r90)
  store i64 %r91, i64* %ptr_s
  %r92 = load i64, i64* %ptr_s
  %r93 = getelementptr [40 x i8], [40 x i8]* @.str.622, i64 0, i64 0
  %r94 = ptrtoint i8* %r93 to i64
  %r95 = call i64 @_add(i64 %r92, i64 %r94)
  %r96 = load i64, i64* %ptr_NL
  %r97 = call i64 @_add(i64 %r95, i64 %r96)
  store i64 %r97, i64* %ptr_s
  %r98 = load i64, i64* %ptr_s
  %r99 = getelementptr [25 x i8], [25 x i8]* @.str.623, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_add(i64 %r98, i64 %r100)
  %r102 = load i64, i64* %ptr_NL
  %r103 = call i64 @_add(i64 %r101, i64 %r102)
  store i64 %r103, i64* %ptr_s
  %r104 = load i64, i64* %ptr_s
  %r105 = getelementptr [25 x i8], [25 x i8]* @.str.624, i64 0, i64 0
  %r106 = ptrtoint i8* %r105 to i64
  %r107 = call i64 @_add(i64 %r104, i64 %r106)
  %r108 = load i64, i64* %ptr_NL
  %r109 = call i64 @_add(i64 %r107, i64 %r108)
  store i64 %r109, i64* %ptr_s
  %r110 = load i64, i64* %ptr_s
  %r111 = getelementptr [25 x i8], [25 x i8]* @.str.625, i64 0, i64 0
  %r112 = ptrtoint i8* %r111 to i64
  %r113 = call i64 @_add(i64 %r110, i64 %r112)
  %r114 = load i64, i64* %ptr_NL
  %r115 = call i64 @_add(i64 %r113, i64 %r114)
  store i64 %r115, i64* %ptr_s
  %r116 = load i64, i64* %ptr_s
  %r117 = getelementptr [30 x i8], [30 x i8]* @.str.626, i64 0, i64 0
  %r118 = ptrtoint i8* %r117 to i64
  %r119 = call i64 @_add(i64 %r116, i64 %r118)
  %r120 = load i64, i64* %ptr_NL
  %r121 = call i64 @_add(i64 %r119, i64 %r120)
  store i64 %r121, i64* %ptr_s
  br label %L957
L957:
  %r122 = load i64, i64* %ptr_s
  %r123 = getelementptr [73 x i8], [73 x i8]* @.str.627, i64 0, i64 0
  %r124 = ptrtoint i8* %r123 to i64
  %r125 = call i64 @_add(i64 %r122, i64 %r124)
  %r126 = load i64, i64* %ptr_NL
  %r127 = call i64 @_add(i64 %r125, i64 %r126)
  store i64 %r127, i64* %ptr_s
  %r128 = load i64, i64* %ptr_s
  %r129 = getelementptr [72 x i8], [72 x i8]* @.str.628, i64 0, i64 0
  %r130 = ptrtoint i8* %r129 to i64
  %r131 = call i64 @_add(i64 %r128, i64 %r130)
  %r132 = load i64, i64* %ptr_NL
  %r133 = call i64 @_add(i64 %r131, i64 %r132)
  store i64 %r133, i64* %ptr_s
  %r134 = load i64, i64* %ptr_s
  %r135 = getelementptr [71 x i8], [71 x i8]* @.str.629, i64 0, i64 0
  %r136 = ptrtoint i8* %r135 to i64
  %r137 = call i64 @_add(i64 %r134, i64 %r136)
  %r138 = load i64, i64* %ptr_NL
  %r139 = call i64 @_add(i64 %r137, i64 %r138)
  store i64 %r139, i64* %ptr_s
  %r140 = load i64, i64* %ptr_s
  %r141 = getelementptr [72 x i8], [72 x i8]* @.str.630, i64 0, i64 0
  %r142 = ptrtoint i8* %r141 to i64
  %r143 = call i64 @_add(i64 %r140, i64 %r142)
  %r144 = load i64, i64* %ptr_NL
  %r145 = call i64 @_add(i64 %r143, i64 %r144)
  store i64 %r145, i64* %ptr_s
  %r146 = load i64, i64* %ptr_s
  %r147 = getelementptr [67 x i8], [67 x i8]* @.str.631, i64 0, i64 0
  %r148 = ptrtoint i8* %r147 to i64
  %r149 = call i64 @_add(i64 %r146, i64 %r148)
  %r150 = load i64, i64* %ptr_NL
  %r151 = call i64 @_add(i64 %r149, i64 %r150)
  store i64 %r151, i64* %ptr_s
  %r152 = load i64, i64* %ptr_s
  %r153 = getelementptr [67 x i8], [67 x i8]* @.str.632, i64 0, i64 0
  %r154 = ptrtoint i8* %r153 to i64
  %r155 = call i64 @_add(i64 %r152, i64 %r154)
  %r156 = load i64, i64* %ptr_NL
  %r157 = call i64 @_add(i64 %r155, i64 %r156)
  store i64 %r157, i64* %ptr_s
  %r158 = load i64, i64* %ptr_s
  %r159 = getelementptr [73 x i8], [73 x i8]* @.str.633, i64 0, i64 0
  %r160 = ptrtoint i8* %r159 to i64
  %r161 = call i64 @_add(i64 %r158, i64 %r160)
  %r162 = load i64, i64* %ptr_NL
  %r163 = call i64 @_add(i64 %r161, i64 %r162)
  store i64 %r163, i64* %ptr_s
  %r164 = load i64, i64* %ptr_s
  %r165 = getelementptr [72 x i8], [72 x i8]* @.str.634, i64 0, i64 0
  %r166 = ptrtoint i8* %r165 to i64
  %r167 = call i64 @_add(i64 %r164, i64 %r166)
  %r168 = load i64, i64* %ptr_NL
  %r169 = call i64 @_add(i64 %r167, i64 %r168)
  store i64 %r169, i64* %ptr_s
  %r170 = load i64, i64* %ptr_s
  %r171 = getelementptr [40 x i8], [40 x i8]* @.str.635, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_add(i64 %r170, i64 %r172)
  %r174 = load i64, i64* %ptr_NL
  %r175 = call i64 @_add(i64 %r173, i64 %r174)
  store i64 %r175, i64* %ptr_s
  %r176 = load i64, i64* %ptr_s
  %r177 = getelementptr [36 x i8], [36 x i8]* @.str.636, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = call i64 @_add(i64 %r176, i64 %r178)
  %r180 = load i64, i64* %ptr_NL
  %r181 = call i64 @_add(i64 %r179, i64 %r180)
  store i64 %r181, i64* %ptr_s
  %r182 = load i64, i64* %ptr_s
  %r183 = getelementptr [68 x i8], [68 x i8]* @.str.637, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_add(i64 %r182, i64 %r184)
  %r186 = load i64, i64* %ptr_NL
  %r187 = call i64 @_add(i64 %r185, i64 %r186)
  store i64 %r187, i64* %ptr_s
  %r188 = load i64, i64* %ptr_s
  %r189 = getelementptr [71 x i8], [71 x i8]* @.str.638, i64 0, i64 0
  %r190 = ptrtoint i8* %r189 to i64
  %r191 = call i64 @_add(i64 %r188, i64 %r190)
  %r192 = load i64, i64* %ptr_NL
  %r193 = call i64 @_add(i64 %r191, i64 %r192)
  store i64 %r193, i64* %ptr_s
  %r194 = load i64, i64* %ptr_s
  %r195 = getelementptr [69 x i8], [69 x i8]* @.str.639, i64 0, i64 0
  %r196 = ptrtoint i8* %r195 to i64
  %r197 = call i64 @_add(i64 %r194, i64 %r196)
  %r198 = load i64, i64* %ptr_NL
  %r199 = call i64 @_add(i64 %r197, i64 %r198)
  store i64 %r199, i64* %ptr_s
  %r200 = load i64, i64* %ptr_s
  %r201 = getelementptr [39 x i8], [39 x i8]* @.str.640, i64 0, i64 0
  %r202 = ptrtoint i8* %r201 to i64
  %r203 = call i64 @_add(i64 %r200, i64 %r202)
  %r204 = load i64, i64* %ptr_NL
  %r205 = call i64 @_add(i64 %r203, i64 %r204)
  store i64 %r205, i64* %ptr_s
  %r206 = load i64, i64* %ptr_s
  %r207 = getelementptr [31 x i8], [31 x i8]* @.str.641, i64 0, i64 0
  %r208 = ptrtoint i8* %r207 to i64
  %r209 = call i64 @_add(i64 %r206, i64 %r208)
  %r210 = load i64, i64* %ptr_NL
  %r211 = call i64 @_add(i64 %r209, i64 %r210)
  store i64 %r211, i64* %ptr_s
  %r212 = load i64, i64* %ptr_s
  %r213 = getelementptr [31 x i8], [31 x i8]* @.str.642, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  %r215 = call i64 @_add(i64 %r212, i64 %r214)
  %r216 = load i64, i64* %ptr_NL
  %r217 = call i64 @_add(i64 %r215, i64 %r216)
  store i64 %r217, i64* %ptr_s
  %r218 = load i64, i64* %ptr_s
  %r219 = getelementptr [34 x i8], [34 x i8]* @.str.643, i64 0, i64 0
  %r220 = ptrtoint i8* %r219 to i64
  %r221 = call i64 @_add(i64 %r218, i64 %r220)
  %r222 = load i64, i64* %ptr_NL
  %r223 = call i64 @_add(i64 %r221, i64 %r222)
  store i64 %r223, i64* %ptr_s
  %r224 = load i64, i64* %ptr_s
  %r225 = getelementptr [34 x i8], [34 x i8]* @.str.644, i64 0, i64 0
  %r226 = ptrtoint i8* %r225 to i64
  %r227 = call i64 @_add(i64 %r224, i64 %r226)
  %r228 = load i64, i64* %ptr_NL
  %r229 = call i64 @_add(i64 %r227, i64 %r228)
  store i64 %r229, i64* %ptr_s
  %r230 = load i64, i64* %ptr_s
  %r231 = getelementptr [25 x i8], [25 x i8]* @.str.645, i64 0, i64 0
  %r232 = ptrtoint i8* %r231 to i64
  %r233 = call i64 @_add(i64 %r230, i64 %r232)
  %r234 = load i64, i64* %ptr_NL
  %r235 = call i64 @_add(i64 %r233, i64 %r234)
  store i64 %r235, i64* %ptr_s
  %r236 = load i64, i64* %ptr_s
  %r237 = getelementptr [24 x i8], [24 x i8]* @.str.646, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = call i64 @_add(i64 %r236, i64 %r238)
  %r240 = load i64, i64* %ptr_NL
  %r241 = call i64 @_add(i64 %r239, i64 %r240)
  store i64 %r241, i64* %ptr_s
  %r242 = load i64, i64* %ptr_s
  %r243 = getelementptr [36 x i8], [36 x i8]* @.str.647, i64 0, i64 0
  %r244 = ptrtoint i8* %r243 to i64
  %r245 = call i64 @_add(i64 %r242, i64 %r244)
  %r246 = load i64, i64* %ptr_NL
  %r247 = call i64 @_add(i64 %r245, i64 %r246)
  store i64 %r247, i64* %ptr_s
  %r248 = load i64, i64* %ptr_s
  %r249 = getelementptr [34 x i8], [34 x i8]* @.str.648, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = call i64 @_add(i64 %r248, i64 %r250)
  %r252 = load i64, i64* %ptr_NL
  %r253 = call i64 @_add(i64 %r251, i64 %r252)
  store i64 %r253, i64* %ptr_s
  %r254 = load i64, i64* %ptr_s
  %r255 = getelementptr [38 x i8], [38 x i8]* @.str.649, i64 0, i64 0
  %r256 = ptrtoint i8* %r255 to i64
  %r257 = call i64 @_add(i64 %r254, i64 %r256)
  %r258 = load i64, i64* %ptr_NL
  %r259 = call i64 @_add(i64 %r257, i64 %r258)
  store i64 %r259, i64* %ptr_s
  %r260 = load i64, i64* %ptr_s
  %r261 = getelementptr [38 x i8], [38 x i8]* @.str.650, i64 0, i64 0
  %r262 = ptrtoint i8* %r261 to i64
  %r263 = call i64 @_add(i64 %r260, i64 %r262)
  %r264 = load i64, i64* %ptr_NL
  %r265 = call i64 @_add(i64 %r263, i64 %r264)
  store i64 %r265, i64* %ptr_s
  %r266 = load i64, i64* %ptr_s
  %r267 = getelementptr [15 x i8], [15 x i8]* @.str.651, i64 0, i64 0
  %r268 = ptrtoint i8* %r267 to i64
  %r269 = call i64 @_add(i64 %r266, i64 %r268)
  %r270 = load i64, i64* %ptr_NL
  %r271 = call i64 @_add(i64 %r269, i64 %r270)
  store i64 %r271, i64* %ptr_s
  %r272 = load i64, i64* %ptr_s
  %r273 = getelementptr [2 x i8], [2 x i8]* @.str.652, i64 0, i64 0
  %r274 = ptrtoint i8* %r273 to i64
  %r275 = call i64 @_add(i64 %r272, i64 %r274)
  %r276 = load i64, i64* %ptr_NL
  %r277 = call i64 @_add(i64 %r275, i64 %r276)
  store i64 %r277, i64* %ptr_s
  %r278 = load i64, i64* %ptr_s
  %r279 = getelementptr [34 x i8], [34 x i8]* @.str.653, i64 0, i64 0
  %r280 = ptrtoint i8* %r279 to i64
  %r281 = call i64 @_add(i64 %r278, i64 %r280)
  %r282 = load i64, i64* %ptr_NL
  %r283 = call i64 @_add(i64 %r281, i64 %r282)
  store i64 %r283, i64* %ptr_s
  %r284 = load i64, i64* %ptr_s
  %r285 = getelementptr [42 x i8], [42 x i8]* @.str.654, i64 0, i64 0
  %r286 = ptrtoint i8* %r285 to i64
  %r287 = call i64 @_add(i64 %r284, i64 %r286)
  %r288 = load i64, i64* %ptr_NL
  %r289 = call i64 @_add(i64 %r287, i64 %r288)
  store i64 %r289, i64* %ptr_s
  %r290 = load i64, i64* %ptr_s
  %r291 = getelementptr [46 x i8], [46 x i8]* @.str.655, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_add(i64 %r290, i64 %r292)
  %r294 = load i64, i64* %ptr_NL
  %r295 = call i64 @_add(i64 %r293, i64 %r294)
  store i64 %r295, i64* %ptr_s
  %r296 = load i64, i64* %ptr_s
  %r297 = getelementptr [21 x i8], [21 x i8]* @.str.656, i64 0, i64 0
  %r298 = ptrtoint i8* %r297 to i64
  %r299 = call i64 @_add(i64 %r296, i64 %r298)
  %r300 = load i64, i64* %ptr_NL
  %r301 = call i64 @_add(i64 %r299, i64 %r300)
  store i64 %r301, i64* %ptr_s
  %r302 = load i64, i64* %ptr_s
  %r303 = getelementptr [8 x i8], [8 x i8]* @.str.657, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_add(i64 %r302, i64 %r304)
  %r306 = load i64, i64* %ptr_NL
  %r307 = call i64 @_add(i64 %r305, i64 %r306)
  store i64 %r307, i64* %ptr_s
  %r308 = load i64, i64* %ptr_s
  %r309 = getelementptr [34 x i8], [34 x i8]* @.str.658, i64 0, i64 0
  %r310 = ptrtoint i8* %r309 to i64
  %r311 = call i64 @_add(i64 %r308, i64 %r310)
  %r312 = load i64, i64* %ptr_NL
  %r313 = call i64 @_add(i64 %r311, i64 %r312)
  store i64 %r313, i64* %ptr_s
  %r314 = load i64, i64* %ptr_s
  %r315 = getelementptr [32 x i8], [32 x i8]* @.str.659, i64 0, i64 0
  %r316 = ptrtoint i8* %r315 to i64
  %r317 = call i64 @_add(i64 %r314, i64 %r316)
  %r318 = load i64, i64* %ptr_NL
  %r319 = call i64 @_add(i64 %r317, i64 %r318)
  store i64 %r319, i64* %ptr_s
  %r320 = load i64, i64* %ptr_s
  %r321 = getelementptr [69 x i8], [69 x i8]* @.str.660, i64 0, i64 0
  %r322 = ptrtoint i8* %r321 to i64
  %r323 = call i64 @_add(i64 %r320, i64 %r322)
  %r324 = load i64, i64* %ptr_NL
  %r325 = call i64 @_add(i64 %r323, i64 %r324)
  store i64 %r325, i64* %ptr_s
  %r326 = load i64, i64* %ptr_s
  %r327 = getelementptr [64 x i8], [64 x i8]* @.str.661, i64 0, i64 0
  %r328 = ptrtoint i8* %r327 to i64
  %r329 = call i64 @_add(i64 %r326, i64 %r328)
  %r330 = load i64, i64* %ptr_NL
  %r331 = call i64 @_add(i64 %r329, i64 %r330)
  store i64 %r331, i64* %ptr_s
  %r332 = load i64, i64* %ptr_s
  %r333 = getelementptr [15 x i8], [15 x i8]* @.str.662, i64 0, i64 0
  %r334 = ptrtoint i8* %r333 to i64
  %r335 = call i64 @_add(i64 %r332, i64 %r334)
  %r336 = load i64, i64* %ptr_NL
  %r337 = call i64 @_add(i64 %r335, i64 %r336)
  store i64 %r337, i64* %ptr_s
  %r338 = load i64, i64* %ptr_s
  %r339 = getelementptr [2 x i8], [2 x i8]* @.str.663, i64 0, i64 0
  %r340 = ptrtoint i8* %r339 to i64
  %r341 = call i64 @_add(i64 %r338, i64 %r340)
  %r342 = load i64, i64* %ptr_NL
  %r343 = call i64 @_add(i64 %r341, i64 %r342)
  store i64 %r343, i64* %ptr_s
  %r344 = load i64, i64* %ptr_s
  %r345 = getelementptr [35 x i8], [35 x i8]* @.str.664, i64 0, i64 0
  %r346 = ptrtoint i8* %r345 to i64
  %r347 = call i64 @_add(i64 %r344, i64 %r346)
  %r348 = load i64, i64* %ptr_NL
  %r349 = call i64 @_add(i64 %r347, i64 %r348)
  store i64 %r349, i64* %ptr_s
  %r350 = load i64, i64* %ptr_s
  %r351 = getelementptr [42 x i8], [42 x i8]* @.str.665, i64 0, i64 0
  %r352 = ptrtoint i8* %r351 to i64
  %r353 = call i64 @_add(i64 %r350, i64 %r352)
  %r354 = load i64, i64* %ptr_NL
  %r355 = call i64 @_add(i64 %r353, i64 %r354)
  store i64 %r355, i64* %ptr_s
  %r356 = load i64, i64* %ptr_s
  %r357 = getelementptr [42 x i8], [42 x i8]* @.str.666, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_add(i64 %r356, i64 %r358)
  %r360 = load i64, i64* %ptr_NL
  %r361 = call i64 @_add(i64 %r359, i64 %r360)
  store i64 %r361, i64* %ptr_s
  %r362 = load i64, i64* %ptr_s
  %r363 = getelementptr [42 x i8], [42 x i8]* @.str.667, i64 0, i64 0
  %r364 = ptrtoint i8* %r363 to i64
  %r365 = call i64 @_add(i64 %r362, i64 %r364)
  %r366 = load i64, i64* %ptr_NL
  %r367 = call i64 @_add(i64 %r365, i64 %r366)
  store i64 %r367, i64* %ptr_s
  %r368 = load i64, i64* %ptr_s
  %r369 = getelementptr [40 x i8], [40 x i8]* @.str.668, i64 0, i64 0
  %r370 = ptrtoint i8* %r369 to i64
  %r371 = call i64 @_add(i64 %r368, i64 %r370)
  %r372 = load i64, i64* %ptr_NL
  %r373 = call i64 @_add(i64 %r371, i64 %r372)
  store i64 %r373, i64* %ptr_s
  %r374 = load i64, i64* %ptr_s
  %r375 = getelementptr [55 x i8], [55 x i8]* @.str.669, i64 0, i64 0
  %r376 = ptrtoint i8* %r375 to i64
  %r377 = call i64 @_add(i64 %r374, i64 %r376)
  %r378 = load i64, i64* %ptr_NL
  %r379 = call i64 @_add(i64 %r377, i64 %r378)
  store i64 %r379, i64* %ptr_s
  %r380 = load i64, i64* %ptr_s
  %r381 = getelementptr [12 x i8], [12 x i8]* @.str.670, i64 0, i64 0
  %r382 = ptrtoint i8* %r381 to i64
  %r383 = call i64 @_add(i64 %r380, i64 %r382)
  %r384 = load i64, i64* %ptr_NL
  %r385 = call i64 @_add(i64 %r383, i64 %r384)
  store i64 %r385, i64* %ptr_s
  %r386 = load i64, i64* %ptr_s
  %r387 = getelementptr [34 x i8], [34 x i8]* @.str.671, i64 0, i64 0
  %r388 = ptrtoint i8* %r387 to i64
  %r389 = call i64 @_add(i64 %r386, i64 %r388)
  %r390 = load i64, i64* %ptr_NL
  %r391 = call i64 @_add(i64 %r389, i64 %r390)
  store i64 %r391, i64* %ptr_s
  %r392 = load i64, i64* %ptr_s
  %r393 = getelementptr [32 x i8], [32 x i8]* @.str.672, i64 0, i64 0
  %r394 = ptrtoint i8* %r393 to i64
  %r395 = call i64 @_add(i64 %r392, i64 %r394)
  %r396 = load i64, i64* %ptr_NL
  %r397 = call i64 @_add(i64 %r395, i64 %r396)
  store i64 %r397, i64* %ptr_s
  %r398 = load i64, i64* %ptr_s
  %r399 = getelementptr [35 x i8], [35 x i8]* @.str.673, i64 0, i64 0
  %r400 = ptrtoint i8* %r399 to i64
  %r401 = call i64 @_add(i64 %r398, i64 %r400)
  %r402 = load i64, i64* %ptr_NL
  %r403 = call i64 @_add(i64 %r401, i64 %r402)
  store i64 %r403, i64* %ptr_s
  %r404 = load i64, i64* %ptr_s
  %r405 = getelementptr [51 x i8], [51 x i8]* @.str.674, i64 0, i64 0
  %r406 = ptrtoint i8* %r405 to i64
  %r407 = call i64 @_add(i64 %r404, i64 %r406)
  %r408 = load i64, i64* %ptr_NL
  %r409 = call i64 @_add(i64 %r407, i64 %r408)
  store i64 %r409, i64* %ptr_s
  %r410 = load i64, i64* %ptr_s
  %r411 = getelementptr [11 x i8], [11 x i8]* @.str.675, i64 0, i64 0
  %r412 = ptrtoint i8* %r411 to i64
  %r413 = call i64 @_add(i64 %r410, i64 %r412)
  %r414 = load i64, i64* %ptr_NL
  %r415 = call i64 @_add(i64 %r413, i64 %r414)
  store i64 %r415, i64* %ptr_s
  %r416 = load i64, i64* %ptr_s
  %r417 = getelementptr [44 x i8], [44 x i8]* @.str.676, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  %r419 = call i64 @_add(i64 %r416, i64 %r418)
  %r420 = load i64, i64* %ptr_NL
  %r421 = call i64 @_add(i64 %r419, i64 %r420)
  store i64 %r421, i64* %ptr_s
  %r422 = load i64, i64* %ptr_s
  %r423 = getelementptr [8 x i8], [8 x i8]* @.str.677, i64 0, i64 0
  %r424 = ptrtoint i8* %r423 to i64
  %r425 = call i64 @_add(i64 %r422, i64 %r424)
  %r426 = load i64, i64* %ptr_NL
  %r427 = call i64 @_add(i64 %r425, i64 %r426)
  store i64 %r427, i64* %ptr_s
  %r428 = load i64, i64* %ptr_s
  %r429 = getelementptr [36 x i8], [36 x i8]* @.str.678, i64 0, i64 0
  %r430 = ptrtoint i8* %r429 to i64
  %r431 = call i64 @_add(i64 %r428, i64 %r430)
  %r432 = load i64, i64* %ptr_NL
  %r433 = call i64 @_add(i64 %r431, i64 %r432)
  store i64 %r433, i64* %ptr_s
  %r434 = load i64, i64* %ptr_s
  %r435 = getelementptr [36 x i8], [36 x i8]* @.str.679, i64 0, i64 0
  %r436 = ptrtoint i8* %r435 to i64
  %r437 = call i64 @_add(i64 %r434, i64 %r436)
  %r438 = load i64, i64* %ptr_NL
  %r439 = call i64 @_add(i64 %r437, i64 %r438)
  store i64 %r439, i64* %ptr_s
  %r440 = load i64, i64* %ptr_s
  %r441 = getelementptr [50 x i8], [50 x i8]* @.str.680, i64 0, i64 0
  %r442 = ptrtoint i8* %r441 to i64
  %r443 = call i64 @_add(i64 %r440, i64 %r442)
  %r444 = load i64, i64* %ptr_NL
  %r445 = call i64 @_add(i64 %r443, i64 %r444)
  store i64 %r445, i64* %ptr_s
  %r446 = load i64, i64* %ptr_s
  %r447 = getelementptr [19 x i8], [19 x i8]* @.str.681, i64 0, i64 0
  %r448 = ptrtoint i8* %r447 to i64
  %r449 = call i64 @_add(i64 %r446, i64 %r448)
  %r450 = load i64, i64* %ptr_NL
  %r451 = call i64 @_add(i64 %r449, i64 %r450)
  store i64 %r451, i64* %ptr_s
  %r452 = load i64, i64* %ptr_s
  %r453 = getelementptr [9 x i8], [9 x i8]* @.str.682, i64 0, i64 0
  %r454 = ptrtoint i8* %r453 to i64
  %r455 = call i64 @_add(i64 %r452, i64 %r454)
  %r456 = load i64, i64* %ptr_NL
  %r457 = call i64 @_add(i64 %r455, i64 %r456)
  store i64 %r457, i64* %ptr_s
  %r458 = load i64, i64* %ptr_s
  %r459 = getelementptr [36 x i8], [36 x i8]* @.str.683, i64 0, i64 0
  %r460 = ptrtoint i8* %r459 to i64
  %r461 = call i64 @_add(i64 %r458, i64 %r460)
  %r462 = load i64, i64* %ptr_NL
  %r463 = call i64 @_add(i64 %r461, i64 %r462)
  store i64 %r463, i64* %ptr_s
  %r464 = load i64, i64* %ptr_s
  %r465 = getelementptr [47 x i8], [47 x i8]* @.str.684, i64 0, i64 0
  %r466 = ptrtoint i8* %r465 to i64
  %r467 = call i64 @_add(i64 %r464, i64 %r466)
  %r468 = load i64, i64* %ptr_NL
  %r469 = call i64 @_add(i64 %r467, i64 %r468)
  store i64 %r469, i64* %ptr_s
  %r470 = load i64, i64* %ptr_s
  %r471 = getelementptr [47 x i8], [47 x i8]* @.str.685, i64 0, i64 0
  %r472 = ptrtoint i8* %r471 to i64
  %r473 = call i64 @_add(i64 %r470, i64 %r472)
  %r474 = load i64, i64* %ptr_NL
  %r475 = call i64 @_add(i64 %r473, i64 %r474)
  store i64 %r475, i64* %ptr_s
  %r476 = load i64, i64* %ptr_s
  %r477 = getelementptr [20 x i8], [20 x i8]* @.str.686, i64 0, i64 0
  %r478 = ptrtoint i8* %r477 to i64
  %r479 = call i64 @_add(i64 %r476, i64 %r478)
  %r480 = load i64, i64* %ptr_NL
  %r481 = call i64 @_add(i64 %r479, i64 %r480)
  store i64 %r481, i64* %ptr_s
  %r482 = load i64, i64* %ptr_s
  %r483 = getelementptr [5 x i8], [5 x i8]* @.str.687, i64 0, i64 0
  %r484 = ptrtoint i8* %r483 to i64
  %r485 = call i64 @_add(i64 %r482, i64 %r484)
  %r486 = load i64, i64* %ptr_NL
  %r487 = call i64 @_add(i64 %r485, i64 %r486)
  store i64 %r487, i64* %ptr_s
  %r488 = load i64, i64* %ptr_s
  %r489 = getelementptr [28 x i8], [28 x i8]* @.str.688, i64 0, i64 0
  %r490 = ptrtoint i8* %r489 to i64
  %r491 = call i64 @_add(i64 %r488, i64 %r490)
  %r492 = load i64, i64* %ptr_NL
  %r493 = call i64 @_add(i64 %r491, i64 %r492)
  store i64 %r493, i64* %ptr_s
  %r494 = load i64, i64* %ptr_s
  %r495 = getelementptr [19 x i8], [19 x i8]* @.str.689, i64 0, i64 0
  %r496 = ptrtoint i8* %r495 to i64
  %r497 = call i64 @_add(i64 %r494, i64 %r496)
  %r498 = load i64, i64* %ptr_NL
  %r499 = call i64 @_add(i64 %r497, i64 %r498)
  store i64 %r499, i64* %ptr_s
  %r500 = load i64, i64* %ptr_s
  %r501 = getelementptr [2 x i8], [2 x i8]* @.str.690, i64 0, i64 0
  %r502 = ptrtoint i8* %r501 to i64
  %r503 = call i64 @_add(i64 %r500, i64 %r502)
  %r504 = load i64, i64* %ptr_NL
  %r505 = call i64 @_add(i64 %r503, i64 %r504)
  store i64 %r505, i64* %ptr_s
  %r506 = load i64, i64* %ptr_s
  %r507 = getelementptr [47 x i8], [47 x i8]* @.str.691, i64 0, i64 0
  %r508 = ptrtoint i8* %r507 to i64
  %r509 = call i64 @_add(i64 %r506, i64 %r508)
  %r510 = load i64, i64* %ptr_NL
  %r511 = call i64 @_add(i64 %r509, i64 %r510)
  store i64 %r511, i64* %ptr_s
  %r512 = load i64, i64* %ptr_s
  %r513 = getelementptr [35 x i8], [35 x i8]* @.str.692, i64 0, i64 0
  %r514 = ptrtoint i8* %r513 to i64
  %r515 = call i64 @_add(i64 %r512, i64 %r514)
  %r516 = load i64, i64* %ptr_NL
  %r517 = call i64 @_add(i64 %r515, i64 %r516)
  store i64 %r517, i64* %ptr_s
  %r518 = load i64, i64* %ptr_s
  %r519 = getelementptr [49 x i8], [49 x i8]* @.str.693, i64 0, i64 0
  %r520 = ptrtoint i8* %r519 to i64
  %r521 = call i64 @_add(i64 %r518, i64 %r520)
  %r522 = load i64, i64* %ptr_NL
  %r523 = call i64 @_add(i64 %r521, i64 %r522)
  store i64 %r523, i64* %ptr_s
  %r524 = load i64, i64* %ptr_s
  %r525 = getelementptr [33 x i8], [33 x i8]* @.str.694, i64 0, i64 0
  %r526 = ptrtoint i8* %r525 to i64
  %r527 = call i64 @_add(i64 %r524, i64 %r526)
  %r528 = load i64, i64* %ptr_NL
  %r529 = call i64 @_add(i64 %r527, i64 %r528)
  store i64 %r529, i64* %ptr_s
  %r530 = load i64, i64* %ptr_s
  %r531 = getelementptr [50 x i8], [50 x i8]* @.str.695, i64 0, i64 0
  %r532 = ptrtoint i8* %r531 to i64
  %r533 = call i64 @_add(i64 %r530, i64 %r532)
  %r534 = load i64, i64* %ptr_NL
  %r535 = call i64 @_add(i64 %r533, i64 %r534)
  store i64 %r535, i64* %ptr_s
  %r536 = load i64, i64* %ptr_s
  %r537 = getelementptr [35 x i8], [35 x i8]* @.str.696, i64 0, i64 0
  %r538 = ptrtoint i8* %r537 to i64
  %r539 = call i64 @_add(i64 %r536, i64 %r538)
  %r540 = load i64, i64* %ptr_NL
  %r541 = call i64 @_add(i64 %r539, i64 %r540)
  store i64 %r541, i64* %ptr_s
  %r542 = load i64, i64* %ptr_s
  %r543 = getelementptr [41 x i8], [41 x i8]* @.str.697, i64 0, i64 0
  %r544 = ptrtoint i8* %r543 to i64
  %r545 = call i64 @_add(i64 %r542, i64 %r544)
  %r546 = load i64, i64* %ptr_NL
  %r547 = call i64 @_add(i64 %r545, i64 %r546)
  store i64 %r547, i64* %ptr_s
  %r548 = load i64, i64* %ptr_s
  %r549 = getelementptr [17 x i8], [17 x i8]* @.str.698, i64 0, i64 0
  %r550 = ptrtoint i8* %r549 to i64
  %r551 = call i64 @_add(i64 %r548, i64 %r550)
  %r552 = load i64, i64* %ptr_NL
  %r553 = call i64 @_add(i64 %r551, i64 %r552)
  store i64 %r553, i64* %ptr_s
  %r554 = load i64, i64* %ptr_s
  %r555 = getelementptr [6 x i8], [6 x i8]* @.str.699, i64 0, i64 0
  %r556 = ptrtoint i8* %r555 to i64
  %r557 = call i64 @_add(i64 %r554, i64 %r556)
  %r558 = load i64, i64* %ptr_NL
  %r559 = call i64 @_add(i64 %r557, i64 %r558)
  store i64 %r559, i64* %ptr_s
  %r560 = load i64, i64* %ptr_s
  %r561 = getelementptr [45 x i8], [45 x i8]* @.str.700, i64 0, i64 0
  %r562 = ptrtoint i8* %r561 to i64
  %r563 = call i64 @_add(i64 %r560, i64 %r562)
  %r564 = load i64, i64* %ptr_NL
  %r565 = call i64 @_add(i64 %r563, i64 %r564)
  store i64 %r565, i64* %ptr_s
  %r566 = load i64, i64* %ptr_s
  %r567 = getelementptr [32 x i8], [32 x i8]* @.str.701, i64 0, i64 0
  %r568 = ptrtoint i8* %r567 to i64
  %r569 = call i64 @_add(i64 %r566, i64 %r568)
  %r570 = load i64, i64* %ptr_NL
  %r571 = call i64 @_add(i64 %r569, i64 %r570)
  store i64 %r571, i64* %ptr_s
  %r572 = load i64, i64* %ptr_s
  %r573 = getelementptr [40 x i8], [40 x i8]* @.str.702, i64 0, i64 0
  %r574 = ptrtoint i8* %r573 to i64
  %r575 = call i64 @_add(i64 %r572, i64 %r574)
  %r576 = load i64, i64* %ptr_NL
  %r577 = call i64 @_add(i64 %r575, i64 %r576)
  store i64 %r577, i64* %ptr_s
  %r578 = load i64, i64* %ptr_s
  %r579 = getelementptr [6 x i8], [6 x i8]* @.str.703, i64 0, i64 0
  %r580 = ptrtoint i8* %r579 to i64
  %r581 = call i64 @_add(i64 %r578, i64 %r580)
  %r582 = load i64, i64* %ptr_NL
  %r583 = call i64 @_add(i64 %r581, i64 %r582)
  store i64 %r583, i64* %ptr_s
  %r584 = load i64, i64* %ptr_s
  %r585 = getelementptr [52 x i8], [52 x i8]* @.str.704, i64 0, i64 0
  %r586 = ptrtoint i8* %r585 to i64
  %r587 = call i64 @_add(i64 %r584, i64 %r586)
  %r588 = load i64, i64* %ptr_NL
  %r589 = call i64 @_add(i64 %r587, i64 %r588)
  store i64 %r589, i64* %ptr_s
  %r590 = load i64, i64* %ptr_s
  %r591 = getelementptr [30 x i8], [30 x i8]* @.str.705, i64 0, i64 0
  %r592 = ptrtoint i8* %r591 to i64
  %r593 = call i64 @_add(i64 %r590, i64 %r592)
  %r594 = load i64, i64* %ptr_NL
  %r595 = call i64 @_add(i64 %r593, i64 %r594)
  store i64 %r595, i64* %ptr_s
  %r596 = load i64, i64* %ptr_s
  %r597 = getelementptr [44 x i8], [44 x i8]* @.str.706, i64 0, i64 0
  %r598 = ptrtoint i8* %r597 to i64
  %r599 = call i64 @_add(i64 %r596, i64 %r598)
  %r600 = load i64, i64* %ptr_NL
  %r601 = call i64 @_add(i64 %r599, i64 %r600)
  store i64 %r601, i64* %ptr_s
  %r602 = load i64, i64* %ptr_s
  %r603 = getelementptr [26 x i8], [26 x i8]* @.str.707, i64 0, i64 0
  %r604 = ptrtoint i8* %r603 to i64
  %r605 = call i64 @_add(i64 %r602, i64 %r604)
  %r606 = load i64, i64* %ptr_NL
  %r607 = call i64 @_add(i64 %r605, i64 %r606)
  store i64 %r607, i64* %ptr_s
  %r608 = load i64, i64* %ptr_s
  %r609 = getelementptr [17 x i8], [17 x i8]* @.str.708, i64 0, i64 0
  %r610 = ptrtoint i8* %r609 to i64
  %r611 = call i64 @_add(i64 %r608, i64 %r610)
  %r612 = load i64, i64* %ptr_NL
  %r613 = call i64 @_add(i64 %r611, i64 %r612)
  store i64 %r613, i64* %ptr_s
  %r614 = load i64, i64* %ptr_s
  %r615 = getelementptr [6 x i8], [6 x i8]* @.str.709, i64 0, i64 0
  %r616 = ptrtoint i8* %r615 to i64
  %r617 = call i64 @_add(i64 %r614, i64 %r616)
  %r618 = load i64, i64* %ptr_NL
  %r619 = call i64 @_add(i64 %r617, i64 %r618)
  store i64 %r619, i64* %ptr_s
  %r620 = load i64, i64* %ptr_s
  %r621 = getelementptr [11 x i8], [11 x i8]* @.str.710, i64 0, i64 0
  %r622 = ptrtoint i8* %r621 to i64
  %r623 = call i64 @_add(i64 %r620, i64 %r622)
  %r624 = load i64, i64* %ptr_NL
  %r625 = call i64 @_add(i64 %r623, i64 %r624)
  store i64 %r625, i64* %ptr_s
  %r626 = load i64, i64* %ptr_s
  %r627 = getelementptr [2 x i8], [2 x i8]* @.str.711, i64 0, i64 0
  %r628 = ptrtoint i8* %r627 to i64
  %r629 = call i64 @_add(i64 %r626, i64 %r628)
  %r630 = load i64, i64* %ptr_NL
  %r631 = call i64 @_add(i64 %r629, i64 %r630)
  store i64 %r631, i64* %ptr_s
  %r632 = load i64, i64* %ptr_s
  %r633 = getelementptr [48 x i8], [48 x i8]* @.str.712, i64 0, i64 0
  %r634 = ptrtoint i8* %r633 to i64
  %r635 = call i64 @_add(i64 %r632, i64 %r634)
  %r636 = load i64, i64* %ptr_NL
  %r637 = call i64 @_add(i64 %r635, i64 %r636)
  store i64 %r637, i64* %ptr_s
  %r638 = load i64, i64* %ptr_s
  %r639 = getelementptr [42 x i8], [42 x i8]* @.str.713, i64 0, i64 0
  %r640 = ptrtoint i8* %r639 to i64
  %r641 = call i64 @_add(i64 %r638, i64 %r640)
  %r642 = load i64, i64* %ptr_NL
  %r643 = call i64 @_add(i64 %r641, i64 %r642)
  store i64 %r643, i64* %ptr_s
  %r644 = load i64, i64* %ptr_s
  %r645 = getelementptr [52 x i8], [52 x i8]* @.str.714, i64 0, i64 0
  %r646 = ptrtoint i8* %r645 to i64
  %r647 = call i64 @_add(i64 %r644, i64 %r646)
  %r648 = load i64, i64* %ptr_NL
  %r649 = call i64 @_add(i64 %r647, i64 %r648)
  store i64 %r649, i64* %ptr_s
  %r650 = load i64, i64* %ptr_s
  %r651 = getelementptr [12 x i8], [12 x i8]* @.str.715, i64 0, i64 0
  %r652 = ptrtoint i8* %r651 to i64
  %r653 = call i64 @_add(i64 %r650, i64 %r652)
  %r654 = load i64, i64* %ptr_NL
  %r655 = call i64 @_add(i64 %r653, i64 %r654)
  store i64 %r655, i64* %ptr_s
  %r656 = load i64, i64* %ptr_s
  %r657 = getelementptr [34 x i8], [34 x i8]* @.str.716, i64 0, i64 0
  %r658 = ptrtoint i8* %r657 to i64
  %r659 = call i64 @_add(i64 %r656, i64 %r658)
  %r660 = load i64, i64* %ptr_NL
  %r661 = call i64 @_add(i64 %r659, i64 %r660)
  store i64 %r661, i64* %ptr_s
  %r662 = load i64, i64* %ptr_s
  %r663 = getelementptr [28 x i8], [28 x i8]* @.str.717, i64 0, i64 0
  %r664 = ptrtoint i8* %r663 to i64
  %r665 = call i64 @_add(i64 %r662, i64 %r664)
  %r666 = load i64, i64* %ptr_NL
  %r667 = call i64 @_add(i64 %r665, i64 %r666)
  store i64 %r667, i64* %ptr_s
  %r668 = load i64, i64* %ptr_s
  %r669 = getelementptr [33 x i8], [33 x i8]* @.str.718, i64 0, i64 0
  %r670 = ptrtoint i8* %r669 to i64
  %r671 = call i64 @_add(i64 %r668, i64 %r670)
  %r672 = load i64, i64* %ptr_NL
  %r673 = call i64 @_add(i64 %r671, i64 %r672)
  store i64 %r673, i64* %ptr_s
  %r674 = load i64, i64* %ptr_s
  %r675 = getelementptr [48 x i8], [48 x i8]* @.str.719, i64 0, i64 0
  %r676 = ptrtoint i8* %r675 to i64
  %r677 = call i64 @_add(i64 %r674, i64 %r676)
  %r678 = load i64, i64* %ptr_NL
  %r679 = call i64 @_add(i64 %r677, i64 %r678)
  store i64 %r679, i64* %ptr_s
  %r680 = load i64, i64* %ptr_s
  %r681 = getelementptr [7 x i8], [7 x i8]* @.str.720, i64 0, i64 0
  %r682 = ptrtoint i8* %r681 to i64
  %r683 = call i64 @_add(i64 %r680, i64 %r682)
  %r684 = load i64, i64* %ptr_NL
  %r685 = call i64 @_add(i64 %r683, i64 %r684)
  store i64 %r685, i64* %ptr_s
  %r686 = load i64, i64* %ptr_s
  %r687 = getelementptr [45 x i8], [45 x i8]* @.str.721, i64 0, i64 0
  %r688 = ptrtoint i8* %r687 to i64
  %r689 = call i64 @_add(i64 %r686, i64 %r688)
  %r690 = load i64, i64* %ptr_NL
  %r691 = call i64 @_add(i64 %r689, i64 %r690)
  store i64 %r691, i64* %ptr_s
  %r692 = load i64, i64* %ptr_s
  %r693 = getelementptr [12 x i8], [12 x i8]* @.str.722, i64 0, i64 0
  %r694 = ptrtoint i8* %r693 to i64
  %r695 = call i64 @_add(i64 %r692, i64 %r694)
  %r696 = load i64, i64* %ptr_NL
  %r697 = call i64 @_add(i64 %r695, i64 %r696)
  store i64 %r697, i64* %ptr_s
  %r698 = load i64, i64* %ptr_s
  %r699 = getelementptr [10 x i8], [10 x i8]* @.str.723, i64 0, i64 0
  %r700 = ptrtoint i8* %r699 to i64
  %r701 = call i64 @_add(i64 %r698, i64 %r700)
  %r702 = load i64, i64* %ptr_NL
  %r703 = call i64 @_add(i64 %r701, i64 %r702)
  store i64 %r703, i64* %ptr_s
  %r704 = load i64, i64* %ptr_s
  %r705 = getelementptr [44 x i8], [44 x i8]* @.str.724, i64 0, i64 0
  %r706 = ptrtoint i8* %r705 to i64
  %r707 = call i64 @_add(i64 %r704, i64 %r706)
  %r708 = load i64, i64* %ptr_NL
  %r709 = call i64 @_add(i64 %r707, i64 %r708)
  store i64 %r709, i64* %ptr_s
  %r710 = load i64, i64* %ptr_s
  %r711 = getelementptr [12 x i8], [12 x i8]* @.str.725, i64 0, i64 0
  %r712 = ptrtoint i8* %r711 to i64
  %r713 = call i64 @_add(i64 %r710, i64 %r712)
  %r714 = load i64, i64* %ptr_NL
  %r715 = call i64 @_add(i64 %r713, i64 %r714)
  store i64 %r715, i64* %ptr_s
  %r716 = load i64, i64* %ptr_s
  %r717 = getelementptr [2 x i8], [2 x i8]* @.str.726, i64 0, i64 0
  %r718 = ptrtoint i8* %r717 to i64
  %r719 = call i64 @_add(i64 %r716, i64 %r718)
  %r720 = load i64, i64* %ptr_NL
  %r721 = call i64 @_add(i64 %r719, i64 %r720)
  store i64 %r721, i64* %ptr_s
  %r722 = load i64, i64* %ptr_s
  %r723 = getelementptr [34 x i8], [34 x i8]* @.str.727, i64 0, i64 0
  %r724 = ptrtoint i8* %r723 to i64
  %r725 = call i64 @_add(i64 %r722, i64 %r724)
  %r726 = load i64, i64* %ptr_NL
  %r727 = call i64 @_add(i64 %r725, i64 %r726)
  store i64 %r727, i64* %ptr_s
  %r728 = load i64, i64* %ptr_s
  %r729 = getelementptr [42 x i8], [42 x i8]* @.str.728, i64 0, i64 0
  %r730 = ptrtoint i8* %r729 to i64
  %r731 = call i64 @_add(i64 %r728, i64 %r730)
  %r732 = load i64, i64* %ptr_NL
  %r733 = call i64 @_add(i64 %r731, i64 %r732)
  store i64 %r733, i64* %ptr_s
  %r734 = load i64, i64* %ptr_s
  %r735 = getelementptr [42 x i8], [42 x i8]* @.str.729, i64 0, i64 0
  %r736 = ptrtoint i8* %r735 to i64
  %r737 = call i64 @_add(i64 %r734, i64 %r736)
  %r738 = load i64, i64* %ptr_NL
  %r739 = call i64 @_add(i64 %r737, i64 %r738)
  store i64 %r739, i64* %ptr_s
  %r740 = load i64, i64* %ptr_s
  %r741 = getelementptr [42 x i8], [42 x i8]* @.str.730, i64 0, i64 0
  %r742 = ptrtoint i8* %r741 to i64
  %r743 = call i64 @_add(i64 %r740, i64 %r742)
  %r744 = load i64, i64* %ptr_NL
  %r745 = call i64 @_add(i64 %r743, i64 %r744)
  store i64 %r745, i64* %ptr_s
  %r746 = load i64, i64* %ptr_s
  %r747 = getelementptr [53 x i8], [53 x i8]* @.str.731, i64 0, i64 0
  %r748 = ptrtoint i8* %r747 to i64
  %r749 = call i64 @_add(i64 %r746, i64 %r748)
  %r750 = load i64, i64* %ptr_NL
  %r751 = call i64 @_add(i64 %r749, i64 %r750)
  store i64 %r751, i64* %ptr_s
  %r752 = load i64, i64* %ptr_s
  %r753 = getelementptr [12 x i8], [12 x i8]* @.str.732, i64 0, i64 0
  %r754 = ptrtoint i8* %r753 to i64
  %r755 = call i64 @_add(i64 %r752, i64 %r754)
  %r756 = load i64, i64* %ptr_NL
  %r757 = call i64 @_add(i64 %r755, i64 %r756)
  store i64 %r757, i64* %ptr_s
  %r758 = load i64, i64* %ptr_s
  %r759 = getelementptr [30 x i8], [30 x i8]* @.str.733, i64 0, i64 0
  %r760 = ptrtoint i8* %r759 to i64
  %r761 = call i64 @_add(i64 %r758, i64 %r760)
  %r762 = load i64, i64* %ptr_NL
  %r763 = call i64 @_add(i64 %r761, i64 %r762)
  store i64 %r763, i64* %ptr_s
  %r764 = load i64, i64* %ptr_s
  %r765 = getelementptr [30 x i8], [30 x i8]* @.str.734, i64 0, i64 0
  %r766 = ptrtoint i8* %r765 to i64
  %r767 = call i64 @_add(i64 %r764, i64 %r766)
  %r768 = load i64, i64* %ptr_NL
  %r769 = call i64 @_add(i64 %r767, i64 %r768)
  store i64 %r769, i64* %ptr_s
  %r770 = load i64, i64* %ptr_s
  %r771 = getelementptr [37 x i8], [37 x i8]* @.str.735, i64 0, i64 0
  %r772 = ptrtoint i8* %r771 to i64
  %r773 = call i64 @_add(i64 %r770, i64 %r772)
  %r774 = load i64, i64* %ptr_NL
  %r775 = call i64 @_add(i64 %r773, i64 %r774)
  store i64 %r775, i64* %ptr_s
  %r776 = load i64, i64* %ptr_s
  %r777 = getelementptr [50 x i8], [50 x i8]* @.str.736, i64 0, i64 0
  %r778 = ptrtoint i8* %r777 to i64
  %r779 = call i64 @_add(i64 %r776, i64 %r778)
  %r780 = load i64, i64* %ptr_NL
  %r781 = call i64 @_add(i64 %r779, i64 %r780)
  store i64 %r781, i64* %ptr_s
  %r782 = load i64, i64* %ptr_s
  %r783 = getelementptr [9 x i8], [9 x i8]* @.str.737, i64 0, i64 0
  %r784 = ptrtoint i8* %r783 to i64
  %r785 = call i64 @_add(i64 %r782, i64 %r784)
  %r786 = load i64, i64* %ptr_NL
  %r787 = call i64 @_add(i64 %r785, i64 %r786)
  store i64 %r787, i64* %ptr_s
  %r788 = load i64, i64* %ptr_s
  %r789 = getelementptr [31 x i8], [31 x i8]* @.str.738, i64 0, i64 0
  %r790 = ptrtoint i8* %r789 to i64
  %r791 = call i64 @_add(i64 %r788, i64 %r790)
  %r792 = load i64, i64* %ptr_NL
  %r793 = call i64 @_add(i64 %r791, i64 %r792)
  store i64 %r793, i64* %ptr_s
  %r794 = load i64, i64* %ptr_s
  %r795 = getelementptr [31 x i8], [31 x i8]* @.str.739, i64 0, i64 0
  %r796 = ptrtoint i8* %r795 to i64
  %r797 = call i64 @_add(i64 %r794, i64 %r796)
  %r798 = load i64, i64* %ptr_NL
  %r799 = call i64 @_add(i64 %r797, i64 %r798)
  store i64 %r799, i64* %ptr_s
  %r800 = load i64, i64* %ptr_s
  %r801 = getelementptr [44 x i8], [44 x i8]* @.str.740, i64 0, i64 0
  %r802 = ptrtoint i8* %r801 to i64
  %r803 = call i64 @_add(i64 %r800, i64 %r802)
  %r804 = load i64, i64* %ptr_NL
  %r805 = call i64 @_add(i64 %r803, i64 %r804)
  store i64 %r805, i64* %ptr_s
  %r806 = load i64, i64* %ptr_s
  %r807 = getelementptr [30 x i8], [30 x i8]* @.str.741, i64 0, i64 0
  %r808 = ptrtoint i8* %r807 to i64
  %r809 = call i64 @_add(i64 %r806, i64 %r808)
  %r810 = load i64, i64* %ptr_NL
  %r811 = call i64 @_add(i64 %r809, i64 %r810)
  store i64 %r811, i64* %ptr_s
  %r812 = load i64, i64* %ptr_s
  %r813 = getelementptr [34 x i8], [34 x i8]* @.str.742, i64 0, i64 0
  %r814 = ptrtoint i8* %r813 to i64
  %r815 = call i64 @_add(i64 %r812, i64 %r814)
  %r816 = load i64, i64* %ptr_NL
  %r817 = call i64 @_add(i64 %r815, i64 %r816)
  store i64 %r817, i64* %ptr_s
  %r818 = load i64, i64* %ptr_s
  %r819 = getelementptr [19 x i8], [19 x i8]* @.str.743, i64 0, i64 0
  %r820 = ptrtoint i8* %r819 to i64
  %r821 = call i64 @_add(i64 %r818, i64 %r820)
  %r822 = load i64, i64* %ptr_NL
  %r823 = call i64 @_add(i64 %r821, i64 %r822)
  store i64 %r823, i64* %ptr_s
  %r824 = load i64, i64* %ptr_s
  %r825 = getelementptr [9 x i8], [9 x i8]* @.str.744, i64 0, i64 0
  %r826 = ptrtoint i8* %r825 to i64
  %r827 = call i64 @_add(i64 %r824, i64 %r826)
  %r828 = load i64, i64* %ptr_NL
  %r829 = call i64 @_add(i64 %r827, i64 %r828)
  store i64 %r829, i64* %ptr_s
  %r830 = load i64, i64* %ptr_s
  %r831 = getelementptr [33 x i8], [33 x i8]* @.str.745, i64 0, i64 0
  %r832 = ptrtoint i8* %r831 to i64
  %r833 = call i64 @_add(i64 %r830, i64 %r832)
  %r834 = load i64, i64* %ptr_NL
  %r835 = call i64 @_add(i64 %r833, i64 %r834)
  store i64 %r835, i64* %ptr_s
  %r836 = load i64, i64* %ptr_s
  %r837 = getelementptr [38 x i8], [38 x i8]* @.str.746, i64 0, i64 0
  %r838 = ptrtoint i8* %r837 to i64
  %r839 = call i64 @_add(i64 %r836, i64 %r838)
  %r840 = load i64, i64* %ptr_NL
  %r841 = call i64 @_add(i64 %r839, i64 %r840)
  store i64 %r841, i64* %ptr_s
  %r842 = load i64, i64* %ptr_s
  %r843 = getelementptr [19 x i8], [19 x i8]* @.str.747, i64 0, i64 0
  %r844 = ptrtoint i8* %r843 to i64
  %r845 = call i64 @_add(i64 %r842, i64 %r844)
  %r846 = load i64, i64* %ptr_NL
  %r847 = call i64 @_add(i64 %r845, i64 %r846)
  store i64 %r847, i64* %ptr_s
  %r848 = load i64, i64* %ptr_s
  %r849 = getelementptr [2 x i8], [2 x i8]* @.str.748, i64 0, i64 0
  %r850 = ptrtoint i8* %r849 to i64
  %r851 = call i64 @_add(i64 %r848, i64 %r850)
  %r852 = load i64, i64* %ptr_NL
  %r853 = call i64 @_add(i64 %r851, i64 %r852)
  store i64 %r853, i64* %ptr_s
  %r854 = load i64, i64* %ptr_s
  %r855 = getelementptr [26 x i8], [26 x i8]* @.str.749, i64 0, i64 0
  %r856 = ptrtoint i8* %r855 to i64
  %r857 = call i64 @_add(i64 %r854, i64 %r856)
  %r858 = load i64, i64* %ptr_NL
  %r859 = call i64 @_add(i64 %r857, i64 %r858)
  store i64 %r859, i64* %ptr_s
  %r860 = load i64, i64* %ptr_s
  %r861 = getelementptr [34 x i8], [34 x i8]* @.str.750, i64 0, i64 0
  %r862 = ptrtoint i8* %r861 to i64
  %r863 = call i64 @_add(i64 %r860, i64 %r862)
  %r864 = load i64, i64* %ptr_NL
  %r865 = call i64 @_add(i64 %r863, i64 %r864)
  store i64 %r865, i64* %ptr_s
  %r866 = load i64, i64* %ptr_s
  %r867 = getelementptr [35 x i8], [35 x i8]* @.str.751, i64 0, i64 0
  %r868 = ptrtoint i8* %r867 to i64
  %r869 = call i64 @_add(i64 %r866, i64 %r868)
  %r870 = load i64, i64* %ptr_NL
  %r871 = call i64 @_add(i64 %r869, i64 %r870)
  store i64 %r871, i64* %ptr_s
  %r872 = load i64, i64* %ptr_s
  %r873 = getelementptr [25 x i8], [25 x i8]* @.str.752, i64 0, i64 0
  %r874 = ptrtoint i8* %r873 to i64
  %r875 = call i64 @_add(i64 %r872, i64 %r874)
  %r876 = load i64, i64* %ptr_NL
  %r877 = call i64 @_add(i64 %r875, i64 %r876)
  store i64 %r877, i64* %ptr_s
  %r878 = load i64, i64* %ptr_s
  %r879 = getelementptr [45 x i8], [45 x i8]* @.str.753, i64 0, i64 0
  %r880 = ptrtoint i8* %r879 to i64
  %r881 = call i64 @_add(i64 %r878, i64 %r880)
  %r882 = load i64, i64* %ptr_NL
  %r883 = call i64 @_add(i64 %r881, i64 %r882)
  store i64 %r883, i64* %ptr_s
  %r884 = load i64, i64* %ptr_s
  %r885 = getelementptr [25 x i8], [25 x i8]* @.str.754, i64 0, i64 0
  %r886 = ptrtoint i8* %r885 to i64
  %r887 = call i64 @_add(i64 %r884, i64 %r886)
  %r888 = load i64, i64* %ptr_NL
  %r889 = call i64 @_add(i64 %r887, i64 %r888)
  store i64 %r889, i64* %ptr_s
  %r890 = load i64, i64* %ptr_s
  %r891 = getelementptr [46 x i8], [46 x i8]* @.str.755, i64 0, i64 0
  %r892 = ptrtoint i8* %r891 to i64
  %r893 = call i64 @_add(i64 %r890, i64 %r892)
  %r894 = load i64, i64* %ptr_NL
  %r895 = call i64 @_add(i64 %r893, i64 %r894)
  store i64 %r895, i64* %ptr_s
  %r896 = load i64, i64* %ptr_s
  %r897 = getelementptr [26 x i8], [26 x i8]* @.str.756, i64 0, i64 0
  %r898 = ptrtoint i8* %r897 to i64
  %r899 = call i64 @_add(i64 %r896, i64 %r898)
  %r900 = load i64, i64* %ptr_NL
  %r901 = call i64 @_add(i64 %r899, i64 %r900)
  store i64 %r901, i64* %ptr_s
  %r902 = load i64, i64* %ptr_s
  %r903 = getelementptr [15 x i8], [15 x i8]* @.str.757, i64 0, i64 0
  %r904 = ptrtoint i8* %r903 to i64
  %r905 = call i64 @_add(i64 %r902, i64 %r904)
  %r906 = load i64, i64* %ptr_NL
  %r907 = call i64 @_add(i64 %r905, i64 %r906)
  store i64 %r907, i64* %ptr_s
  %r908 = load i64, i64* %ptr_s
  %r909 = getelementptr [2 x i8], [2 x i8]* @.str.758, i64 0, i64 0
  %r910 = ptrtoint i8* %r909 to i64
  %r911 = call i64 @_add(i64 %r908, i64 %r910)
  %r912 = load i64, i64* %ptr_NL
  %r913 = call i64 @_add(i64 %r911, i64 %r912)
  store i64 %r913, i64* %ptr_s
  %r914 = load i64, i64* %ptr_s
  %r915 = getelementptr [50 x i8], [50 x i8]* @.str.759, i64 0, i64 0
  %r916 = ptrtoint i8* %r915 to i64
  %r917 = call i64 @_add(i64 %r914, i64 %r916)
  %r918 = load i64, i64* %ptr_NL
  %r919 = call i64 @_add(i64 %r917, i64 %r918)
  store i64 %r919, i64* %ptr_s
  %r920 = load i64, i64* %ptr_s
  %r921 = getelementptr [33 x i8], [33 x i8]* @.str.760, i64 0, i64 0
  %r922 = ptrtoint i8* %r921 to i64
  %r923 = call i64 @_add(i64 %r920, i64 %r922)
  %r924 = load i64, i64* %ptr_NL
  %r925 = call i64 @_add(i64 %r923, i64 %r924)
  store i64 %r925, i64* %ptr_s
  %r926 = load i64, i64* %ptr_s
  %r927 = getelementptr [50 x i8], [50 x i8]* @.str.761, i64 0, i64 0
  %r928 = ptrtoint i8* %r927 to i64
  %r929 = call i64 @_add(i64 %r926, i64 %r928)
  %r930 = load i64, i64* %ptr_NL
  %r931 = call i64 @_add(i64 %r929, i64 %r930)
  store i64 %r931, i64* %ptr_s
  %r932 = load i64, i64* %ptr_s
  %r933 = getelementptr [35 x i8], [35 x i8]* @.str.762, i64 0, i64 0
  %r934 = ptrtoint i8* %r933 to i64
  %r935 = call i64 @_add(i64 %r932, i64 %r934)
  %r936 = load i64, i64* %ptr_NL
  %r937 = call i64 @_add(i64 %r935, i64 %r936)
  store i64 %r937, i64* %ptr_s
  %r938 = load i64, i64* %ptr_s
  %r939 = getelementptr [41 x i8], [41 x i8]* @.str.763, i64 0, i64 0
  %r940 = ptrtoint i8* %r939 to i64
  %r941 = call i64 @_add(i64 %r938, i64 %r940)
  %r942 = load i64, i64* %ptr_NL
  %r943 = call i64 @_add(i64 %r941, i64 %r942)
  store i64 %r943, i64* %ptr_s
  %r944 = load i64, i64* %ptr_s
  %r945 = getelementptr [54 x i8], [54 x i8]* @.str.764, i64 0, i64 0
  %r946 = ptrtoint i8* %r945 to i64
  %r947 = call i64 @_add(i64 %r944, i64 %r946)
  %r948 = load i64, i64* %ptr_NL
  %r949 = call i64 @_add(i64 %r947, i64 %r948)
  store i64 %r949, i64* %ptr_s
  %r950 = load i64, i64* %ptr_s
  %r951 = getelementptr [27 x i8], [27 x i8]* @.str.765, i64 0, i64 0
  %r952 = ptrtoint i8* %r951 to i64
  %r953 = call i64 @_add(i64 %r950, i64 %r952)
  %r954 = load i64, i64* %ptr_NL
  %r955 = call i64 @_add(i64 %r953, i64 %r954)
  store i64 %r955, i64* %ptr_s
  %r956 = load i64, i64* %ptr_s
  %r957 = getelementptr [12 x i8], [12 x i8]* @.str.766, i64 0, i64 0
  %r958 = ptrtoint i8* %r957 to i64
  %r959 = call i64 @_add(i64 %r956, i64 %r958)
  %r960 = load i64, i64* %ptr_NL
  %r961 = call i64 @_add(i64 %r959, i64 %r960)
  store i64 %r961, i64* %ptr_s
  %r962 = load i64, i64* %ptr_s
  %r963 = getelementptr [2 x i8], [2 x i8]* @.str.767, i64 0, i64 0
  %r964 = ptrtoint i8* %r963 to i64
  %r965 = call i64 @_add(i64 %r962, i64 %r964)
  %r966 = load i64, i64* %ptr_NL
  %r967 = call i64 @_add(i64 %r965, i64 %r966)
  store i64 %r967, i64* %ptr_s
  %r968 = load i64, i64* %ptr_s
  %r969 = getelementptr [41 x i8], [41 x i8]* @.str.768, i64 0, i64 0
  %r970 = ptrtoint i8* %r969 to i64
  %r971 = call i64 @_add(i64 %r968, i64 %r970)
  %r972 = load i64, i64* %ptr_NL
  %r973 = call i64 @_add(i64 %r971, i64 %r972)
  store i64 %r973, i64* %ptr_s
  %r974 = load i64, i64* %ptr_s
  %r975 = getelementptr [33 x i8], [33 x i8]* @.str.769, i64 0, i64 0
  %r976 = ptrtoint i8* %r975 to i64
  %r977 = call i64 @_add(i64 %r974, i64 %r976)
  %r978 = load i64, i64* %ptr_NL
  %r979 = call i64 @_add(i64 %r977, i64 %r978)
  store i64 %r979, i64* %ptr_s
  %r980 = load i64, i64* %ptr_s
  %r981 = getelementptr [49 x i8], [49 x i8]* @.str.770, i64 0, i64 0
  %r982 = ptrtoint i8* %r981 to i64
  %r983 = call i64 @_add(i64 %r980, i64 %r982)
  %r984 = load i64, i64* %ptr_NL
  %r985 = call i64 @_add(i64 %r983, i64 %r984)
  store i64 %r985, i64* %ptr_s
  %r986 = load i64, i64* %ptr_s
  %r987 = getelementptr [33 x i8], [33 x i8]* @.str.771, i64 0, i64 0
  %r988 = ptrtoint i8* %r987 to i64
  %r989 = call i64 @_add(i64 %r986, i64 %r988)
  %r990 = load i64, i64* %ptr_NL
  %r991 = call i64 @_add(i64 %r989, i64 %r990)
  store i64 %r991, i64* %ptr_s
  %r992 = load i64, i64* %ptr_s
  %r993 = getelementptr [29 x i8], [29 x i8]* @.str.772, i64 0, i64 0
  %r994 = ptrtoint i8* %r993 to i64
  %r995 = call i64 @_add(i64 %r992, i64 %r994)
  %r996 = load i64, i64* %ptr_NL
  %r997 = call i64 @_add(i64 %r995, i64 %r996)
  store i64 %r997, i64* %ptr_s
  %r998 = load i64, i64* %ptr_s
  %r999 = getelementptr [36 x i8], [36 x i8]* @.str.773, i64 0, i64 0
  %r1000 = ptrtoint i8* %r999 to i64
  %r1001 = call i64 @_add(i64 %r998, i64 %r1000)
  %r1002 = load i64, i64* %ptr_NL
  %r1003 = call i64 @_add(i64 %r1001, i64 %r1002)
  store i64 %r1003, i64* %ptr_s
  %r1004 = load i64, i64* %ptr_s
  %r1005 = getelementptr [50 x i8], [50 x i8]* @.str.774, i64 0, i64 0
  %r1006 = ptrtoint i8* %r1005 to i64
  %r1007 = call i64 @_add(i64 %r1004, i64 %r1006)
  %r1008 = load i64, i64* %ptr_NL
  %r1009 = call i64 @_add(i64 %r1007, i64 %r1008)
  store i64 %r1009, i64* %ptr_s
  %r1010 = load i64, i64* %ptr_s
  %r1011 = getelementptr [40 x i8], [40 x i8]* @.str.775, i64 0, i64 0
  %r1012 = ptrtoint i8* %r1011 to i64
  %r1013 = call i64 @_add(i64 %r1010, i64 %r1012)
  %r1014 = load i64, i64* %ptr_NL
  %r1015 = call i64 @_add(i64 %r1013, i64 %r1014)
  store i64 %r1015, i64* %ptr_s
  %r1016 = load i64, i64* %ptr_s
  %r1017 = getelementptr [35 x i8], [35 x i8]* @.str.776, i64 0, i64 0
  %r1018 = ptrtoint i8* %r1017 to i64
  %r1019 = call i64 @_add(i64 %r1016, i64 %r1018)
  %r1020 = load i64, i64* %ptr_NL
  %r1021 = call i64 @_add(i64 %r1019, i64 %r1020)
  store i64 %r1021, i64* %ptr_s
  %r1022 = load i64, i64* %ptr_s
  %r1023 = getelementptr [44 x i8], [44 x i8]* @.str.777, i64 0, i64 0
  %r1024 = ptrtoint i8* %r1023 to i64
  %r1025 = call i64 @_add(i64 %r1022, i64 %r1024)
  %r1026 = load i64, i64* %ptr_NL
  %r1027 = call i64 @_add(i64 %r1025, i64 %r1026)
  store i64 %r1027, i64* %ptr_s
  %r1028 = load i64, i64* %ptr_s
  %r1029 = getelementptr [61 x i8], [61 x i8]* @.str.778, i64 0, i64 0
  %r1030 = ptrtoint i8* %r1029 to i64
  %r1031 = call i64 @_add(i64 %r1028, i64 %r1030)
  %r1032 = load i64, i64* %ptr_NL
  %r1033 = call i64 @_add(i64 %r1031, i64 %r1032)
  store i64 %r1033, i64* %ptr_s
  %r1034 = load i64, i64* %ptr_s
  %r1035 = getelementptr [42 x i8], [42 x i8]* @.str.779, i64 0, i64 0
  %r1036 = ptrtoint i8* %r1035 to i64
  %r1037 = call i64 @_add(i64 %r1034, i64 %r1036)
  %r1038 = load i64, i64* %ptr_NL
  %r1039 = call i64 @_add(i64 %r1037, i64 %r1038)
  store i64 %r1039, i64* %ptr_s
  %r1040 = load i64, i64* %ptr_s
  %r1041 = getelementptr [37 x i8], [37 x i8]* @.str.780, i64 0, i64 0
  %r1042 = ptrtoint i8* %r1041 to i64
  %r1043 = call i64 @_add(i64 %r1040, i64 %r1042)
  %r1044 = load i64, i64* %ptr_NL
  %r1045 = call i64 @_add(i64 %r1043, i64 %r1044)
  store i64 %r1045, i64* %ptr_s
  %r1046 = load i64, i64* %ptr_s
  %r1047 = getelementptr [44 x i8], [44 x i8]* @.str.781, i64 0, i64 0
  %r1048 = ptrtoint i8* %r1047 to i64
  %r1049 = call i64 @_add(i64 %r1046, i64 %r1048)
  %r1050 = load i64, i64* %ptr_NL
  %r1051 = call i64 @_add(i64 %r1049, i64 %r1050)
  store i64 %r1051, i64* %ptr_s
  %r1052 = load i64, i64* %ptr_s
  %r1053 = getelementptr [53 x i8], [53 x i8]* @.str.782, i64 0, i64 0
  %r1054 = ptrtoint i8* %r1053 to i64
  %r1055 = call i64 @_add(i64 %r1052, i64 %r1054)
  %r1056 = load i64, i64* %ptr_NL
  %r1057 = call i64 @_add(i64 %r1055, i64 %r1056)
  store i64 %r1057, i64* %ptr_s
  %r1058 = load i64, i64* %ptr_s
  %r1059 = getelementptr [26 x i8], [26 x i8]* @.str.783, i64 0, i64 0
  %r1060 = ptrtoint i8* %r1059 to i64
  %r1061 = call i64 @_add(i64 %r1058, i64 %r1060)
  %r1062 = load i64, i64* %ptr_NL
  %r1063 = call i64 @_add(i64 %r1061, i64 %r1062)
  store i64 %r1063, i64* %ptr_s
  %r1064 = load i64, i64* %ptr_s
  %r1065 = getelementptr [12 x i8], [12 x i8]* @.str.784, i64 0, i64 0
  %r1066 = ptrtoint i8* %r1065 to i64
  %r1067 = call i64 @_add(i64 %r1064, i64 %r1066)
  %r1068 = load i64, i64* %ptr_NL
  %r1069 = call i64 @_add(i64 %r1067, i64 %r1068)
  store i64 %r1069, i64* %ptr_s
  %r1070 = load i64, i64* %ptr_s
  %r1071 = getelementptr [2 x i8], [2 x i8]* @.str.785, i64 0, i64 0
  %r1072 = ptrtoint i8* %r1071 to i64
  %r1073 = call i64 @_add(i64 %r1070, i64 %r1072)
  %r1074 = load i64, i64* %ptr_NL
  %r1075 = call i64 @_add(i64 %r1073, i64 %r1074)
  store i64 %r1075, i64* %ptr_s
  %r1076 = load i64, i64* %ptr_s
  %r1077 = getelementptr [25 x i8], [25 x i8]* @.str.786, i64 0, i64 0
  %r1078 = ptrtoint i8* %r1077 to i64
  %r1079 = call i64 @_add(i64 %r1076, i64 %r1078)
  %r1080 = load i64, i64* %ptr_NL
  %r1081 = call i64 @_add(i64 %r1079, i64 %r1080)
  store i64 %r1081, i64* %ptr_s
  %r1082 = load i64, i64* %ptr_s
  %r1083 = getelementptr [29 x i8], [29 x i8]* @.str.787, i64 0, i64 0
  %r1084 = ptrtoint i8* %r1083 to i64
  %r1085 = call i64 @_add(i64 %r1082, i64 %r1084)
  %r1086 = load i64, i64* %ptr_NL
  %r1087 = call i64 @_add(i64 %r1085, i64 %r1086)
  store i64 %r1087, i64* %ptr_s
  %r1088 = load i64, i64* %ptr_s
  %r1089 = getelementptr [33 x i8], [33 x i8]* @.str.788, i64 0, i64 0
  %r1090 = ptrtoint i8* %r1089 to i64
  %r1091 = call i64 @_add(i64 %r1088, i64 %r1090)
  %r1092 = load i64, i64* %ptr_NL
  %r1093 = call i64 @_add(i64 %r1091, i64 %r1092)
  store i64 %r1093, i64* %ptr_s
  %r1094 = load i64, i64* %ptr_s
  %r1095 = getelementptr [25 x i8], [25 x i8]* @.str.789, i64 0, i64 0
  %r1096 = ptrtoint i8* %r1095 to i64
  %r1097 = call i64 @_add(i64 %r1094, i64 %r1096)
  %r1098 = load i64, i64* %ptr_NL
  %r1099 = call i64 @_add(i64 %r1097, i64 %r1098)
  store i64 %r1099, i64* %ptr_s
  %r1100 = load i64, i64* %ptr_s
  %r1101 = getelementptr [13 x i8], [13 x i8]* @.str.790, i64 0, i64 0
  %r1102 = ptrtoint i8* %r1101 to i64
  %r1103 = call i64 @_add(i64 %r1100, i64 %r1102)
  %r1104 = load i64, i64* %ptr_NL
  %r1105 = call i64 @_add(i64 %r1103, i64 %r1104)
  store i64 %r1105, i64* %ptr_s
  %r1106 = load i64, i64* %ptr_s
  %r1107 = getelementptr [2 x i8], [2 x i8]* @.str.791, i64 0, i64 0
  %r1108 = ptrtoint i8* %r1107 to i64
  %r1109 = call i64 @_add(i64 %r1106, i64 %r1108)
  %r1110 = load i64, i64* %ptr_NL
  %r1111 = call i64 @_add(i64 %r1109, i64 %r1110)
  store i64 %r1111, i64* %ptr_s
  %r1112 = load i64, i64* %ptr_s
  %r1113 = getelementptr [47 x i8], [47 x i8]* @.str.792, i64 0, i64 0
  %r1114 = ptrtoint i8* %r1113 to i64
  %r1115 = call i64 @_add(i64 %r1112, i64 %r1114)
  %r1116 = load i64, i64* %ptr_NL
  %r1117 = call i64 @_add(i64 %r1115, i64 %r1116)
  store i64 %r1117, i64* %ptr_s
  %r1118 = load i64, i64* %ptr_s
  %r1119 = getelementptr [39 x i8], [39 x i8]* @.str.793, i64 0, i64 0
  %r1120 = ptrtoint i8* %r1119 to i64
  %r1121 = call i64 @_add(i64 %r1118, i64 %r1120)
  %r1122 = load i64, i64* %ptr_NL
  %r1123 = call i64 @_add(i64 %r1121, i64 %r1122)
  store i64 %r1123, i64* %ptr_s
  %r1124 = load i64, i64* %ptr_s
  %r1125 = getelementptr [39 x i8], [39 x i8]* @.str.794, i64 0, i64 0
  %r1126 = ptrtoint i8* %r1125 to i64
  %r1127 = call i64 @_add(i64 %r1124, i64 %r1126)
  %r1128 = load i64, i64* %ptr_NL
  %r1129 = call i64 @_add(i64 %r1127, i64 %r1128)
  store i64 %r1129, i64* %ptr_s
  %r1130 = load i64, i64* %ptr_s
  %r1131 = getelementptr [12 x i8], [12 x i8]* @.str.795, i64 0, i64 0
  %r1132 = ptrtoint i8* %r1131 to i64
  %r1133 = call i64 @_add(i64 %r1130, i64 %r1132)
  %r1134 = load i64, i64* %ptr_NL
  %r1135 = call i64 @_add(i64 %r1133, i64 %r1134)
  store i64 %r1135, i64* %ptr_s
  %r1136 = load i64, i64* %ptr_s
  %r1137 = getelementptr [2 x i8], [2 x i8]* @.str.796, i64 0, i64 0
  %r1138 = ptrtoint i8* %r1137 to i64
  %r1139 = call i64 @_add(i64 %r1136, i64 %r1138)
  %r1140 = load i64, i64* %ptr_NL
  %r1141 = call i64 @_add(i64 %r1139, i64 %r1140)
  store i64 %r1141, i64* %ptr_s
  %r1142 = load i64, i64* %ptr_s
  %r1143 = getelementptr [47 x i8], [47 x i8]* @.str.797, i64 0, i64 0
  %r1144 = ptrtoint i8* %r1143 to i64
  %r1145 = call i64 @_add(i64 %r1142, i64 %r1144)
  %r1146 = load i64, i64* %ptr_NL
  %r1147 = call i64 @_add(i64 %r1145, i64 %r1146)
  store i64 %r1147, i64* %ptr_s
  %r1148 = load i64, i64* %ptr_s
  %r1149 = getelementptr [35 x i8], [35 x i8]* @.str.798, i64 0, i64 0
  %r1150 = ptrtoint i8* %r1149 to i64
  %r1151 = call i64 @_add(i64 %r1148, i64 %r1150)
  %r1152 = load i64, i64* %ptr_NL
  %r1153 = call i64 @_add(i64 %r1151, i64 %r1152)
  store i64 %r1153, i64* %ptr_s
  %r1154 = load i64, i64* %ptr_s
  %r1155 = getelementptr [30 x i8], [30 x i8]* @.str.799, i64 0, i64 0
  %r1156 = ptrtoint i8* %r1155 to i64
  %r1157 = call i64 @_add(i64 %r1154, i64 %r1156)
  %r1158 = load i64, i64* %ptr_NL
  %r1159 = call i64 @_add(i64 %r1157, i64 %r1158)
  store i64 %r1159, i64* %ptr_s
  %r1160 = load i64, i64* %ptr_s
  %r1161 = getelementptr [33 x i8], [33 x i8]* @.str.800, i64 0, i64 0
  %r1162 = ptrtoint i8* %r1161 to i64
  %r1163 = call i64 @_add(i64 %r1160, i64 %r1162)
  %r1164 = load i64, i64* %ptr_NL
  %r1165 = call i64 @_add(i64 %r1163, i64 %r1164)
  store i64 %r1165, i64* %ptr_s
  %r1166 = load i64, i64* %ptr_s
  %r1167 = getelementptr [47 x i8], [47 x i8]* @.str.801, i64 0, i64 0
  %r1168 = ptrtoint i8* %r1167 to i64
  %r1169 = call i64 @_add(i64 %r1166, i64 %r1168)
  %r1170 = load i64, i64* %ptr_NL
  %r1171 = call i64 @_add(i64 %r1169, i64 %r1170)
  store i64 %r1171, i64* %ptr_s
  %r1172 = load i64, i64* %ptr_s
  %r1173 = getelementptr [9 x i8], [9 x i8]* @.str.802, i64 0, i64 0
  %r1174 = ptrtoint i8* %r1173 to i64
  %r1175 = call i64 @_add(i64 %r1172, i64 %r1174)
  %r1176 = load i64, i64* %ptr_NL
  %r1177 = call i64 @_add(i64 %r1175, i64 %r1176)
  store i64 %r1177, i64* %ptr_s
  %r1178 = load i64, i64* %ptr_s
  %r1179 = getelementptr [50 x i8], [50 x i8]* @.str.803, i64 0, i64 0
  %r1180 = ptrtoint i8* %r1179 to i64
  %r1181 = call i64 @_add(i64 %r1178, i64 %r1180)
  %r1182 = load i64, i64* %ptr_NL
  %r1183 = call i64 @_add(i64 %r1181, i64 %r1182)
  store i64 %r1183, i64* %ptr_s
  %r1184 = load i64, i64* %ptr_s
  %r1185 = getelementptr [12 x i8], [12 x i8]* @.str.804, i64 0, i64 0
  %r1186 = ptrtoint i8* %r1185 to i64
  %r1187 = call i64 @_add(i64 %r1184, i64 %r1186)
  %r1188 = load i64, i64* %ptr_NL
  %r1189 = call i64 @_add(i64 %r1187, i64 %r1188)
  store i64 %r1189, i64* %ptr_s
  %r1190 = load i64, i64* %ptr_s
  %r1191 = getelementptr [8 x i8], [8 x i8]* @.str.805, i64 0, i64 0
  %r1192 = ptrtoint i8* %r1191 to i64
  %r1193 = call i64 @_add(i64 %r1190, i64 %r1192)
  %r1194 = load i64, i64* %ptr_NL
  %r1195 = call i64 @_add(i64 %r1193, i64 %r1194)
  store i64 %r1195, i64* %ptr_s
  %r1196 = load i64, i64* %ptr_s
  %r1197 = getelementptr [49 x i8], [49 x i8]* @.str.806, i64 0, i64 0
  %r1198 = ptrtoint i8* %r1197 to i64
  %r1199 = call i64 @_add(i64 %r1196, i64 %r1198)
  %r1200 = load i64, i64* %ptr_NL
  %r1201 = call i64 @_add(i64 %r1199, i64 %r1200)
  store i64 %r1201, i64* %ptr_s
  %r1202 = load i64, i64* %ptr_s
  %r1203 = getelementptr [12 x i8], [12 x i8]* @.str.807, i64 0, i64 0
  %r1204 = ptrtoint i8* %r1203 to i64
  %r1205 = call i64 @_add(i64 %r1202, i64 %r1204)
  %r1206 = load i64, i64* %ptr_NL
  %r1207 = call i64 @_add(i64 %r1205, i64 %r1206)
  store i64 %r1207, i64* %ptr_s
  %r1208 = load i64, i64* %ptr_s
  %r1209 = getelementptr [2 x i8], [2 x i8]* @.str.808, i64 0, i64 0
  %r1210 = ptrtoint i8* %r1209 to i64
  %r1211 = call i64 @_add(i64 %r1208, i64 %r1210)
  %r1212 = load i64, i64* %ptr_NL
  %r1213 = call i64 @_add(i64 %r1211, i64 %r1212)
  store i64 %r1213, i64* %ptr_s
  %r1214 = load i64, i64* %ptr_s
  %r1215 = getelementptr [41 x i8], [41 x i8]* @.str.809, i64 0, i64 0
  %r1216 = ptrtoint i8* %r1215 to i64
  %r1217 = call i64 @_add(i64 %r1214, i64 %r1216)
  %r1218 = load i64, i64* %ptr_NL
  %r1219 = call i64 @_add(i64 %r1217, i64 %r1218)
  store i64 %r1219, i64* %ptr_s
  %r1220 = load i64, i64* %ptr_s
  %r1221 = getelementptr [33 x i8], [33 x i8]* @.str.810, i64 0, i64 0
  %r1222 = ptrtoint i8* %r1221 to i64
  %r1223 = call i64 @_add(i64 %r1220, i64 %r1222)
  %r1224 = load i64, i64* %ptr_NL
  %r1225 = call i64 @_add(i64 %r1223, i64 %r1224)
  store i64 %r1225, i64* %ptr_s
  %r1226 = load i64, i64* %ptr_s
  %r1227 = getelementptr [49 x i8], [49 x i8]* @.str.811, i64 0, i64 0
  %r1228 = ptrtoint i8* %r1227 to i64
  %r1229 = call i64 @_add(i64 %r1226, i64 %r1228)
  %r1230 = load i64, i64* %ptr_NL
  %r1231 = call i64 @_add(i64 %r1229, i64 %r1230)
  store i64 %r1231, i64* %ptr_s
  %r1232 = load i64, i64* %ptr_s
  %r1233 = getelementptr [33 x i8], [33 x i8]* @.str.812, i64 0, i64 0
  %r1234 = ptrtoint i8* %r1233 to i64
  %r1235 = call i64 @_add(i64 %r1232, i64 %r1234)
  %r1236 = load i64, i64* %ptr_NL
  %r1237 = call i64 @_add(i64 %r1235, i64 %r1236)
  store i64 %r1237, i64* %ptr_s
  %r1238 = load i64, i64* %ptr_s
  %r1239 = getelementptr [50 x i8], [50 x i8]* @.str.813, i64 0, i64 0
  %r1240 = ptrtoint i8* %r1239 to i64
  %r1241 = call i64 @_add(i64 %r1238, i64 %r1240)
  %r1242 = load i64, i64* %ptr_NL
  %r1243 = call i64 @_add(i64 %r1241, i64 %r1242)
  store i64 %r1243, i64* %ptr_s
  %r1244 = load i64, i64* %ptr_s
  %r1245 = getelementptr [35 x i8], [35 x i8]* @.str.814, i64 0, i64 0
  %r1246 = ptrtoint i8* %r1245 to i64
  %r1247 = call i64 @_add(i64 %r1244, i64 %r1246)
  %r1248 = load i64, i64* %ptr_NL
  %r1249 = call i64 @_add(i64 %r1247, i64 %r1248)
  store i64 %r1249, i64* %ptr_s
  %r1250 = load i64, i64* %ptr_s
  %r1251 = getelementptr [41 x i8], [41 x i8]* @.str.815, i64 0, i64 0
  %r1252 = ptrtoint i8* %r1251 to i64
  %r1253 = call i64 @_add(i64 %r1250, i64 %r1252)
  %r1254 = load i64, i64* %ptr_NL
  %r1255 = call i64 @_add(i64 %r1253, i64 %r1254)
  store i64 %r1255, i64* %ptr_s
  %r1256 = load i64, i64* %ptr_s
  %r1257 = getelementptr [36 x i8], [36 x i8]* @.str.816, i64 0, i64 0
  %r1258 = ptrtoint i8* %r1257 to i64
  %r1259 = call i64 @_add(i64 %r1256, i64 %r1258)
  %r1260 = load i64, i64* %ptr_NL
  %r1261 = call i64 @_add(i64 %r1259, i64 %r1260)
  store i64 %r1261, i64* %ptr_s
  %r1262 = load i64, i64* %ptr_s
  %r1263 = getelementptr [29 x i8], [29 x i8]* @.str.817, i64 0, i64 0
  %r1264 = ptrtoint i8* %r1263 to i64
  %r1265 = call i64 @_add(i64 %r1262, i64 %r1264)
  %r1266 = load i64, i64* %ptr_NL
  %r1267 = call i64 @_add(i64 %r1265, i64 %r1266)
  store i64 %r1267, i64* %ptr_s
  %r1268 = load i64, i64* %ptr_s
  %r1269 = getelementptr [17 x i8], [17 x i8]* @.str.818, i64 0, i64 0
  %r1270 = ptrtoint i8* %r1269 to i64
  %r1271 = call i64 @_add(i64 %r1268, i64 %r1270)
  %r1272 = load i64, i64* %ptr_NL
  %r1273 = call i64 @_add(i64 %r1271, i64 %r1272)
  store i64 %r1273, i64* %ptr_s
  %r1274 = load i64, i64* %ptr_s
  %r1275 = getelementptr [6 x i8], [6 x i8]* @.str.819, i64 0, i64 0
  %r1276 = ptrtoint i8* %r1275 to i64
  %r1277 = call i64 @_add(i64 %r1274, i64 %r1276)
  %r1278 = load i64, i64* %ptr_NL
  %r1279 = call i64 @_add(i64 %r1277, i64 %r1278)
  store i64 %r1279, i64* %ptr_s
  %r1280 = load i64, i64* %ptr_s
  %r1281 = getelementptr [52 x i8], [52 x i8]* @.str.820, i64 0, i64 0
  %r1282 = ptrtoint i8* %r1281 to i64
  %r1283 = call i64 @_add(i64 %r1280, i64 %r1282)
  %r1284 = load i64, i64* %ptr_NL
  %r1285 = call i64 @_add(i64 %r1283, i64 %r1284)
  store i64 %r1285, i64* %ptr_s
  %r1286 = load i64, i64* %ptr_s
  %r1287 = getelementptr [29 x i8], [29 x i8]* @.str.821, i64 0, i64 0
  %r1288 = ptrtoint i8* %r1287 to i64
  %r1289 = call i64 @_add(i64 %r1286, i64 %r1288)
  %r1290 = load i64, i64* %ptr_NL
  %r1291 = call i64 @_add(i64 %r1289, i64 %r1290)
  store i64 %r1291, i64* %ptr_s
  %r1292 = load i64, i64* %ptr_s
  %r1293 = getelementptr [50 x i8], [50 x i8]* @.str.822, i64 0, i64 0
  %r1294 = ptrtoint i8* %r1293 to i64
  %r1295 = call i64 @_add(i64 %r1292, i64 %r1294)
  %r1296 = load i64, i64* %ptr_NL
  %r1297 = call i64 @_add(i64 %r1295, i64 %r1296)
  store i64 %r1297, i64* %ptr_s
  %r1298 = load i64, i64* %ptr_s
  %r1299 = getelementptr [11 x i8], [11 x i8]* @.str.823, i64 0, i64 0
  %r1300 = ptrtoint i8* %r1299 to i64
  %r1301 = call i64 @_add(i64 %r1298, i64 %r1300)
  %r1302 = load i64, i64* %ptr_NL
  %r1303 = call i64 @_add(i64 %r1301, i64 %r1302)
  store i64 %r1303, i64* %ptr_s
  %r1304 = load i64, i64* %ptr_s
  %r1305 = getelementptr [54 x i8], [54 x i8]* @.str.824, i64 0, i64 0
  %r1306 = ptrtoint i8* %r1305 to i64
  %r1307 = call i64 @_add(i64 %r1304, i64 %r1306)
  %r1308 = load i64, i64* %ptr_NL
  %r1309 = call i64 @_add(i64 %r1307, i64 %r1308)
  store i64 %r1309, i64* %ptr_s
  %r1310 = load i64, i64* %ptr_s
  %r1311 = getelementptr [34 x i8], [34 x i8]* @.str.825, i64 0, i64 0
  %r1312 = ptrtoint i8* %r1311 to i64
  %r1313 = call i64 @_add(i64 %r1310, i64 %r1312)
  %r1314 = load i64, i64* %ptr_NL
  %r1315 = call i64 @_add(i64 %r1313, i64 %r1314)
  store i64 %r1315, i64* %ptr_s
  %r1316 = load i64, i64* %ptr_s
  %r1317 = getelementptr [38 x i8], [38 x i8]* @.str.826, i64 0, i64 0
  %r1318 = ptrtoint i8* %r1317 to i64
  %r1319 = call i64 @_add(i64 %r1316, i64 %r1318)
  %r1320 = load i64, i64* %ptr_NL
  %r1321 = call i64 @_add(i64 %r1319, i64 %r1320)
  store i64 %r1321, i64* %ptr_s
  %r1322 = load i64, i64* %ptr_s
  %r1323 = getelementptr [50 x i8], [50 x i8]* @.str.827, i64 0, i64 0
  %r1324 = ptrtoint i8* %r1323 to i64
  %r1325 = call i64 @_add(i64 %r1322, i64 %r1324)
  %r1326 = load i64, i64* %ptr_NL
  %r1327 = call i64 @_add(i64 %r1325, i64 %r1326)
  store i64 %r1327, i64* %ptr_s
  %r1328 = load i64, i64* %ptr_s
  %r1329 = getelementptr [31 x i8], [31 x i8]* @.str.828, i64 0, i64 0
  %r1330 = ptrtoint i8* %r1329 to i64
  %r1331 = call i64 @_add(i64 %r1328, i64 %r1330)
  %r1332 = load i64, i64* %ptr_NL
  %r1333 = call i64 @_add(i64 %r1331, i64 %r1332)
  store i64 %r1333, i64* %ptr_s
  %r1334 = load i64, i64* %ptr_s
  %r1335 = getelementptr [42 x i8], [42 x i8]* @.str.829, i64 0, i64 0
  %r1336 = ptrtoint i8* %r1335 to i64
  %r1337 = call i64 @_add(i64 %r1334, i64 %r1336)
  %r1338 = load i64, i64* %ptr_NL
  %r1339 = call i64 @_add(i64 %r1337, i64 %r1338)
  store i64 %r1339, i64* %ptr_s
  %r1340 = load i64, i64* %ptr_s
  %r1341 = getelementptr [6 x i8], [6 x i8]* @.str.830, i64 0, i64 0
  %r1342 = ptrtoint i8* %r1341 to i64
  %r1343 = call i64 @_add(i64 %r1340, i64 %r1342)
  %r1344 = load i64, i64* %ptr_NL
  %r1345 = call i64 @_add(i64 %r1343, i64 %r1344)
  store i64 %r1345, i64* %ptr_s
  %r1346 = load i64, i64* %ptr_s
  %r1347 = getelementptr [26 x i8], [26 x i8]* @.str.831, i64 0, i64 0
  %r1348 = ptrtoint i8* %r1347 to i64
  %r1349 = call i64 @_add(i64 %r1346, i64 %r1348)
  %r1350 = load i64, i64* %ptr_NL
  %r1351 = call i64 @_add(i64 %r1349, i64 %r1350)
  store i64 %r1351, i64* %ptr_s
  %r1352 = load i64, i64* %ptr_s
  %r1353 = getelementptr [17 x i8], [17 x i8]* @.str.832, i64 0, i64 0
  %r1354 = ptrtoint i8* %r1353 to i64
  %r1355 = call i64 @_add(i64 %r1352, i64 %r1354)
  %r1356 = load i64, i64* %ptr_NL
  %r1357 = call i64 @_add(i64 %r1355, i64 %r1356)
  store i64 %r1357, i64* %ptr_s
  %r1358 = load i64, i64* %ptr_s
  %r1359 = getelementptr [7 x i8], [7 x i8]* @.str.833, i64 0, i64 0
  %r1360 = ptrtoint i8* %r1359 to i64
  %r1361 = call i64 @_add(i64 %r1358, i64 %r1360)
  %r1362 = load i64, i64* %ptr_NL
  %r1363 = call i64 @_add(i64 %r1361, i64 %r1362)
  store i64 %r1363, i64* %ptr_s
  %r1364 = load i64, i64* %ptr_s
  %r1365 = getelementptr [25 x i8], [25 x i8]* @.str.834, i64 0, i64 0
  %r1366 = ptrtoint i8* %r1365 to i64
  %r1367 = call i64 @_add(i64 %r1364, i64 %r1366)
  %r1368 = load i64, i64* %ptr_NL
  %r1369 = call i64 @_add(i64 %r1367, i64 %r1368)
  store i64 %r1369, i64* %ptr_s
  %r1370 = load i64, i64* %ptr_s
  %r1371 = getelementptr [58 x i8], [58 x i8]* @.str.835, i64 0, i64 0
  %r1372 = ptrtoint i8* %r1371 to i64
  %r1373 = call i64 @_add(i64 %r1370, i64 %r1372)
  %r1374 = load i64, i64* %ptr_NL
  %r1375 = call i64 @_add(i64 %r1373, i64 %r1374)
  store i64 %r1375, i64* %ptr_s
  %r1376 = load i64, i64* %ptr_s
  %r1377 = getelementptr [32 x i8], [32 x i8]* @.str.836, i64 0, i64 0
  %r1378 = ptrtoint i8* %r1377 to i64
  %r1379 = call i64 @_add(i64 %r1376, i64 %r1378)
  %r1380 = load i64, i64* %ptr_NL
  %r1381 = call i64 @_add(i64 %r1379, i64 %r1380)
  store i64 %r1381, i64* %ptr_s
  %r1382 = load i64, i64* %ptr_s
  %r1383 = getelementptr [15 x i8], [15 x i8]* @.str.837, i64 0, i64 0
  %r1384 = ptrtoint i8* %r1383 to i64
  %r1385 = call i64 @_add(i64 %r1382, i64 %r1384)
  %r1386 = load i64, i64* %ptr_NL
  %r1387 = call i64 @_add(i64 %r1385, i64 %r1386)
  store i64 %r1387, i64* %ptr_s
  %r1388 = load i64, i64* %ptr_s
  %r1389 = getelementptr [11 x i8], [11 x i8]* @.str.838, i64 0, i64 0
  %r1390 = ptrtoint i8* %r1389 to i64
  %r1391 = call i64 @_add(i64 %r1388, i64 %r1390)
  %r1392 = load i64, i64* %ptr_NL
  %r1393 = call i64 @_add(i64 %r1391, i64 %r1392)
  store i64 %r1393, i64* %ptr_s
  %r1394 = load i64, i64* %ptr_s
  %r1395 = getelementptr [12 x i8], [12 x i8]* @.str.839, i64 0, i64 0
  %r1396 = ptrtoint i8* %r1395 to i64
  %r1397 = call i64 @_add(i64 %r1394, i64 %r1396)
  %r1398 = load i64, i64* %ptr_NL
  %r1399 = call i64 @_add(i64 %r1397, i64 %r1398)
  store i64 %r1399, i64* %ptr_s
  %r1400 = load i64, i64* %ptr_s
  %r1401 = getelementptr [2 x i8], [2 x i8]* @.str.840, i64 0, i64 0
  %r1402 = ptrtoint i8* %r1401 to i64
  %r1403 = call i64 @_add(i64 %r1400, i64 %r1402)
  %r1404 = load i64, i64* %ptr_NL
  %r1405 = call i64 @_add(i64 %r1403, i64 %r1404)
  store i64 %r1405, i64* %ptr_s
  %r1406 = load i64, i64* %ptr_s
  %r1407 = getelementptr [39 x i8], [39 x i8]* @.str.841, i64 0, i64 0
  %r1408 = ptrtoint i8* %r1407 to i64
  %r1409 = call i64 @_add(i64 %r1406, i64 %r1408)
  %r1410 = load i64, i64* %ptr_NL
  %r1411 = call i64 @_add(i64 %r1409, i64 %r1410)
  store i64 %r1411, i64* %ptr_s
  %r1412 = load i64, i64* %ptr_s
  %r1413 = getelementptr [33 x i8], [33 x i8]* @.str.842, i64 0, i64 0
  %r1414 = ptrtoint i8* %r1413 to i64
  %r1415 = call i64 @_add(i64 %r1412, i64 %r1414)
  %r1416 = load i64, i64* %ptr_NL
  %r1417 = call i64 @_add(i64 %r1415, i64 %r1416)
  store i64 %r1417, i64* %ptr_s
  %r1418 = load i64, i64* %ptr_s
  %r1419 = getelementptr [43 x i8], [43 x i8]* @.str.843, i64 0, i64 0
  %r1420 = ptrtoint i8* %r1419 to i64
  %r1421 = call i64 @_add(i64 %r1418, i64 %r1420)
  %r1422 = load i64, i64* %ptr_NL
  %r1423 = call i64 @_add(i64 %r1421, i64 %r1422)
  store i64 %r1423, i64* %ptr_s
  %r1424 = load i64, i64* %ptr_s
  %r1425 = getelementptr [7 x i8], [7 x i8]* @.str.844, i64 0, i64 0
  %r1426 = ptrtoint i8* %r1425 to i64
  %r1427 = call i64 @_add(i64 %r1424, i64 %r1426)
  %r1428 = load i64, i64* %ptr_NL
  %r1429 = call i64 @_add(i64 %r1427, i64 %r1428)
  store i64 %r1429, i64* %ptr_s
  %r1430 = load i64, i64* %ptr_s
  %r1431 = getelementptr [35 x i8], [35 x i8]* @.str.845, i64 0, i64 0
  %r1432 = ptrtoint i8* %r1431 to i64
  %r1433 = call i64 @_add(i64 %r1430, i64 %r1432)
  %r1434 = load i64, i64* %ptr_NL
  %r1435 = call i64 @_add(i64 %r1433, i64 %r1434)
  store i64 %r1435, i64* %ptr_s
  %r1436 = load i64, i64* %ptr_s
  %r1437 = getelementptr [28 x i8], [28 x i8]* @.str.846, i64 0, i64 0
  %r1438 = ptrtoint i8* %r1437 to i64
  %r1439 = call i64 @_add(i64 %r1436, i64 %r1438)
  %r1440 = load i64, i64* %ptr_NL
  %r1441 = call i64 @_add(i64 %r1439, i64 %r1440)
  store i64 %r1441, i64* %ptr_s
  %r1442 = load i64, i64* %ptr_s
  %r1443 = getelementptr [32 x i8], [32 x i8]* @.str.847, i64 0, i64 0
  %r1444 = ptrtoint i8* %r1443 to i64
  %r1445 = call i64 @_add(i64 %r1442, i64 %r1444)
  %r1446 = load i64, i64* %ptr_NL
  %r1447 = call i64 @_add(i64 %r1445, i64 %r1446)
  store i64 %r1447, i64* %ptr_s
  %r1448 = load i64, i64* %ptr_s
  %r1449 = getelementptr [51 x i8], [51 x i8]* @.str.848, i64 0, i64 0
  %r1450 = ptrtoint i8* %r1449 to i64
  %r1451 = call i64 @_add(i64 %r1448, i64 %r1450)
  %r1452 = load i64, i64* %ptr_NL
  %r1453 = call i64 @_add(i64 %r1451, i64 %r1452)
  store i64 %r1453, i64* %ptr_s
  %r1454 = load i64, i64* %ptr_s
  %r1455 = getelementptr [11 x i8], [11 x i8]* @.str.849, i64 0, i64 0
  %r1456 = ptrtoint i8* %r1455 to i64
  %r1457 = call i64 @_add(i64 %r1454, i64 %r1456)
  %r1458 = load i64, i64* %ptr_NL
  %r1459 = call i64 @_add(i64 %r1457, i64 %r1458)
  store i64 %r1459, i64* %ptr_s
  %r1460 = load i64, i64* %ptr_s
  %r1461 = getelementptr [31 x i8], [31 x i8]* @.str.850, i64 0, i64 0
  %r1462 = ptrtoint i8* %r1461 to i64
  %r1463 = call i64 @_add(i64 %r1460, i64 %r1462)
  %r1464 = load i64, i64* %ptr_NL
  %r1465 = call i64 @_add(i64 %r1463, i64 %r1464)
  store i64 %r1465, i64* %ptr_s
  %r1466 = load i64, i64* %ptr_s
  %r1467 = getelementptr [46 x i8], [46 x i8]* @.str.851, i64 0, i64 0
  %r1468 = ptrtoint i8* %r1467 to i64
  %r1469 = call i64 @_add(i64 %r1466, i64 %r1468)
  %r1470 = load i64, i64* %ptr_NL
  %r1471 = call i64 @_add(i64 %r1469, i64 %r1470)
  store i64 %r1471, i64* %ptr_s
  %r1472 = load i64, i64* %ptr_s
  %r1473 = getelementptr [8 x i8], [8 x i8]* @.str.852, i64 0, i64 0
  %r1474 = ptrtoint i8* %r1473 to i64
  %r1475 = call i64 @_add(i64 %r1472, i64 %r1474)
  %r1476 = load i64, i64* %ptr_NL
  %r1477 = call i64 @_add(i64 %r1475, i64 %r1476)
  store i64 %r1477, i64* %ptr_s
  %r1478 = load i64, i64* %ptr_s
  %r1479 = getelementptr [39 x i8], [39 x i8]* @.str.853, i64 0, i64 0
  %r1480 = ptrtoint i8* %r1479 to i64
  %r1481 = call i64 @_add(i64 %r1478, i64 %r1480)
  %r1482 = load i64, i64* %ptr_NL
  %r1483 = call i64 @_add(i64 %r1481, i64 %r1482)
  store i64 %r1483, i64* %ptr_s
  %r1484 = load i64, i64* %ptr_s
  %r1485 = getelementptr [56 x i8], [56 x i8]* @.str.854, i64 0, i64 0
  %r1486 = ptrtoint i8* %r1485 to i64
  %r1487 = call i64 @_add(i64 %r1484, i64 %r1486)
  %r1488 = load i64, i64* %ptr_NL
  %r1489 = call i64 @_add(i64 %r1487, i64 %r1488)
  store i64 %r1489, i64* %ptr_s
  %r1490 = load i64, i64* %ptr_s
  %r1491 = getelementptr [33 x i8], [33 x i8]* @.str.855, i64 0, i64 0
  %r1492 = ptrtoint i8* %r1491 to i64
  %r1493 = call i64 @_add(i64 %r1490, i64 %r1492)
  %r1494 = load i64, i64* %ptr_NL
  %r1495 = call i64 @_add(i64 %r1493, i64 %r1494)
  store i64 %r1495, i64* %ptr_s
  %r1496 = load i64, i64* %ptr_s
  %r1497 = getelementptr [37 x i8], [37 x i8]* @.str.856, i64 0, i64 0
  %r1498 = ptrtoint i8* %r1497 to i64
  %r1499 = call i64 @_add(i64 %r1496, i64 %r1498)
  %r1500 = load i64, i64* %ptr_NL
  %r1501 = call i64 @_add(i64 %r1499, i64 %r1500)
  store i64 %r1501, i64* %ptr_s
  %r1502 = load i64, i64* %ptr_s
  %r1503 = getelementptr [42 x i8], [42 x i8]* @.str.857, i64 0, i64 0
  %r1504 = ptrtoint i8* %r1503 to i64
  %r1505 = call i64 @_add(i64 %r1502, i64 %r1504)
  %r1506 = load i64, i64* %ptr_NL
  %r1507 = call i64 @_add(i64 %r1505, i64 %r1506)
  store i64 %r1507, i64* %ptr_s
  %r1508 = load i64, i64* %ptr_s
  %r1509 = getelementptr [31 x i8], [31 x i8]* @.str.858, i64 0, i64 0
  %r1510 = ptrtoint i8* %r1509 to i64
  %r1511 = call i64 @_add(i64 %r1508, i64 %r1510)
  %r1512 = load i64, i64* %ptr_NL
  %r1513 = call i64 @_add(i64 %r1511, i64 %r1512)
  store i64 %r1513, i64* %ptr_s
  %r1514 = load i64, i64* %ptr_s
  %r1515 = getelementptr [48 x i8], [48 x i8]* @.str.859, i64 0, i64 0
  %r1516 = ptrtoint i8* %r1515 to i64
  %r1517 = call i64 @_add(i64 %r1514, i64 %r1516)
  %r1518 = load i64, i64* %ptr_NL
  %r1519 = call i64 @_add(i64 %r1517, i64 %r1518)
  store i64 %r1519, i64* %ptr_s
  %r1520 = load i64, i64* %ptr_s
  %r1521 = getelementptr [24 x i8], [24 x i8]* @.str.860, i64 0, i64 0
  %r1522 = ptrtoint i8* %r1521 to i64
  %r1523 = call i64 @_add(i64 %r1520, i64 %r1522)
  %r1524 = load i64, i64* %ptr_NL
  %r1525 = call i64 @_add(i64 %r1523, i64 %r1524)
  store i64 %r1525, i64* %ptr_s
  %r1526 = load i64, i64* %ptr_s
  %r1527 = getelementptr [42 x i8], [42 x i8]* @.str.861, i64 0, i64 0
  %r1528 = ptrtoint i8* %r1527 to i64
  %r1529 = call i64 @_add(i64 %r1526, i64 %r1528)
  %r1530 = load i64, i64* %ptr_NL
  %r1531 = call i64 @_add(i64 %r1529, i64 %r1530)
  store i64 %r1531, i64* %ptr_s
  %r1532 = load i64, i64* %ptr_s
  %r1533 = getelementptr [19 x i8], [19 x i8]* @.str.862, i64 0, i64 0
  %r1534 = ptrtoint i8* %r1533 to i64
  %r1535 = call i64 @_add(i64 %r1532, i64 %r1534)
  %r1536 = load i64, i64* %ptr_NL
  %r1537 = call i64 @_add(i64 %r1535, i64 %r1536)
  store i64 %r1537, i64* %ptr_s
  %r1538 = load i64, i64* %ptr_s
  %r1539 = getelementptr [8 x i8], [8 x i8]* @.str.863, i64 0, i64 0
  %r1540 = ptrtoint i8* %r1539 to i64
  %r1541 = call i64 @_add(i64 %r1538, i64 %r1540)
  %r1542 = load i64, i64* %ptr_NL
  %r1543 = call i64 @_add(i64 %r1541, i64 %r1542)
  store i64 %r1543, i64* %ptr_s
  %r1544 = load i64, i64* %ptr_s
  %r1545 = getelementptr [52 x i8], [52 x i8]* @.str.864, i64 0, i64 0
  %r1546 = ptrtoint i8* %r1545 to i64
  %r1547 = call i64 @_add(i64 %r1544, i64 %r1546)
  %r1548 = load i64, i64* %ptr_NL
  %r1549 = call i64 @_add(i64 %r1547, i64 %r1548)
  store i64 %r1549, i64* %ptr_s
  %r1550 = load i64, i64* %ptr_s
  %r1551 = getelementptr [19 x i8], [19 x i8]* @.str.865, i64 0, i64 0
  %r1552 = ptrtoint i8* %r1551 to i64
  %r1553 = call i64 @_add(i64 %r1550, i64 %r1552)
  %r1554 = load i64, i64* %ptr_NL
  %r1555 = call i64 @_add(i64 %r1553, i64 %r1554)
  store i64 %r1555, i64* %ptr_s
  %r1556 = load i64, i64* %ptr_s
  %r1557 = getelementptr [9 x i8], [9 x i8]* @.str.866, i64 0, i64 0
  %r1558 = ptrtoint i8* %r1557 to i64
  %r1559 = call i64 @_add(i64 %r1556, i64 %r1558)
  %r1560 = load i64, i64* %ptr_NL
  %r1561 = call i64 @_add(i64 %r1559, i64 %r1560)
  store i64 %r1561, i64* %ptr_s
  %r1562 = load i64, i64* %ptr_s
  %r1563 = getelementptr [37 x i8], [37 x i8]* @.str.867, i64 0, i64 0
  %r1564 = ptrtoint i8* %r1563 to i64
  %r1565 = call i64 @_add(i64 %r1562, i64 %r1564)
  %r1566 = load i64, i64* %ptr_NL
  %r1567 = call i64 @_add(i64 %r1565, i64 %r1566)
  store i64 %r1567, i64* %ptr_s
  %r1568 = load i64, i64* %ptr_s
  %r1569 = getelementptr [52 x i8], [52 x i8]* @.str.868, i64 0, i64 0
  %r1570 = ptrtoint i8* %r1569 to i64
  %r1571 = call i64 @_add(i64 %r1568, i64 %r1570)
  %r1572 = load i64, i64* %ptr_NL
  %r1573 = call i64 @_add(i64 %r1571, i64 %r1572)
  store i64 %r1573, i64* %ptr_s
  %r1574 = load i64, i64* %ptr_s
  %r1575 = getelementptr [35 x i8], [35 x i8]* @.str.869, i64 0, i64 0
  %r1576 = ptrtoint i8* %r1575 to i64
  %r1577 = call i64 @_add(i64 %r1574, i64 %r1576)
  %r1578 = load i64, i64* %ptr_NL
  %r1579 = call i64 @_add(i64 %r1577, i64 %r1578)
  store i64 %r1579, i64* %ptr_s
  %r1580 = load i64, i64* %ptr_s
  %r1581 = getelementptr [36 x i8], [36 x i8]* @.str.870, i64 0, i64 0
  %r1582 = ptrtoint i8* %r1581 to i64
  %r1583 = call i64 @_add(i64 %r1580, i64 %r1582)
  %r1584 = load i64, i64* %ptr_NL
  %r1585 = call i64 @_add(i64 %r1583, i64 %r1584)
  store i64 %r1585, i64* %ptr_s
  %r1586 = load i64, i64* %ptr_s
  %r1587 = getelementptr [49 x i8], [49 x i8]* @.str.871, i64 0, i64 0
  %r1588 = ptrtoint i8* %r1587 to i64
  %r1589 = call i64 @_add(i64 %r1586, i64 %r1588)
  %r1590 = load i64, i64* %ptr_NL
  %r1591 = call i64 @_add(i64 %r1589, i64 %r1590)
  store i64 %r1591, i64* %ptr_s
  %r1592 = load i64, i64* %ptr_s
  %r1593 = getelementptr [30 x i8], [30 x i8]* @.str.872, i64 0, i64 0
  %r1594 = ptrtoint i8* %r1593 to i64
  %r1595 = call i64 @_add(i64 %r1592, i64 %r1594)
  %r1596 = load i64, i64* %ptr_NL
  %r1597 = call i64 @_add(i64 %r1595, i64 %r1596)
  store i64 %r1597, i64* %ptr_s
  %r1598 = load i64, i64* %ptr_s
  %r1599 = getelementptr [15 x i8], [15 x i8]* @.str.873, i64 0, i64 0
  %r1600 = ptrtoint i8* %r1599 to i64
  %r1601 = call i64 @_add(i64 %r1598, i64 %r1600)
  %r1602 = load i64, i64* %ptr_NL
  %r1603 = call i64 @_add(i64 %r1601, i64 %r1602)
  store i64 %r1603, i64* %ptr_s
  %r1604 = load i64, i64* %ptr_s
  %r1605 = getelementptr [15 x i8], [15 x i8]* @.str.874, i64 0, i64 0
  %r1606 = ptrtoint i8* %r1605 to i64
  %r1607 = call i64 @_add(i64 %r1604, i64 %r1606)
  %r1608 = load i64, i64* %ptr_NL
  %r1609 = call i64 @_add(i64 %r1607, i64 %r1608)
  store i64 %r1609, i64* %ptr_s
  %r1610 = load i64, i64* %ptr_s
  %r1611 = getelementptr [2 x i8], [2 x i8]* @.str.875, i64 0, i64 0
  %r1612 = ptrtoint i8* %r1611 to i64
  %r1613 = call i64 @_add(i64 %r1610, i64 %r1612)
  %r1614 = load i64, i64* %ptr_NL
  %r1615 = call i64 @_add(i64 %r1613, i64 %r1614)
  store i64 %r1615, i64* %ptr_s
  %r1616 = load i64, i64* %ptr_s
  %r1617 = getelementptr [34 x i8], [34 x i8]* @.str.876, i64 0, i64 0
  %r1618 = ptrtoint i8* %r1617 to i64
  %r1619 = call i64 @_add(i64 %r1616, i64 %r1618)
  %r1620 = load i64, i64* %ptr_NL
  %r1621 = call i64 @_add(i64 %r1619, i64 %r1620)
  store i64 %r1621, i64* %ptr_s
  %r1622 = load i64, i64* %ptr_s
  %r1623 = getelementptr [37 x i8], [37 x i8]* @.str.877, i64 0, i64 0
  %r1624 = ptrtoint i8* %r1623 to i64
  %r1625 = call i64 @_add(i64 %r1622, i64 %r1624)
  %r1626 = load i64, i64* %ptr_NL
  %r1627 = call i64 @_add(i64 %r1625, i64 %r1626)
  store i64 %r1627, i64* %ptr_s
  %r1628 = load i64, i64* %ptr_s
  %r1629 = getelementptr [34 x i8], [34 x i8]* @.str.878, i64 0, i64 0
  %r1630 = ptrtoint i8* %r1629 to i64
  %r1631 = call i64 @_add(i64 %r1628, i64 %r1630)
  %r1632 = load i64, i64* %ptr_NL
  %r1633 = call i64 @_add(i64 %r1631, i64 %r1632)
  store i64 %r1633, i64* %ptr_s
  %r1634 = load i64, i64* %ptr_s
  %r1635 = getelementptr [39 x i8], [39 x i8]* @.str.879, i64 0, i64 0
  %r1636 = ptrtoint i8* %r1635 to i64
  %r1637 = call i64 @_add(i64 %r1634, i64 %r1636)
  %r1638 = load i64, i64* %ptr_NL
  %r1639 = call i64 @_add(i64 %r1637, i64 %r1638)
  store i64 %r1639, i64* %ptr_s
  %r1640 = load i64, i64* %ptr_s
  %r1641 = getelementptr [39 x i8], [39 x i8]* @.str.880, i64 0, i64 0
  %r1642 = ptrtoint i8* %r1641 to i64
  %r1643 = call i64 @_add(i64 %r1640, i64 %r1642)
  %r1644 = load i64, i64* %ptr_NL
  %r1645 = call i64 @_add(i64 %r1643, i64 %r1644)
  store i64 %r1645, i64* %ptr_s
  %r1646 = load i64, i64* %ptr_s
  %r1647 = getelementptr [5 x i8], [5 x i8]* @.str.881, i64 0, i64 0
  %r1648 = ptrtoint i8* %r1647 to i64
  %r1649 = call i64 @_add(i64 %r1646, i64 %r1648)
  %r1650 = load i64, i64* %ptr_NL
  %r1651 = call i64 @_add(i64 %r1649, i64 %r1650)
  store i64 %r1651, i64* %ptr_s
  %r1652 = load i64, i64* %ptr_s
  %r1653 = getelementptr [33 x i8], [33 x i8]* @.str.882, i64 0, i64 0
  %r1654 = ptrtoint i8* %r1653 to i64
  %r1655 = call i64 @_add(i64 %r1652, i64 %r1654)
  %r1656 = load i64, i64* %ptr_NL
  %r1657 = call i64 @_add(i64 %r1655, i64 %r1656)
  store i64 %r1657, i64* %ptr_s
  %r1658 = load i64, i64* %ptr_s
  %r1659 = getelementptr [36 x i8], [36 x i8]* @.str.883, i64 0, i64 0
  %r1660 = ptrtoint i8* %r1659 to i64
  %r1661 = call i64 @_add(i64 %r1658, i64 %r1660)
  %r1662 = load i64, i64* %ptr_NL
  %r1663 = call i64 @_add(i64 %r1661, i64 %r1662)
  store i64 %r1663, i64* %ptr_s
  %r1664 = load i64, i64* %ptr_s
  %r1665 = getelementptr [25 x i8], [25 x i8]* @.str.884, i64 0, i64 0
  %r1666 = ptrtoint i8* %r1665 to i64
  %r1667 = call i64 @_add(i64 %r1664, i64 %r1666)
  %r1668 = load i64, i64* %ptr_NL
  %r1669 = call i64 @_add(i64 %r1667, i64 %r1668)
  store i64 %r1669, i64* %ptr_s
  %r1670 = load i64, i64* %ptr_s
  %r1671 = getelementptr [15 x i8], [15 x i8]* @.str.885, i64 0, i64 0
  %r1672 = ptrtoint i8* %r1671 to i64
  %r1673 = call i64 @_add(i64 %r1670, i64 %r1672)
  %r1674 = load i64, i64* %ptr_NL
  %r1675 = call i64 @_add(i64 %r1673, i64 %r1674)
  store i64 %r1675, i64* %ptr_s
  %r1676 = load i64, i64* %ptr_s
  %r1677 = getelementptr [4 x i8], [4 x i8]* @.str.886, i64 0, i64 0
  %r1678 = ptrtoint i8* %r1677 to i64
  %r1679 = call i64 @_add(i64 %r1676, i64 %r1678)
  %r1680 = load i64, i64* %ptr_NL
  %r1681 = call i64 @_add(i64 %r1679, i64 %r1680)
  store i64 %r1681, i64* %ptr_s
  %r1682 = load i64, i64* %ptr_s
  %r1683 = getelementptr [39 x i8], [39 x i8]* @.str.887, i64 0, i64 0
  %r1684 = ptrtoint i8* %r1683 to i64
  %r1685 = call i64 @_add(i64 %r1682, i64 %r1684)
  %r1686 = load i64, i64* %ptr_NL
  %r1687 = call i64 @_add(i64 %r1685, i64 %r1686)
  store i64 %r1687, i64* %ptr_s
  %r1688 = load i64, i64* %ptr_s
  %r1689 = getelementptr [49 x i8], [49 x i8]* @.str.888, i64 0, i64 0
  %r1690 = ptrtoint i8* %r1689 to i64
  %r1691 = call i64 @_add(i64 %r1688, i64 %r1690)
  %r1692 = load i64, i64* %ptr_NL
  %r1693 = call i64 @_add(i64 %r1691, i64 %r1692)
  store i64 %r1693, i64* %ptr_s
  %r1694 = load i64, i64* %ptr_s
  %r1695 = getelementptr [29 x i8], [29 x i8]* @.str.889, i64 0, i64 0
  %r1696 = ptrtoint i8* %r1695 to i64
  %r1697 = call i64 @_add(i64 %r1694, i64 %r1696)
  %r1698 = load i64, i64* %ptr_NL
  %r1699 = call i64 @_add(i64 %r1697, i64 %r1698)
  store i64 %r1699, i64* %ptr_s
  %r1700 = load i64, i64* %ptr_s
  %r1701 = getelementptr [34 x i8], [34 x i8]* @.str.890, i64 0, i64 0
  %r1702 = ptrtoint i8* %r1701 to i64
  %r1703 = call i64 @_add(i64 %r1700, i64 %r1702)
  %r1704 = load i64, i64* %ptr_NL
  %r1705 = call i64 @_add(i64 %r1703, i64 %r1704)
  store i64 %r1705, i64* %ptr_s
  %r1706 = load i64, i64* %ptr_s
  %r1707 = getelementptr [15 x i8], [15 x i8]* @.str.891, i64 0, i64 0
  %r1708 = ptrtoint i8* %r1707 to i64
  %r1709 = call i64 @_add(i64 %r1706, i64 %r1708)
  %r1710 = load i64, i64* %ptr_NL
  %r1711 = call i64 @_add(i64 %r1709, i64 %r1710)
  store i64 %r1711, i64* %ptr_s
  %r1712 = load i64, i64* %ptr_s
  %r1713 = getelementptr [2 x i8], [2 x i8]* @.str.892, i64 0, i64 0
  %r1714 = ptrtoint i8* %r1713 to i64
  %r1715 = call i64 @_add(i64 %r1712, i64 %r1714)
  %r1716 = load i64, i64* %ptr_NL
  %r1717 = call i64 @_add(i64 %r1715, i64 %r1716)
  store i64 %r1717, i64* %ptr_s
  %r1718 = load i64, i64* %ptr_s
  %r1719 = getelementptr [36 x i8], [36 x i8]* @.str.893, i64 0, i64 0
  %r1720 = ptrtoint i8* %r1719 to i64
  %r1721 = call i64 @_add(i64 %r1718, i64 %r1720)
  %r1722 = load i64, i64* %ptr_NL
  %r1723 = call i64 @_add(i64 %r1721, i64 %r1722)
  store i64 %r1723, i64* %ptr_s
  %r1724 = load i64, i64* %ptr_s
  %r1725 = getelementptr [38 x i8], [38 x i8]* @.str.894, i64 0, i64 0
  %r1726 = ptrtoint i8* %r1725 to i64
  %r1727 = call i64 @_add(i64 %r1724, i64 %r1726)
  %r1728 = load i64, i64* %ptr_NL
  %r1729 = call i64 @_add(i64 %r1727, i64 %r1728)
  store i64 %r1729, i64* %ptr_s
  %r1730 = load i64, i64* %ptr_s
  %r1731 = getelementptr [67 x i8], [67 x i8]* @.str.895, i64 0, i64 0
  %r1732 = ptrtoint i8* %r1731 to i64
  %r1733 = call i64 @_add(i64 %r1730, i64 %r1732)
  %r1734 = load i64, i64* %ptr_NL
  %r1735 = call i64 @_add(i64 %r1733, i64 %r1734)
  store i64 %r1735, i64* %ptr_s
  %r1736 = load i64, i64* %ptr_s
  %r1737 = getelementptr [45 x i8], [45 x i8]* @.str.896, i64 0, i64 0
  %r1738 = ptrtoint i8* %r1737 to i64
  %r1739 = call i64 @_add(i64 %r1736, i64 %r1738)
  %r1740 = load i64, i64* %ptr_NL
  %r1741 = call i64 @_add(i64 %r1739, i64 %r1740)
  store i64 %r1741, i64* %ptr_s
  %r1742 = load i64, i64* %ptr_s
  %r1743 = getelementptr [34 x i8], [34 x i8]* @.str.897, i64 0, i64 0
  %r1744 = ptrtoint i8* %r1743 to i64
  %r1745 = call i64 @_add(i64 %r1742, i64 %r1744)
  %r1746 = load i64, i64* %ptr_NL
  %r1747 = call i64 @_add(i64 %r1745, i64 %r1746)
  store i64 %r1747, i64* %ptr_s
  %r1748 = load i64, i64* %ptr_s
  %r1749 = getelementptr [33 x i8], [33 x i8]* @.str.898, i64 0, i64 0
  %r1750 = ptrtoint i8* %r1749 to i64
  %r1751 = call i64 @_add(i64 %r1748, i64 %r1750)
  %r1752 = load i64, i64* %ptr_NL
  %r1753 = call i64 @_add(i64 %r1751, i64 %r1752)
  store i64 %r1753, i64* %ptr_s
  %r1754 = load i64, i64* %ptr_s
  %r1755 = getelementptr [40 x i8], [40 x i8]* @.str.899, i64 0, i64 0
  %r1756 = ptrtoint i8* %r1755 to i64
  %r1757 = call i64 @_add(i64 %r1754, i64 %r1756)
  %r1758 = load i64, i64* %ptr_NL
  %r1759 = call i64 @_add(i64 %r1757, i64 %r1758)
  store i64 %r1759, i64* %ptr_s
  %r1760 = load i64, i64* %ptr_s
  %r1761 = getelementptr [6 x i8], [6 x i8]* @.str.900, i64 0, i64 0
  %r1762 = ptrtoint i8* %r1761 to i64
  %r1763 = call i64 @_add(i64 %r1760, i64 %r1762)
  %r1764 = load i64, i64* %ptr_NL
  %r1765 = call i64 @_add(i64 %r1763, i64 %r1764)
  store i64 %r1765, i64* %ptr_s
  %r1766 = load i64, i64* %ptr_s
  %r1767 = getelementptr [40 x i8], [40 x i8]* @.str.901, i64 0, i64 0
  %r1768 = ptrtoint i8* %r1767 to i64
  %r1769 = call i64 @_add(i64 %r1766, i64 %r1768)
  %r1770 = load i64, i64* %ptr_NL
  %r1771 = call i64 @_add(i64 %r1769, i64 %r1770)
  store i64 %r1771, i64* %ptr_s
  %r1772 = load i64, i64* %ptr_s
  %r1773 = getelementptr [33 x i8], [33 x i8]* @.str.902, i64 0, i64 0
  %r1774 = ptrtoint i8* %r1773 to i64
  %r1775 = call i64 @_add(i64 %r1772, i64 %r1774)
  %r1776 = load i64, i64* %ptr_NL
  %r1777 = call i64 @_add(i64 %r1775, i64 %r1776)
  store i64 %r1777, i64* %ptr_s
  %r1778 = load i64, i64* %ptr_s
  %r1779 = getelementptr [40 x i8], [40 x i8]* @.str.903, i64 0, i64 0
  %r1780 = ptrtoint i8* %r1779 to i64
  %r1781 = call i64 @_add(i64 %r1778, i64 %r1780)
  %r1782 = load i64, i64* %ptr_NL
  %r1783 = call i64 @_add(i64 %r1781, i64 %r1782)
  store i64 %r1783, i64* %ptr_s
  %r1784 = load i64, i64* %ptr_s
  %r1785 = getelementptr [30 x i8], [30 x i8]* @.str.904, i64 0, i64 0
  %r1786 = ptrtoint i8* %r1785 to i64
  %r1787 = call i64 @_add(i64 %r1784, i64 %r1786)
  %r1788 = load i64, i64* %ptr_NL
  %r1789 = call i64 @_add(i64 %r1787, i64 %r1788)
  store i64 %r1789, i64* %ptr_s
  %r1790 = load i64, i64* %ptr_s
  %r1791 = getelementptr [41 x i8], [41 x i8]* @.str.905, i64 0, i64 0
  %r1792 = ptrtoint i8* %r1791 to i64
  %r1793 = call i64 @_add(i64 %r1790, i64 %r1792)
  %r1794 = load i64, i64* %ptr_NL
  %r1795 = call i64 @_add(i64 %r1793, i64 %r1794)
  store i64 %r1795, i64* %ptr_s
  %r1796 = load i64, i64* %ptr_s
  %r1797 = getelementptr [38 x i8], [38 x i8]* @.str.906, i64 0, i64 0
  %r1798 = ptrtoint i8* %r1797 to i64
  %r1799 = call i64 @_add(i64 %r1796, i64 %r1798)
  %r1800 = load i64, i64* %ptr_NL
  %r1801 = call i64 @_add(i64 %r1799, i64 %r1800)
  store i64 %r1801, i64* %ptr_s
  %r1802 = load i64, i64* %ptr_s
  %r1803 = getelementptr [57 x i8], [57 x i8]* @.str.907, i64 0, i64 0
  %r1804 = ptrtoint i8* %r1803 to i64
  %r1805 = call i64 @_add(i64 %r1802, i64 %r1804)
  %r1806 = load i64, i64* %ptr_NL
  %r1807 = call i64 @_add(i64 %r1805, i64 %r1806)
  store i64 %r1807, i64* %ptr_s
  %r1808 = load i64, i64* %ptr_s
  %r1809 = getelementptr [51 x i8], [51 x i8]* @.str.908, i64 0, i64 0
  %r1810 = ptrtoint i8* %r1809 to i64
  %r1811 = call i64 @_add(i64 %r1808, i64 %r1810)
  %r1812 = load i64, i64* %ptr_NL
  %r1813 = call i64 @_add(i64 %r1811, i64 %r1812)
  store i64 %r1813, i64* %ptr_s
  %r1814 = load i64, i64* %ptr_s
  %r1815 = getelementptr [24 x i8], [24 x i8]* @.str.909, i64 0, i64 0
  %r1816 = ptrtoint i8* %r1815 to i64
  %r1817 = call i64 @_add(i64 %r1814, i64 %r1816)
  %r1818 = load i64, i64* %ptr_NL
  %r1819 = call i64 @_add(i64 %r1817, i64 %r1818)
  store i64 %r1819, i64* %ptr_s
  %r1820 = load i64, i64* %ptr_s
  %r1821 = getelementptr [27 x i8], [27 x i8]* @.str.910, i64 0, i64 0
  %r1822 = ptrtoint i8* %r1821 to i64
  %r1823 = call i64 @_add(i64 %r1820, i64 %r1822)
  %r1824 = load i64, i64* %ptr_NL
  %r1825 = call i64 @_add(i64 %r1823, i64 %r1824)
  store i64 %r1825, i64* %ptr_s
  %r1826 = load i64, i64* %ptr_s
  %r1827 = getelementptr [15 x i8], [15 x i8]* @.str.911, i64 0, i64 0
  %r1828 = ptrtoint i8* %r1827 to i64
  %r1829 = call i64 @_add(i64 %r1826, i64 %r1828)
  %r1830 = load i64, i64* %ptr_NL
  %r1831 = call i64 @_add(i64 %r1829, i64 %r1830)
  store i64 %r1831, i64* %ptr_s
  %r1832 = load i64, i64* %ptr_s
  %r1833 = getelementptr [5 x i8], [5 x i8]* @.str.912, i64 0, i64 0
  %r1834 = ptrtoint i8* %r1833 to i64
  %r1835 = call i64 @_add(i64 %r1832, i64 %r1834)
  %r1836 = load i64, i64* %ptr_NL
  %r1837 = call i64 @_add(i64 %r1835, i64 %r1836)
  store i64 %r1837, i64* %ptr_s
  %r1838 = load i64, i64* %ptr_s
  %r1839 = getelementptr [12 x i8], [12 x i8]* @.str.913, i64 0, i64 0
  %r1840 = ptrtoint i8* %r1839 to i64
  %r1841 = call i64 @_add(i64 %r1838, i64 %r1840)
  %r1842 = load i64, i64* %ptr_NL
  %r1843 = call i64 @_add(i64 %r1841, i64 %r1842)
  store i64 %r1843, i64* %ptr_s
  %r1844 = load i64, i64* %ptr_s
  %r1845 = getelementptr [2 x i8], [2 x i8]* @.str.914, i64 0, i64 0
  %r1846 = ptrtoint i8* %r1845 to i64
  %r1847 = call i64 @_add(i64 %r1844, i64 %r1846)
  %r1848 = load i64, i64* %ptr_NL
  %r1849 = call i64 @_add(i64 %r1847, i64 %r1848)
  store i64 %r1849, i64* %ptr_s
  %r1850 = load i64, i64* %ptr_s
  %r1851 = getelementptr [52 x i8], [52 x i8]* @.str.915, i64 0, i64 0
  %r1852 = ptrtoint i8* %r1851 to i64
  %r1853 = call i64 @_add(i64 %r1850, i64 %r1852)
  %r1854 = load i64, i64* %ptr_NL
  %r1855 = call i64 @_add(i64 %r1853, i64 %r1854)
  store i64 %r1855, i64* %ptr_s
  %r1856 = load i64, i64* %ptr_s
  %r1857 = getelementptr [38 x i8], [38 x i8]* @.str.916, i64 0, i64 0
  %r1858 = ptrtoint i8* %r1857 to i64
  %r1859 = call i64 @_add(i64 %r1856, i64 %r1858)
  %r1860 = load i64, i64* %ptr_NL
  %r1861 = call i64 @_add(i64 %r1859, i64 %r1860)
  store i64 %r1861, i64* %ptr_s
  %r1862 = load i64, i64* %ptr_s
  %r1863 = getelementptr [44 x i8], [44 x i8]* @.str.917, i64 0, i64 0
  %r1864 = ptrtoint i8* %r1863 to i64
  %r1865 = call i64 @_add(i64 %r1862, i64 %r1864)
  %r1866 = load i64, i64* %ptr_NL
  %r1867 = call i64 @_add(i64 %r1865, i64 %r1866)
  store i64 %r1867, i64* %ptr_s
  %r1868 = load i64, i64* %ptr_s
  %r1869 = getelementptr [67 x i8], [67 x i8]* @.str.918, i64 0, i64 0
  %r1870 = ptrtoint i8* %r1869 to i64
  %r1871 = call i64 @_add(i64 %r1868, i64 %r1870)
  %r1872 = load i64, i64* %ptr_NL
  %r1873 = call i64 @_add(i64 %r1871, i64 %r1872)
  store i64 %r1873, i64* %ptr_s
  %r1874 = load i64, i64* %ptr_s
  %r1875 = getelementptr [45 x i8], [45 x i8]* @.str.919, i64 0, i64 0
  %r1876 = ptrtoint i8* %r1875 to i64
  %r1877 = call i64 @_add(i64 %r1874, i64 %r1876)
  %r1878 = load i64, i64* %ptr_NL
  %r1879 = call i64 @_add(i64 %r1877, i64 %r1878)
  store i64 %r1879, i64* %ptr_s
  %r1880 = load i64, i64* %ptr_s
  %r1881 = getelementptr [40 x i8], [40 x i8]* @.str.920, i64 0, i64 0
  %r1882 = ptrtoint i8* %r1881 to i64
  %r1883 = call i64 @_add(i64 %r1880, i64 %r1882)
  %r1884 = load i64, i64* %ptr_NL
  %r1885 = call i64 @_add(i64 %r1883, i64 %r1884)
  store i64 %r1885, i64* %ptr_s
  %r1886 = load i64, i64* %ptr_s
  %r1887 = getelementptr [58 x i8], [58 x i8]* @.str.921, i64 0, i64 0
  %r1888 = ptrtoint i8* %r1887 to i64
  %r1889 = call i64 @_add(i64 %r1886, i64 %r1888)
  %r1890 = load i64, i64* %ptr_NL
  %r1891 = call i64 @_add(i64 %r1889, i64 %r1890)
  store i64 %r1891, i64* %ptr_s
  %r1892 = load i64, i64* %ptr_s
  %r1893 = getelementptr [27 x i8], [27 x i8]* @.str.922, i64 0, i64 0
  %r1894 = ptrtoint i8* %r1893 to i64
  %r1895 = call i64 @_add(i64 %r1892, i64 %r1894)
  %r1896 = load i64, i64* %ptr_NL
  %r1897 = call i64 @_add(i64 %r1895, i64 %r1896)
  store i64 %r1897, i64* %ptr_s
  %r1898 = load i64, i64* %ptr_s
  %r1899 = getelementptr [12 x i8], [12 x i8]* @.str.923, i64 0, i64 0
  %r1900 = ptrtoint i8* %r1899 to i64
  %r1901 = call i64 @_add(i64 %r1898, i64 %r1900)
  %r1902 = load i64, i64* %ptr_NL
  %r1903 = call i64 @_add(i64 %r1901, i64 %r1902)
  store i64 %r1903, i64* %ptr_s
  %r1904 = load i64, i64* %ptr_s
  %r1905 = getelementptr [2 x i8], [2 x i8]* @.str.924, i64 0, i64 0
  %r1906 = ptrtoint i8* %r1905 to i64
  %r1907 = call i64 @_add(i64 %r1904, i64 %r1906)
  %r1908 = load i64, i64* %ptr_NL
  %r1909 = call i64 @_add(i64 %r1907, i64 %r1908)
  store i64 %r1909, i64* %ptr_s
  %r1910 = load i64, i64* %ptr_s
  %r1911 = getelementptr [34 x i8], [34 x i8]* @.str.925, i64 0, i64 0
  %r1912 = ptrtoint i8* %r1911 to i64
  %r1913 = call i64 @_add(i64 %r1910, i64 %r1912)
  %r1914 = load i64, i64* %ptr_NL
  %r1915 = call i64 @_add(i64 %r1913, i64 %r1914)
  store i64 %r1915, i64* %ptr_s
  %r1916 = load i64, i64* %ptr_s
  %r1917 = getelementptr [7 x i8], [7 x i8]* @.str.926, i64 0, i64 0
  %r1918 = ptrtoint i8* %r1917 to i64
  %r1919 = call i64 @_add(i64 %r1916, i64 %r1918)
  %r1920 = load i64, i64* %ptr_NL
  %r1921 = call i64 @_add(i64 %r1919, i64 %r1920)
  store i64 %r1921, i64* %ptr_s
  %r1922 = load i64, i64* %ptr_s
  %r1923 = getelementptr [42 x i8], [42 x i8]* @.str.927, i64 0, i64 0
  %r1924 = ptrtoint i8* %r1923 to i64
  %r1925 = call i64 @_add(i64 %r1922, i64 %r1924)
  %r1926 = load i64, i64* %ptr_NL
  %r1927 = call i64 @_add(i64 %r1925, i64 %r1926)
  store i64 %r1927, i64* %ptr_s
  %r1928 = load i64, i64* %ptr_s
  %r1929 = getelementptr [52 x i8], [52 x i8]* @.str.928, i64 0, i64 0
  %r1930 = ptrtoint i8* %r1929 to i64
  %r1931 = call i64 @_add(i64 %r1928, i64 %r1930)
  %r1932 = load i64, i64* %ptr_NL
  %r1933 = call i64 @_add(i64 %r1931, i64 %r1932)
  store i64 %r1933, i64* %ptr_s
  %r1934 = load i64, i64* %ptr_s
  %r1935 = getelementptr [11 x i8], [11 x i8]* @.str.929, i64 0, i64 0
  %r1936 = ptrtoint i8* %r1935 to i64
  %r1937 = call i64 @_add(i64 %r1934, i64 %r1936)
  %r1938 = load i64, i64* %ptr_NL
  %r1939 = call i64 @_add(i64 %r1937, i64 %r1938)
  store i64 %r1939, i64* %ptr_s
  %r1940 = load i64, i64* %ptr_s
  %r1941 = getelementptr [35 x i8], [35 x i8]* @.str.930, i64 0, i64 0
  %r1942 = ptrtoint i8* %r1941 to i64
  %r1943 = call i64 @_add(i64 %r1940, i64 %r1942)
  %r1944 = load i64, i64* %ptr_NL
  %r1945 = call i64 @_add(i64 %r1943, i64 %r1944)
  store i64 %r1945, i64* %ptr_s
  %r1946 = load i64, i64* %ptr_s
  %r1947 = getelementptr [28 x i8], [28 x i8]* @.str.931, i64 0, i64 0
  %r1948 = ptrtoint i8* %r1947 to i64
  %r1949 = call i64 @_add(i64 %r1946, i64 %r1948)
  %r1950 = load i64, i64* %ptr_NL
  %r1951 = call i64 @_add(i64 %r1949, i64 %r1950)
  store i64 %r1951, i64* %ptr_s
  %r1952 = load i64, i64* %ptr_s
  %r1953 = getelementptr [32 x i8], [32 x i8]* @.str.932, i64 0, i64 0
  %r1954 = ptrtoint i8* %r1953 to i64
  %r1955 = call i64 @_add(i64 %r1952, i64 %r1954)
  %r1956 = load i64, i64* %ptr_NL
  %r1957 = call i64 @_add(i64 %r1955, i64 %r1956)
  store i64 %r1957, i64* %ptr_s
  %r1958 = load i64, i64* %ptr_s
  %r1959 = getelementptr [54 x i8], [54 x i8]* @.str.933, i64 0, i64 0
  %r1960 = ptrtoint i8* %r1959 to i64
  %r1961 = call i64 @_add(i64 %r1958, i64 %r1960)
  %r1962 = load i64, i64* %ptr_NL
  %r1963 = call i64 @_add(i64 %r1961, i64 %r1962)
  store i64 %r1963, i64* %ptr_s
  %r1964 = load i64, i64* %ptr_s
  %r1965 = getelementptr [12 x i8], [12 x i8]* @.str.934, i64 0, i64 0
  %r1966 = ptrtoint i8* %r1965 to i64
  %r1967 = call i64 @_add(i64 %r1964, i64 %r1966)
  %r1968 = load i64, i64* %ptr_NL
  %r1969 = call i64 @_add(i64 %r1967, i64 %r1968)
  store i64 %r1969, i64* %ptr_s
  %r1970 = load i64, i64* %ptr_s
  %r1971 = getelementptr [70 x i8], [70 x i8]* @.str.935, i64 0, i64 0
  %r1972 = ptrtoint i8* %r1971 to i64
  %r1973 = call i64 @_add(i64 %r1970, i64 %r1972)
  %r1974 = load i64, i64* %ptr_NL
  %r1975 = call i64 @_add(i64 %r1973, i64 %r1974)
  store i64 %r1975, i64* %ptr_s
  %r1976 = load i64, i64* %ptr_s
  %r1977 = getelementptr [67 x i8], [67 x i8]* @.str.936, i64 0, i64 0
  %r1978 = ptrtoint i8* %r1977 to i64
  %r1979 = call i64 @_add(i64 %r1976, i64 %r1978)
  %r1980 = load i64, i64* %ptr_NL
  %r1981 = call i64 @_add(i64 %r1979, i64 %r1980)
  store i64 %r1981, i64* %ptr_s
  %r1982 = load i64, i64* %ptr_s
  %r1983 = getelementptr [51 x i8], [51 x i8]* @.str.937, i64 0, i64 0
  %r1984 = ptrtoint i8* %r1983 to i64
  %r1985 = call i64 @_add(i64 %r1982, i64 %r1984)
  %r1986 = load i64, i64* %ptr_NL
  %r1987 = call i64 @_add(i64 %r1985, i64 %r1986)
  store i64 %r1987, i64* %ptr_s
  %r1988 = load i64, i64* %ptr_s
  %r1989 = getelementptr [29 x i8], [29 x i8]* @.str.938, i64 0, i64 0
  %r1990 = ptrtoint i8* %r1989 to i64
  %r1991 = call i64 @_add(i64 %r1988, i64 %r1990)
  %r1992 = load i64, i64* %ptr_NL
  %r1993 = call i64 @_add(i64 %r1991, i64 %r1992)
  store i64 %r1993, i64* %ptr_s
  %r1994 = load i64, i64* %ptr_s
  %r1995 = getelementptr [37 x i8], [37 x i8]* @.str.939, i64 0, i64 0
  %r1996 = ptrtoint i8* %r1995 to i64
  %r1997 = call i64 @_add(i64 %r1994, i64 %r1996)
  %r1998 = load i64, i64* %ptr_NL
  %r1999 = call i64 @_add(i64 %r1997, i64 %r1998)
  store i64 %r1999, i64* %ptr_s
  %r2000 = load i64, i64* %ptr_s
  %r2001 = getelementptr [51 x i8], [51 x i8]* @.str.940, i64 0, i64 0
  %r2002 = ptrtoint i8* %r2001 to i64
  %r2003 = call i64 @_add(i64 %r2000, i64 %r2002)
  %r2004 = load i64, i64* %ptr_NL
  %r2005 = call i64 @_add(i64 %r2003, i64 %r2004)
  store i64 %r2005, i64* %ptr_s
  %r2006 = load i64, i64* %ptr_s
  %r2007 = getelementptr [33 x i8], [33 x i8]* @.str.941, i64 0, i64 0
  %r2008 = ptrtoint i8* %r2007 to i64
  %r2009 = call i64 @_add(i64 %r2006, i64 %r2008)
  %r2010 = load i64, i64* %ptr_NL
  %r2011 = call i64 @_add(i64 %r2009, i64 %r2010)
  store i64 %r2011, i64* %ptr_s
  %r2012 = load i64, i64* %ptr_s
  %r2013 = getelementptr [34 x i8], [34 x i8]* @.str.942, i64 0, i64 0
  %r2014 = ptrtoint i8* %r2013 to i64
  %r2015 = call i64 @_add(i64 %r2012, i64 %r2014)
  %r2016 = load i64, i64* %ptr_NL
  %r2017 = call i64 @_add(i64 %r2015, i64 %r2016)
  store i64 %r2017, i64* %ptr_s
  %r2018 = load i64, i64* %ptr_s
  %r2019 = getelementptr [50 x i8], [50 x i8]* @.str.943, i64 0, i64 0
  %r2020 = ptrtoint i8* %r2019 to i64
  %r2021 = call i64 @_add(i64 %r2018, i64 %r2020)
  %r2022 = load i64, i64* %ptr_NL
  %r2023 = call i64 @_add(i64 %r2021, i64 %r2022)
  store i64 %r2023, i64* %ptr_s
  %r2024 = load i64, i64* %ptr_s
  %r2025 = getelementptr [12 x i8], [12 x i8]* @.str.944, i64 0, i64 0
  %r2026 = ptrtoint i8* %r2025 to i64
  %r2027 = call i64 @_add(i64 %r2024, i64 %r2026)
  %r2028 = load i64, i64* %ptr_NL
  %r2029 = call i64 @_add(i64 %r2027, i64 %r2028)
  store i64 %r2029, i64* %ptr_s
  %r2030 = load i64, i64* %ptr_s
  %r2031 = getelementptr [52 x i8], [52 x i8]* @.str.945, i64 0, i64 0
  %r2032 = ptrtoint i8* %r2031 to i64
  %r2033 = call i64 @_add(i64 %r2030, i64 %r2032)
  %r2034 = load i64, i64* %ptr_NL
  %r2035 = call i64 @_add(i64 %r2033, i64 %r2034)
  store i64 %r2035, i64* %ptr_s
  %r2036 = load i64, i64* %ptr_s
  %r2037 = getelementptr [35 x i8], [35 x i8]* @.str.946, i64 0, i64 0
  %r2038 = ptrtoint i8* %r2037 to i64
  %r2039 = call i64 @_add(i64 %r2036, i64 %r2038)
  %r2040 = load i64, i64* %ptr_NL
  %r2041 = call i64 @_add(i64 %r2039, i64 %r2040)
  store i64 %r2041, i64* %ptr_s
  %r2042 = load i64, i64* %ptr_s
  %r2043 = getelementptr [41 x i8], [41 x i8]* @.str.947, i64 0, i64 0
  %r2044 = ptrtoint i8* %r2043 to i64
  %r2045 = call i64 @_add(i64 %r2042, i64 %r2044)
  %r2046 = load i64, i64* %ptr_NL
  %r2047 = call i64 @_add(i64 %r2045, i64 %r2046)
  store i64 %r2047, i64* %ptr_s
  %r2048 = load i64, i64* %ptr_s
  %r2049 = getelementptr [17 x i8], [17 x i8]* @.str.948, i64 0, i64 0
  %r2050 = ptrtoint i8* %r2049 to i64
  %r2051 = call i64 @_add(i64 %r2048, i64 %r2050)
  %r2052 = load i64, i64* %ptr_NL
  %r2053 = call i64 @_add(i64 %r2051, i64 %r2052)
  store i64 %r2053, i64* %ptr_s
  %r2054 = load i64, i64* %ptr_s
  %r2055 = getelementptr [6 x i8], [6 x i8]* @.str.949, i64 0, i64 0
  %r2056 = ptrtoint i8* %r2055 to i64
  %r2057 = call i64 @_add(i64 %r2054, i64 %r2056)
  %r2058 = load i64, i64* %ptr_NL
  %r2059 = call i64 @_add(i64 %r2057, i64 %r2058)
  store i64 %r2059, i64* %ptr_s
  %r2060 = load i64, i64* %ptr_s
  %r2061 = getelementptr [58 x i8], [58 x i8]* @.str.950, i64 0, i64 0
  %r2062 = ptrtoint i8* %r2061 to i64
  %r2063 = call i64 @_add(i64 %r2060, i64 %r2062)
  %r2064 = load i64, i64* %ptr_NL
  %r2065 = call i64 @_add(i64 %r2063, i64 %r2064)
  store i64 %r2065, i64* %ptr_s
  %r2066 = load i64, i64* %ptr_s
  %r2067 = getelementptr [32 x i8], [32 x i8]* @.str.951, i64 0, i64 0
  %r2068 = ptrtoint i8* %r2067 to i64
  %r2069 = call i64 @_add(i64 %r2066, i64 %r2068)
  %r2070 = load i64, i64* %ptr_NL
  %r2071 = call i64 @_add(i64 %r2069, i64 %r2070)
  store i64 %r2071, i64* %ptr_s
  %r2072 = load i64, i64* %ptr_s
  %r2073 = getelementptr [40 x i8], [40 x i8]* @.str.952, i64 0, i64 0
  %r2074 = ptrtoint i8* %r2073 to i64
  %r2075 = call i64 @_add(i64 %r2072, i64 %r2074)
  %r2076 = load i64, i64* %ptr_NL
  %r2077 = call i64 @_add(i64 %r2075, i64 %r2076)
  store i64 %r2077, i64* %ptr_s
  %r2078 = load i64, i64* %ptr_s
  %r2079 = getelementptr [6 x i8], [6 x i8]* @.str.953, i64 0, i64 0
  %r2080 = ptrtoint i8* %r2079 to i64
  %r2081 = call i64 @_add(i64 %r2078, i64 %r2080)
  %r2082 = load i64, i64* %ptr_NL
  %r2083 = call i64 @_add(i64 %r2081, i64 %r2082)
  store i64 %r2083, i64* %ptr_s
  %r2084 = load i64, i64* %ptr_s
  %r2085 = getelementptr [33 x i8], [33 x i8]* @.str.954, i64 0, i64 0
  %r2086 = ptrtoint i8* %r2085 to i64
  %r2087 = call i64 @_add(i64 %r2084, i64 %r2086)
  %r2088 = load i64, i64* %ptr_NL
  %r2089 = call i64 @_add(i64 %r2087, i64 %r2088)
  store i64 %r2089, i64* %ptr_s
  %r2090 = load i64, i64* %ptr_s
  %r2091 = getelementptr [51 x i8], [51 x i8]* @.str.955, i64 0, i64 0
  %r2092 = ptrtoint i8* %r2091 to i64
  %r2093 = call i64 @_add(i64 %r2090, i64 %r2092)
  %r2094 = load i64, i64* %ptr_NL
  %r2095 = call i64 @_add(i64 %r2093, i64 %r2094)
  store i64 %r2095, i64* %ptr_s
  %r2096 = load i64, i64* %ptr_s
  %r2097 = getelementptr [7 x i8], [7 x i8]* @.str.956, i64 0, i64 0
  %r2098 = ptrtoint i8* %r2097 to i64
  %r2099 = call i64 @_add(i64 %r2096, i64 %r2098)
  %r2100 = load i64, i64* %ptr_NL
  %r2101 = call i64 @_add(i64 %r2099, i64 %r2100)
  store i64 %r2101, i64* %ptr_s
  %r2102 = load i64, i64* %ptr_s
  %r2103 = getelementptr [70 x i8], [70 x i8]* @.str.957, i64 0, i64 0
  %r2104 = ptrtoint i8* %r2103 to i64
  %r2105 = call i64 @_add(i64 %r2102, i64 %r2104)
  %r2106 = load i64, i64* %ptr_NL
  %r2107 = call i64 @_add(i64 %r2105, i64 %r2106)
  store i64 %r2107, i64* %ptr_s
  %r2108 = load i64, i64* %ptr_s
  %r2109 = getelementptr [67 x i8], [67 x i8]* @.str.958, i64 0, i64 0
  %r2110 = ptrtoint i8* %r2109 to i64
  %r2111 = call i64 @_add(i64 %r2108, i64 %r2110)
  %r2112 = load i64, i64* %ptr_NL
  %r2113 = call i64 @_add(i64 %r2111, i64 %r2112)
  store i64 %r2113, i64* %ptr_s
  %r2114 = load i64, i64* %ptr_s
  %r2115 = getelementptr [51 x i8], [51 x i8]* @.str.959, i64 0, i64 0
  %r2116 = ptrtoint i8* %r2115 to i64
  %r2117 = call i64 @_add(i64 %r2114, i64 %r2116)
  %r2118 = load i64, i64* %ptr_NL
  %r2119 = call i64 @_add(i64 %r2117, i64 %r2118)
  store i64 %r2119, i64* %ptr_s
  %r2120 = load i64, i64* %ptr_s
  %r2121 = getelementptr [29 x i8], [29 x i8]* @.str.960, i64 0, i64 0
  %r2122 = ptrtoint i8* %r2121 to i64
  %r2123 = call i64 @_add(i64 %r2120, i64 %r2122)
  %r2124 = load i64, i64* %ptr_NL
  %r2125 = call i64 @_add(i64 %r2123, i64 %r2124)
  store i64 %r2125, i64* %ptr_s
  %r2126 = load i64, i64* %ptr_s
  %r2127 = getelementptr [22 x i8], [22 x i8]* @.str.961, i64 0, i64 0
  %r2128 = ptrtoint i8* %r2127 to i64
  %r2129 = call i64 @_add(i64 %r2126, i64 %r2128)
  %r2130 = load i64, i64* %ptr_NL
  %r2131 = call i64 @_add(i64 %r2129, i64 %r2130)
  store i64 %r2131, i64* %ptr_s
  %r2132 = load i64, i64* %ptr_s
  %r2133 = getelementptr [11 x i8], [11 x i8]* @.str.962, i64 0, i64 0
  %r2134 = ptrtoint i8* %r2133 to i64
  %r2135 = call i64 @_add(i64 %r2132, i64 %r2134)
  %r2136 = load i64, i64* %ptr_NL
  %r2137 = call i64 @_add(i64 %r2135, i64 %r2136)
  store i64 %r2137, i64* %ptr_s
  %r2138 = load i64, i64* %ptr_s
  %r2139 = getelementptr [52 x i8], [52 x i8]* @.str.963, i64 0, i64 0
  %r2140 = ptrtoint i8* %r2139 to i64
  %r2141 = call i64 @_add(i64 %r2138, i64 %r2140)
  %r2142 = load i64, i64* %ptr_NL
  %r2143 = call i64 @_add(i64 %r2141, i64 %r2142)
  store i64 %r2143, i64* %ptr_s
  %r2144 = load i64, i64* %ptr_s
  %r2145 = getelementptr [28 x i8], [28 x i8]* @.str.964, i64 0, i64 0
  %r2146 = ptrtoint i8* %r2145 to i64
  %r2147 = call i64 @_add(i64 %r2144, i64 %r2146)
  %r2148 = load i64, i64* %ptr_NL
  %r2149 = call i64 @_add(i64 %r2147, i64 %r2148)
  store i64 %r2149, i64* %ptr_s
  %r2150 = load i64, i64* %ptr_s
  %r2151 = getelementptr [42 x i8], [42 x i8]* @.str.965, i64 0, i64 0
  %r2152 = ptrtoint i8* %r2151 to i64
  %r2153 = call i64 @_add(i64 %r2150, i64 %r2152)
  %r2154 = load i64, i64* %ptr_NL
  %r2155 = call i64 @_add(i64 %r2153, i64 %r2154)
  store i64 %r2155, i64* %ptr_s
  %r2156 = load i64, i64* %ptr_s
  %r2157 = getelementptr [52 x i8], [52 x i8]* @.str.966, i64 0, i64 0
  %r2158 = ptrtoint i8* %r2157 to i64
  %r2159 = call i64 @_add(i64 %r2156, i64 %r2158)
  %r2160 = load i64, i64* %ptr_NL
  %r2161 = call i64 @_add(i64 %r2159, i64 %r2160)
  store i64 %r2161, i64* %ptr_s
  %r2162 = load i64, i64* %ptr_s
  %r2163 = getelementptr [13 x i8], [13 x i8]* @.str.967, i64 0, i64 0
  %r2164 = ptrtoint i8* %r2163 to i64
  %r2165 = call i64 @_add(i64 %r2162, i64 %r2164)
  %r2166 = load i64, i64* %ptr_NL
  %r2167 = call i64 @_add(i64 %r2165, i64 %r2166)
  store i64 %r2167, i64* %ptr_s
  %r2168 = load i64, i64* %ptr_s
  %r2169 = getelementptr [36 x i8], [36 x i8]* @.str.968, i64 0, i64 0
  %r2170 = ptrtoint i8* %r2169 to i64
  %r2171 = call i64 @_add(i64 %r2168, i64 %r2170)
  %r2172 = load i64, i64* %ptr_NL
  %r2173 = call i64 @_add(i64 %r2171, i64 %r2172)
  store i64 %r2173, i64* %ptr_s
  %r2174 = load i64, i64* %ptr_s
  %r2175 = getelementptr [34 x i8], [34 x i8]* @.str.969, i64 0, i64 0
  %r2176 = ptrtoint i8* %r2175 to i64
  %r2177 = call i64 @_add(i64 %r2174, i64 %r2176)
  %r2178 = load i64, i64* %ptr_NL
  %r2179 = call i64 @_add(i64 %r2177, i64 %r2178)
  store i64 %r2179, i64* %ptr_s
  %r2180 = load i64, i64* %ptr_s
  %r2181 = getelementptr [38 x i8], [38 x i8]* @.str.970, i64 0, i64 0
  %r2182 = ptrtoint i8* %r2181 to i64
  %r2183 = call i64 @_add(i64 %r2180, i64 %r2182)
  %r2184 = load i64, i64* %ptr_NL
  %r2185 = call i64 @_add(i64 %r2183, i64 %r2184)
  store i64 %r2185, i64* %ptr_s
  %r2186 = load i64, i64* %ptr_s
  %r2187 = getelementptr [55 x i8], [55 x i8]* @.str.971, i64 0, i64 0
  %r2188 = ptrtoint i8* %r2187 to i64
  %r2189 = call i64 @_add(i64 %r2186, i64 %r2188)
  %r2190 = load i64, i64* %ptr_NL
  %r2191 = call i64 @_add(i64 %r2189, i64 %r2190)
  store i64 %r2191, i64* %ptr_s
  %r2192 = load i64, i64* %ptr_s
  %r2193 = getelementptr [10 x i8], [10 x i8]* @.str.972, i64 0, i64 0
  %r2194 = ptrtoint i8* %r2193 to i64
  %r2195 = call i64 @_add(i64 %r2192, i64 %r2194)
  %r2196 = load i64, i64* %ptr_NL
  %r2197 = call i64 @_add(i64 %r2195, i64 %r2196)
  store i64 %r2197, i64* %ptr_s
  %r2198 = load i64, i64* %ptr_s
  %r2199 = getelementptr [30 x i8], [30 x i8]* @.str.973, i64 0, i64 0
  %r2200 = ptrtoint i8* %r2199 to i64
  %r2201 = call i64 @_add(i64 %r2198, i64 %r2200)
  %r2202 = load i64, i64* %ptr_NL
  %r2203 = call i64 @_add(i64 %r2201, i64 %r2202)
  store i64 %r2203, i64* %ptr_s
  %r2204 = load i64, i64* %ptr_s
  %r2205 = getelementptr [21 x i8], [21 x i8]* @.str.974, i64 0, i64 0
  %r2206 = ptrtoint i8* %r2205 to i64
  %r2207 = call i64 @_add(i64 %r2204, i64 %r2206)
  %r2208 = load i64, i64* %ptr_NL
  %r2209 = call i64 @_add(i64 %r2207, i64 %r2208)
  store i64 %r2209, i64* %ptr_s
  %r2210 = load i64, i64* %ptr_s
  %r2211 = getelementptr [11 x i8], [11 x i8]* @.str.975, i64 0, i64 0
  %r2212 = ptrtoint i8* %r2211 to i64
  %r2213 = call i64 @_add(i64 %r2210, i64 %r2212)
  %r2214 = load i64, i64* %ptr_NL
  %r2215 = call i64 @_add(i64 %r2213, i64 %r2214)
  store i64 %r2215, i64* %ptr_s
  %r2216 = load i64, i64* %ptr_s
  %r2217 = getelementptr [70 x i8], [70 x i8]* @.str.976, i64 0, i64 0
  %r2218 = ptrtoint i8* %r2217 to i64
  %r2219 = call i64 @_add(i64 %r2216, i64 %r2218)
  %r2220 = load i64, i64* %ptr_NL
  %r2221 = call i64 @_add(i64 %r2219, i64 %r2220)
  store i64 %r2221, i64* %ptr_s
  %r2222 = load i64, i64* %ptr_s
  %r2223 = getelementptr [35 x i8], [35 x i8]* @.str.977, i64 0, i64 0
  %r2224 = ptrtoint i8* %r2223 to i64
  %r2225 = call i64 @_add(i64 %r2222, i64 %r2224)
  %r2226 = load i64, i64* %ptr_NL
  %r2227 = call i64 @_add(i64 %r2225, i64 %r2226)
  store i64 %r2227, i64* %ptr_s
  %r2228 = load i64, i64* %ptr_s
  %r2229 = getelementptr [54 x i8], [54 x i8]* @.str.978, i64 0, i64 0
  %r2230 = ptrtoint i8* %r2229 to i64
  %r2231 = call i64 @_add(i64 %r2228, i64 %r2230)
  %r2232 = load i64, i64* %ptr_NL
  %r2233 = call i64 @_add(i64 %r2231, i64 %r2232)
  store i64 %r2233, i64* %ptr_s
  %r2234 = load i64, i64* %ptr_s
  %r2235 = getelementptr [29 x i8], [29 x i8]* @.str.979, i64 0, i64 0
  %r2236 = ptrtoint i8* %r2235 to i64
  %r2237 = call i64 @_add(i64 %r2234, i64 %r2236)
  %r2238 = load i64, i64* %ptr_NL
  %r2239 = call i64 @_add(i64 %r2237, i64 %r2238)
  store i64 %r2239, i64* %ptr_s
  %r2240 = load i64, i64* %ptr_s
  %r2241 = getelementptr [21 x i8], [21 x i8]* @.str.980, i64 0, i64 0
  %r2242 = ptrtoint i8* %r2241 to i64
  %r2243 = call i64 @_add(i64 %r2240, i64 %r2242)
  %r2244 = load i64, i64* %ptr_NL
  %r2245 = call i64 @_add(i64 %r2243, i64 %r2244)
  store i64 %r2245, i64* %ptr_s
  %r2246 = load i64, i64* %ptr_s
  %r2247 = getelementptr [7 x i8], [7 x i8]* @.str.981, i64 0, i64 0
  %r2248 = ptrtoint i8* %r2247 to i64
  %r2249 = call i64 @_add(i64 %r2246, i64 %r2248)
  %r2250 = load i64, i64* %ptr_NL
  %r2251 = call i64 @_add(i64 %r2249, i64 %r2250)
  store i64 %r2251, i64* %ptr_s
  %r2252 = load i64, i64* %ptr_s
  %r2253 = getelementptr [69 x i8], [69 x i8]* @.str.982, i64 0, i64 0
  %r2254 = ptrtoint i8* %r2253 to i64
  %r2255 = call i64 @_add(i64 %r2252, i64 %r2254)
  %r2256 = load i64, i64* %ptr_NL
  %r2257 = call i64 @_add(i64 %r2255, i64 %r2256)
  store i64 %r2257, i64* %ptr_s
  %r2258 = load i64, i64* %ptr_s
  %r2259 = getelementptr [48 x i8], [48 x i8]* @.str.983, i64 0, i64 0
  %r2260 = ptrtoint i8* %r2259 to i64
  %r2261 = call i64 @_add(i64 %r2258, i64 %r2260)
  %r2262 = load i64, i64* %ptr_NL
  %r2263 = call i64 @_add(i64 %r2261, i64 %r2262)
  store i64 %r2263, i64* %ptr_s
  %r2264 = load i64, i64* %ptr_s
  %r2265 = getelementptr [29 x i8], [29 x i8]* @.str.984, i64 0, i64 0
  %r2266 = ptrtoint i8* %r2265 to i64
  %r2267 = call i64 @_add(i64 %r2264, i64 %r2266)
  %r2268 = load i64, i64* %ptr_NL
  %r2269 = call i64 @_add(i64 %r2267, i64 %r2268)
  store i64 %r2269, i64* %ptr_s
  %r2270 = load i64, i64* %ptr_s
  %r2271 = getelementptr [21 x i8], [21 x i8]* @.str.985, i64 0, i64 0
  %r2272 = ptrtoint i8* %r2271 to i64
  %r2273 = call i64 @_add(i64 %r2270, i64 %r2272)
  %r2274 = load i64, i64* %ptr_NL
  %r2275 = call i64 @_add(i64 %r2273, i64 %r2274)
  store i64 %r2275, i64* %ptr_s
  %r2276 = load i64, i64* %ptr_s
  %r2277 = getelementptr [10 x i8], [10 x i8]* @.str.986, i64 0, i64 0
  %r2278 = ptrtoint i8* %r2277 to i64
  %r2279 = call i64 @_add(i64 %r2276, i64 %r2278)
  %r2280 = load i64, i64* %ptr_NL
  %r2281 = call i64 @_add(i64 %r2279, i64 %r2280)
  store i64 %r2281, i64* %ptr_s
  %r2282 = load i64, i64* %ptr_s
  %r2283 = getelementptr [26 x i8], [26 x i8]* @.str.987, i64 0, i64 0
  %r2284 = ptrtoint i8* %r2283 to i64
  %r2285 = call i64 @_add(i64 %r2282, i64 %r2284)
  %r2286 = load i64, i64* %ptr_NL
  %r2287 = call i64 @_add(i64 %r2285, i64 %r2286)
  store i64 %r2287, i64* %ptr_s
  %r2288 = load i64, i64* %ptr_s
  %r2289 = getelementptr [17 x i8], [17 x i8]* @.str.988, i64 0, i64 0
  %r2290 = ptrtoint i8* %r2289 to i64
  %r2291 = call i64 @_add(i64 %r2288, i64 %r2290)
  %r2292 = load i64, i64* %ptr_NL
  %r2293 = call i64 @_add(i64 %r2291, i64 %r2292)
  store i64 %r2293, i64* %ptr_s
  %r2294 = load i64, i64* %ptr_s
  %r2295 = getelementptr [6 x i8], [6 x i8]* @.str.989, i64 0, i64 0
  %r2296 = ptrtoint i8* %r2295 to i64
  %r2297 = call i64 @_add(i64 %r2294, i64 %r2296)
  %r2298 = load i64, i64* %ptr_NL
  %r2299 = call i64 @_add(i64 %r2297, i64 %r2298)
  store i64 %r2299, i64* %ptr_s
  %r2300 = load i64, i64* %ptr_s
  %r2301 = getelementptr [70 x i8], [70 x i8]* @.str.990, i64 0, i64 0
  %r2302 = ptrtoint i8* %r2301 to i64
  %r2303 = call i64 @_add(i64 %r2300, i64 %r2302)
  %r2304 = load i64, i64* %ptr_NL
  %r2305 = call i64 @_add(i64 %r2303, i64 %r2304)
  store i64 %r2305, i64* %ptr_s
  %r2306 = load i64, i64* %ptr_s
  %r2307 = getelementptr [67 x i8], [67 x i8]* @.str.991, i64 0, i64 0
  %r2308 = ptrtoint i8* %r2307 to i64
  %r2309 = call i64 @_add(i64 %r2306, i64 %r2308)
  %r2310 = load i64, i64* %ptr_NL
  %r2311 = call i64 @_add(i64 %r2309, i64 %r2310)
  store i64 %r2311, i64* %ptr_s
  %r2312 = load i64, i64* %ptr_s
  %r2313 = getelementptr [51 x i8], [51 x i8]* @.str.992, i64 0, i64 0
  %r2314 = ptrtoint i8* %r2313 to i64
  %r2315 = call i64 @_add(i64 %r2312, i64 %r2314)
  %r2316 = load i64, i64* %ptr_NL
  %r2317 = call i64 @_add(i64 %r2315, i64 %r2316)
  store i64 %r2317, i64* %ptr_s
  %r2318 = load i64, i64* %ptr_s
  %r2319 = getelementptr [29 x i8], [29 x i8]* @.str.993, i64 0, i64 0
  %r2320 = ptrtoint i8* %r2319 to i64
  %r2321 = call i64 @_add(i64 %r2318, i64 %r2320)
  %r2322 = load i64, i64* %ptr_NL
  %r2323 = call i64 @_add(i64 %r2321, i64 %r2322)
  store i64 %r2323, i64* %ptr_s
  %r2324 = load i64, i64* %ptr_s
  %r2325 = getelementptr [12 x i8], [12 x i8]* @.str.994, i64 0, i64 0
  %r2326 = ptrtoint i8* %r2325 to i64
  %r2327 = call i64 @_add(i64 %r2324, i64 %r2326)
  %r2328 = load i64, i64* %ptr_NL
  %r2329 = call i64 @_add(i64 %r2327, i64 %r2328)
  store i64 %r2329, i64* %ptr_s
  %r2330 = load i64, i64* %ptr_s
  %r2331 = getelementptr [11 x i8], [11 x i8]* @.str.995, i64 0, i64 0
  %r2332 = ptrtoint i8* %r2331 to i64
  %r2333 = call i64 @_add(i64 %r2330, i64 %r2332)
  %r2334 = load i64, i64* %ptr_NL
  %r2335 = call i64 @_add(i64 %r2333, i64 %r2334)
  store i64 %r2335, i64* %ptr_s
  %r2336 = load i64, i64* %ptr_s
  %r2337 = getelementptr [71 x i8], [71 x i8]* @.str.996, i64 0, i64 0
  %r2338 = ptrtoint i8* %r2337 to i64
  %r2339 = call i64 @_add(i64 %r2336, i64 %r2338)
  %r2340 = load i64, i64* %ptr_NL
  %r2341 = call i64 @_add(i64 %r2339, i64 %r2340)
  store i64 %r2341, i64* %ptr_s
  %r2342 = load i64, i64* %ptr_s
  %r2343 = getelementptr [54 x i8], [54 x i8]* @.str.997, i64 0, i64 0
  %r2344 = ptrtoint i8* %r2343 to i64
  %r2345 = call i64 @_add(i64 %r2342, i64 %r2344)
  %r2346 = load i64, i64* %ptr_NL
  %r2347 = call i64 @_add(i64 %r2345, i64 %r2346)
  store i64 %r2347, i64* %ptr_s
  %r2348 = load i64, i64* %ptr_s
  %r2349 = getelementptr [29 x i8], [29 x i8]* @.str.998, i64 0, i64 0
  %r2350 = ptrtoint i8* %r2349 to i64
  %r2351 = call i64 @_add(i64 %r2348, i64 %r2350)
  %r2352 = load i64, i64* %ptr_NL
  %r2353 = call i64 @_add(i64 %r2351, i64 %r2352)
  store i64 %r2353, i64* %ptr_s
  %r2354 = load i64, i64* %ptr_s
  %r2355 = getelementptr [12 x i8], [12 x i8]* @.str.999, i64 0, i64 0
  %r2356 = ptrtoint i8* %r2355 to i64
  %r2357 = call i64 @_add(i64 %r2354, i64 %r2356)
  %r2358 = load i64, i64* %ptr_NL
  %r2359 = call i64 @_add(i64 %r2357, i64 %r2358)
  store i64 %r2359, i64* %ptr_s
  %r2360 = load i64, i64* %ptr_s
  %r2361 = getelementptr [11 x i8], [11 x i8]* @.str.1000, i64 0, i64 0
  %r2362 = ptrtoint i8* %r2361 to i64
  %r2363 = call i64 @_add(i64 %r2360, i64 %r2362)
  %r2364 = load i64, i64* %ptr_NL
  %r2365 = call i64 @_add(i64 %r2363, i64 %r2364)
  store i64 %r2365, i64* %ptr_s
  %r2366 = load i64, i64* %ptr_s
  %r2367 = getelementptr [71 x i8], [71 x i8]* @.str.1001, i64 0, i64 0
  %r2368 = ptrtoint i8* %r2367 to i64
  %r2369 = call i64 @_add(i64 %r2366, i64 %r2368)
  %r2370 = load i64, i64* %ptr_NL
  %r2371 = call i64 @_add(i64 %r2369, i64 %r2370)
  store i64 %r2371, i64* %ptr_s
  %r2372 = load i64, i64* %ptr_s
  %r2373 = getelementptr [36 x i8], [36 x i8]* @.str.1002, i64 0, i64 0
  %r2374 = ptrtoint i8* %r2373 to i64
  %r2375 = call i64 @_add(i64 %r2372, i64 %r2374)
  %r2376 = load i64, i64* %ptr_NL
  %r2377 = call i64 @_add(i64 %r2375, i64 %r2376)
  store i64 %r2377, i64* %ptr_s
  %r2378 = load i64, i64* %ptr_s
  %r2379 = getelementptr [56 x i8], [56 x i8]* @.str.1003, i64 0, i64 0
  %r2380 = ptrtoint i8* %r2379 to i64
  %r2381 = call i64 @_add(i64 %r2378, i64 %r2380)
  %r2382 = load i64, i64* %ptr_NL
  %r2383 = call i64 @_add(i64 %r2381, i64 %r2382)
  store i64 %r2383, i64* %ptr_s
  %r2384 = load i64, i64* %ptr_s
  %r2385 = getelementptr [29 x i8], [29 x i8]* @.str.1004, i64 0, i64 0
  %r2386 = ptrtoint i8* %r2385 to i64
  %r2387 = call i64 @_add(i64 %r2384, i64 %r2386)
  %r2388 = load i64, i64* %ptr_NL
  %r2389 = call i64 @_add(i64 %r2387, i64 %r2388)
  store i64 %r2389, i64* %ptr_s
  %r2390 = load i64, i64* %ptr_s
  %r2391 = getelementptr [12 x i8], [12 x i8]* @.str.1005, i64 0, i64 0
  %r2392 = ptrtoint i8* %r2391 to i64
  %r2393 = call i64 @_add(i64 %r2390, i64 %r2392)
  %r2394 = load i64, i64* %ptr_NL
  %r2395 = call i64 @_add(i64 %r2393, i64 %r2394)
  store i64 %r2395, i64* %ptr_s
  %r2396 = load i64, i64* %ptr_s
  %r2397 = getelementptr [2 x i8], [2 x i8]* @.str.1006, i64 0, i64 0
  %r2398 = ptrtoint i8* %r2397 to i64
  %r2399 = call i64 @_add(i64 %r2396, i64 %r2398)
  %r2400 = load i64, i64* %ptr_NL
  %r2401 = call i64 @_add(i64 %r2399, i64 %r2400)
  store i64 %r2401, i64* %ptr_s
  %r2402 = load i64, i64* %ptr_s
  %r2403 = getelementptr [30 x i8], [30 x i8]* @.str.1007, i64 0, i64 0
  %r2404 = ptrtoint i8* %r2403 to i64
  %r2405 = call i64 @_add(i64 %r2402, i64 %r2404)
  %r2406 = load i64, i64* %ptr_NL
  %r2407 = call i64 @_add(i64 %r2405, i64 %r2406)
  store i64 %r2407, i64* %ptr_s
  %r2408 = load i64, i64* %ptr_s
  %r2409 = getelementptr [34 x i8], [34 x i8]* @.str.1008, i64 0, i64 0
  %r2410 = ptrtoint i8* %r2409 to i64
  %r2411 = call i64 @_add(i64 %r2408, i64 %r2410)
  %r2412 = load i64, i64* %ptr_NL
  %r2413 = call i64 @_add(i64 %r2411, i64 %r2412)
  store i64 %r2413, i64* %ptr_s
  %r2414 = load i64, i64* %ptr_s
  %r2415 = getelementptr [25 x i8], [25 x i8]* @.str.1009, i64 0, i64 0
  %r2416 = ptrtoint i8* %r2415 to i64
  %r2417 = call i64 @_add(i64 %r2414, i64 %r2416)
  %r2418 = load i64, i64* %ptr_NL
  %r2419 = call i64 @_add(i64 %r2417, i64 %r2418)
  store i64 %r2419, i64* %ptr_s
  %r2420 = load i64, i64* %ptr_s
  %r2421 = getelementptr [27 x i8], [27 x i8]* @.str.1010, i64 0, i64 0
  %r2422 = ptrtoint i8* %r2421 to i64
  %r2423 = call i64 @_add(i64 %r2420, i64 %r2422)
  %r2424 = load i64, i64* %ptr_NL
  %r2425 = call i64 @_add(i64 %r2423, i64 %r2424)
  store i64 %r2425, i64* %ptr_s
  %r2426 = load i64, i64* %ptr_s
  %r2427 = getelementptr [15 x i8], [15 x i8]* @.str.1011, i64 0, i64 0
  %r2428 = ptrtoint i8* %r2427 to i64
  %r2429 = call i64 @_add(i64 %r2426, i64 %r2428)
  %r2430 = load i64, i64* %ptr_NL
  %r2431 = call i64 @_add(i64 %r2429, i64 %r2430)
  store i64 %r2431, i64* %ptr_s
  %r2432 = load i64, i64* %ptr_s
  %r2433 = getelementptr [2 x i8], [2 x i8]* @.str.1012, i64 0, i64 0
  %r2434 = ptrtoint i8* %r2433 to i64
  %r2435 = call i64 @_add(i64 %r2432, i64 %r2434)
  %r2436 = load i64, i64* %ptr_NL
  %r2437 = call i64 @_add(i64 %r2435, i64 %r2436)
  store i64 %r2437, i64* %ptr_s
  %r2438 = load i64, i64* %ptr_s
  %r2439 = getelementptr [51 x i8], [51 x i8]* @.str.1013, i64 0, i64 0
  %r2440 = ptrtoint i8* %r2439 to i64
  %r2441 = call i64 @_add(i64 %r2438, i64 %r2440)
  %r2442 = load i64, i64* %ptr_NL
  %r2443 = call i64 @_add(i64 %r2441, i64 %r2442)
  store i64 %r2443, i64* %ptr_s
  %r2444 = load i64, i64* %ptr_s
  %r2445 = getelementptr [34 x i8], [34 x i8]* @.str.1014, i64 0, i64 0
  %r2446 = ptrtoint i8* %r2445 to i64
  %r2447 = call i64 @_add(i64 %r2444, i64 %r2446)
  %r2448 = load i64, i64* %ptr_NL
  %r2449 = call i64 @_add(i64 %r2447, i64 %r2448)
  store i64 %r2449, i64* %ptr_s
  %r2450 = load i64, i64* %ptr_s
  %r2451 = getelementptr [37 x i8], [37 x i8]* @.str.1015, i64 0, i64 0
  %r2452 = ptrtoint i8* %r2451 to i64
  %r2453 = call i64 @_add(i64 %r2450, i64 %r2452)
  %r2454 = load i64, i64* %ptr_NL
  %r2455 = call i64 @_add(i64 %r2453, i64 %r2454)
  store i64 %r2455, i64* %ptr_s
  %r2456 = load i64, i64* %ptr_s
  %r2457 = getelementptr [39 x i8], [39 x i8]* @.str.1016, i64 0, i64 0
  %r2458 = ptrtoint i8* %r2457 to i64
  %r2459 = call i64 @_add(i64 %r2456, i64 %r2458)
  %r2460 = load i64, i64* %ptr_NL
  %r2461 = call i64 @_add(i64 %r2459, i64 %r2460)
  store i64 %r2461, i64* %ptr_s
  %r2462 = load i64, i64* %ptr_s
  %r2463 = getelementptr [39 x i8], [39 x i8]* @.str.1017, i64 0, i64 0
  %r2464 = ptrtoint i8* %r2463 to i64
  %r2465 = call i64 @_add(i64 %r2462, i64 %r2464)
  %r2466 = load i64, i64* %ptr_NL
  %r2467 = call i64 @_add(i64 %r2465, i64 %r2466)
  store i64 %r2467, i64* %ptr_s
  %r2468 = load i64, i64* %ptr_s
  %r2469 = getelementptr [5 x i8], [5 x i8]* @.str.1018, i64 0, i64 0
  %r2470 = ptrtoint i8* %r2469 to i64
  %r2471 = call i64 @_add(i64 %r2468, i64 %r2470)
  %r2472 = load i64, i64* %ptr_NL
  %r2473 = call i64 @_add(i64 %r2471, i64 %r2472)
  store i64 %r2473, i64* %ptr_s
  %r2474 = load i64, i64* %ptr_s
  %r2475 = getelementptr [33 x i8], [33 x i8]* @.str.1019, i64 0, i64 0
  %r2476 = ptrtoint i8* %r2475 to i64
  %r2477 = call i64 @_add(i64 %r2474, i64 %r2476)
  %r2478 = load i64, i64* %ptr_NL
  %r2479 = call i64 @_add(i64 %r2477, i64 %r2478)
  store i64 %r2479, i64* %ptr_s
  %r2480 = load i64, i64* %ptr_s
  %r2481 = getelementptr [36 x i8], [36 x i8]* @.str.1020, i64 0, i64 0
  %r2482 = ptrtoint i8* %r2481 to i64
  %r2483 = call i64 @_add(i64 %r2480, i64 %r2482)
  %r2484 = load i64, i64* %ptr_NL
  %r2485 = call i64 @_add(i64 %r2483, i64 %r2484)
  store i64 %r2485, i64* %ptr_s
  %r2486 = load i64, i64* %ptr_s
  %r2487 = getelementptr [25 x i8], [25 x i8]* @.str.1021, i64 0, i64 0
  %r2488 = ptrtoint i8* %r2487 to i64
  %r2489 = call i64 @_add(i64 %r2486, i64 %r2488)
  %r2490 = load i64, i64* %ptr_NL
  %r2491 = call i64 @_add(i64 %r2489, i64 %r2490)
  store i64 %r2491, i64* %ptr_s
  %r2492 = load i64, i64* %ptr_s
  %r2493 = getelementptr [15 x i8], [15 x i8]* @.str.1022, i64 0, i64 0
  %r2494 = ptrtoint i8* %r2493 to i64
  %r2495 = call i64 @_add(i64 %r2492, i64 %r2494)
  %r2496 = load i64, i64* %ptr_NL
  %r2497 = call i64 @_add(i64 %r2495, i64 %r2496)
  store i64 %r2497, i64* %ptr_s
  %r2498 = load i64, i64* %ptr_s
  %r2499 = getelementptr [4 x i8], [4 x i8]* @.str.1023, i64 0, i64 0
  %r2500 = ptrtoint i8* %r2499 to i64
  %r2501 = call i64 @_add(i64 %r2498, i64 %r2500)
  %r2502 = load i64, i64* %ptr_NL
  %r2503 = call i64 @_add(i64 %r2501, i64 %r2502)
  store i64 %r2503, i64* %ptr_s
  %r2504 = load i64, i64* %ptr_s
  %r2505 = getelementptr [31 x i8], [31 x i8]* @.str.1024, i64 0, i64 0
  %r2506 = ptrtoint i8* %r2505 to i64
  %r2507 = call i64 @_add(i64 %r2504, i64 %r2506)
  %r2508 = load i64, i64* %ptr_NL
  %r2509 = call i64 @_add(i64 %r2507, i64 %r2508)
  store i64 %r2509, i64* %ptr_s
  %r2510 = load i64, i64* %ptr_s
  %r2511 = getelementptr [37 x i8], [37 x i8]* @.str.1025, i64 0, i64 0
  %r2512 = ptrtoint i8* %r2511 to i64
  %r2513 = call i64 @_add(i64 %r2510, i64 %r2512)
  %r2514 = load i64, i64* %ptr_NL
  %r2515 = call i64 @_add(i64 %r2513, i64 %r2514)
  store i64 %r2515, i64* %ptr_s
  %r2516 = load i64, i64* %ptr_s
  %r2517 = getelementptr [53 x i8], [53 x i8]* @.str.1026, i64 0, i64 0
  %r2518 = ptrtoint i8* %r2517 to i64
  %r2519 = call i64 @_add(i64 %r2516, i64 %r2518)
  %r2520 = load i64, i64* %ptr_NL
  %r2521 = call i64 @_add(i64 %r2519, i64 %r2520)
  store i64 %r2521, i64* %ptr_s
  %r2522 = load i64, i64* %ptr_s
  %r2523 = getelementptr [52 x i8], [52 x i8]* @.str.1027, i64 0, i64 0
  %r2524 = ptrtoint i8* %r2523 to i64
  %r2525 = call i64 @_add(i64 %r2522, i64 %r2524)
  %r2526 = load i64, i64* %ptr_NL
  %r2527 = call i64 @_add(i64 %r2525, i64 %r2526)
  store i64 %r2527, i64* %ptr_s
  %r2528 = load i64, i64* %ptr_s
  %r2529 = getelementptr [35 x i8], [35 x i8]* @.str.1028, i64 0, i64 0
  %r2530 = ptrtoint i8* %r2529 to i64
  %r2531 = call i64 @_add(i64 %r2528, i64 %r2530)
  %r2532 = load i64, i64* %ptr_NL
  %r2533 = call i64 @_add(i64 %r2531, i64 %r2532)
  store i64 %r2533, i64* %ptr_s
  %r2534 = load i64, i64* %ptr_s
  %r2535 = getelementptr [42 x i8], [42 x i8]* @.str.1029, i64 0, i64 0
  %r2536 = ptrtoint i8* %r2535 to i64
  %r2537 = call i64 @_add(i64 %r2534, i64 %r2536)
  %r2538 = load i64, i64* %ptr_NL
  %r2539 = call i64 @_add(i64 %r2537, i64 %r2538)
  store i64 %r2539, i64* %ptr_s
  %r2540 = load i64, i64* %ptr_s
  %r2541 = getelementptr [40 x i8], [40 x i8]* @.str.1030, i64 0, i64 0
  %r2542 = ptrtoint i8* %r2541 to i64
  %r2543 = call i64 @_add(i64 %r2540, i64 %r2542)
  %r2544 = load i64, i64* %ptr_NL
  %r2545 = call i64 @_add(i64 %r2543, i64 %r2544)
  store i64 %r2545, i64* %ptr_s
  %r2546 = load i64, i64* %ptr_s
  %r2547 = getelementptr [64 x i8], [64 x i8]* @.str.1031, i64 0, i64 0
  %r2548 = ptrtoint i8* %r2547 to i64
  %r2549 = call i64 @_add(i64 %r2546, i64 %r2548)
  %r2550 = load i64, i64* %ptr_NL
  %r2551 = call i64 @_add(i64 %r2549, i64 %r2550)
  store i64 %r2551, i64* %ptr_s
  %r2552 = load i64, i64* %ptr_s
  %r2553 = getelementptr [57 x i8], [57 x i8]* @.str.1032, i64 0, i64 0
  %r2554 = ptrtoint i8* %r2553 to i64
  %r2555 = call i64 @_add(i64 %r2552, i64 %r2554)
  %r2556 = load i64, i64* %ptr_NL
  %r2557 = call i64 @_add(i64 %r2555, i64 %r2556)
  store i64 %r2557, i64* %ptr_s
  %r2558 = load i64, i64* %ptr_s
  %r2559 = getelementptr [24 x i8], [24 x i8]* @.str.1033, i64 0, i64 0
  %r2560 = ptrtoint i8* %r2559 to i64
  %r2561 = call i64 @_add(i64 %r2558, i64 %r2560)
  %r2562 = load i64, i64* %ptr_NL
  %r2563 = call i64 @_add(i64 %r2561, i64 %r2562)
  store i64 %r2563, i64* %ptr_s
  %r2564 = load i64, i64* %ptr_s
  %r2565 = getelementptr [16 x i8], [16 x i8]* @.str.1034, i64 0, i64 0
  %r2566 = ptrtoint i8* %r2565 to i64
  %r2567 = call i64 @_add(i64 %r2564, i64 %r2566)
  %r2568 = load i64, i64* %ptr_NL
  %r2569 = call i64 @_add(i64 %r2567, i64 %r2568)
  store i64 %r2569, i64* %ptr_s
  %r2570 = load i64, i64* %ptr_s
  %r2571 = getelementptr [2 x i8], [2 x i8]* @.str.1035, i64 0, i64 0
  %r2572 = ptrtoint i8* %r2571 to i64
  %r2573 = call i64 @_add(i64 %r2570, i64 %r2572)
  %r2574 = load i64, i64* %ptr_NL
  %r2575 = call i64 @_add(i64 %r2573, i64 %r2574)
  store i64 %r2575, i64* %ptr_s
  %r2576 = load i64, i64* %ptr_s
  %r2577 = getelementptr [34 x i8], [34 x i8]* @.str.1036, i64 0, i64 0
  %r2578 = ptrtoint i8* %r2577 to i64
  %r2579 = call i64 @_add(i64 %r2576, i64 %r2578)
  %r2580 = load i64, i64* %ptr_NL
  %r2581 = call i64 @_add(i64 %r2579, i64 %r2580)
  store i64 %r2581, i64* %ptr_s
  %r2582 = load i64, i64* %ptr_s
  %r2583 = getelementptr [33 x i8], [33 x i8]* @.str.1037, i64 0, i64 0
  %r2584 = ptrtoint i8* %r2583 to i64
  %r2585 = call i64 @_add(i64 %r2582, i64 %r2584)
  %r2586 = load i64, i64* %ptr_NL
  %r2587 = call i64 @_add(i64 %r2585, i64 %r2586)
  store i64 %r2587, i64* %ptr_s
  %r2588 = load i64, i64* %ptr_s
  %r2589 = getelementptr [34 x i8], [34 x i8]* @.str.1038, i64 0, i64 0
  %r2590 = ptrtoint i8* %r2589 to i64
  %r2591 = call i64 @_add(i64 %r2588, i64 %r2590)
  %r2592 = load i64, i64* %ptr_NL
  %r2593 = call i64 @_add(i64 %r2591, i64 %r2592)
  store i64 %r2593, i64* %ptr_s
  %r2594 = load i64, i64* %ptr_s
  %r2595 = getelementptr [28 x i8], [28 x i8]* @.str.1039, i64 0, i64 0
  %r2596 = ptrtoint i8* %r2595 to i64
  %r2597 = call i64 @_add(i64 %r2594, i64 %r2596)
  %r2598 = load i64, i64* %ptr_NL
  %r2599 = call i64 @_add(i64 %r2597, i64 %r2598)
  store i64 %r2599, i64* %ptr_s
  %r2600 = load i64, i64* %ptr_s
  %r2601 = getelementptr [24 x i8], [24 x i8]* @.str.1040, i64 0, i64 0
  %r2602 = ptrtoint i8* %r2601 to i64
  %r2603 = call i64 @_add(i64 %r2600, i64 %r2602)
  %r2604 = load i64, i64* %ptr_NL
  %r2605 = call i64 @_add(i64 %r2603, i64 %r2604)
  store i64 %r2605, i64* %ptr_s
  %r2606 = load i64, i64* %ptr_s
  %r2607 = getelementptr [44 x i8], [44 x i8]* @.str.1041, i64 0, i64 0
  %r2608 = ptrtoint i8* %r2607 to i64
  %r2609 = call i64 @_add(i64 %r2606, i64 %r2608)
  %r2610 = load i64, i64* %ptr_NL
  %r2611 = call i64 @_add(i64 %r2609, i64 %r2610)
  store i64 %r2611, i64* %ptr_s
  %r2612 = load i64, i64* %ptr_s
  %r2613 = getelementptr [24 x i8], [24 x i8]* @.str.1042, i64 0, i64 0
  %r2614 = ptrtoint i8* %r2613 to i64
  %r2615 = call i64 @_add(i64 %r2612, i64 %r2614)
  %r2616 = load i64, i64* %ptr_NL
  %r2617 = call i64 @_add(i64 %r2615, i64 %r2616)
  store i64 %r2617, i64* %ptr_s
  %r2618 = load i64, i64* %ptr_s
  %r2619 = getelementptr [15 x i8], [15 x i8]* @.str.1043, i64 0, i64 0
  %r2620 = ptrtoint i8* %r2619 to i64
  %r2621 = call i64 @_add(i64 %r2618, i64 %r2620)
  %r2622 = load i64, i64* %ptr_NL
  %r2623 = call i64 @_add(i64 %r2621, i64 %r2622)
  store i64 %r2623, i64* %ptr_s
  %r2624 = load i64, i64* %ptr_s
  %r2625 = getelementptr [2 x i8], [2 x i8]* @.str.1044, i64 0, i64 0
  %r2626 = ptrtoint i8* %r2625 to i64
  %r2627 = call i64 @_add(i64 %r2624, i64 %r2626)
  %r2628 = load i64, i64* %ptr_NL
  %r2629 = call i64 @_add(i64 %r2627, i64 %r2628)
  store i64 %r2629, i64* %ptr_s
  %r2630 = load i64, i64* %ptr_s
  %r2631 = getelementptr [32 x i8], [32 x i8]* @.str.1045, i64 0, i64 0
  %r2632 = ptrtoint i8* %r2631 to i64
  %r2633 = call i64 @_add(i64 %r2630, i64 %r2632)
  %r2634 = load i64, i64* %ptr_NL
  %r2635 = call i64 @_add(i64 %r2633, i64 %r2634)
  store i64 %r2635, i64* %ptr_s
  %r2636 = load i64, i64* %ptr_s
  %r2637 = getelementptr [33 x i8], [33 x i8]* @.str.1046, i64 0, i64 0
  %r2638 = ptrtoint i8* %r2637 to i64
  %r2639 = call i64 @_add(i64 %r2636, i64 %r2638)
  %r2640 = load i64, i64* %ptr_NL
  %r2641 = call i64 @_add(i64 %r2639, i64 %r2640)
  store i64 %r2641, i64* %ptr_s
  %r2642 = load i64, i64* %ptr_s
  %r2643 = getelementptr [47 x i8], [47 x i8]* @.str.1047, i64 0, i64 0
  %r2644 = ptrtoint i8* %r2643 to i64
  %r2645 = call i64 @_add(i64 %r2642, i64 %r2644)
  %r2646 = load i64, i64* %ptr_NL
  %r2647 = call i64 @_add(i64 %r2645, i64 %r2646)
  store i64 %r2647, i64* %ptr_s
  %r2648 = load i64, i64* %ptr_s
  %r2649 = getelementptr [10 x i8], [10 x i8]* @.str.1048, i64 0, i64 0
  %r2650 = ptrtoint i8* %r2649 to i64
  %r2651 = call i64 @_add(i64 %r2648, i64 %r2650)
  %r2652 = load i64, i64* %ptr_NL
  %r2653 = call i64 @_add(i64 %r2651, i64 %r2652)
  store i64 %r2653, i64* %ptr_s
  %r2654 = load i64, i64* %ptr_s
  %r2655 = getelementptr [12 x i8], [12 x i8]* @.str.1049, i64 0, i64 0
  %r2656 = ptrtoint i8* %r2655 to i64
  %r2657 = call i64 @_add(i64 %r2654, i64 %r2656)
  %r2658 = load i64, i64* %ptr_NL
  %r2659 = call i64 @_add(i64 %r2657, i64 %r2658)
  store i64 %r2659, i64* %ptr_s
  %r2660 = load i64, i64* %ptr_s
  %r2661 = getelementptr [6 x i8], [6 x i8]* @.str.1050, i64 0, i64 0
  %r2662 = ptrtoint i8* %r2661 to i64
  %r2663 = call i64 @_add(i64 %r2660, i64 %r2662)
  %r2664 = load i64, i64* %ptr_NL
  %r2665 = call i64 @_add(i64 %r2663, i64 %r2664)
  store i64 %r2665, i64* %ptr_s
  %r2666 = load i64, i64* %ptr_s
  %r2667 = getelementptr [35 x i8], [35 x i8]* @.str.1051, i64 0, i64 0
  %r2668 = ptrtoint i8* %r2667 to i64
  %r2669 = call i64 @_add(i64 %r2666, i64 %r2668)
  %r2670 = load i64, i64* %ptr_NL
  %r2671 = call i64 @_add(i64 %r2669, i64 %r2670)
  store i64 %r2671, i64* %ptr_s
  %r2672 = load i64, i64* %ptr_s
  %r2673 = getelementptr [29 x i8], [29 x i8]* @.str.1052, i64 0, i64 0
  %r2674 = ptrtoint i8* %r2673 to i64
  %r2675 = call i64 @_add(i64 %r2672, i64 %r2674)
  %r2676 = load i64, i64* %ptr_NL
  %r2677 = call i64 @_add(i64 %r2675, i64 %r2676)
  store i64 %r2677, i64* %ptr_s
  %r2678 = load i64, i64* %ptr_s
  %r2679 = getelementptr [33 x i8], [33 x i8]* @.str.1053, i64 0, i64 0
  %r2680 = ptrtoint i8* %r2679 to i64
  %r2681 = call i64 @_add(i64 %r2678, i64 %r2680)
  %r2682 = load i64, i64* %ptr_NL
  %r2683 = call i64 @_add(i64 %r2681, i64 %r2682)
  store i64 %r2683, i64* %ptr_s
  %r2684 = load i64, i64* %ptr_s
  %r2685 = getelementptr [32 x i8], [32 x i8]* @.str.1054, i64 0, i64 0
  %r2686 = ptrtoint i8* %r2685 to i64
  %r2687 = call i64 @_add(i64 %r2684, i64 %r2686)
  %r2688 = load i64, i64* %ptr_NL
  %r2689 = call i64 @_add(i64 %r2687, i64 %r2688)
  store i64 %r2689, i64* %ptr_s
  %r2690 = load i64, i64* %ptr_s
  %r2691 = getelementptr [36 x i8], [36 x i8]* @.str.1055, i64 0, i64 0
  %r2692 = ptrtoint i8* %r2691 to i64
  %r2693 = call i64 @_add(i64 %r2690, i64 %r2692)
  %r2694 = load i64, i64* %ptr_NL
  %r2695 = call i64 @_add(i64 %r2693, i64 %r2694)
  store i64 %r2695, i64* %ptr_s
  %r2696 = load i64, i64* %ptr_s
  %r2697 = getelementptr [48 x i8], [48 x i8]* @.str.1056, i64 0, i64 0
  %r2698 = ptrtoint i8* %r2697 to i64
  %r2699 = call i64 @_add(i64 %r2696, i64 %r2698)
  %r2700 = load i64, i64* %ptr_NL
  %r2701 = call i64 @_add(i64 %r2699, i64 %r2700)
  store i64 %r2701, i64* %ptr_s
  %r2702 = load i64, i64* %ptr_s
  %r2703 = getelementptr [9 x i8], [9 x i8]* @.str.1057, i64 0, i64 0
  %r2704 = ptrtoint i8* %r2703 to i64
  %r2705 = call i64 @_add(i64 %r2702, i64 %r2704)
  %r2706 = load i64, i64* %ptr_NL
  %r2707 = call i64 @_add(i64 %r2705, i64 %r2706)
  store i64 %r2707, i64* %ptr_s
  %r2708 = load i64, i64* %ptr_s
  %r2709 = getelementptr [37 x i8], [37 x i8]* @.str.1058, i64 0, i64 0
  %r2710 = ptrtoint i8* %r2709 to i64
  %r2711 = call i64 @_add(i64 %r2708, i64 %r2710)
  %r2712 = load i64, i64* %ptr_NL
  %r2713 = call i64 @_add(i64 %r2711, i64 %r2712)
  store i64 %r2713, i64* %ptr_s
  %r2714 = load i64, i64* %ptr_s
  %r2715 = getelementptr [51 x i8], [51 x i8]* @.str.1059, i64 0, i64 0
  %r2716 = ptrtoint i8* %r2715 to i64
  %r2717 = call i64 @_add(i64 %r2714, i64 %r2716)
  %r2718 = load i64, i64* %ptr_NL
  %r2719 = call i64 @_add(i64 %r2717, i64 %r2718)
  store i64 %r2719, i64* %ptr_s
  %r2720 = load i64, i64* %ptr_s
  %r2721 = getelementptr [33 x i8], [33 x i8]* @.str.1060, i64 0, i64 0
  %r2722 = ptrtoint i8* %r2721 to i64
  %r2723 = call i64 @_add(i64 %r2720, i64 %r2722)
  %r2724 = load i64, i64* %ptr_NL
  %r2725 = call i64 @_add(i64 %r2723, i64 %r2724)
  store i64 %r2725, i64* %ptr_s
  %r2726 = load i64, i64* %ptr_s
  %r2727 = getelementptr [15 x i8], [15 x i8]* @.str.1061, i64 0, i64 0
  %r2728 = ptrtoint i8* %r2727 to i64
  %r2729 = call i64 @_add(i64 %r2726, i64 %r2728)
  %r2730 = load i64, i64* %ptr_NL
  %r2731 = call i64 @_add(i64 %r2729, i64 %r2730)
  store i64 %r2731, i64* %ptr_s
  %r2732 = load i64, i64* %ptr_s
  %r2733 = getelementptr [9 x i8], [9 x i8]* @.str.1062, i64 0, i64 0
  %r2734 = ptrtoint i8* %r2733 to i64
  %r2735 = call i64 @_add(i64 %r2732, i64 %r2734)
  %r2736 = load i64, i64* %ptr_NL
  %r2737 = call i64 @_add(i64 %r2735, i64 %r2736)
  store i64 %r2737, i64* %ptr_s
  %r2738 = load i64, i64* %ptr_s
  %r2739 = getelementptr [38 x i8], [38 x i8]* @.str.1063, i64 0, i64 0
  %r2740 = ptrtoint i8* %r2739 to i64
  %r2741 = call i64 @_add(i64 %r2738, i64 %r2740)
  %r2742 = load i64, i64* %ptr_NL
  %r2743 = call i64 @_add(i64 %r2741, i64 %r2742)
  store i64 %r2743, i64* %ptr_s
  %r2744 = load i64, i64* %ptr_s
  %r2745 = getelementptr [40 x i8], [40 x i8]* @.str.1064, i64 0, i64 0
  %r2746 = ptrtoint i8* %r2745 to i64
  %r2747 = call i64 @_add(i64 %r2744, i64 %r2746)
  %r2748 = load i64, i64* %ptr_NL
  %r2749 = call i64 @_add(i64 %r2747, i64 %r2748)
  store i64 %r2749, i64* %ptr_s
  %r2750 = load i64, i64* %ptr_s
  %r2751 = getelementptr [15 x i8], [15 x i8]* @.str.1065, i64 0, i64 0
  %r2752 = ptrtoint i8* %r2751 to i64
  %r2753 = call i64 @_add(i64 %r2750, i64 %r2752)
  %r2754 = load i64, i64* %ptr_NL
  %r2755 = call i64 @_add(i64 %r2753, i64 %r2754)
  store i64 %r2755, i64* %ptr_s
  %r2756 = load i64, i64* %ptr_s
  %r2757 = getelementptr [2 x i8], [2 x i8]* @.str.1066, i64 0, i64 0
  %r2758 = ptrtoint i8* %r2757 to i64
  %r2759 = call i64 @_add(i64 %r2756, i64 %r2758)
  %r2760 = load i64, i64* %ptr_NL
  %r2761 = call i64 @_add(i64 %r2759, i64 %r2760)
  store i64 %r2761, i64* %ptr_s
  %r2762 = load i64, i64* %ptr_s
  %r2763 = getelementptr [22 x i8], [22 x i8]* @.str.1067, i64 0, i64 0
  %r2764 = ptrtoint i8* %r2763 to i64
  %r2765 = call i64 @_add(i64 %r2762, i64 %r2764)
  %r2766 = load i64, i64* %ptr_NL
  %r2767 = call i64 @_add(i64 %r2765, i64 %r2766)
  store i64 %r2767, i64* %ptr_s
  %r2768 = load i64, i64* %ptr_s
  %r2769 = getelementptr [36 x i8], [36 x i8]* @.str.1068, i64 0, i64 0
  %r2770 = ptrtoint i8* %r2769 to i64
  %r2771 = call i64 @_add(i64 %r2768, i64 %r2770)
  %r2772 = load i64, i64* %ptr_NL
  %r2773 = call i64 @_add(i64 %r2771, i64 %r2772)
  store i64 %r2773, i64* %ptr_s
  %r2774 = load i64, i64* %ptr_s
  %r2775 = getelementptr [34 x i8], [34 x i8]* @.str.1069, i64 0, i64 0
  %r2776 = ptrtoint i8* %r2775 to i64
  %r2777 = call i64 @_add(i64 %r2774, i64 %r2776)
  %r2778 = load i64, i64* %ptr_NL
  %r2779 = call i64 @_add(i64 %r2777, i64 %r2778)
  store i64 %r2779, i64* %ptr_s
  %r2780 = load i64, i64* %ptr_s
  %r2781 = getelementptr [17 x i8], [17 x i8]* @.str.1070, i64 0, i64 0
  %r2782 = ptrtoint i8* %r2781 to i64
  %r2783 = call i64 @_add(i64 %r2780, i64 %r2782)
  %r2784 = load i64, i64* %ptr_NL
  %r2785 = call i64 @_add(i64 %r2783, i64 %r2784)
  store i64 %r2785, i64* %ptr_s
  %r2786 = load i64, i64* %ptr_s
  %r2787 = getelementptr [6 x i8], [6 x i8]* @.str.1071, i64 0, i64 0
  %r2788 = ptrtoint i8* %r2787 to i64
  %r2789 = call i64 @_add(i64 %r2786, i64 %r2788)
  %r2790 = load i64, i64* %ptr_NL
  %r2791 = call i64 @_add(i64 %r2789, i64 %r2790)
  store i64 %r2791, i64* %ptr_s
  %r2792 = load i64, i64* %ptr_s
  %r2793 = getelementptr [45 x i8], [45 x i8]* @.str.1072, i64 0, i64 0
  %r2794 = ptrtoint i8* %r2793 to i64
  %r2795 = call i64 @_add(i64 %r2792, i64 %r2794)
  %r2796 = load i64, i64* %ptr_NL
  %r2797 = call i64 @_add(i64 %r2795, i64 %r2796)
  store i64 %r2797, i64* %ptr_s
  %r2798 = load i64, i64* %ptr_s
  %r2799 = getelementptr [27 x i8], [27 x i8]* @.str.1073, i64 0, i64 0
  %r2800 = ptrtoint i8* %r2799 to i64
  %r2801 = call i64 @_add(i64 %r2798, i64 %r2800)
  %r2802 = load i64, i64* %ptr_NL
  %r2803 = call i64 @_add(i64 %r2801, i64 %r2802)
  store i64 %r2803, i64* %ptr_s
  %r2804 = load i64, i64* %ptr_s
  %r2805 = getelementptr [31 x i8], [31 x i8]* @.str.1074, i64 0, i64 0
  %r2806 = ptrtoint i8* %r2805 to i64
  %r2807 = call i64 @_add(i64 %r2804, i64 %r2806)
  %r2808 = load i64, i64* %ptr_NL
  %r2809 = call i64 @_add(i64 %r2807, i64 %r2808)
  store i64 %r2809, i64* %ptr_s
  %r2810 = load i64, i64* %ptr_s
  %r2811 = getelementptr [30 x i8], [30 x i8]* @.str.1075, i64 0, i64 0
  %r2812 = ptrtoint i8* %r2811 to i64
  %r2813 = call i64 @_add(i64 %r2810, i64 %r2812)
  %r2814 = load i64, i64* %ptr_NL
  %r2815 = call i64 @_add(i64 %r2813, i64 %r2814)
  store i64 %r2815, i64* %ptr_s
  %r2816 = load i64, i64* %ptr_s
  %r2817 = getelementptr [32 x i8], [32 x i8]* @.str.1076, i64 0, i64 0
  %r2818 = ptrtoint i8* %r2817 to i64
  %r2819 = call i64 @_add(i64 %r2816, i64 %r2818)
  %r2820 = load i64, i64* %ptr_NL
  %r2821 = call i64 @_add(i64 %r2819, i64 %r2820)
  store i64 %r2821, i64* %ptr_s
  %r2822 = load i64, i64* %ptr_s
  %r2823 = getelementptr [40 x i8], [40 x i8]* @.str.1077, i64 0, i64 0
  %r2824 = ptrtoint i8* %r2823 to i64
  %r2825 = call i64 @_add(i64 %r2822, i64 %r2824)
  %r2826 = load i64, i64* %ptr_NL
  %r2827 = call i64 @_add(i64 %r2825, i64 %r2826)
  store i64 %r2827, i64* %ptr_s
  %r2828 = load i64, i64* %ptr_s
  %r2829 = getelementptr [6 x i8], [6 x i8]* @.str.1078, i64 0, i64 0
  %r2830 = ptrtoint i8* %r2829 to i64
  %r2831 = call i64 @_add(i64 %r2828, i64 %r2830)
  %r2832 = load i64, i64* %ptr_NL
  %r2833 = call i64 @_add(i64 %r2831, i64 %r2832)
  store i64 %r2833, i64* %ptr_s
  %r2834 = load i64, i64* %ptr_s
  %r2835 = getelementptr [29 x i8], [29 x i8]* @.str.1079, i64 0, i64 0
  %r2836 = ptrtoint i8* %r2835 to i64
  %r2837 = call i64 @_add(i64 %r2834, i64 %r2836)
  %r2838 = load i64, i64* %ptr_NL
  %r2839 = call i64 @_add(i64 %r2837, i64 %r2838)
  store i64 %r2839, i64* %ptr_s
  %r2840 = load i64, i64* %ptr_s
  %r2841 = getelementptr [45 x i8], [45 x i8]* @.str.1080, i64 0, i64 0
  %r2842 = ptrtoint i8* %r2841 to i64
  %r2843 = call i64 @_add(i64 %r2840, i64 %r2842)
  %r2844 = load i64, i64* %ptr_NL
  %r2845 = call i64 @_add(i64 %r2843, i64 %r2844)
  store i64 %r2845, i64* %ptr_s
  %r2846 = load i64, i64* %ptr_s
  %r2847 = getelementptr [28 x i8], [28 x i8]* @.str.1081, i64 0, i64 0
  %r2848 = ptrtoint i8* %r2847 to i64
  %r2849 = call i64 @_add(i64 %r2846, i64 %r2848)
  %r2850 = load i64, i64* %ptr_NL
  %r2851 = call i64 @_add(i64 %r2849, i64 %r2850)
  store i64 %r2851, i64* %ptr_s
  %r2852 = load i64, i64* %ptr_s
  %r2853 = getelementptr [26 x i8], [26 x i8]* @.str.1082, i64 0, i64 0
  %r2854 = ptrtoint i8* %r2853 to i64
  %r2855 = call i64 @_add(i64 %r2852, i64 %r2854)
  %r2856 = load i64, i64* %ptr_NL
  %r2857 = call i64 @_add(i64 %r2855, i64 %r2856)
  store i64 %r2857, i64* %ptr_s
  %r2858 = load i64, i64* %ptr_s
  %r2859 = getelementptr [38 x i8], [38 x i8]* @.str.1083, i64 0, i64 0
  %r2860 = ptrtoint i8* %r2859 to i64
  %r2861 = call i64 @_add(i64 %r2858, i64 %r2860)
  %r2862 = load i64, i64* %ptr_NL
  %r2863 = call i64 @_add(i64 %r2861, i64 %r2862)
  store i64 %r2863, i64* %ptr_s
  %r2864 = load i64, i64* %ptr_s
  %r2865 = getelementptr [41 x i8], [41 x i8]* @.str.1084, i64 0, i64 0
  %r2866 = ptrtoint i8* %r2865 to i64
  %r2867 = call i64 @_add(i64 %r2864, i64 %r2866)
  %r2868 = load i64, i64* %ptr_NL
  %r2869 = call i64 @_add(i64 %r2867, i64 %r2868)
  store i64 %r2869, i64* %ptr_s
  %r2870 = load i64, i64* %ptr_s
  %r2871 = getelementptr [6 x i8], [6 x i8]* @.str.1085, i64 0, i64 0
  %r2872 = ptrtoint i8* %r2871 to i64
  %r2873 = call i64 @_add(i64 %r2870, i64 %r2872)
  %r2874 = load i64, i64* %ptr_NL
  %r2875 = call i64 @_add(i64 %r2873, i64 %r2874)
  store i64 %r2875, i64* %ptr_s
  %r2876 = load i64, i64* %ptr_s
  %r2877 = getelementptr [50 x i8], [50 x i8]* @.str.1086, i64 0, i64 0
  %r2878 = ptrtoint i8* %r2877 to i64
  %r2879 = call i64 @_add(i64 %r2876, i64 %r2878)
  %r2880 = load i64, i64* %ptr_NL
  %r2881 = call i64 @_add(i64 %r2879, i64 %r2880)
  store i64 %r2881, i64* %ptr_s
  %r2882 = load i64, i64* %ptr_s
  %r2883 = getelementptr [29 x i8], [29 x i8]* @.str.1087, i64 0, i64 0
  %r2884 = ptrtoint i8* %r2883 to i64
  %r2885 = call i64 @_add(i64 %r2882, i64 %r2884)
  %r2886 = load i64, i64* %ptr_NL
  %r2887 = call i64 @_add(i64 %r2885, i64 %r2886)
  store i64 %r2887, i64* %ptr_s
  %r2888 = load i64, i64* %ptr_s
  %r2889 = getelementptr [15 x i8], [15 x i8]* @.str.1088, i64 0, i64 0
  %r2890 = ptrtoint i8* %r2889 to i64
  %r2891 = call i64 @_add(i64 %r2888, i64 %r2890)
  %r2892 = load i64, i64* %ptr_NL
  %r2893 = call i64 @_add(i64 %r2891, i64 %r2892)
  store i64 %r2893, i64* %ptr_s
  %r2894 = load i64, i64* %ptr_s
  %r2895 = getelementptr [2 x i8], [2 x i8]* @.str.1089, i64 0, i64 0
  %r2896 = ptrtoint i8* %r2895 to i64
  %r2897 = call i64 @_add(i64 %r2894, i64 %r2896)
  %r2898 = load i64, i64* %ptr_NL
  %r2899 = call i64 @_add(i64 %r2897, i64 %r2898)
  store i64 %r2899, i64* %ptr_s
  %r2900 = load i64, i64* %ptr_s
  %r2901 = getelementptr [33 x i8], [33 x i8]* @.str.1090, i64 0, i64 0
  %r2902 = ptrtoint i8* %r2901 to i64
  %r2903 = call i64 @_add(i64 %r2900, i64 %r2902)
  %r2904 = load i64, i64* %ptr_NL
  %r2905 = call i64 @_add(i64 %r2903, i64 %r2904)
  store i64 %r2905, i64* %ptr_s
  %r2906 = load i64, i64* %ptr_s
  %r2907 = getelementptr [32 x i8], [32 x i8]* @.str.1091, i64 0, i64 0
  %r2908 = ptrtoint i8* %r2907 to i64
  %r2909 = call i64 @_add(i64 %r2906, i64 %r2908)
  %r2910 = load i64, i64* %ptr_NL
  %r2911 = call i64 @_add(i64 %r2909, i64 %r2910)
  store i64 %r2911, i64* %ptr_s
  %r2912 = load i64, i64* %ptr_s
  %r2913 = getelementptr [34 x i8], [34 x i8]* @.str.1092, i64 0, i64 0
  %r2914 = ptrtoint i8* %r2913 to i64
  %r2915 = call i64 @_add(i64 %r2912, i64 %r2914)
  %r2916 = load i64, i64* %ptr_NL
  %r2917 = call i64 @_add(i64 %r2915, i64 %r2916)
  store i64 %r2917, i64* %ptr_s
  %r2918 = load i64, i64* %ptr_s
  %r2919 = getelementptr [30 x i8], [30 x i8]* @.str.1093, i64 0, i64 0
  %r2920 = ptrtoint i8* %r2919 to i64
  %r2921 = call i64 @_add(i64 %r2918, i64 %r2920)
  %r2922 = load i64, i64* %ptr_NL
  %r2923 = call i64 @_add(i64 %r2921, i64 %r2922)
  store i64 %r2923, i64* %ptr_s
  %r2924 = load i64, i64* %ptr_s
  %r2925 = getelementptr [15 x i8], [15 x i8]* @.str.1094, i64 0, i64 0
  %r2926 = ptrtoint i8* %r2925 to i64
  %r2927 = call i64 @_add(i64 %r2924, i64 %r2926)
  %r2928 = load i64, i64* %ptr_NL
  %r2929 = call i64 @_add(i64 %r2927, i64 %r2928)
  store i64 %r2929, i64* %ptr_s
  %r2930 = load i64, i64* %ptr_s
  %r2931 = getelementptr [2 x i8], [2 x i8]* @.str.1095, i64 0, i64 0
  %r2932 = ptrtoint i8* %r2931 to i64
  %r2933 = call i64 @_add(i64 %r2930, i64 %r2932)
  %r2934 = load i64, i64* %ptr_NL
  %r2935 = call i64 @_add(i64 %r2933, i64 %r2934)
  store i64 %r2935, i64* %ptr_s
  %r2936 = load i64, i64* %ptr_s
  %r2937 = getelementptr [31 x i8], [31 x i8]* @.str.1096, i64 0, i64 0
  %r2938 = ptrtoint i8* %r2937 to i64
  %r2939 = call i64 @_add(i64 %r2936, i64 %r2938)
  %r2940 = load i64, i64* %ptr_NL
  %r2941 = call i64 @_add(i64 %r2939, i64 %r2940)
  store i64 %r2941, i64* %ptr_s
  %r2942 = load i64, i64* %ptr_s
  %r2943 = getelementptr [26 x i8], [26 x i8]* @.str.1097, i64 0, i64 0
  %r2944 = ptrtoint i8* %r2943 to i64
  %r2945 = call i64 @_add(i64 %r2942, i64 %r2944)
  %r2946 = load i64, i64* %ptr_NL
  %r2947 = call i64 @_add(i64 %r2945, i64 %r2946)
  store i64 %r2947, i64* %ptr_s
  %r2948 = load i64, i64* %ptr_s
  %r2949 = getelementptr [31 x i8], [31 x i8]* @.str.1098, i64 0, i64 0
  %r2950 = ptrtoint i8* %r2949 to i64
  %r2951 = call i64 @_add(i64 %r2948, i64 %r2950)
  %r2952 = load i64, i64* %ptr_NL
  %r2953 = call i64 @_add(i64 %r2951, i64 %r2952)
  store i64 %r2953, i64* %ptr_s
  %r2954 = load i64, i64* %ptr_s
  %r2955 = getelementptr [30 x i8], [30 x i8]* @.str.1099, i64 0, i64 0
  %r2956 = ptrtoint i8* %r2955 to i64
  %r2957 = call i64 @_add(i64 %r2954, i64 %r2956)
  %r2958 = load i64, i64* %ptr_NL
  %r2959 = call i64 @_add(i64 %r2957, i64 %r2958)
  store i64 %r2959, i64* %ptr_s
  %r2960 = load i64, i64* %ptr_s
  %r2961 = getelementptr [12 x i8], [12 x i8]* @.str.1100, i64 0, i64 0
  %r2962 = ptrtoint i8* %r2961 to i64
  %r2963 = call i64 @_add(i64 %r2960, i64 %r2962)
  %r2964 = load i64, i64* %ptr_NL
  %r2965 = call i64 @_add(i64 %r2963, i64 %r2964)
  store i64 %r2965, i64* %ptr_s
  %r2966 = load i64, i64* %ptr_s
  %r2967 = getelementptr [2 x i8], [2 x i8]* @.str.1101, i64 0, i64 0
  %r2968 = ptrtoint i8* %r2967 to i64
  %r2969 = call i64 @_add(i64 %r2966, i64 %r2968)
  %r2970 = load i64, i64* %ptr_NL
  %r2971 = call i64 @_add(i64 %r2969, i64 %r2970)
  store i64 %r2971, i64* %ptr_s
  %r2972 = load i64, i64* %ptr_s
  %r2973 = getelementptr [32 x i8], [32 x i8]* @.str.1102, i64 0, i64 0
  %r2974 = ptrtoint i8* %r2973 to i64
  %r2975 = call i64 @_add(i64 %r2972, i64 %r2974)
  %r2976 = load i64, i64* %ptr_NL
  %r2977 = call i64 @_add(i64 %r2975, i64 %r2976)
  store i64 %r2977, i64* %ptr_s
  %r2978 = load i64, i64* %ptr_s
  %r2979 = getelementptr [34 x i8], [34 x i8]* @.str.1103, i64 0, i64 0
  %r2980 = ptrtoint i8* %r2979 to i64
  %r2981 = call i64 @_add(i64 %r2978, i64 %r2980)
  %r2982 = load i64, i64* %ptr_NL
  %r2983 = call i64 @_add(i64 %r2981, i64 %r2982)
  store i64 %r2983, i64* %ptr_s
  %r2984 = load i64, i64* %ptr_s
  %r2985 = getelementptr [17 x i8], [17 x i8]* @.str.1104, i64 0, i64 0
  %r2986 = ptrtoint i8* %r2985 to i64
  %r2987 = call i64 @_add(i64 %r2984, i64 %r2986)
  %r2988 = load i64, i64* %ptr_NL
  %r2989 = call i64 @_add(i64 %r2987, i64 %r2988)
  store i64 %r2989, i64* %ptr_s
  %r2990 = load i64, i64* %ptr_s
  %r2991 = getelementptr [6 x i8], [6 x i8]* @.str.1105, i64 0, i64 0
  %r2992 = ptrtoint i8* %r2991 to i64
  %r2993 = call i64 @_add(i64 %r2990, i64 %r2992)
  %r2994 = load i64, i64* %ptr_NL
  %r2995 = call i64 @_add(i64 %r2993, i64 %r2994)
  store i64 %r2995, i64* %ptr_s
  %r2996 = load i64, i64* %ptr_s
  %r2997 = getelementptr [45 x i8], [45 x i8]* @.str.1106, i64 0, i64 0
  %r2998 = ptrtoint i8* %r2997 to i64
  %r2999 = call i64 @_add(i64 %r2996, i64 %r2998)
  %r3000 = load i64, i64* %ptr_NL
  %r3001 = call i64 @_add(i64 %r2999, i64 %r3000)
  store i64 %r3001, i64* %ptr_s
  %r3002 = load i64, i64* %ptr_s
  %r3003 = getelementptr [49 x i8], [49 x i8]* @.str.1107, i64 0, i64 0
  %r3004 = ptrtoint i8* %r3003 to i64
  %r3005 = call i64 @_add(i64 %r3002, i64 %r3004)
  %r3006 = load i64, i64* %ptr_NL
  %r3007 = call i64 @_add(i64 %r3005, i64 %r3006)
  store i64 %r3007, i64* %ptr_s
  %r3008 = load i64, i64* %ptr_s
  %r3009 = getelementptr [49 x i8], [49 x i8]* @.str.1108, i64 0, i64 0
  %r3010 = ptrtoint i8* %r3009 to i64
  %r3011 = call i64 @_add(i64 %r3008, i64 %r3010)
  %r3012 = load i64, i64* %ptr_NL
  %r3013 = call i64 @_add(i64 %r3011, i64 %r3012)
  store i64 %r3013, i64* %ptr_s
  %r3014 = load i64, i64* %ptr_s
  %r3015 = getelementptr [30 x i8], [30 x i8]* @.str.1109, i64 0, i64 0
  %r3016 = ptrtoint i8* %r3015 to i64
  %r3017 = call i64 @_add(i64 %r3014, i64 %r3016)
  %r3018 = load i64, i64* %ptr_NL
  %r3019 = call i64 @_add(i64 %r3017, i64 %r3018)
  store i64 %r3019, i64* %ptr_s
  %r3020 = load i64, i64* %ptr_s
  %r3021 = getelementptr [30 x i8], [30 x i8]* @.str.1110, i64 0, i64 0
  %r3022 = ptrtoint i8* %r3021 to i64
  %r3023 = call i64 @_add(i64 %r3020, i64 %r3022)
  %r3024 = load i64, i64* %ptr_NL
  %r3025 = call i64 @_add(i64 %r3023, i64 %r3024)
  store i64 %r3025, i64* %ptr_s
  %r3026 = load i64, i64* %ptr_s
  %r3027 = getelementptr [43 x i8], [43 x i8]* @.str.1111, i64 0, i64 0
  %r3028 = ptrtoint i8* %r3027 to i64
  %r3029 = call i64 @_add(i64 %r3026, i64 %r3028)
  %r3030 = load i64, i64* %ptr_NL
  %r3031 = call i64 @_add(i64 %r3029, i64 %r3030)
  store i64 %r3031, i64* %ptr_s
  %r3032 = load i64, i64* %ptr_s
  %r3033 = getelementptr [6 x i8], [6 x i8]* @.str.1112, i64 0, i64 0
  %r3034 = ptrtoint i8* %r3033 to i64
  %r3035 = call i64 @_add(i64 %r3032, i64 %r3034)
  %r3036 = load i64, i64* %ptr_NL
  %r3037 = call i64 @_add(i64 %r3035, i64 %r3036)
  store i64 %r3037, i64* %ptr_s
  %r3038 = load i64, i64* %ptr_s
  %r3039 = getelementptr [29 x i8], [29 x i8]* @.str.1113, i64 0, i64 0
  %r3040 = ptrtoint i8* %r3039 to i64
  %r3041 = call i64 @_add(i64 %r3038, i64 %r3040)
  %r3042 = load i64, i64* %ptr_NL
  %r3043 = call i64 @_add(i64 %r3041, i64 %r3042)
  store i64 %r3043, i64* %ptr_s
  %r3044 = load i64, i64* %ptr_s
  %r3045 = getelementptr [30 x i8], [30 x i8]* @.str.1114, i64 0, i64 0
  %r3046 = ptrtoint i8* %r3045 to i64
  %r3047 = call i64 @_add(i64 %r3044, i64 %r3046)
  %r3048 = load i64, i64* %ptr_NL
  %r3049 = call i64 @_add(i64 %r3047, i64 %r3048)
  store i64 %r3049, i64* %ptr_s
  %r3050 = load i64, i64* %ptr_s
  %r3051 = getelementptr [28 x i8], [28 x i8]* @.str.1115, i64 0, i64 0
  %r3052 = ptrtoint i8* %r3051 to i64
  %r3053 = call i64 @_add(i64 %r3050, i64 %r3052)
  %r3054 = load i64, i64* %ptr_NL
  %r3055 = call i64 @_add(i64 %r3053, i64 %r3054)
  store i64 %r3055, i64* %ptr_s
  %r3056 = load i64, i64* %ptr_s
  %r3057 = getelementptr [37 x i8], [37 x i8]* @.str.1116, i64 0, i64 0
  %r3058 = ptrtoint i8* %r3057 to i64
  %r3059 = call i64 @_add(i64 %r3056, i64 %r3058)
  %r3060 = load i64, i64* %ptr_NL
  %r3061 = call i64 @_add(i64 %r3059, i64 %r3060)
  store i64 %r3061, i64* %ptr_s
  %r3062 = load i64, i64* %ptr_s
  %r3063 = getelementptr [26 x i8], [26 x i8]* @.str.1117, i64 0, i64 0
  %r3064 = ptrtoint i8* %r3063 to i64
  %r3065 = call i64 @_add(i64 %r3062, i64 %r3064)
  %r3066 = load i64, i64* %ptr_NL
  %r3067 = call i64 @_add(i64 %r3065, i64 %r3066)
  store i64 %r3067, i64* %ptr_s
  %r3068 = load i64, i64* %ptr_s
  %r3069 = getelementptr [17 x i8], [17 x i8]* @.str.1118, i64 0, i64 0
  %r3070 = ptrtoint i8* %r3069 to i64
  %r3071 = call i64 @_add(i64 %r3068, i64 %r3070)
  %r3072 = load i64, i64* %ptr_NL
  %r3073 = call i64 @_add(i64 %r3071, i64 %r3072)
  store i64 %r3073, i64* %ptr_s
  %r3074 = load i64, i64* %ptr_s
  %r3075 = getelementptr [6 x i8], [6 x i8]* @.str.1119, i64 0, i64 0
  %r3076 = ptrtoint i8* %r3075 to i64
  %r3077 = call i64 @_add(i64 %r3074, i64 %r3076)
  %r3078 = load i64, i64* %ptr_NL
  %r3079 = call i64 @_add(i64 %r3077, i64 %r3078)
  store i64 %r3079, i64* %ptr_s
  %r3080 = load i64, i64* %ptr_s
  %r3081 = getelementptr [15 x i8], [15 x i8]* @.str.1120, i64 0, i64 0
  %r3082 = ptrtoint i8* %r3081 to i64
  %r3083 = call i64 @_add(i64 %r3080, i64 %r3082)
  %r3084 = load i64, i64* %ptr_NL
  %r3085 = call i64 @_add(i64 %r3083, i64 %r3084)
  store i64 %r3085, i64* %ptr_s
  %r3086 = load i64, i64* %ptr_s
  %r3087 = getelementptr [2 x i8], [2 x i8]* @.str.1121, i64 0, i64 0
  %r3088 = ptrtoint i8* %r3087 to i64
  %r3089 = call i64 @_add(i64 %r3086, i64 %r3088)
  %r3090 = load i64, i64* %ptr_NL
  %r3091 = call i64 @_add(i64 %r3089, i64 %r3090)
  store i64 %r3091, i64* %ptr_s
  %r3092 = load i64, i64* %ptr_s
  %r3093 = getelementptr [45 x i8], [45 x i8]* @.str.1122, i64 0, i64 0
  %r3094 = ptrtoint i8* %r3093 to i64
  %r3095 = call i64 @_add(i64 %r3092, i64 %r3094)
  %r3096 = load i64, i64* %ptr_NL
  %r3097 = call i64 @_add(i64 %r3095, i64 %r3096)
  store i64 %r3097, i64* %ptr_s
  %r3098 = load i64, i64* %ptr_s
  %r3099 = getelementptr [32 x i8], [32 x i8]* @.str.1123, i64 0, i64 0
  %r3100 = ptrtoint i8* %r3099 to i64
  %r3101 = call i64 @_add(i64 %r3098, i64 %r3100)
  %r3102 = load i64, i64* %ptr_NL
  %r3103 = call i64 @_add(i64 %r3101, i64 %r3102)
  store i64 %r3103, i64* %ptr_s
  %r3104 = load i64, i64* %ptr_s
  %r3105 = getelementptr [34 x i8], [34 x i8]* @.str.1124, i64 0, i64 0
  %r3106 = ptrtoint i8* %r3105 to i64
  %r3107 = call i64 @_add(i64 %r3104, i64 %r3106)
  %r3108 = load i64, i64* %ptr_NL
  %r3109 = call i64 @_add(i64 %r3107, i64 %r3108)
  store i64 %r3109, i64* %ptr_s
  %r3110 = load i64, i64* %ptr_s
  %r3111 = getelementptr [36 x i8], [36 x i8]* @.str.1125, i64 0, i64 0
  %r3112 = ptrtoint i8* %r3111 to i64
  %r3113 = call i64 @_add(i64 %r3110, i64 %r3112)
  %r3114 = load i64, i64* %ptr_NL
  %r3115 = call i64 @_add(i64 %r3113, i64 %r3114)
  store i64 %r3115, i64* %ptr_s
  %r3116 = load i64, i64* %ptr_s
  %r3117 = getelementptr [36 x i8], [36 x i8]* @.str.1126, i64 0, i64 0
  %r3118 = ptrtoint i8* %r3117 to i64
  %r3119 = call i64 @_add(i64 %r3116, i64 %r3118)
  %r3120 = load i64, i64* %ptr_NL
  %r3121 = call i64 @_add(i64 %r3119, i64 %r3120)
  store i64 %r3121, i64* %ptr_s
  %r3122 = load i64, i64* %ptr_s
  %r3123 = getelementptr [24 x i8], [24 x i8]* @.str.1127, i64 0, i64 0
  %r3124 = ptrtoint i8* %r3123 to i64
  %r3125 = call i64 @_add(i64 %r3122, i64 %r3124)
  %r3126 = load i64, i64* %ptr_NL
  %r3127 = call i64 @_add(i64 %r3125, i64 %r3126)
  store i64 %r3127, i64* %ptr_s
  %r3128 = load i64, i64* %ptr_s
  %r3129 = getelementptr [35 x i8], [35 x i8]* @.str.1128, i64 0, i64 0
  %r3130 = ptrtoint i8* %r3129 to i64
  %r3131 = call i64 @_add(i64 %r3128, i64 %r3130)
  %r3132 = load i64, i64* %ptr_NL
  %r3133 = call i64 @_add(i64 %r3131, i64 %r3132)
  store i64 %r3133, i64* %ptr_s
  %r3134 = load i64, i64* %ptr_s
  %r3135 = getelementptr [33 x i8], [33 x i8]* @.str.1129, i64 0, i64 0
  %r3136 = ptrtoint i8* %r3135 to i64
  %r3137 = call i64 @_add(i64 %r3134, i64 %r3136)
  %r3138 = load i64, i64* %ptr_NL
  %r3139 = call i64 @_add(i64 %r3137, i64 %r3138)
  store i64 %r3139, i64* %ptr_s
  %r3140 = load i64, i64* %ptr_s
  %r3141 = getelementptr [38 x i8], [38 x i8]* @.str.1130, i64 0, i64 0
  %r3142 = ptrtoint i8* %r3141 to i64
  %r3143 = call i64 @_add(i64 %r3140, i64 %r3142)
  %r3144 = load i64, i64* %ptr_NL
  %r3145 = call i64 @_add(i64 %r3143, i64 %r3144)
  store i64 %r3145, i64* %ptr_s
  %r3146 = load i64, i64* %ptr_s
  %r3147 = getelementptr [45 x i8], [45 x i8]* @.str.1131, i64 0, i64 0
  %r3148 = ptrtoint i8* %r3147 to i64
  %r3149 = call i64 @_add(i64 %r3146, i64 %r3148)
  %r3150 = load i64, i64* %ptr_NL
  %r3151 = call i64 @_add(i64 %r3149, i64 %r3150)
  store i64 %r3151, i64* %ptr_s
  %r3152 = load i64, i64* %ptr_s
  %r3153 = getelementptr [17 x i8], [17 x i8]* @.str.1132, i64 0, i64 0
  %r3154 = ptrtoint i8* %r3153 to i64
  %r3155 = call i64 @_add(i64 %r3152, i64 %r3154)
  %r3156 = load i64, i64* %ptr_NL
  %r3157 = call i64 @_add(i64 %r3155, i64 %r3156)
  store i64 %r3157, i64* %ptr_s
  %r3158 = load i64, i64* %ptr_s
  %r3159 = getelementptr [6 x i8], [6 x i8]* @.str.1133, i64 0, i64 0
  %r3160 = ptrtoint i8* %r3159 to i64
  %r3161 = call i64 @_add(i64 %r3158, i64 %r3160)
  %r3162 = load i64, i64* %ptr_NL
  %r3163 = call i64 @_add(i64 %r3161, i64 %r3162)
  store i64 %r3163, i64* %ptr_s
  %r3164 = load i64, i64* %ptr_s
  %r3165 = getelementptr [48 x i8], [48 x i8]* @.str.1134, i64 0, i64 0
  %r3166 = ptrtoint i8* %r3165 to i64
  %r3167 = call i64 @_add(i64 %r3164, i64 %r3166)
  %r3168 = load i64, i64* %ptr_NL
  %r3169 = call i64 @_add(i64 %r3167, i64 %r3168)
  store i64 %r3169, i64* %ptr_s
  %r3170 = load i64, i64* %ptr_s
  %r3171 = getelementptr [37 x i8], [37 x i8]* @.str.1135, i64 0, i64 0
  %r3172 = ptrtoint i8* %r3171 to i64
  %r3173 = call i64 @_add(i64 %r3170, i64 %r3172)
  %r3174 = load i64, i64* %ptr_NL
  %r3175 = call i64 @_add(i64 %r3173, i64 %r3174)
  store i64 %r3175, i64* %ptr_s
  %r3176 = load i64, i64* %ptr_s
  %r3177 = getelementptr [43 x i8], [43 x i8]* @.str.1136, i64 0, i64 0
  %r3178 = ptrtoint i8* %r3177 to i64
  %r3179 = call i64 @_add(i64 %r3176, i64 %r3178)
  %r3180 = load i64, i64* %ptr_NL
  %r3181 = call i64 @_add(i64 %r3179, i64 %r3180)
  store i64 %r3181, i64* %ptr_s
  %r3182 = load i64, i64* %ptr_s
  %r3183 = getelementptr [6 x i8], [6 x i8]* @.str.1137, i64 0, i64 0
  %r3184 = ptrtoint i8* %r3183 to i64
  %r3185 = call i64 @_add(i64 %r3182, i64 %r3184)
  %r3186 = load i64, i64* %ptr_NL
  %r3187 = call i64 @_add(i64 %r3185, i64 %r3186)
  store i64 %r3187, i64* %ptr_s
  %r3188 = load i64, i64* %ptr_s
  %r3189 = getelementptr [37 x i8], [37 x i8]* @.str.1138, i64 0, i64 0
  %r3190 = ptrtoint i8* %r3189 to i64
  %r3191 = call i64 @_add(i64 %r3188, i64 %r3190)
  %r3192 = load i64, i64* %ptr_NL
  %r3193 = call i64 @_add(i64 %r3191, i64 %r3192)
  store i64 %r3193, i64* %ptr_s
  %r3194 = load i64, i64* %ptr_s
  %r3195 = getelementptr [46 x i8], [46 x i8]* @.str.1139, i64 0, i64 0
  %r3196 = ptrtoint i8* %r3195 to i64
  %r3197 = call i64 @_add(i64 %r3194, i64 %r3196)
  %r3198 = load i64, i64* %ptr_NL
  %r3199 = call i64 @_add(i64 %r3197, i64 %r3198)
  store i64 %r3199, i64* %ptr_s
  %r3200 = load i64, i64* %ptr_s
  %r3201 = getelementptr [46 x i8], [46 x i8]* @.str.1140, i64 0, i64 0
  %r3202 = ptrtoint i8* %r3201 to i64
  %r3203 = call i64 @_add(i64 %r3200, i64 %r3202)
  %r3204 = load i64, i64* %ptr_NL
  %r3205 = call i64 @_add(i64 %r3203, i64 %r3204)
  store i64 %r3205, i64* %ptr_s
  %r3206 = load i64, i64* %ptr_s
  %r3207 = getelementptr [17 x i8], [17 x i8]* @.str.1141, i64 0, i64 0
  %r3208 = ptrtoint i8* %r3207 to i64
  %r3209 = call i64 @_add(i64 %r3206, i64 %r3208)
  %r3210 = load i64, i64* %ptr_NL
  %r3211 = call i64 @_add(i64 %r3209, i64 %r3210)
  store i64 %r3211, i64* %ptr_s
  %r3212 = load i64, i64* %ptr_s
  %r3213 = getelementptr [6 x i8], [6 x i8]* @.str.1142, i64 0, i64 0
  %r3214 = ptrtoint i8* %r3213 to i64
  %r3215 = call i64 @_add(i64 %r3212, i64 %r3214)
  %r3216 = load i64, i64* %ptr_NL
  %r3217 = call i64 @_add(i64 %r3215, i64 %r3216)
  store i64 %r3217, i64* %ptr_s
  %r3218 = load i64, i64* %ptr_s
  %r3219 = getelementptr [16 x i8], [16 x i8]* @.str.1143, i64 0, i64 0
  %r3220 = ptrtoint i8* %r3219 to i64
  %r3221 = call i64 @_add(i64 %r3218, i64 %r3220)
  %r3222 = load i64, i64* %ptr_NL
  %r3223 = call i64 @_add(i64 %r3221, i64 %r3222)
  store i64 %r3223, i64* %ptr_s
  %r3224 = load i64, i64* %ptr_s
  %r3225 = getelementptr [2 x i8], [2 x i8]* @.str.1144, i64 0, i64 0
  %r3226 = ptrtoint i8* %r3225 to i64
  %r3227 = call i64 @_add(i64 %r3224, i64 %r3226)
  %r3228 = load i64, i64* %ptr_NL
  %r3229 = call i64 @_add(i64 %r3227, i64 %r3228)
  store i64 %r3229, i64* %ptr_s
  %r3230 = load i64, i64* %ptr_s
  %r3231 = getelementptr [50 x i8], [50 x i8]* @.str.1145, i64 0, i64 0
  %r3232 = ptrtoint i8* %r3231 to i64
  %r3233 = call i64 @_add(i64 %r3230, i64 %r3232)
  %r3234 = load i64, i64* %ptr_NL
  %r3235 = call i64 @_add(i64 %r3233, i64 %r3234)
  store i64 %r3235, i64* %ptr_s
  %r3236 = load i64, i64* %ptr_s
  %r3237 = getelementptr [38 x i8], [38 x i8]* @.str.1146, i64 0, i64 0
  %r3238 = ptrtoint i8* %r3237 to i64
  %r3239 = call i64 @_add(i64 %r3236, i64 %r3238)
  %r3240 = load i64, i64* %ptr_NL
  %r3241 = call i64 @_add(i64 %r3239, i64 %r3240)
  store i64 %r3241, i64* %ptr_s
  %r3242 = load i64, i64* %ptr_s
  %r3243 = getelementptr [49 x i8], [49 x i8]* @.str.1147, i64 0, i64 0
  %r3244 = ptrtoint i8* %r3243 to i64
  %r3245 = call i64 @_add(i64 %r3242, i64 %r3244)
  %r3246 = load i64, i64* %ptr_NL
  %r3247 = call i64 @_add(i64 %r3245, i64 %r3246)
  store i64 %r3247, i64* %ptr_s
  %r3248 = load i64, i64* %ptr_s
  %r3249 = getelementptr [7 x i8], [7 x i8]* @.str.1148, i64 0, i64 0
  %r3250 = ptrtoint i8* %r3249 to i64
  %r3251 = call i64 @_add(i64 %r3248, i64 %r3250)
  %r3252 = load i64, i64* %ptr_NL
  %r3253 = call i64 @_add(i64 %r3251, i64 %r3252)
  store i64 %r3253, i64* %ptr_s
  %r3254 = load i64, i64* %ptr_s
  %r3255 = getelementptr [42 x i8], [42 x i8]* @.str.1149, i64 0, i64 0
  %r3256 = ptrtoint i8* %r3255 to i64
  %r3257 = call i64 @_add(i64 %r3254, i64 %r3256)
  %r3258 = load i64, i64* %ptr_NL
  %r3259 = call i64 @_add(i64 %r3257, i64 %r3258)
  store i64 %r3259, i64* %ptr_s
  %r3260 = load i64, i64* %ptr_s
  %r3261 = getelementptr [51 x i8], [51 x i8]* @.str.1150, i64 0, i64 0
  %r3262 = ptrtoint i8* %r3261 to i64
  %r3263 = call i64 @_add(i64 %r3260, i64 %r3262)
  %r3264 = load i64, i64* %ptr_NL
  %r3265 = call i64 @_add(i64 %r3263, i64 %r3264)
  store i64 %r3265, i64* %ptr_s
  %r3266 = load i64, i64* %ptr_s
  %r3267 = getelementptr [33 x i8], [33 x i8]* @.str.1151, i64 0, i64 0
  %r3268 = ptrtoint i8* %r3267 to i64
  %r3269 = call i64 @_add(i64 %r3266, i64 %r3268)
  %r3270 = load i64, i64* %ptr_NL
  %r3271 = call i64 @_add(i64 %r3269, i64 %r3270)
  store i64 %r3271, i64* %ptr_s
  %r3272 = load i64, i64* %ptr_s
  %r3273 = getelementptr [34 x i8], [34 x i8]* @.str.1152, i64 0, i64 0
  %r3274 = ptrtoint i8* %r3273 to i64
  %r3275 = call i64 @_add(i64 %r3272, i64 %r3274)
  %r3276 = load i64, i64* %ptr_NL
  %r3277 = call i64 @_add(i64 %r3275, i64 %r3276)
  store i64 %r3277, i64* %ptr_s
  %r3278 = load i64, i64* %ptr_s
  %r3279 = getelementptr [49 x i8], [49 x i8]* @.str.1153, i64 0, i64 0
  %r3280 = ptrtoint i8* %r3279 to i64
  %r3281 = call i64 @_add(i64 %r3278, i64 %r3280)
  %r3282 = load i64, i64* %ptr_NL
  %r3283 = call i64 @_add(i64 %r3281, i64 %r3282)
  store i64 %r3283, i64* %ptr_s
  %r3284 = load i64, i64* %ptr_s
  %r3285 = getelementptr [11 x i8], [11 x i8]* @.str.1154, i64 0, i64 0
  %r3286 = ptrtoint i8* %r3285 to i64
  %r3287 = call i64 @_add(i64 %r3284, i64 %r3286)
  %r3288 = load i64, i64* %ptr_NL
  %r3289 = call i64 @_add(i64 %r3287, i64 %r3288)
  store i64 %r3289, i64* %ptr_s
  %r3290 = load i64, i64* %ptr_s
  %r3291 = getelementptr [33 x i8], [33 x i8]* @.str.1155, i64 0, i64 0
  %r3292 = ptrtoint i8* %r3291 to i64
  %r3293 = call i64 @_add(i64 %r3290, i64 %r3292)
  %r3294 = load i64, i64* %ptr_NL
  %r3295 = call i64 @_add(i64 %r3293, i64 %r3294)
  store i64 %r3295, i64* %ptr_s
  %r3296 = load i64, i64* %ptr_s
  %r3297 = getelementptr [36 x i8], [36 x i8]* @.str.1156, i64 0, i64 0
  %r3298 = ptrtoint i8* %r3297 to i64
  %r3299 = call i64 @_add(i64 %r3296, i64 %r3298)
  %r3300 = load i64, i64* %ptr_NL
  %r3301 = call i64 @_add(i64 %r3299, i64 %r3300)
  store i64 %r3301, i64* %ptr_s
  %r3302 = load i64, i64* %ptr_s
  %r3303 = getelementptr [25 x i8], [25 x i8]* @.str.1157, i64 0, i64 0
  %r3304 = ptrtoint i8* %r3303 to i64
  %r3305 = call i64 @_add(i64 %r3302, i64 %r3304)
  %r3306 = load i64, i64* %ptr_NL
  %r3307 = call i64 @_add(i64 %r3305, i64 %r3306)
  store i64 %r3307, i64* %ptr_s
  %r3308 = load i64, i64* %ptr_s
  %r3309 = getelementptr [15 x i8], [15 x i8]* @.str.1158, i64 0, i64 0
  %r3310 = ptrtoint i8* %r3309 to i64
  %r3311 = call i64 @_add(i64 %r3308, i64 %r3310)
  %r3312 = load i64, i64* %ptr_NL
  %r3313 = call i64 @_add(i64 %r3311, i64 %r3312)
  store i64 %r3313, i64* %ptr_s
  %r3314 = load i64, i64* %ptr_s
  %r3315 = getelementptr [6 x i8], [6 x i8]* @.str.1159, i64 0, i64 0
  %r3316 = ptrtoint i8* %r3315 to i64
  %r3317 = call i64 @_add(i64 %r3314, i64 %r3316)
  %r3318 = load i64, i64* %ptr_NL
  %r3319 = call i64 @_add(i64 %r3317, i64 %r3318)
  store i64 %r3319, i64* %ptr_s
  %r3320 = load i64, i64* %ptr_s
  %r3321 = getelementptr [52 x i8], [52 x i8]* @.str.1160, i64 0, i64 0
  %r3322 = ptrtoint i8* %r3321 to i64
  %r3323 = call i64 @_add(i64 %r3320, i64 %r3322)
  %r3324 = load i64, i64* %ptr_NL
  %r3325 = call i64 @_add(i64 %r3323, i64 %r3324)
  store i64 %r3325, i64* %ptr_s
  %r3326 = load i64, i64* %ptr_s
  %r3327 = getelementptr [35 x i8], [35 x i8]* @.str.1161, i64 0, i64 0
  %r3328 = ptrtoint i8* %r3327 to i64
  %r3329 = call i64 @_add(i64 %r3326, i64 %r3328)
  %r3330 = load i64, i64* %ptr_NL
  %r3331 = call i64 @_add(i64 %r3329, i64 %r3330)
  store i64 %r3331, i64* %ptr_s
  %r3332 = load i64, i64* %ptr_s
  %r3333 = getelementptr [41 x i8], [41 x i8]* @.str.1162, i64 0, i64 0
  %r3334 = ptrtoint i8* %r3333 to i64
  %r3335 = call i64 @_add(i64 %r3332, i64 %r3334)
  %r3336 = load i64, i64* %ptr_NL
  %r3337 = call i64 @_add(i64 %r3335, i64 %r3336)
  store i64 %r3337, i64* %ptr_s
  %r3338 = load i64, i64* %ptr_s
  %r3339 = getelementptr [35 x i8], [35 x i8]* @.str.1163, i64 0, i64 0
  %r3340 = ptrtoint i8* %r3339 to i64
  %r3341 = call i64 @_add(i64 %r3338, i64 %r3340)
  %r3342 = load i64, i64* %ptr_NL
  %r3343 = call i64 @_add(i64 %r3341, i64 %r3342)
  store i64 %r3343, i64* %ptr_s
  %r3344 = load i64, i64* %ptr_s
  %r3345 = getelementptr [40 x i8], [40 x i8]* @.str.1164, i64 0, i64 0
  %r3346 = ptrtoint i8* %r3345 to i64
  %r3347 = call i64 @_add(i64 %r3344, i64 %r3346)
  %r3348 = load i64, i64* %ptr_NL
  %r3349 = call i64 @_add(i64 %r3347, i64 %r3348)
  store i64 %r3349, i64* %ptr_s
  %r3350 = load i64, i64* %ptr_s
  %r3351 = getelementptr [27 x i8], [27 x i8]* @.str.1165, i64 0, i64 0
  %r3352 = ptrtoint i8* %r3351 to i64
  %r3353 = call i64 @_add(i64 %r3350, i64 %r3352)
  %r3354 = load i64, i64* %ptr_NL
  %r3355 = call i64 @_add(i64 %r3353, i64 %r3354)
  store i64 %r3355, i64* %ptr_s
  %r3356 = load i64, i64* %ptr_s
  %r3357 = getelementptr [17 x i8], [17 x i8]* @.str.1166, i64 0, i64 0
  %r3358 = ptrtoint i8* %r3357 to i64
  %r3359 = call i64 @_add(i64 %r3356, i64 %r3358)
  %r3360 = load i64, i64* %ptr_NL
  %r3361 = call i64 @_add(i64 %r3359, i64 %r3360)
  store i64 %r3361, i64* %ptr_s
  %r3362 = load i64, i64* %ptr_s
  %r3363 = getelementptr [6 x i8], [6 x i8]* @.str.1167, i64 0, i64 0
  %r3364 = ptrtoint i8* %r3363 to i64
  %r3365 = call i64 @_add(i64 %r3362, i64 %r3364)
  %r3366 = load i64, i64* %ptr_NL
  %r3367 = call i64 @_add(i64 %r3365, i64 %r3366)
  store i64 %r3367, i64* %ptr_s
  %r3368 = load i64, i64* %ptr_s
  %r3369 = getelementptr [49 x i8], [49 x i8]* @.str.1168, i64 0, i64 0
  %r3370 = ptrtoint i8* %r3369 to i64
  %r3371 = call i64 @_add(i64 %r3368, i64 %r3370)
  %r3372 = load i64, i64* %ptr_NL
  %r3373 = call i64 @_add(i64 %r3371, i64 %r3372)
  store i64 %r3373, i64* %ptr_s
  %r3374 = load i64, i64* %ptr_s
  %r3375 = getelementptr [63 x i8], [63 x i8]* @.str.1169, i64 0, i64 0
  %r3376 = ptrtoint i8* %r3375 to i64
  %r3377 = call i64 @_add(i64 %r3374, i64 %r3376)
  %r3378 = load i64, i64* %ptr_NL
  %r3379 = call i64 @_add(i64 %r3377, i64 %r3378)
  store i64 %r3379, i64* %ptr_s
  %r3380 = load i64, i64* %ptr_s
  %r3381 = getelementptr [32 x i8], [32 x i8]* @.str.1170, i64 0, i64 0
  %r3382 = ptrtoint i8* %r3381 to i64
  %r3383 = call i64 @_add(i64 %r3380, i64 %r3382)
  %r3384 = load i64, i64* %ptr_NL
  %r3385 = call i64 @_add(i64 %r3383, i64 %r3384)
  store i64 %r3385, i64* %ptr_s
  %r3386 = load i64, i64* %ptr_s
  %r3387 = getelementptr [40 x i8], [40 x i8]* @.str.1171, i64 0, i64 0
  %r3388 = ptrtoint i8* %r3387 to i64
  %r3389 = call i64 @_add(i64 %r3386, i64 %r3388)
  %r3390 = load i64, i64* %ptr_NL
  %r3391 = call i64 @_add(i64 %r3389, i64 %r3390)
  store i64 %r3391, i64* %ptr_s
  %r3392 = load i64, i64* %ptr_s
  %r3393 = getelementptr [6 x i8], [6 x i8]* @.str.1172, i64 0, i64 0
  %r3394 = ptrtoint i8* %r3393 to i64
  %r3395 = call i64 @_add(i64 %r3392, i64 %r3394)
  %r3396 = load i64, i64* %ptr_NL
  %r3397 = call i64 @_add(i64 %r3395, i64 %r3396)
  store i64 %r3397, i64* %ptr_s
  %r3398 = load i64, i64* %ptr_s
  %r3399 = getelementptr [52 x i8], [52 x i8]* @.str.1173, i64 0, i64 0
  %r3400 = ptrtoint i8* %r3399 to i64
  %r3401 = call i64 @_add(i64 %r3398, i64 %r3400)
  %r3402 = load i64, i64* %ptr_NL
  %r3403 = call i64 @_add(i64 %r3401, i64 %r3402)
  store i64 %r3403, i64* %ptr_s
  %r3404 = load i64, i64* %ptr_s
  %r3405 = getelementptr [31 x i8], [31 x i8]* @.str.1174, i64 0, i64 0
  %r3406 = ptrtoint i8* %r3405 to i64
  %r3407 = call i64 @_add(i64 %r3404, i64 %r3406)
  %r3408 = load i64, i64* %ptr_NL
  %r3409 = call i64 @_add(i64 %r3407, i64 %r3408)
  store i64 %r3409, i64* %ptr_s
  %r3410 = load i64, i64* %ptr_s
  %r3411 = getelementptr [43 x i8], [43 x i8]* @.str.1175, i64 0, i64 0
  %r3412 = ptrtoint i8* %r3411 to i64
  %r3413 = call i64 @_add(i64 %r3410, i64 %r3412)
  %r3414 = load i64, i64* %ptr_NL
  %r3415 = call i64 @_add(i64 %r3413, i64 %r3414)
  store i64 %r3415, i64* %ptr_s
  %r3416 = load i64, i64* %ptr_s
  %r3417 = getelementptr [58 x i8], [58 x i8]* @.str.1176, i64 0, i64 0
  %r3418 = ptrtoint i8* %r3417 to i64
  %r3419 = call i64 @_add(i64 %r3416, i64 %r3418)
  %r3420 = load i64, i64* %ptr_NL
  %r3421 = call i64 @_add(i64 %r3419, i64 %r3420)
  store i64 %r3421, i64* %ptr_s
  %r3422 = load i64, i64* %ptr_s
  %r3423 = getelementptr [30 x i8], [30 x i8]* @.str.1177, i64 0, i64 0
  %r3424 = ptrtoint i8* %r3423 to i64
  %r3425 = call i64 @_add(i64 %r3422, i64 %r3424)
  %r3426 = load i64, i64* %ptr_NL
  %r3427 = call i64 @_add(i64 %r3425, i64 %r3426)
  store i64 %r3427, i64* %ptr_s
  %r3428 = load i64, i64* %ptr_s
  %r3429 = getelementptr [39 x i8], [39 x i8]* @.str.1178, i64 0, i64 0
  %r3430 = ptrtoint i8* %r3429 to i64
  %r3431 = call i64 @_add(i64 %r3428, i64 %r3430)
  %r3432 = load i64, i64* %ptr_NL
  %r3433 = call i64 @_add(i64 %r3431, i64 %r3432)
  store i64 %r3433, i64* %ptr_s
  %r3434 = load i64, i64* %ptr_s
  %r3435 = getelementptr [54 x i8], [54 x i8]* @.str.1179, i64 0, i64 0
  %r3436 = ptrtoint i8* %r3435 to i64
  %r3437 = call i64 @_add(i64 %r3434, i64 %r3436)
  %r3438 = load i64, i64* %ptr_NL
  %r3439 = call i64 @_add(i64 %r3437, i64 %r3438)
  store i64 %r3439, i64* %ptr_s
  %r3440 = load i64, i64* %ptr_s
  %r3441 = getelementptr [11 x i8], [11 x i8]* @.str.1180, i64 0, i64 0
  %r3442 = ptrtoint i8* %r3441 to i64
  %r3443 = call i64 @_add(i64 %r3440, i64 %r3442)
  %r3444 = load i64, i64* %ptr_NL
  %r3445 = call i64 @_add(i64 %r3443, i64 %r3444)
  store i64 %r3445, i64* %ptr_s
  %r3446 = load i64, i64* %ptr_s
  %r3447 = getelementptr [59 x i8], [59 x i8]* @.str.1181, i64 0, i64 0
  %r3448 = ptrtoint i8* %r3447 to i64
  %r3449 = call i64 @_add(i64 %r3446, i64 %r3448)
  %r3450 = load i64, i64* %ptr_NL
  %r3451 = call i64 @_add(i64 %r3449, i64 %r3450)
  store i64 %r3451, i64* %ptr_s
  %r3452 = load i64, i64* %ptr_s
  %r3453 = getelementptr [18 x i8], [18 x i8]* @.str.1182, i64 0, i64 0
  %r3454 = ptrtoint i8* %r3453 to i64
  %r3455 = call i64 @_add(i64 %r3452, i64 %r3454)
  %r3456 = load i64, i64* %ptr_NL
  %r3457 = call i64 @_add(i64 %r3455, i64 %r3456)
  store i64 %r3457, i64* %ptr_s
  %r3458 = load i64, i64* %ptr_s
  %r3459 = getelementptr [12 x i8], [12 x i8]* @.str.1183, i64 0, i64 0
  %r3460 = ptrtoint i8* %r3459 to i64
  %r3461 = call i64 @_add(i64 %r3458, i64 %r3460)
  %r3462 = load i64, i64* %ptr_NL
  %r3463 = call i64 @_add(i64 %r3461, i64 %r3462)
  store i64 %r3463, i64* %ptr_s
  %r3464 = load i64, i64* %ptr_s
  %r3465 = getelementptr [18 x i8], [18 x i8]* @.str.1184, i64 0, i64 0
  %r3466 = ptrtoint i8* %r3465 to i64
  %r3467 = call i64 @_add(i64 %r3464, i64 %r3466)
  %r3468 = load i64, i64* %ptr_NL
  %r3469 = call i64 @_add(i64 %r3467, i64 %r3468)
  store i64 %r3469, i64* %ptr_s
  %r3470 = load i64, i64* %ptr_s
  %r3471 = getelementptr [7 x i8], [7 x i8]* @.str.1185, i64 0, i64 0
  %r3472 = ptrtoint i8* %r3471 to i64
  %r3473 = call i64 @_add(i64 %r3470, i64 %r3472)
  %r3474 = load i64, i64* %ptr_NL
  %r3475 = call i64 @_add(i64 %r3473, i64 %r3474)
  store i64 %r3475, i64* %ptr_s
  %r3476 = load i64, i64* %ptr_s
  %r3477 = getelementptr [75 x i8], [75 x i8]* @.str.1186, i64 0, i64 0
  %r3478 = ptrtoint i8* %r3477 to i64
  %r3479 = call i64 @_add(i64 %r3476, i64 %r3478)
  %r3480 = load i64, i64* %ptr_NL
  %r3481 = call i64 @_add(i64 %r3479, i64 %r3480)
  store i64 %r3481, i64* %ptr_s
  %r3482 = load i64, i64* %ptr_s
  %r3483 = getelementptr [26 x i8], [26 x i8]* @.str.1187, i64 0, i64 0
  %r3484 = ptrtoint i8* %r3483 to i64
  %r3485 = call i64 @_add(i64 %r3482, i64 %r3484)
  %r3486 = load i64, i64* %ptr_NL
  %r3487 = call i64 @_add(i64 %r3485, i64 %r3486)
  store i64 %r3487, i64* %ptr_s
  %r3488 = load i64, i64* %ptr_s
  %r3489 = getelementptr [17 x i8], [17 x i8]* @.str.1188, i64 0, i64 0
  %r3490 = ptrtoint i8* %r3489 to i64
  %r3491 = call i64 @_add(i64 %r3488, i64 %r3490)
  %r3492 = load i64, i64* %ptr_NL
  %r3493 = call i64 @_add(i64 %r3491, i64 %r3492)
  store i64 %r3493, i64* %ptr_s
  %r3494 = load i64, i64* %ptr_s
  %r3495 = getelementptr [6 x i8], [6 x i8]* @.str.1189, i64 0, i64 0
  %r3496 = ptrtoint i8* %r3495 to i64
  %r3497 = call i64 @_add(i64 %r3494, i64 %r3496)
  %r3498 = load i64, i64* %ptr_NL
  %r3499 = call i64 @_add(i64 %r3497, i64 %r3498)
  store i64 %r3499, i64* %ptr_s
  %r3500 = load i64, i64* %ptr_s
  %r3501 = getelementptr [20 x i8], [20 x i8]* @.str.1190, i64 0, i64 0
  %r3502 = ptrtoint i8* %r3501 to i64
  %r3503 = call i64 @_add(i64 %r3500, i64 %r3502)
  %r3504 = load i64, i64* %ptr_NL
  %r3505 = call i64 @_add(i64 %r3503, i64 %r3504)
  store i64 %r3505, i64* %ptr_s
  %r3506 = load i64, i64* %ptr_s
  %r3507 = getelementptr [2 x i8], [2 x i8]* @.str.1191, i64 0, i64 0
  %r3508 = ptrtoint i8* %r3507 to i64
  %r3509 = call i64 @_add(i64 %r3506, i64 %r3508)
  %r3510 = load i64, i64* %ptr_NL
  %r3511 = call i64 @_add(i64 %r3509, i64 %r3510)
  store i64 %r3511, i64* %ptr_s
  %r3512 = load i64, i64* %ptr_s
  %r3513 = getelementptr [90 x i8], [90 x i8]* @.str.1192, i64 0, i64 0
  %r3514 = ptrtoint i8* %r3513 to i64
  %r3515 = call i64 @_add(i64 %r3512, i64 %r3514)
  %r3516 = load i64, i64* %ptr_NL
  %r3517 = call i64 @_add(i64 %r3515, i64 %r3516)
  store i64 %r3517, i64* %ptr_s
  %r3518 = load i64, i64* %ptr_s
  %r3519 = getelementptr [184 x i8], [184 x i8]* @.str.1193, i64 0, i64 0
  %r3520 = ptrtoint i8* %r3519 to i64
  %r3521 = call i64 @_add(i64 %r3518, i64 %r3520)
  %r3522 = load i64, i64* %ptr_NL
  %r3523 = call i64 @_add(i64 %r3521, i64 %r3522)
  store i64 %r3523, i64* %ptr_s
  %r3524 = load i64, i64* %ptr_s
  %r3525 = getelementptr [15 x i8], [15 x i8]* @.str.1194, i64 0, i64 0
  %r3526 = ptrtoint i8* %r3525 to i64
  %r3527 = call i64 @_add(i64 %r3524, i64 %r3526)
  %r3528 = load i64, i64* %ptr_NL
  %r3529 = call i64 @_add(i64 %r3527, i64 %r3528)
  store i64 %r3529, i64* %ptr_s
  %r3530 = load i64, i64* %ptr_s
  %r3531 = getelementptr [2 x i8], [2 x i8]* @.str.1195, i64 0, i64 0
  %r3532 = ptrtoint i8* %r3531 to i64
  %r3533 = call i64 @_add(i64 %r3530, i64 %r3532)
  %r3534 = load i64, i64* %ptr_NL
  %r3535 = call i64 @_add(i64 %r3533, i64 %r3534)
  store i64 %r3535, i64* %ptr_s
  %r3536 = load i64, i64* %ptr_s
  %r3537 = getelementptr [31 x i8], [31 x i8]* @.str.1196, i64 0, i64 0
  %r3538 = ptrtoint i8* %r3537 to i64
  %r3539 = call i64 @_add(i64 %r3536, i64 %r3538)
  %r3540 = load i64, i64* %ptr_NL
  %r3541 = call i64 @_add(i64 %r3539, i64 %r3540)
  store i64 %r3541, i64* %ptr_s
  %r3542 = load i64, i64* %ptr_s
  %r3543 = getelementptr [22 x i8], [22 x i8]* @.str.1197, i64 0, i64 0
  %r3544 = ptrtoint i8* %r3543 to i64
  %r3545 = call i64 @_add(i64 %r3542, i64 %r3544)
  %r3546 = load i64, i64* %ptr_NL
  %r3547 = call i64 @_add(i64 %r3545, i64 %r3546)
  store i64 %r3547, i64* %ptr_s
  %r3548 = load i64, i64* %ptr_s
  %r3549 = getelementptr [6 x i8], [6 x i8]* @.str.1198, i64 0, i64 0
  %r3550 = ptrtoint i8* %r3549 to i64
  %r3551 = call i64 @_add(i64 %r3548, i64 %r3550)
  %r3552 = load i64, i64* %ptr_NL
  %r3553 = call i64 @_add(i64 %r3551, i64 %r3552)
  store i64 %r3553, i64* %ptr_s
  %r3554 = load i64, i64* %ptr_s
  %r3555 = getelementptr [46 x i8], [46 x i8]* @.str.1199, i64 0, i64 0
  %r3556 = ptrtoint i8* %r3555 to i64
  %r3557 = call i64 @_add(i64 %r3554, i64 %r3556)
  %r3558 = load i64, i64* %ptr_NL
  %r3559 = call i64 @_add(i64 %r3557, i64 %r3558)
  store i64 %r3559, i64* %ptr_s
  %r3560 = load i64, i64* %ptr_s
  %r3561 = getelementptr [44 x i8], [44 x i8]* @.str.1200, i64 0, i64 0
  %r3562 = ptrtoint i8* %r3561 to i64
  %r3563 = call i64 @_add(i64 %r3560, i64 %r3562)
  %r3564 = load i64, i64* %ptr_NL
  %r3565 = call i64 @_add(i64 %r3563, i64 %r3564)
  store i64 %r3565, i64* %ptr_s
  %r3566 = load i64, i64* %ptr_s
  %r3567 = getelementptr [25 x i8], [25 x i8]* @.str.1201, i64 0, i64 0
  %r3568 = ptrtoint i8* %r3567 to i64
  %r3569 = call i64 @_add(i64 %r3566, i64 %r3568)
  %r3570 = load i64, i64* %ptr_NL
  %r3571 = call i64 @_add(i64 %r3569, i64 %r3570)
  store i64 %r3571, i64* %ptr_s
  %r3572 = load i64, i64* %ptr_s
  %r3573 = getelementptr [30 x i8], [30 x i8]* @.str.1202, i64 0, i64 0
  %r3574 = ptrtoint i8* %r3573 to i64
  %r3575 = call i64 @_add(i64 %r3572, i64 %r3574)
  %r3576 = load i64, i64* %ptr_NL
  %r3577 = call i64 @_add(i64 %r3575, i64 %r3576)
  store i64 %r3577, i64* %ptr_s
  %r3578 = load i64, i64* %ptr_s
  %r3579 = getelementptr [23 x i8], [23 x i8]* @.str.1203, i64 0, i64 0
  %r3580 = ptrtoint i8* %r3579 to i64
  %r3581 = call i64 @_add(i64 %r3578, i64 %r3580)
  %r3582 = load i64, i64* %ptr_NL
  %r3583 = call i64 @_add(i64 %r3581, i64 %r3582)
  store i64 %r3583, i64* %ptr_s
  %r3584 = load i64, i64* %ptr_s
  %r3585 = getelementptr [43 x i8], [43 x i8]* @.str.1204, i64 0, i64 0
  %r3586 = ptrtoint i8* %r3585 to i64
  %r3587 = call i64 @_add(i64 %r3584, i64 %r3586)
  %r3588 = load i64, i64* %ptr_NL
  %r3589 = call i64 @_add(i64 %r3587, i64 %r3588)
  store i64 %r3589, i64* %ptr_s
  %r3590 = load i64, i64* %ptr_s
  %r3591 = getelementptr [17 x i8], [17 x i8]* @.str.1205, i64 0, i64 0
  %r3592 = ptrtoint i8* %r3591 to i64
  %r3593 = call i64 @_add(i64 %r3590, i64 %r3592)
  %r3594 = load i64, i64* %ptr_NL
  %r3595 = call i64 @_add(i64 %r3593, i64 %r3594)
  store i64 %r3595, i64* %ptr_s
  %r3596 = load i64, i64* %ptr_s
  %r3597 = getelementptr [2 x i8], [2 x i8]* @.str.1206, i64 0, i64 0
  %r3598 = ptrtoint i8* %r3597 to i64
  %r3599 = call i64 @_add(i64 %r3596, i64 %r3598)
  %r3600 = load i64, i64* %ptr_NL
  %r3601 = call i64 @_add(i64 %r3599, i64 %r3600)
  store i64 %r3601, i64* %ptr_s
  %r3602 = load i64, i64* %ptr_s
  %r3603 = getelementptr [39 x i8], [39 x i8]* @.str.1207, i64 0, i64 0
  %r3604 = ptrtoint i8* %r3603 to i64
  %r3605 = call i64 @_add(i64 %r3602, i64 %r3604)
  %r3606 = load i64, i64* %ptr_NL
  %r3607 = call i64 @_add(i64 %r3605, i64 %r3606)
  store i64 %r3607, i64* %ptr_s
  %r3608 = load i64, i64* %ptr_s
  %r3609 = getelementptr [22 x i8], [22 x i8]* @.str.1208, i64 0, i64 0
  %r3610 = ptrtoint i8* %r3609 to i64
  %r3611 = call i64 @_add(i64 %r3608, i64 %r3610)
  %r3612 = load i64, i64* %ptr_NL
  %r3613 = call i64 @_add(i64 %r3611, i64 %r3612)
  store i64 %r3613, i64* %ptr_s
  %r3614 = load i64, i64* %ptr_s
  %r3615 = getelementptr [6 x i8], [6 x i8]* @.str.1209, i64 0, i64 0
  %r3616 = ptrtoint i8* %r3615 to i64
  %r3617 = call i64 @_add(i64 %r3614, i64 %r3616)
  %r3618 = load i64, i64* %ptr_NL
  %r3619 = call i64 @_add(i64 %r3617, i64 %r3618)
  store i64 %r3619, i64* %ptr_s
  %r3620 = load i64, i64* %ptr_s
  %r3621 = getelementptr [46 x i8], [46 x i8]* @.str.1210, i64 0, i64 0
  %r3622 = ptrtoint i8* %r3621 to i64
  %r3623 = call i64 @_add(i64 %r3620, i64 %r3622)
  %r3624 = load i64, i64* %ptr_NL
  %r3625 = call i64 @_add(i64 %r3623, i64 %r3624)
  store i64 %r3625, i64* %ptr_s
  %r3626 = load i64, i64* %ptr_s
  %r3627 = getelementptr [42 x i8], [42 x i8]* @.str.1211, i64 0, i64 0
  %r3628 = ptrtoint i8* %r3627 to i64
  %r3629 = call i64 @_add(i64 %r3626, i64 %r3628)
  %r3630 = load i64, i64* %ptr_NL
  %r3631 = call i64 @_add(i64 %r3629, i64 %r3630)
  store i64 %r3631, i64* %ptr_s
  %r3632 = load i64, i64* %ptr_s
  %r3633 = getelementptr [42 x i8], [42 x i8]* @.str.1212, i64 0, i64 0
  %r3634 = ptrtoint i8* %r3633 to i64
  %r3635 = call i64 @_add(i64 %r3632, i64 %r3634)
  %r3636 = load i64, i64* %ptr_NL
  %r3637 = call i64 @_add(i64 %r3635, i64 %r3636)
  store i64 %r3637, i64* %ptr_s
  %r3638 = load i64, i64* %ptr_s
  %r3639 = getelementptr [25 x i8], [25 x i8]* @.str.1213, i64 0, i64 0
  %r3640 = ptrtoint i8* %r3639 to i64
  %r3641 = call i64 @_add(i64 %r3638, i64 %r3640)
  %r3642 = load i64, i64* %ptr_NL
  %r3643 = call i64 @_add(i64 %r3641, i64 %r3642)
  store i64 %r3643, i64* %ptr_s
  %r3644 = load i64, i64* %ptr_s
  %r3645 = getelementptr [25 x i8], [25 x i8]* @.str.1214, i64 0, i64 0
  %r3646 = ptrtoint i8* %r3645 to i64
  %r3647 = call i64 @_add(i64 %r3644, i64 %r3646)
  %r3648 = load i64, i64* %ptr_NL
  %r3649 = call i64 @_add(i64 %r3647, i64 %r3648)
  store i64 %r3649, i64* %ptr_s
  %r3650 = load i64, i64* %ptr_s
  %r3651 = getelementptr [32 x i8], [32 x i8]* @.str.1215, i64 0, i64 0
  %r3652 = ptrtoint i8* %r3651 to i64
  %r3653 = call i64 @_add(i64 %r3650, i64 %r3652)
  %r3654 = load i64, i64* %ptr_NL
  %r3655 = call i64 @_add(i64 %r3653, i64 %r3654)
  store i64 %r3655, i64* %ptr_s
  %r3656 = load i64, i64* %ptr_s
  %r3657 = getelementptr [31 x i8], [31 x i8]* @.str.1216, i64 0, i64 0
  %r3658 = ptrtoint i8* %r3657 to i64
  %r3659 = call i64 @_add(i64 %r3656, i64 %r3658)
  %r3660 = load i64, i64* %ptr_NL
  %r3661 = call i64 @_add(i64 %r3659, i64 %r3660)
  store i64 %r3661, i64* %ptr_s
  %r3662 = load i64, i64* %ptr_s
  %r3663 = getelementptr [34 x i8], [34 x i8]* @.str.1217, i64 0, i64 0
  %r3664 = ptrtoint i8* %r3663 to i64
  %r3665 = call i64 @_add(i64 %r3662, i64 %r3664)
  %r3666 = load i64, i64* %ptr_NL
  %r3667 = call i64 @_add(i64 %r3665, i64 %r3666)
  store i64 %r3667, i64* %ptr_s
  %r3668 = load i64, i64* %ptr_s
  %r3669 = getelementptr [23 x i8], [23 x i8]* @.str.1218, i64 0, i64 0
  %r3670 = ptrtoint i8* %r3669 to i64
  %r3671 = call i64 @_add(i64 %r3668, i64 %r3670)
  %r3672 = load i64, i64* %ptr_NL
  %r3673 = call i64 @_add(i64 %r3671, i64 %r3672)
  store i64 %r3673, i64* %ptr_s
  %r3674 = load i64, i64* %ptr_s
  %r3675 = getelementptr [40 x i8], [40 x i8]* @.str.1219, i64 0, i64 0
  %r3676 = ptrtoint i8* %r3675 to i64
  %r3677 = call i64 @_add(i64 %r3674, i64 %r3676)
  %r3678 = load i64, i64* %ptr_NL
  %r3679 = call i64 @_add(i64 %r3677, i64 %r3678)
  store i64 %r3679, i64* %ptr_s
  %r3680 = load i64, i64* %ptr_s
  %r3681 = getelementptr [6 x i8], [6 x i8]* @.str.1220, i64 0, i64 0
  %r3682 = ptrtoint i8* %r3681 to i64
  %r3683 = call i64 @_add(i64 %r3680, i64 %r3682)
  %r3684 = load i64, i64* %ptr_NL
  %r3685 = call i64 @_add(i64 %r3683, i64 %r3684)
  store i64 %r3685, i64* %ptr_s
  %r3686 = load i64, i64* %ptr_s
  %r3687 = getelementptr [27 x i8], [27 x i8]* @.str.1221, i64 0, i64 0
  %r3688 = ptrtoint i8* %r3687 to i64
  %r3689 = call i64 @_add(i64 %r3686, i64 %r3688)
  %r3690 = load i64, i64* %ptr_NL
  %r3691 = call i64 @_add(i64 %r3689, i64 %r3690)
  store i64 %r3691, i64* %ptr_s
  %r3692 = load i64, i64* %ptr_s
  %r3693 = getelementptr [27 x i8], [27 x i8]* @.str.1222, i64 0, i64 0
  %r3694 = ptrtoint i8* %r3693 to i64
  %r3695 = call i64 @_add(i64 %r3692, i64 %r3694)
  %r3696 = load i64, i64* %ptr_NL
  %r3697 = call i64 @_add(i64 %r3695, i64 %r3696)
  store i64 %r3697, i64* %ptr_s
  %r3698 = load i64, i64* %ptr_s
  %r3699 = getelementptr [27 x i8], [27 x i8]* @.str.1223, i64 0, i64 0
  %r3700 = ptrtoint i8* %r3699 to i64
  %r3701 = call i64 @_add(i64 %r3698, i64 %r3700)
  %r3702 = load i64, i64* %ptr_NL
  %r3703 = call i64 @_add(i64 %r3701, i64 %r3702)
  store i64 %r3703, i64* %ptr_s
  %r3704 = load i64, i64* %ptr_s
  %r3705 = getelementptr [16 x i8], [16 x i8]* @.str.1224, i64 0, i64 0
  %r3706 = ptrtoint i8* %r3705 to i64
  %r3707 = call i64 @_add(i64 %r3704, i64 %r3706)
  %r3708 = load i64, i64* %ptr_NL
  %r3709 = call i64 @_add(i64 %r3707, i64 %r3708)
  store i64 %r3709, i64* %ptr_s
  %r3710 = load i64, i64* %ptr_s
  %r3711 = getelementptr [2 x i8], [2 x i8]* @.str.1225, i64 0, i64 0
  %r3712 = ptrtoint i8* %r3711 to i64
  %r3713 = call i64 @_add(i64 %r3710, i64 %r3712)
  %r3714 = load i64, i64* %ptr_NL
  %r3715 = call i64 @_add(i64 %r3713, i64 %r3714)
  store i64 %r3715, i64* %ptr_s
  %r3716 = load i64, i64* %ptr_s
  %r3717 = getelementptr [42 x i8], [42 x i8]* @.str.1226, i64 0, i64 0
  %r3718 = ptrtoint i8* %r3717 to i64
  %r3719 = call i64 @_add(i64 %r3716, i64 %r3718)
  %r3720 = load i64, i64* %ptr_NL
  %r3721 = call i64 @_add(i64 %r3719, i64 %r3720)
  store i64 %r3721, i64* %ptr_s
  %r3722 = load i64, i64* %ptr_s
  %r3723 = getelementptr [22 x i8], [22 x i8]* @.str.1227, i64 0, i64 0
  %r3724 = ptrtoint i8* %r3723 to i64
  %r3725 = call i64 @_add(i64 %r3722, i64 %r3724)
  %r3726 = load i64, i64* %ptr_NL
  %r3727 = call i64 @_add(i64 %r3725, i64 %r3726)
  store i64 %r3727, i64* %ptr_s
  %r3728 = load i64, i64* %ptr_s
  %r3729 = getelementptr [6 x i8], [6 x i8]* @.str.1228, i64 0, i64 0
  %r3730 = ptrtoint i8* %r3729 to i64
  %r3731 = call i64 @_add(i64 %r3728, i64 %r3730)
  %r3732 = load i64, i64* %ptr_NL
  %r3733 = call i64 @_add(i64 %r3731, i64 %r3732)
  store i64 %r3733, i64* %ptr_s
  %r3734 = load i64, i64* %ptr_s
  %r3735 = getelementptr [46 x i8], [46 x i8]* @.str.1229, i64 0, i64 0
  %r3736 = ptrtoint i8* %r3735 to i64
  %r3737 = call i64 @_add(i64 %r3734, i64 %r3736)
  %r3738 = load i64, i64* %ptr_NL
  %r3739 = call i64 @_add(i64 %r3737, i64 %r3738)
  store i64 %r3739, i64* %ptr_s
  %r3740 = load i64, i64* %ptr_s
  %r3741 = getelementptr [43 x i8], [43 x i8]* @.str.1230, i64 0, i64 0
  %r3742 = ptrtoint i8* %r3741 to i64
  %r3743 = call i64 @_add(i64 %r3740, i64 %r3742)
  %r3744 = load i64, i64* %ptr_NL
  %r3745 = call i64 @_add(i64 %r3743, i64 %r3744)
  store i64 %r3745, i64* %ptr_s
  %r3746 = load i64, i64* %ptr_s
  %r3747 = getelementptr [44 x i8], [44 x i8]* @.str.1231, i64 0, i64 0
  %r3748 = ptrtoint i8* %r3747 to i64
  %r3749 = call i64 @_add(i64 %r3746, i64 %r3748)
  %r3750 = load i64, i64* %ptr_NL
  %r3751 = call i64 @_add(i64 %r3749, i64 %r3750)
  store i64 %r3751, i64* %ptr_s
  %r3752 = load i64, i64* %ptr_s
  %r3753 = getelementptr [24 x i8], [24 x i8]* @.str.1232, i64 0, i64 0
  %r3754 = ptrtoint i8* %r3753 to i64
  %r3755 = call i64 @_add(i64 %r3752, i64 %r3754)
  %r3756 = load i64, i64* %ptr_NL
  %r3757 = call i64 @_add(i64 %r3755, i64 %r3756)
  store i64 %r3757, i64* %ptr_s
  %r3758 = load i64, i64* %ptr_s
  %r3759 = getelementptr [23 x i8], [23 x i8]* @.str.1233, i64 0, i64 0
  %r3760 = ptrtoint i8* %r3759 to i64
  %r3761 = call i64 @_add(i64 %r3758, i64 %r3760)
  %r3762 = load i64, i64* %ptr_NL
  %r3763 = call i64 @_add(i64 %r3761, i64 %r3762)
  store i64 %r3763, i64* %ptr_s
  %r3764 = load i64, i64* %ptr_s
  %r3765 = getelementptr [30 x i8], [30 x i8]* @.str.1234, i64 0, i64 0
  %r3766 = ptrtoint i8* %r3765 to i64
  %r3767 = call i64 @_add(i64 %r3764, i64 %r3766)
  %r3768 = load i64, i64* %ptr_NL
  %r3769 = call i64 @_add(i64 %r3767, i64 %r3768)
  store i64 %r3769, i64* %ptr_s
  %r3770 = load i64, i64* %ptr_s
  %r3771 = getelementptr [23 x i8], [23 x i8]* @.str.1235, i64 0, i64 0
  %r3772 = ptrtoint i8* %r3771 to i64
  %r3773 = call i64 @_add(i64 %r3770, i64 %r3772)
  %r3774 = load i64, i64* %ptr_NL
  %r3775 = call i64 @_add(i64 %r3773, i64 %r3774)
  store i64 %r3775, i64* %ptr_s
  %r3776 = load i64, i64* %ptr_s
  %r3777 = getelementptr [43 x i8], [43 x i8]* @.str.1236, i64 0, i64 0
  %r3778 = ptrtoint i8* %r3777 to i64
  %r3779 = call i64 @_add(i64 %r3776, i64 %r3778)
  %r3780 = load i64, i64* %ptr_NL
  %r3781 = call i64 @_add(i64 %r3779, i64 %r3780)
  store i64 %r3781, i64* %ptr_s
  %r3782 = load i64, i64* %ptr_s
  %r3783 = getelementptr [20 x i8], [20 x i8]* @.str.1237, i64 0, i64 0
  %r3784 = ptrtoint i8* %r3783 to i64
  %r3785 = call i64 @_add(i64 %r3782, i64 %r3784)
  %r3786 = load i64, i64* %ptr_NL
  %r3787 = call i64 @_add(i64 %r3785, i64 %r3786)
  store i64 %r3787, i64* %ptr_s
  %r3788 = load i64, i64* %ptr_s
  %r3789 = getelementptr [2 x i8], [2 x i8]* @.str.1238, i64 0, i64 0
  %r3790 = ptrtoint i8* %r3789 to i64
  %r3791 = call i64 @_add(i64 %r3788, i64 %r3790)
  %r3792 = load i64, i64* %ptr_NL
  %r3793 = call i64 @_add(i64 %r3791, i64 %r3792)
  store i64 %r3793, i64* %ptr_s
  %r3794 = load i64, i64* %ptr_s
  %r3795 = getelementptr [51 x i8], [51 x i8]* @.str.1239, i64 0, i64 0
  %r3796 = ptrtoint i8* %r3795 to i64
  %r3797 = call i64 @_add(i64 %r3794, i64 %r3796)
  %r3798 = load i64, i64* %ptr_NL
  %r3799 = call i64 @_add(i64 %r3797, i64 %r3798)
  store i64 %r3799, i64* %ptr_s
  %r3800 = load i64, i64* %ptr_s
  %r3801 = getelementptr [22 x i8], [22 x i8]* @.str.1240, i64 0, i64 0
  %r3802 = ptrtoint i8* %r3801 to i64
  %r3803 = call i64 @_add(i64 %r3800, i64 %r3802)
  %r3804 = load i64, i64* %ptr_NL
  %r3805 = call i64 @_add(i64 %r3803, i64 %r3804)
  store i64 %r3805, i64* %ptr_s
  %r3806 = load i64, i64* %ptr_s
  %r3807 = getelementptr [6 x i8], [6 x i8]* @.str.1241, i64 0, i64 0
  %r3808 = ptrtoint i8* %r3807 to i64
  %r3809 = call i64 @_add(i64 %r3806, i64 %r3808)
  %r3810 = load i64, i64* %ptr_NL
  %r3811 = call i64 @_add(i64 %r3809, i64 %r3810)
  store i64 %r3811, i64* %ptr_s
  %r3812 = load i64, i64* %ptr_s
  %r3813 = getelementptr [46 x i8], [46 x i8]* @.str.1242, i64 0, i64 0
  %r3814 = ptrtoint i8* %r3813 to i64
  %r3815 = call i64 @_add(i64 %r3812, i64 %r3814)
  %r3816 = load i64, i64* %ptr_NL
  %r3817 = call i64 @_add(i64 %r3815, i64 %r3816)
  store i64 %r3817, i64* %ptr_s
  %r3818 = load i64, i64* %ptr_s
  %r3819 = getelementptr [29 x i8], [29 x i8]* @.str.1243, i64 0, i64 0
  %r3820 = ptrtoint i8* %r3819 to i64
  %r3821 = call i64 @_add(i64 %r3818, i64 %r3820)
  %r3822 = load i64, i64* %ptr_NL
  %r3823 = call i64 @_add(i64 %r3821, i64 %r3822)
  store i64 %r3823, i64* %ptr_s
  %r3824 = load i64, i64* %ptr_s
  %r3825 = getelementptr [39 x i8], [39 x i8]* @.str.1244, i64 0, i64 0
  %r3826 = ptrtoint i8* %r3825 to i64
  %r3827 = call i64 @_add(i64 %r3824, i64 %r3826)
  %r3828 = load i64, i64* %ptr_NL
  %r3829 = call i64 @_add(i64 %r3827, i64 %r3828)
  store i64 %r3829, i64* %ptr_s
  %r3830 = load i64, i64* %ptr_s
  %r3831 = getelementptr [6 x i8], [6 x i8]* @.str.1245, i64 0, i64 0
  %r3832 = ptrtoint i8* %r3831 to i64
  %r3833 = call i64 @_add(i64 %r3830, i64 %r3832)
  %r3834 = load i64, i64* %ptr_NL
  %r3835 = call i64 @_add(i64 %r3833, i64 %r3834)
  store i64 %r3835, i64* %ptr_s
  %r3836 = load i64, i64* %ptr_s
  %r3837 = getelementptr [43 x i8], [43 x i8]* @.str.1246, i64 0, i64 0
  %r3838 = ptrtoint i8* %r3837 to i64
  %r3839 = call i64 @_add(i64 %r3836, i64 %r3838)
  %r3840 = load i64, i64* %ptr_NL
  %r3841 = call i64 @_add(i64 %r3839, i64 %r3840)
  store i64 %r3841, i64* %ptr_s
  %r3842 = load i64, i64* %ptr_s
  %r3843 = getelementptr [44 x i8], [44 x i8]* @.str.1247, i64 0, i64 0
  %r3844 = ptrtoint i8* %r3843 to i64
  %r3845 = call i64 @_add(i64 %r3842, i64 %r3844)
  %r3846 = load i64, i64* %ptr_NL
  %r3847 = call i64 @_add(i64 %r3845, i64 %r3846)
  store i64 %r3847, i64* %ptr_s
  %r3848 = load i64, i64* %ptr_s
  %r3849 = getelementptr [24 x i8], [24 x i8]* @.str.1248, i64 0, i64 0
  %r3850 = ptrtoint i8* %r3849 to i64
  %r3851 = call i64 @_add(i64 %r3848, i64 %r3850)
  %r3852 = load i64, i64* %ptr_NL
  %r3853 = call i64 @_add(i64 %r3851, i64 %r3852)
  store i64 %r3853, i64* %ptr_s
  %r3854 = load i64, i64* %ptr_s
  %r3855 = getelementptr [23 x i8], [23 x i8]* @.str.1249, i64 0, i64 0
  %r3856 = ptrtoint i8* %r3855 to i64
  %r3857 = call i64 @_add(i64 %r3854, i64 %r3856)
  %r3858 = load i64, i64* %ptr_NL
  %r3859 = call i64 @_add(i64 %r3857, i64 %r3858)
  store i64 %r3859, i64* %ptr_s
  %r3860 = load i64, i64* %ptr_s
  %r3861 = getelementptr [23 x i8], [23 x i8]* @.str.1250, i64 0, i64 0
  %r3862 = ptrtoint i8* %r3861 to i64
  %r3863 = call i64 @_add(i64 %r3860, i64 %r3862)
  %r3864 = load i64, i64* %ptr_NL
  %r3865 = call i64 @_add(i64 %r3863, i64 %r3864)
  store i64 %r3865, i64* %ptr_s
  %r3866 = load i64, i64* %ptr_s
  %r3867 = getelementptr [17 x i8], [17 x i8]* @.str.1251, i64 0, i64 0
  %r3868 = ptrtoint i8* %r3867 to i64
  %r3869 = call i64 @_add(i64 %r3866, i64 %r3868)
  %r3870 = load i64, i64* %ptr_NL
  %r3871 = call i64 @_add(i64 %r3869, i64 %r3870)
  store i64 %r3871, i64* %ptr_s
  %r3872 = load i64, i64* %ptr_s
  %r3873 = getelementptr [20 x i8], [20 x i8]* @.str.1252, i64 0, i64 0
  %r3874 = ptrtoint i8* %r3873 to i64
  %r3875 = call i64 @_add(i64 %r3872, i64 %r3874)
  %r3876 = load i64, i64* %ptr_NL
  %r3877 = call i64 @_add(i64 %r3875, i64 %r3876)
  store i64 %r3877, i64* %ptr_s
  %r3878 = load i64, i64* %ptr_s
  %r3879 = getelementptr [2 x i8], [2 x i8]* @.str.1253, i64 0, i64 0
  %r3880 = ptrtoint i8* %r3879 to i64
  %r3881 = call i64 @_add(i64 %r3878, i64 %r3880)
  %r3882 = load i64, i64* %ptr_NL
  %r3883 = call i64 @_add(i64 %r3881, i64 %r3882)
  store i64 %r3883, i64* %ptr_s
  %r3884 = load i64, i64* %ptr_s
  %r3885 = getelementptr [42 x i8], [42 x i8]* @.str.1254, i64 0, i64 0
  %r3886 = ptrtoint i8* %r3885 to i64
  %r3887 = call i64 @_add(i64 %r3884, i64 %r3886)
  %r3888 = load i64, i64* %ptr_NL
  %r3889 = call i64 @_add(i64 %r3887, i64 %r3888)
  store i64 %r3889, i64* %ptr_s
  %r3890 = load i64, i64* %ptr_s
  %r3891 = getelementptr [37 x i8], [37 x i8]* @.str.1255, i64 0, i64 0
  %r3892 = ptrtoint i8* %r3891 to i64
  %r3893 = call i64 @_add(i64 %r3890, i64 %r3892)
  %r3894 = load i64, i64* %ptr_NL
  %r3895 = call i64 @_add(i64 %r3893, i64 %r3894)
  store i64 %r3895, i64* %ptr_s
  %r3896 = load i64, i64* %ptr_s
  %r3897 = getelementptr [49 x i8], [49 x i8]* @.str.1256, i64 0, i64 0
  %r3898 = ptrtoint i8* %r3897 to i64
  %r3899 = call i64 @_add(i64 %r3896, i64 %r3898)
  %r3900 = load i64, i64* %ptr_NL
  %r3901 = call i64 @_add(i64 %r3899, i64 %r3900)
  store i64 %r3901, i64* %ptr_s
  %r3902 = load i64, i64* %ptr_s
  %r3903 = getelementptr [41 x i8], [41 x i8]* @.str.1257, i64 0, i64 0
  %r3904 = ptrtoint i8* %r3903 to i64
  %r3905 = call i64 @_add(i64 %r3902, i64 %r3904)
  %r3906 = load i64, i64* %ptr_NL
  %r3907 = call i64 @_add(i64 %r3905, i64 %r3906)
  store i64 %r3907, i64* %ptr_s
  %r3908 = load i64, i64* %ptr_s
  %r3909 = getelementptr [16 x i8], [16 x i8]* @.str.1258, i64 0, i64 0
  %r3910 = ptrtoint i8* %r3909 to i64
  %r3911 = call i64 @_add(i64 %r3908, i64 %r3910)
  %r3912 = load i64, i64* %ptr_NL
  %r3913 = call i64 @_add(i64 %r3911, i64 %r3912)
  store i64 %r3913, i64* %ptr_s
  %r3914 = load i64, i64* %ptr_s
  %r3915 = getelementptr [2 x i8], [2 x i8]* @.str.1259, i64 0, i64 0
  %r3916 = ptrtoint i8* %r3915 to i64
  %r3917 = call i64 @_add(i64 %r3914, i64 %r3916)
  %r3918 = load i64, i64* %ptr_NL
  %r3919 = call i64 @_add(i64 %r3917, i64 %r3918)
  store i64 %r3919, i64* %ptr_s
  %r3920 = load i64, i64* %ptr_s
  ret i64 %r3920
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
  br label %L958
L958:
  %r2 = load i64, i64* %ptr_i
  %r3 = load i64, i64* %ptr_stmts
  %r4 = call i64 @mensura(i64 %r3)
  %r6 = icmp slt i64 %r2, %r4
  %r5 = zext i1 %r6 to i64
  %r7 = icmp ne i64 %r5, 0
  br i1 %r7, label %L959, label %L960
L959:
  %r8 = load i64, i64* %ptr_stmts
  %r9 = load i64, i64* %ptr_i
  %r10 = call i64 @_get(i64 %r8, i64 %r9)
  store i64 %r10, i64* %ptr_s
  %r11 = load i64, i64* %ptr_s
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.1260, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  %r15 = load i64, i64* @STMT_IMPORT
  %r16 = call i64 @_eq(i64 %r14, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L961, label %L962
L961:
  %r18 = load i64, i64* %ptr_s
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.1261, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_get(i64 %r18, i64 %r20)
  %r22 = getelementptr [4 x i8], [4 x i8]* @.str.1262, i64 0, i64 0
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
  br i1 %r31, label %L964, label %L965
L964:
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
  br label %L967
L967:
  %r37 = call i64 @peek()
  %r38 = getelementptr [5 x i8], [5 x i8]* @.str.1263, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = call i64 @_get(i64 %r37, i64 %r39)
  %r42 = call i64 @_eq(i64 %r40, i64 0)
  %r41 = xor i64 %r42, 1
  %r43 = icmp ne i64 %r41, 0
  br i1 %r43, label %L968, label %L969
L968:
  %r44 = call i64 @peek()
  %r45 = getelementptr [5 x i8], [5 x i8]* @.str.1264, i64 0, i64 0
  %r46 = ptrtoint i8* %r45 to i64
  %r47 = call i64 @_get(i64 %r44, i64 %r46)
  %r48 = call i64 @_eq(i64 %r47, i64 29)
  %r49 = icmp ne i64 %r48, 0
  br i1 %r49, label %L970, label %L971
L970:
  %r50 = call i64 @advance()
  br label %L972
L971:
  %r51 = call i64 @parse_stmt()
  %r52 = load i64, i64* %ptr_imp_stmts
  call i64 @_append_poly(i64 %r52, i64 %r51)
  br label %L972
L972:
  br label %L967
L969:
  %r53 = load i64, i64* %ptr_imp_stmts
  %r54 = call i64 @expand_imports(i64 %r53)
  store i64 %r54, i64* %ptr_sub_exp
  store i64 0, i64* %ptr_j
  br label %L973
L973:
  %r55 = load i64, i64* %ptr_j
  %r56 = load i64, i64* %ptr_sub_exp
  %r57 = call i64 @mensura(i64 %r56)
  %r59 = icmp slt i64 %r55, %r57
  %r58 = zext i1 %r59 to i64
  %r60 = icmp ne i64 %r58, 0
  br i1 %r60, label %L974, label %L975
L974:
  %r61 = load i64, i64* %ptr_sub_exp
  %r62 = load i64, i64* %ptr_j
  %r63 = call i64 @_get(i64 %r61, i64 %r62)
  %r64 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r64, i64 %r63)
  %r65 = load i64, i64* %ptr_j
  %r66 = call i64 @_add(i64 %r65, i64 1)
  store i64 %r66, i64* %ptr_j
  br label %L973
L975:
  %r67 = load i64, i64* %ptr_old_toks
  store i64 %r67, i64* @global_tokens
  %r68 = load i64, i64* %ptr_old_pos
  store i64 %r68, i64* @p_pos
  br label %L966
L965:
  %r69 = getelementptr [41 x i8], [41 x i8]* @.str.1265, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_path
  %r72 = call i64 @_add(i64 %r70, i64 %r71)
  call i64 @print_any(i64 %r72)
  br label %L966
L966:
  br label %L963
L962:
  %r73 = load i64, i64* %ptr_s
  %r74 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r74, i64 %r73)
  br label %L963
L963:
  %r75 = load i64, i64* %ptr_i
  %r76 = call i64 @_add(i64 %r75, i64 1)
  store i64 %r76, i64* %ptr_i
  br label %L958
L960:
  %r77 = load i64, i64* %ptr_expanded
  ret i64 %r77
  ret i64 0
}
define i64 @achlys_main() {
  %ptr_is_freestanding = alloca i64
  %ptr_is_arm64 = alloca i64
  %ptr_arg_idx = alloca i64
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
  %r1 = getelementptr [61 x i8], [61 x i8]* @.str.1266, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  call i64 @print_any(i64 %r2)
  %r3 = call i64 @init_constants()
  %r4 = call i64 @_list_new()
  store i64 %r4, i64* @global_tokens
  store i64 0, i64* @p_pos
  store i64 0, i64* %ptr_is_freestanding
  store i64 0, i64* %ptr_is_arm64
  store i64 1, i64* %ptr_arg_idx
  %r5 = getelementptr [1 x i8], [1 x i8]* @.str.1267, i64 0, i64 0
  %r6 = ptrtoint i8* %r5 to i64
  store i64 %r6, i64* %ptr_arg
  %r7 = getelementptr [1 x i8], [1 x i8]* @.str.1268, i64 0, i64 0
  %r8 = ptrtoint i8* %r7 to i64
  store i64 %r8, i64* %ptr_filename
  store i64 1, i64* %ptr_valid
  br label %L976
L976:
  %r9 = icmp ne i64 1, 0
  br i1 %r9, label %L977, label %L978
L977:
  %r10 = load i64, i64* %ptr_arg_idx
  %r11 = call i64 @_get_argv(i64 %r10)
  store i64 %r11, i64* %ptr_arg
  %r12 = load i64, i64* %ptr_arg
  %r13 = call i64 @mensura(i64 %r12)
  %r14 = call i64 @_eq(i64 %r13, i64 0)
  %r15 = icmp ne i64 %r14, 0
  br i1 %r15, label %L979, label %L981
L979:
  br label %L978
L981:
  %r16 = load i64, i64* %ptr_arg
  %r17 = getelementptr [15 x i8], [15 x i8]* @.str.1269, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L982, label %L983
L982:
  store i64 1, i64* %ptr_is_freestanding
  br label %L984
L983:
  %r21 = load i64, i64* %ptr_arg
  %r22 = getelementptr [8 x i8], [8 x i8]* @.str.1270, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L985, label %L986
L985:
  store i64 1, i64* %ptr_is_arm64
  br label %L987
L986:
  %r26 = load i64, i64* %ptr_arg
  store i64 %r26, i64* %ptr_filename
  br label %L987
L987:
  br label %L984
L984:
  %r27 = load i64, i64* %ptr_arg_idx
  %r28 = call i64 @_add(i64 %r27, i64 1)
  store i64 %r28, i64* %ptr_arg_idx
  br label %L976
L978:
  %r29 = load i64, i64* %ptr_filename
  %r30 = call i64 @mensura(i64 %r29)
  %r31 = call i64 @_eq(i64 %r30, i64 0)
  %r32 = icmp ne i64 %r31, 0
  br i1 %r32, label %L988, label %L990
L988:
  %r33 = getelementptr [52 x i8], [52 x i8]* @.str.1271, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  call i64 @print_any(i64 %r34)
  store i64 0, i64* %ptr_valid
  br label %L990
L990:
  %r35 = load i64, i64* %ptr_valid
  %r36 = icmp ne i64 %r35, 0
  br i1 %r36, label %L991, label %L993
L991:
  %r37 = load i64, i64* %ptr_filename
  %r38 = call i64 @revelare(i64 %r37)
  store i64 %r38, i64* %ptr_src
  %r39 = load i64, i64* %ptr_src
  %r40 = call i64 @mensura(i64 %r39)
  %r41 = call i64 @_eq(i64 %r40, i64 0)
  %r42 = icmp ne i64 %r41, 0
  br i1 %r42, label %L994, label %L995
L994:
  %r43 = getelementptr [25 x i8], [25 x i8]* @.str.1272, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = load i64, i64* %ptr_filename
  %r46 = call i64 @_add(i64 %r44, i64 %r45)
  call i64 @print_any(i64 %r46)
  br label %L996
L995:
  %r47 = getelementptr [16 x i8], [16 x i8]* @.str.1273, i64 0, i64 0
  %r48 = ptrtoint i8* %r47 to i64
  call i64 @print_any(i64 %r48)
  %r49 = load i64, i64* %ptr_src
  %r50 = call i64 @lex_source(i64 %r49)
  store i64 %r50, i64* @global_tokens
  %r51 = load i64, i64* @global_tokens
  %r52 = call i64 @mensura(i64 %r51)
  store i64 %r52, i64* %ptr_token_count
  %r53 = getelementptr [19 x i8], [19 x i8]* @.str.1274, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = load i64, i64* %ptr_token_count
  %r56 = call i64 @int_to_str(i64 %r55)
  %r57 = call i64 @_add(i64 %r54, i64 %r56)
  %r58 = getelementptr [9 x i8], [9 x i8]* @.str.1275, i64 0, i64 0
  %r59 = ptrtoint i8* %r58 to i64
  %r60 = call i64 @_add(i64 %r57, i64 %r59)
  call i64 @print_any(i64 %r60)
  store i64 0, i64* %ptr_k
  br label %L997
L997:
  %r61 = load i64, i64* %ptr_k
  %r62 = load i64, i64* %ptr_token_count
  %r64 = icmp slt i64 %r61, %r62
  %r63 = zext i1 %r64 to i64
  %r65 = icmp ne i64 %r63, 0
  br i1 %r65, label %L998, label %L999
L998:
  %r66 = load i64, i64* @global_tokens
  %r67 = load i64, i64* %ptr_k
  %r68 = call i64 @_get(i64 %r66, i64 %r67)
  store i64 %r68, i64* %ptr_t
  %r69 = getelementptr [4 x i8], [4 x i8]* @.str.1276, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_k
  %r72 = call i64 @int_to_str(i64 %r71)
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  %r74 = getelementptr [4 x i8], [4 x i8]* @.str.1277, i64 0, i64 0
  %r75 = ptrtoint i8* %r74 to i64
  %r76 = call i64 @_add(i64 %r73, i64 %r75)
  %r77 = load i64, i64* %ptr_t
  %r78 = getelementptr [5 x i8], [5 x i8]* @.str.1278, i64 0, i64 0
  %r79 = ptrtoint i8* %r78 to i64
  %r80 = call i64 @_get(i64 %r77, i64 %r79)
  %r81 = call i64 @_add(i64 %r76, i64 %r80)
  %r82 = getelementptr [3 x i8], [3 x i8]* @.str.1279, i64 0, i64 0
  %r83 = ptrtoint i8* %r82 to i64
  %r84 = call i64 @_add(i64 %r81, i64 %r83)
  %r85 = load i64, i64* %ptr_t
  %r86 = getelementptr [5 x i8], [5 x i8]* @.str.1280, i64 0, i64 0
  %r87 = ptrtoint i8* %r86 to i64
  %r88 = call i64 @_get(i64 %r85, i64 %r87)
  %r89 = call i64 @int_to_str(i64 %r88)
  %r90 = call i64 @_add(i64 %r84, i64 %r89)
  %r91 = getelementptr [2 x i8], [2 x i8]* @.str.1281, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_add(i64 %r90, i64 %r92)
  call i64 @print_any(i64 %r93)
  %r94 = load i64, i64* %ptr_k
  %r95 = call i64 @_add(i64 %r94, i64 1)
  store i64 %r95, i64* %ptr_k
  br label %L997
L999:
  %r96 = getelementptr [17 x i8], [17 x i8]* @.str.1282, i64 0, i64 0
  %r97 = ptrtoint i8* %r96 to i64
  call i64 @print_any(i64 %r97)
  store i64 1, i64* @use_huge_lists
  %r98 = call i64 @_list_new()
  store i64 %r98, i64* %ptr_stmts
  store i64 0, i64* @use_huge_lists
  %r99 = call i64 @peek()
  store i64 %r99, i64* %ptr_pt
  br label %L1000
L1000:
  %r100 = load i64, i64* %ptr_pt
  %r101 = getelementptr [5 x i8], [5 x i8]* @.str.1283, i64 0, i64 0
  %r102 = ptrtoint i8* %r101 to i64
  %r103 = call i64 @_get(i64 %r100, i64 %r102)
  %r104 = load i64, i64* @TOK_EOF
  %r106 = call i64 @_eq(i64 %r103, i64 %r104)
  %r105 = xor i64 %r106, 1
  %r107 = icmp ne i64 %r105, 0
  br i1 %r107, label %L1001, label %L1002
L1001:
  %r108 = load i64, i64* @has_error
  %r109 = icmp ne i64 %r108, 0
  br i1 %r109, label %L1003, label %L1005
L1003:
  br label %L1002
L1005:
  %r110 = load i64, i64* %ptr_pt
  %r111 = getelementptr [5 x i8], [5 x i8]* @.str.1284, i64 0, i64 0
  %r112 = ptrtoint i8* %r111 to i64
  %r113 = call i64 @_get(i64 %r110, i64 %r112)
  %r114 = load i64, i64* @TOK_CARET
  %r115 = call i64 @_eq(i64 %r113, i64 %r114)
  %r116 = icmp ne i64 %r115, 0
  br i1 %r116, label %L1006, label %L1008
L1006:
  %r117 = call i64 @advance()
  br label %L1000
L1008:
  %r118 = call i64 @parse_stmt()
  %r119 = load i64, i64* %ptr_stmts
  call i64 @_append_poly(i64 %r119, i64 %r118)
  %r120 = call i64 @peek()
  store i64 %r120, i64* %ptr_pt
  br label %L1000
L1002:
  %r121 = load i64, i64* %ptr_stmts
  %r122 = call i64 @expand_imports(i64 %r121)
  store i64 %r122, i64* %ptr_flat_stmts
  %r123 = load i64, i64* @has_error
  %r124 = icmp ne i64 %r123, 0
  br i1 %r124, label %L1009, label %L1010
L1009:
  %r125 = getelementptr [24 x i8], [24 x i8]* @.str.1285, i64 0, i64 0
  %r126 = ptrtoint i8* %r125 to i64
  call i64 @print_any(i64 %r126)
  br label %L1011
L1010:
  %r127 = getelementptr [28 x i8], [28 x i8]* @.str.1286, i64 0, i64 0
  %r128 = ptrtoint i8* %r127 to i64
  call i64 @print_any(i64 %r128)
  %r129 = load i64, i64* %ptr_is_freestanding
  %r130 = load i64, i64* %ptr_is_arm64
  %r131 = call i64 @get_llvm_header(i64 %r129, i64 %r130)
  store i64 %r131, i64* %ptr_header
  %r132 = call i64 @_list_new()
  store i64 %r132, i64* %ptr_top_level
  store i64 0, i64* %ptr_i
  br label %L1012
L1012:
  %r133 = load i64, i64* %ptr_i
  %r134 = load i64, i64* %ptr_flat_stmts
  %r135 = call i64 @mensura(i64 %r134)
  %r137 = icmp slt i64 %r133, %r135
  %r136 = zext i1 %r137 to i64
  %r138 = icmp ne i64 %r136, 0
  br i1 %r138, label %L1013, label %L1014
L1013:
  %r139 = load i64, i64* %ptr_flat_stmts
  %r140 = load i64, i64* %ptr_i
  %r141 = call i64 @_get(i64 %r139, i64 %r140)
  store i64 %r141, i64* %ptr_s
  %r142 = load i64, i64* %ptr_s
  %r143 = getelementptr [5 x i8], [5 x i8]* @.str.1287, i64 0, i64 0
  %r144 = ptrtoint i8* %r143 to i64
  %r145 = call i64 @_get(i64 %r142, i64 %r144)
  %r146 = load i64, i64* @STMT_FUNC
  %r147 = call i64 @_eq(i64 %r145, i64 %r146)
  %r148 = icmp ne i64 %r147, 0
  br i1 %r148, label %L1015, label %L1016
L1015:
  %r149 = load i64, i64* %ptr_s
  %r150 = call i64 @compile_func(i64 %r149)
  br label %L1017
L1016:
  %r151 = load i64, i64* %ptr_s
  %r152 = getelementptr [5 x i8], [5 x i8]* @.str.1288, i64 0, i64 0
  %r153 = ptrtoint i8* %r152 to i64
  %r154 = call i64 @_get(i64 %r151, i64 %r153)
  %r155 = load i64, i64* @STMT_SHARED
  %r156 = call i64 @_eq(i64 %r154, i64 %r155)
  %r157 = load i64, i64* %ptr_s
  %r158 = getelementptr [5 x i8], [5 x i8]* @.str.1289, i64 0, i64 0
  %r159 = ptrtoint i8* %r158 to i64
  %r160 = call i64 @_get(i64 %r157, i64 %r159)
  %r161 = load i64, i64* @STMT_CONST
  %r162 = call i64 @_eq(i64 %r160, i64 %r161)
  %r163 = or i64 %r156, %r162
  %r164 = icmp ne i64 %r163, 0
  br i1 %r164, label %L1018, label %L1019
L1018:
  %r165 = getelementptr [2 x i8], [2 x i8]* @.str.1290, i64 0, i64 0
  %r166 = ptrtoint i8* %r165 to i64
  %r167 = load i64, i64* %ptr_s
  %r168 = getelementptr [5 x i8], [5 x i8]* @.str.1291, i64 0, i64 0
  %r169 = ptrtoint i8* %r168 to i64
  %r170 = call i64 @_get(i64 %r167, i64 %r169)
  %r171 = call i64 @_add(i64 %r166, i64 %r170)
  store i64 %r171, i64* %ptr_g_name
  %r172 = load i64, i64* @out_data
  %r173 = load i64, i64* %ptr_g_name
  %r174 = call i64 @_add(i64 %r172, i64 %r173)
  %r175 = getelementptr [16 x i8], [16 x i8]* @.str.1292, i64 0, i64 0
  %r176 = ptrtoint i8* %r175 to i64
  %r177 = call i64 @_add(i64 %r174, i64 %r176)
  %r178 = call i64 @signum_ex(i64 10)
  %r179 = call i64 @_add(i64 %r177, i64 %r178)
  store i64 %r179, i64* @out_data
  %r180 = load i64, i64* %ptr_g_name
  %r181 = load i64, i64* %ptr_s
  %r182 = getelementptr [5 x i8], [5 x i8]* @.str.1293, i64 0, i64 0
  %r183 = ptrtoint i8* %r182 to i64
  %r184 = call i64 @_get(i64 %r181, i64 %r183)
  %r185 = load i64, i64* @global_map
  call i64 @_set(i64 %r185, i64 %r184, i64 %r180)
  %r186 = call i64 @_map_new()
  %r187 = getelementptr [5 x i8], [5 x i8]* @.str.1294, i64 0, i64 0
  %r188 = ptrtoint i8* %r187 to i64
  %r189 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r186, i64 %r188, i64 %r189)
  %r190 = getelementptr [5 x i8], [5 x i8]* @.str.1295, i64 0, i64 0
  %r191 = ptrtoint i8* %r190 to i64
  %r192 = load i64, i64* %ptr_s
  %r193 = getelementptr [5 x i8], [5 x i8]* @.str.1296, i64 0, i64 0
  %r194 = ptrtoint i8* %r193 to i64
  %r195 = call i64 @_get(i64 %r192, i64 %r194)
  call i64 @_map_set(i64 %r186, i64 %r191, i64 %r195)
  %r196 = getelementptr [4 x i8], [4 x i8]* @.str.1297, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = load i64, i64* %ptr_s
  %r199 = getelementptr [4 x i8], [4 x i8]* @.str.1298, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  call i64 @_map_set(i64 %r186, i64 %r197, i64 %r201)
  store i64 %r186, i64* %ptr_assign
  %r202 = load i64, i64* %ptr_assign
  %r203 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r203, i64 %r202)
  br label %L1020
L1019:
  %r204 = load i64, i64* %ptr_s
  %r205 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r205, i64 %r204)
  br label %L1020
L1020:
  br label %L1017
L1017:
  %r206 = load i64, i64* %ptr_i
  %r207 = call i64 @_add(i64 %r206, i64 1)
  store i64 %r207, i64* %ptr_i
  br label %L1012
L1014:
  %r208 = call i64 @signum_ex(i64 10)
  store i64 %r208, i64* %ptr_NL
  %r209 = getelementptr [42 x i8], [42 x i8]* @.str.1299, i64 0, i64 0
  %r210 = ptrtoint i8* %r209 to i64
  %r211 = call i64 @emit_raw(i64 %r210)
  %r212 = getelementptr [36 x i8], [36 x i8]* @.str.1300, i64 0, i64 0
  %r213 = ptrtoint i8* %r212 to i64
  %r214 = call i64 @emit_raw(i64 %r213)
  %r215 = getelementptr [38 x i8], [38 x i8]* @.str.1301, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = call i64 @emit_raw(i64 %r216)
  %r218 = getelementptr [16 x i8], [16 x i8]* @.str.1302, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @add_global_string(i64 %r219)
  store i64 %r220, i64* %ptr_boot_msg
  %r221 = getelementptr [55 x i8], [55 x i8]* @.str.1303, i64 0, i64 0
  %r222 = ptrtoint i8* %r221 to i64
  %r223 = load i64, i64* %ptr_boot_msg
  %r224 = call i64 @_add(i64 %r222, i64 %r223)
  %r225 = getelementptr [15 x i8], [15 x i8]* @.str.1304, i64 0, i64 0
  %r226 = ptrtoint i8* %r225 to i64
  %r227 = call i64 @_add(i64 %r224, i64 %r226)
  %r228 = call i64 @emit_raw(i64 %r227)
  %r229 = getelementptr [52 x i8], [52 x i8]* @.str.1305, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @emit_raw(i64 %r230)
  %r232 = getelementptr [41 x i8], [41 x i8]* @.str.1306, i64 0, i64 0
  %r233 = ptrtoint i8* %r232 to i64
  %r234 = call i64 @emit_raw(i64 %r233)
  store i64 0, i64* @reg_count
  %r235 = call i64 @_map_new()
  store i64 %r235, i64* @var_map
  %r236 = getelementptr [31 x i8], [31 x i8]* @.str.1307, i64 0, i64 0
  %r237 = ptrtoint i8* %r236 to i64
  %r238 = load i64, i64* %ptr_top_level
  %r239 = call i64 @mensura(i64 %r238)
  %r240 = call i64 @int_to_str(i64 %r239)
  %r241 = call i64 @_add(i64 %r237, i64 %r240)
  call i64 @print_any(i64 %r241)
  store i64 0, i64* %ptr_i
  br label %L1021
L1021:
  %r242 = load i64, i64* %ptr_i
  %r243 = load i64, i64* %ptr_top_level
  %r244 = call i64 @mensura(i64 %r243)
  %r246 = icmp slt i64 %r242, %r244
  %r245 = zext i1 %r246 to i64
  %r247 = icmp ne i64 %r245, 0
  br i1 %r247, label %L1022, label %L1023
L1022:
  %r248 = load i64, i64* %ptr_top_level
  %r249 = load i64, i64* %ptr_i
  %r250 = call i64 @_get(i64 %r248, i64 %r249)
  %r251 = call i64 @compile_stmt(i64 %r250)
  %r252 = load i64, i64* %ptr_i
  %r253 = call i64 @_add(i64 %r252, i64 1)
  store i64 %r253, i64* %ptr_i
  br label %L1021
L1023:
  %r254 = getelementptr [10 x i8], [10 x i8]* @.str.1308, i64 0, i64 0
  %r255 = ptrtoint i8* %r254 to i64
  %r256 = call i64 @emit(i64 %r255)
  %r257 = getelementptr [2 x i8], [2 x i8]* @.str.1309, i64 0, i64 0
  %r258 = ptrtoint i8* %r257 to i64
  %r259 = call i64 @emit_raw(i64 %r258)
  %r260 = load i64, i64* %ptr_header
  %r261 = load i64, i64* @out_data
  %r262 = call i64 @_add(i64 %r260, i64 %r261)
  %r263 = load i64, i64* @out_code
  %r264 = call i64 @_add(i64 %r262, i64 %r263)
  store i64 %r264, i64* %ptr_final_ir
  %r265 = getelementptr [10 x i8], [10 x i8]* @.str.1310, i64 0, i64 0
  %r266 = ptrtoint i8* %r265 to i64
  %r267 = load i64, i64* %ptr_final_ir
  %r268 = call i64 @inscribo(i64 %r266, i64 %r267)
  %r269 = getelementptr [36 x i8], [36 x i8]* @.str.1311, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  call i64 @print_any(i64 %r270)
  br label %L1011
L1011:
  br label %L996
L996:
  br label %L993
L993:
  ret i64 0
}
define i32 @main(i32 %argc, i8** %argv) {
  store i32 %argc, i32* @__sys_argc
  store i8** %argv, i8*** @__sys_argv
  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* @.str.1312, i64 0, i64 0
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
  %r4 = getelementptr [1 x i8], [1 x i8]* @.str.1313, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  store i64 %r5, i64* @asm_main
  %r6 = getelementptr [1 x i8], [1 x i8]* @.str.1314, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* @asm_funcs
  store i64 0, i64* @in_func
  %r8 = call i64 @_list_new()
  store i64 %r8, i64* @local_vars
  store i64 0, i64* @stack_depth
  store i64 0, i64* @reg_count
  store i64 0, i64* @str_count
  store i64 0, i64* @label_count
  %r9 = getelementptr [1 x i8], [1 x i8]* @.str.1315, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  store i64 %r10, i64* @out_code
  %r11 = getelementptr [1 x i8], [1 x i8]* @.str.1316, i64 0, i64 0
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
  store i64 0, i64* @block_terminated
  %r17 = call i64 @achlys_main()
  ret i32 0
}
