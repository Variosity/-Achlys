; ModuleID = 'achlys_kernel'
target triple = "x86_64-pc-linux-gnu"
declare i32 @printf(i8*, ...)
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
declare i64 @fast_memcpy(i64, i64, i64)
declare i64 @fast_fill32(i64, i64, i64)
declare i64 @get_system_ticks()
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
  %ptr = inttoptr i64 %mem to i8*
  %is_zero = icmp eq i64 %val, 0
  br i1 %is_zero, label %zero, label %calc
zero:
  store i8 48, i8* %ptr
  %zterm = getelementptr i8, i8* %ptr, i64 1
  store i8 0, i8* %zterm
  %zret = ptrtoint i8* %ptr to i64
  ret i64 %zret
calc:
  %is_neg = icmp slt i64 %val, 0
  %neg_val = sub i64 0, %val
  %abs_val = select i1 %is_neg, i64 %neg_val, i64 %val
  br label %loop
loop:
  %curr = phi i64 [ %abs_val, %calc ], [ %next_val, %loop ]
  %idx = phi i64 [ 30, %calc ], [ %next_idx, %loop ]
  %rem = srem i64 %curr, 10
  %char = add i64 %rem, 48
  %c8 = trunc i64 %char to i8
  %slot = getelementptr i8, i8* %ptr, i64 %idx
  store i8 %c8, i8* %slot
  %next_val = sdiv i64 %curr, 10
  %next_idx = sub i64 %idx, 1
  %stop = icmp eq i64 %next_val, 0
  br i1 %stop, label %done, label %loop
done:
  %start_idx = add i64 %next_idx, 1
  br i1 %is_neg, label %add_neg, label %copy
add_neg:
  %neg_slot = getelementptr i8, i8* %ptr, i64 %next_idx
  store i8 45, i8* %neg_slot
  br label %copy
copy:
  %final_start = phi i64 [ %start_idx, %done ], [ %next_idx, %add_neg ]
  %term_slot = getelementptr i8, i8* %ptr, i64 31
  store i8 0, i8* %term_slot
  %ret_ptr = getelementptr i8, i8* %ptr, i64 %final_start
  %ret_int = ptrtoint i8* %ret_ptr to i64
  ret i64 %ret_int
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
@.sc.26 = global i64 0
@.str.27 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.28 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.29 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.30 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.31 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.32 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.33 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.34 = private unnamed_addr constant [2 x i8] c"n\00", align 8
@.str.35 = private unnamed_addr constant [2 x i8] c"t\00", align 8
@.str.36 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.37 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.38 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.39 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.40 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.41 = private unnamed_addr constant [2 x i8] c"x\00", align 8
@.str.42 = private unnamed_addr constant [2 x i8] c"X\00", align 8
@.str.43 = private unnamed_addr constant [2 x i8] c".\00", align 8
@.str.44 = private unnamed_addr constant [4 x i8] c"vas\00", align 8
@.str.45 = private unnamed_addr constant [5 x i8] c"idea\00", align 8
@.str.46 = private unnamed_addr constant [6 x i8] c"umbra\00", align 8
@.str.47 = private unnamed_addr constant [7 x i8] c"scribo\00", align 8
@.str.48 = private unnamed_addr constant [8 x i8] c"monstro\00", align 8
@.str.49 = private unnamed_addr constant [10 x i8] c"insusurro\00", align 8
@.str.50 = private unnamed_addr constant [3 x i8] c"si\00", align 8
@.str.51 = private unnamed_addr constant [7 x i8] c"aliter\00", align 8
@.str.52 = private unnamed_addr constant [4 x i8] c"dum\00", align 8
@.str.53 = private unnamed_addr constant [5 x i8] c"opus\00", align 8
@.str.54 = private unnamed_addr constant [6 x i8] c"reddo\00", align 8
@.str.55 = private unnamed_addr constant [10 x i8] c"abrumpere\00", align 8
@.str.56 = private unnamed_addr constant [8 x i8] c"pergere\00", align 8
@.str.57 = private unnamed_addr constant [10 x i8] c"importare\00", align 8
@.str.58 = private unnamed_addr constant [9 x i8] c"constans\00", align 8
@.str.59 = private unnamed_addr constant [9 x i8] c"communis\00", align 8
@.str.60 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.61 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.62 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.63 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.64 = private unnamed_addr constant [6 x i8] c"verum\00", align 8
@.str.65 = private unnamed_addr constant [2 x i8] c"1\00", align 8
@.str.66 = private unnamed_addr constant [7 x i8] c"falsum\00", align 8
@.str.67 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.68 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.69 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.70 = private unnamed_addr constant [2 x i8] c"{\00", align 8
@.str.71 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.72 = private unnamed_addr constant [2 x i8] c"[\00", align 8
@.str.73 = private unnamed_addr constant [2 x i8] c"]\00", align 8
@.str.74 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.75 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.76 = private unnamed_addr constant [2 x i8] c".\00", align 8
@.str.77 = private unnamed_addr constant [2 x i8] c",\00", align 8
@.str.78 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.79 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.80 = private unnamed_addr constant [3 x i8] c"->\00", align 8
@.str.81 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.82 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.83 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.84 = private unnamed_addr constant [2 x i8] c"!\00", align 8
@.str.85 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.86 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.87 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.88 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.89 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.90 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.91 = private unnamed_addr constant [3 x i8] c"<<\00", align 8
@.str.92 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.93 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.94 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.95 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.96 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.97 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.98 = private unnamed_addr constant [3 x i8] c">>\00", align 8
@.str.99 = private unnamed_addr constant [2 x i8] c"=\00", align 8
@.str.100 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.101 = private unnamed_addr constant [4 x i8] c"EOF\00", align 8
@.str.102 = private unnamed_addr constant [39 x i8] c"[DEBUG] Lexer finished. Total Tokens: \00", align 8
@.str.103 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.104 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.105 = private unnamed_addr constant [4 x i8] c"EOF\00", align 8
@.str.106 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.107 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.108 = private unnamed_addr constant [21 x i8] c"Expected token type \00", align 8
@.str.109 = private unnamed_addr constant [10 x i8] c" but got \00", align 8
@.str.110 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.111 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.112 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.113 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.114 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.115 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.116 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.117 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.118 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.119 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.120 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.121 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.122 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.123 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.124 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.125 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.126 = private unnamed_addr constant [6 x i8] c"items\00", align 8
@.str.127 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.128 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.129 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.130 = private unnamed_addr constant [5 x i8] c"keys\00", align 8
@.str.131 = private unnamed_addr constant [5 x i8] c"vals\00", align 8
@.sc.132 = global i64 0
@.str.133 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.134 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.135 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.136 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.137 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.138 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.139 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.140 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.141 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.142 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.143 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.sc.144 = global i64 0
@.str.145 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.146 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.147 = private unnamed_addr constant [2 x i8] c"!\00", align 8
@.str.148 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.149 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.150 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.151 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.152 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.153 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.154 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.155 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.156 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.157 = private unnamed_addr constant [19 x i8] c"Unexpected token: \00", align 8
@.str.158 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.159 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.160 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.161 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.162 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.163 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.164 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.165 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.166 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.167 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.168 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.169 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.170 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.171 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.172 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.173 = private unnamed_addr constant [2 x i8] c"%\00", align 8
@.str.174 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.175 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.176 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.177 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.178 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.179 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.180 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.181 = private unnamed_addr constant [2 x i8] c"+\00", align 8
@.str.182 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.183 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.184 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.185 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.186 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.187 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.188 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.189 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.190 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.191 = private unnamed_addr constant [2 x i8] c"&\00", align 8
@.str.192 = private unnamed_addr constant [2 x i8] c"|\00", align 8
@.str.193 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.194 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.195 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.196 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.197 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.198 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.199 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.200 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.201 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.202 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.203 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.204 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.205 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.206 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.207 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.208 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.209 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.210 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.211 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.212 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.213 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.214 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.sc.215 = global i64 0
@.str.216 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.217 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.218 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.219 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.220 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.221 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.222 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.223 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.224 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.225 = private unnamed_addr constant [24 x i8] c"[DEBUG] Parsing stmt...\00", align 8
@.str.226 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.227 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.228 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.229 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.230 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.231 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.232 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.233 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.234 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.235 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.236 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.237 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.238 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.239 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.240 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.241 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.242 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.243 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.244 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.245 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.246 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.247 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.248 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.249 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.250 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.251 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.252 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.253 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.254 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.255 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.256 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.257 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.258 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.259 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.260 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.261 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.262 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.263 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.264 = private unnamed_addr constant [15 x i8] c"Unexpected EOF\00", align 8
@.str.265 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.266 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.267 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.268 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.269 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.270 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.271 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.272 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.273 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.274 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.275 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.276 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.277 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.278 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.279 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.280 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.281 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.282 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.283 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.284 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.285 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.286 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.287 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.288 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.289 = private unnamed_addr constant [5 x i8] c"type\00", align 8
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
@.str.290 = private unnamed_addr constant [3 x i8] c"%r\00", align 8
@.str.291 = private unnamed_addr constant [2 x i8] c"L\00", align 8
@.str.292 = private unnamed_addr constant [3 x i8] c"  \00", align 8
@.str.293 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.294 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.295 = private unnamed_addr constant [4 x i8] c"\5C22\00", align 8
@.str.296 = private unnamed_addr constant [2 x i8] c"\5C\00", align 8
@.str.297 = private unnamed_addr constant [4 x i8] c"\5C5C\00", align 8
@.str.298 = private unnamed_addr constant [4 x i8] c"\5C0A\00", align 8
@.str.299 = private unnamed_addr constant [7 x i8] c"@.str.\00", align 8
@.str.300 = private unnamed_addr constant [35 x i8] c" = private unnamed_addr constant [\00", align 8
@.str.301 = private unnamed_addr constant [10 x i8] c" x i8] c\22\00", align 8
@.str.302 = private unnamed_addr constant [14 x i8] c"\5C00\22, align 8\00", align 8
@.str.303 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.304 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.305 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.306 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.307 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.308 = private unnamed_addr constant [33 x i8] c"💀 FATAL: Undefined variable '\00", align 8
@.str.309 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.310 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.311 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.312 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.313 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.314 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.315 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.316 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.317 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.318 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.319 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.320 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.321 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.322 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.323 = private unnamed_addr constant [3 x i8] c"op\00", align 8
@.str.324 = private unnamed_addr constant [3 x i8] c"et\00", align 8
@.str.325 = private unnamed_addr constant [6 x i8] c"@.sc.\00", align 8
@.str.326 = private unnamed_addr constant [16 x i8] c" = global i64 0\00", align 8
@.str.327 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.328 = private unnamed_addr constant [19 x i8] c"store i64 0, i64* \00", align 8
@.str.329 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.330 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.331 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.332 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.333 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.334 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.335 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.336 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.337 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.338 = private unnamed_addr constant [12 x i8] c" = zext i1 \00", align 8
@.str.339 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.340 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.341 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.342 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.343 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.344 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.345 = private unnamed_addr constant [4 x i8] c"vel\00", align 8
@.str.346 = private unnamed_addr constant [6 x i8] c"@.sc.\00", align 8
@.str.347 = private unnamed_addr constant [16 x i8] c" = global i64 0\00", align 8
@.str.348 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.349 = private unnamed_addr constant [19 x i8] c"store i64 1, i64* \00", align 8
@.str.350 = private unnamed_addr constant [16 x i8] c" = icmp eq i64 \00", align 8
@.str.351 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.352 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.353 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.354 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.355 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.356 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.357 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.358 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.359 = private unnamed_addr constant [12 x i8] c" = zext i1 \00", align 8
@.str.360 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.361 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.362 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.363 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.364 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.365 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.366 = private unnamed_addr constant [5 x i8] c"left\00", align 8
@.str.367 = private unnamed_addr constant [6 x i8] c"right\00", align 8
@.str.368 = private unnamed_addr constant [2 x i8] c"+\00", align 8
@.str.369 = private unnamed_addr constant [23 x i8] c" = call i64 @_add(i64 \00", align 8
@.str.370 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.371 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.372 = private unnamed_addr constant [2 x i8] c"-\00", align 8
@.str.373 = private unnamed_addr constant [12 x i8] c" = sub i64 \00", align 8
@.str.374 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.375 = private unnamed_addr constant [2 x i8] c"*\00", align 8
@.str.376 = private unnamed_addr constant [12 x i8] c" = mul i64 \00", align 8
@.str.377 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.378 = private unnamed_addr constant [2 x i8] c"/\00", align 8
@.str.379 = private unnamed_addr constant [13 x i8] c" = sdiv i64 \00", align 8
@.str.380 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.381 = private unnamed_addr constant [2 x i8] c"%\00", align 8
@.str.382 = private unnamed_addr constant [13 x i8] c" = srem i64 \00", align 8
@.str.383 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.384 = private unnamed_addr constant [2 x i8] c"&\00", align 8
@.str.385 = private unnamed_addr constant [12 x i8] c" = and i64 \00", align 8
@.str.386 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.387 = private unnamed_addr constant [2 x i8] c"|\00", align 8
@.str.388 = private unnamed_addr constant [11 x i8] c" = or i64 \00", align 8
@.str.389 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.390 = private unnamed_addr constant [2 x i8] c"^\00", align 8
@.str.391 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.392 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.393 = private unnamed_addr constant [4 x i8] c"xor\00", align 8
@.str.394 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.395 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.396 = private unnamed_addr constant [2 x i8] c"~\00", align 8
@.str.397 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.398 = private unnamed_addr constant [5 x i8] c", -1\00", align 8
@.str.399 = private unnamed_addr constant [4 x i8] c"<<<\00", align 8
@.str.400 = private unnamed_addr constant [12 x i8] c" = shl i64 \00", align 8
@.str.401 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.402 = private unnamed_addr constant [4 x i8] c">>>\00", align 8
@.str.403 = private unnamed_addr constant [13 x i8] c" = lshr i64 \00", align 8
@.str.404 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.405 = private unnamed_addr constant [3 x i8] c"==\00", align 8
@.str.406 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.407 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.408 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.409 = private unnamed_addr constant [3 x i8] c"!=\00", align 8
@.str.410 = private unnamed_addr constant [22 x i8] c" = call i64 @_eq(i64 \00", align 8
@.str.411 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.412 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.413 = private unnamed_addr constant [12 x i8] c" = xor i64 \00", align 8
@.str.414 = private unnamed_addr constant [4 x i8] c", 1\00", align 8
@.str.415 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.416 = private unnamed_addr constant [2 x i8] c"<\00", align 8
@.str.417 = private unnamed_addr constant [4 x i8] c"slt\00", align 8
@.str.418 = private unnamed_addr constant [2 x i8] c">\00", align 8
@.str.419 = private unnamed_addr constant [4 x i8] c"sgt\00", align 8
@.str.420 = private unnamed_addr constant [3 x i8] c"<=\00", align 8
@.str.421 = private unnamed_addr constant [4 x i8] c"sle\00", align 8
@.str.422 = private unnamed_addr constant [3 x i8] c">=\00", align 8
@.str.423 = private unnamed_addr constant [4 x i8] c"sge\00", align 8
@.str.424 = private unnamed_addr constant [9 x i8] c" = icmp \00", align 8
@.str.425 = private unnamed_addr constant [6 x i8] c" i64 \00", align 8
@.str.426 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.427 = private unnamed_addr constant [12 x i8] c" = zext i1 \00", align 8
@.str.428 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.429 = private unnamed_addr constant [16 x i8] c" = add i64 0, 0\00", align 8
@.str.430 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.431 = private unnamed_addr constant [25 x i8] c" = call i64 @_list_new()\00", align 8
@.str.432 = private unnamed_addr constant [6 x i8] c"items\00", align 8
@.str.433 = private unnamed_addr constant [26 x i8] c"call i64 @_list_push(i64 \00", align 8
@.str.434 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.435 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.436 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.437 = private unnamed_addr constant [24 x i8] c" = call i64 @_map_new()\00", align 8
@.str.438 = private unnamed_addr constant [5 x i8] c"keys\00", align 8
@.str.439 = private unnamed_addr constant [5 x i8] c"vals\00", align 8
@.str.440 = private unnamed_addr constant [19 x i8] c" = getelementptr [\00", align 8
@.str.441 = private unnamed_addr constant [10 x i8] c" x i8], [\00", align 8
@.str.442 = private unnamed_addr constant [9 x i8] c" x i8]* \00", align 8
@.str.443 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.444 = private unnamed_addr constant [17 x i8] c" = ptrtoint i8* \00", align 8
@.str.445 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.446 = private unnamed_addr constant [24 x i8] c"call i64 @_map_set(i64 \00", align 8
@.str.447 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.448 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.449 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.sc.450 = global i64 0
@.str.451 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.452 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.453 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.454 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.455 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.456 = private unnamed_addr constant [4 x i8] c"obj\00", align 8
@.str.457 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.458 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.459 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.460 = private unnamed_addr constant [23 x i8] c" = call i64 @_get(i64 \00", align 8
@.str.461 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.462 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.463 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.464 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.465 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.466 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.467 = private unnamed_addr constant [4 x i8] c"sys\00", align 8
@.str.468 = private unnamed_addr constant [9 x i8] c"imperium\00", align 8
@.str.469 = private unnamed_addr constant [9 x i8] c"scrutari\00", align 8
@.str.470 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.471 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.472 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.473 = private unnamed_addr constant [17 x i8] c" = load i8, ptr \00", align 8
@.str.474 = private unnamed_addr constant [12 x i8] c" = zext i8 \00", align 8
@.str.475 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.476 = private unnamed_addr constant [11 x i8] c"mutare_mem\00", align 8
@.str.477 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.478 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.479 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.480 = private unnamed_addr constant [8 x i8] c" to ptr\00", align 8
@.str.481 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.482 = private unnamed_addr constant [7 x i8] c" to i8\00", align 8
@.str.483 = private unnamed_addr constant [19 x i8] c"store volatile i8 \00", align 8
@.str.484 = private unnamed_addr constant [7 x i8] c", ptr \00", align 8
@.str.485 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.486 = private unnamed_addr constant [10 x i8] c"alloc_mem\00", align 8
@.str.487 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.488 = private unnamed_addr constant [25 x i8] c" = call i64 @malloc(i64 \00", align 8
@.str.489 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.490 = private unnamed_addr constant [8 x i8] c"ptr_add\00", align 8
@.str.491 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.492 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.493 = private unnamed_addr constant [12 x i8] c" = add i64 \00", align 8
@.str.494 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.495 = private unnamed_addr constant [9 x i8] c"port_out\00", align 8
@.str.496 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.497 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.498 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.499 = private unnamed_addr constant [8 x i8] c" to i16\00", align 8
@.str.500 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.501 = private unnamed_addr constant [7 x i8] c" to i8\00", align 8
@.str.502 = private unnamed_addr constant [86 x i8] c"call void asm sideeffect \22outb %al, %dx\22, \22{al},{dx},~{dirflag},~{fpsr},~{flags}\22(i8 \00", align 8
@.str.503 = private unnamed_addr constant [7 x i8] c", i16 \00", align 8
@.str.504 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.505 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.506 = private unnamed_addr constant [8 x i8] c"port_in\00", align 8
@.str.507 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.508 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.509 = private unnamed_addr constant [8 x i8] c" to i16\00", align 8
@.str.510 = private unnamed_addr constant [88 x i8] c" = call i8 asm sideeffect \22inb %dx, %al\22, \22={al},{dx},~{dirflag},~{fpsr},~{flags}\22(i16 \00", align 8
@.str.511 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.512 = private unnamed_addr constant [12 x i8] c" = zext i8 \00", align 8
@.str.513 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.514 = private unnamed_addr constant [12 x i8] c"port_out_32\00", align 8
@.str.515 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.516 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.517 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.518 = private unnamed_addr constant [8 x i8] c" to i16\00", align 8
@.str.519 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.520 = private unnamed_addr constant [8 x i8] c" to i32\00", align 8
@.str.521 = private unnamed_addr constant [89 x i8] c"call void asm sideeffect \22outl %eax, %dx\22, \22{eax},{dx},~{dirflag},~{fpsr},~{flags}\22(i32 \00", align 8
@.str.522 = private unnamed_addr constant [7 x i8] c", i16 \00", align 8
@.str.523 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.524 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.525 = private unnamed_addr constant [11 x i8] c"port_in_32\00", align 8
@.str.526 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.527 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.528 = private unnamed_addr constant [8 x i8] c" to i16\00", align 8
@.str.529 = private unnamed_addr constant [91 x i8] c" = call i32 asm sideeffect \22inl %dx, %eax\22, \22={eax},{dx},~{dirflag},~{fpsr},~{flags}\22(i16 \00", align 8
@.str.530 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.531 = private unnamed_addr constant [13 x i8] c" = zext i32 \00", align 8
@.str.532 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.533 = private unnamed_addr constant [12 x i8] c"mem_read_32\00", align 8
@.str.534 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.535 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.536 = private unnamed_addr constant [9 x i8] c" to i32*\00", align 8
@.str.537 = private unnamed_addr constant [28 x i8] c" = load volatile i32, i32* \00", align 8
@.str.538 = private unnamed_addr constant [13 x i8] c" = zext i32 \00", align 8
@.str.539 = private unnamed_addr constant [8 x i8] c" to i64\00", align 8
@.str.540 = private unnamed_addr constant [13 x i8] c"mem_write_32\00", align 8
@.str.541 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.542 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.543 = private unnamed_addr constant [17 x i8] c" = inttoptr i64 \00", align 8
@.str.544 = private unnamed_addr constant [9 x i8] c" to i32*\00", align 8
@.str.545 = private unnamed_addr constant [14 x i8] c" = trunc i64 \00", align 8
@.str.546 = private unnamed_addr constant [8 x i8] c" to i32\00", align 8
@.str.547 = private unnamed_addr constant [20 x i8] c"store volatile i32 \00", align 8
@.str.548 = private unnamed_addr constant [8 x i8] c", i32* \00", align 8
@.str.549 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.550 = private unnamed_addr constant [16 x i8] c"imperium_kernel\00", align 8
@.str.551 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.552 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.553 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.554 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.555 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.556 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.557 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.558 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.559 = private unnamed_addr constant [27 x i8] c" = call i64 @syscall6(i64 \00", align 8
@.str.560 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.561 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.562 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.563 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.564 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.565 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.566 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.567 = private unnamed_addr constant [18 x i8] c"capere_argumentum\00", align 8
@.str.568 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.569 = private unnamed_addr constant [28 x i8] c" = call i64 @_get_argv(i64 \00", align 8
@.str.570 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.571 = private unnamed_addr constant [5 x i8] c"args\00", align 8
@.str.572 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.573 = private unnamed_addr constant [5 x i8] c"i64 \00", align 8
@.str.574 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.575 = private unnamed_addr constant [7 x i8] c"scribo\00", align 8
@.str.576 = private unnamed_addr constant [28 x i8] c" = call i64 @print_any(i64 \00", align 8
@.str.577 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.578 = private unnamed_addr constant [14 x i8] c" = call i64 @\00", align 8
@.str.579 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.580 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.581 = private unnamed_addr constant [2 x i8] c"0\00", align 8
@.str.582 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.583 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.584 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.585 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.586 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.587 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.588 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.589 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.590 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.591 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.592 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.593 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.594 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.595 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.596 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.597 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.598 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.599 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.600 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.601 = private unnamed_addr constant [4 x i8] c"idx\00", align 8
@.str.602 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.603 = private unnamed_addr constant [46 x i8] c"💀 FATAL: Index set on undefined variable '\00", align 8
@.str.604 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.605 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.606 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.607 = private unnamed_addr constant [20 x i8] c"call i64 @_set(i64 \00", align 8
@.str.608 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.609 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.610 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.611 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.612 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.613 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.614 = private unnamed_addr constant [47 x i8] c"💀 FATAL: Assignment to undefined variable '\00", align 8
@.str.615 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.616 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.617 = private unnamed_addr constant [11 x i8] c"store i64 \00", align 8
@.str.618 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.619 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.620 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.621 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.622 = private unnamed_addr constant [43 x i8] c"💀 FATAL: Append to undefined variable '\00", align 8
@.str.623 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.624 = private unnamed_addr constant [2 x i8] c"'\00", align 8
@.str.625 = private unnamed_addr constant [19 x i8] c" = load i64, i64* \00", align 8
@.str.626 = private unnamed_addr constant [28 x i8] c"call i64 @_append_poly(i64 \00", align 8
@.str.627 = private unnamed_addr constant [7 x i8] c", i64 \00", align 8
@.str.628 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.629 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.630 = private unnamed_addr constant [29 x i8] c"[DEBUG] Compiling STMT_PRINT\00", align 8
@.str.631 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.632 = private unnamed_addr constant [25 x i8] c"call i64 @print_any(i64 \00", align 8
@.str.633 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.634 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.635 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.636 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.637 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.638 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.639 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.640 = private unnamed_addr constant [9 x i8] c"ret i64 \00", align 8
@.str.641 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.642 = private unnamed_addr constant [5 x i8] c"expr\00", align 8
@.str.643 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.644 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.645 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.646 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.647 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.648 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.649 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.650 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.651 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.652 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.653 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.654 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.655 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.656 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.657 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.658 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.659 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.660 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.661 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.662 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.663 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.664 = private unnamed_addr constant [5 x i8] c"cond\00", align 8
@.str.665 = private unnamed_addr constant [16 x i8] c" = icmp ne i64 \00", align 8
@.str.666 = private unnamed_addr constant [4 x i8] c", 0\00", align 8
@.str.667 = private unnamed_addr constant [7 x i8] c"br i1 \00", align 8
@.str.668 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.669 = private unnamed_addr constant [10 x i8] c", label %\00", align 8
@.str.670 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.671 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.672 = private unnamed_addr constant [11 x i8] c"br label %\00", align 8
@.str.673 = private unnamed_addr constant [2 x i8] c":\00", align 8
@.str.674 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.675 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.676 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.677 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.678 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.679 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.680 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.681 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.682 = private unnamed_addr constant [5 x i8] c"else\00", align 8
@.str.683 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.684 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.685 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.686 = private unnamed_addr constant [5 x i8] c"main\00", align 8
@.str.687 = private unnamed_addr constant [12 x i8] c"achlys_main\00", align 8
@.str.688 = private unnamed_addr constant [13 x i8] c"define i64 @\00", align 8
@.str.689 = private unnamed_addr constant [2 x i8] c"(\00", align 8
@.str.690 = private unnamed_addr constant [7 x i8] c"params\00", align 8
@.str.691 = private unnamed_addr constant [10 x i8] c"i64 %arg_\00", align 8
@.str.692 = private unnamed_addr constant [3 x i8] c", \00", align 8
@.str.693 = private unnamed_addr constant [4 x i8] c") {\00", align 8
@.str.694 = private unnamed_addr constant [6 x i8] c"%ptr_\00", align 8
@.str.695 = private unnamed_addr constant [14 x i8] c" = alloca i64\00", align 8
@.str.696 = private unnamed_addr constant [16 x i8] c"store i64 %arg_\00", align 8
@.str.697 = private unnamed_addr constant [8 x i8] c", i64* \00", align 8
@.str.698 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.699 = private unnamed_addr constant [5 x i8] c"body\00", align 8
@.str.700 = private unnamed_addr constant [10 x i8] c"ret i64 0\00", align 8
@.str.701 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.702 = private unnamed_addr constant [29 x i8] c"; ModuleID = 'achlys_kernel'\00", align 8
@.str.703 = private unnamed_addr constant [11 x i8] c"4294967296\00", align 8
@.str.704 = private unnamed_addr constant [6 x i8] c"65536\00", align 8
@.str.705 = private unnamed_addr constant [20 x i8] c"x86_64-pc-linux-gnu\00", align 8
@.str.706 = private unnamed_addr constant [22 x i8] c"aarch64-linux-android\00", align 8
@.str.707 = private unnamed_addr constant [18 x i8] c"target triple = \22\00", align 8
@.str.708 = private unnamed_addr constant [2 x i8] c"\22\00", align 8
@.str.709 = private unnamed_addr constant [30 x i8] c"declare i32 @printf(i8*, ...)\00", align 8
@.str.710 = private unnamed_addr constant [25 x i8] c"declare i32 @fflush(i8*)\00", align 8
@.str.711 = private unnamed_addr constant [25 x i8] c"declare i64 @malloc(i64)\00", align 8
@.str.712 = private unnamed_addr constant [31 x i8] c"declare i8* @realloc(i8*, i64)\00", align 8
@.str.713 = private unnamed_addr constant [23 x i8] c"declare i32 @getchar()\00", align 8
@.str.714 = private unnamed_addr constant [24 x i8] c"declare void @exit(i32)\00", align 8
@.str.715 = private unnamed_addr constant [29 x i8] c"declare i8* @fopen(i8*, i8*)\00", align 8
@.str.716 = private unnamed_addr constant [34 x i8] c"declare i32 @fseek(i8*, i64, i32)\00", align 8
@.str.717 = private unnamed_addr constant [24 x i8] c"declare i64 @ftell(i8*)\00", align 8
@.str.718 = private unnamed_addr constant [39 x i8] c"declare i64 @fread(i8*, i64, i64, i8*)\00", align 8
@.str.719 = private unnamed_addr constant [40 x i8] c"declare i64 @fwrite(i8*, i64, i64, i8*)\00", align 8
@.str.720 = private unnamed_addr constant [25 x i8] c"declare i32 @fclose(i8*)\00", align 8
@.str.721 = private unnamed_addr constant [25 x i8] c"declare i32 @system(i8*)\00", align 8
@.str.722 = private unnamed_addr constant [25 x i8] c"declare i32 @usleep(i32)\00", align 8
@.str.723 = private unnamed_addr constant [30 x i8] c"declare i8* @strtok(i8*, i8*)\00", align 8
@.str.724 = private unnamed_addr constant [40 x i8] c"declare i64 @fast_memcpy(i64, i64, i64)\00", align 8
@.str.725 = private unnamed_addr constant [40 x i8] c"declare i64 @fast_fill32(i64, i64, i64)\00", align 8
@.str.726 = private unnamed_addr constant [32 x i8] c"declare i64 @get_system_ticks()\00", align 8
@.str.727 = private unnamed_addr constant [73 x i8] c"@.fmt_int = private unnamed_addr constant [5 x i8] c\22%ld\5C0A\5C00\22, align 8\00", align 8
@.str.728 = private unnamed_addr constant [72 x i8] c"@.fmt_str = private unnamed_addr constant [4 x i8] c\22%s\5C0A\5C00\22, align 8\00", align 8
@.str.729 = private unnamed_addr constant [71 x i8] c"@.fmt_raw_s = private unnamed_addr constant [3 x i8] c\22%s\5C00\22, align 8\00", align 8
@.str.730 = private unnamed_addr constant [72 x i8] c"@.fmt_raw_i = private unnamed_addr constant [4 x i8] c\22%ld\5C00\22, align 8\00", align 8
@.str.731 = private unnamed_addr constant [67 x i8] c"@.mode_r = private unnamed_addr constant [2 x i8] c\22r\5C00\22, align 8\00", align 8
@.str.732 = private unnamed_addr constant [67 x i8] c"@.mode_w = private unnamed_addr constant [2 x i8] c\22w\5C00\22, align 8\00", align 8
@.str.733 = private unnamed_addr constant [73 x i8] c"@.str_lst = private unnamed_addr constant [7 x i8] c\22<list>\5C00\22, align 8\00", align 8
@.str.734 = private unnamed_addr constant [72 x i8] c"@.str_map = private unnamed_addr constant [6 x i8] c\22<map>\5C00\22, align 8\00", align 8
@.str.735 = private unnamed_addr constant [40 x i8] c"@__sys_argv = global i8** null, align 8\00", align 8
@.str.736 = private unnamed_addr constant [36 x i8] c"@__sys_argc = global i32 0, align 8\00", align 8
@.str.737 = private unnamed_addr constant [68 x i8] c"@.m_brk_l = private unnamed_addr constant [2 x i8] c\22[\5C00\22, align 8\00", align 8
@.str.738 = private unnamed_addr constant [71 x i8] c"@.m_brk_r = private unnamed_addr constant [3 x i8] c\22]\5C0A\5C00\22, align 8\00", align 8
@.str.739 = private unnamed_addr constant [69 x i8] c"@.m_comma = private unnamed_addr constant [3 x i8] c\22, \5C00\22, align 8\00", align 8
@.str.740 = private unnamed_addr constant [39 x i8] c"define i64 @_str_cat(i64 %a, i64 %b) {\00", align 8
@.str.741 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.742 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.743 = private unnamed_addr constant [34 x i8] c"  %la = call i64 @strlen(i8* %sa)\00", align 8
@.str.744 = private unnamed_addr constant [34 x i8] c"  %lb = call i64 @strlen(i8* %sb)\00", align 8
@.str.745 = private unnamed_addr constant [25 x i8] c"  %sz = add i64 %la, %lb\00", align 8
@.str.746 = private unnamed_addr constant [24 x i8] c"  %sz1 = add i64 %sz, 1\00", align 8
@.str.747 = private unnamed_addr constant [36 x i8] c"  %mem = call i64 @malloc(i64 %sz1)\00", align 8
@.str.748 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.749 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %ptr, i8* %sa)\00", align 8
@.str.750 = private unnamed_addr constant [38 x i8] c"  call i8* @strcat(i8* %ptr, i8* %sb)\00", align 8
@.str.751 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.752 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.753 = private unnamed_addr constant [34 x i8] c"define i64 @to_string(i64 %val) {\00", align 8
@.str.754 = private unnamed_addr constant [32 x i8] c"  %is_ptr = icmp sgt i64 %val, \00", align 8
@.str.755 = private unnamed_addr constant [46 x i8] c"  br i1 %is_ptr, label %is_str, label %is_int\00", align 8
@.str.756 = private unnamed_addr constant [21 x i8] c"is_str: ret i64 %val\00", align 8
@.str.757 = private unnamed_addr constant [8 x i8] c"is_int:\00", align 8
@.str.758 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 32)\00", align 8
@.str.759 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.760 = private unnamed_addr constant [33 x i8] c"  %is_zero = icmp eq i64 %val, 0\00", align 8
@.str.761 = private unnamed_addr constant [43 x i8] c"  br i1 %is_zero, label %zero, label %calc\00", align 8
@.str.762 = private unnamed_addr constant [6 x i8] c"zero:\00", align 8
@.str.763 = private unnamed_addr constant [24 x i8] c"  store i8 48, i8* %ptr\00", align 8
@.str.764 = private unnamed_addr constant [45 x i8] c"  %zterm = getelementptr i8, i8* %ptr, i64 1\00", align 8
@.str.765 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %zterm\00", align 8
@.str.766 = private unnamed_addr constant [35 x i8] c"  %zret = ptrtoint i8* %ptr to i64\00", align 8
@.str.767 = private unnamed_addr constant [16 x i8] c"  ret i64 %zret\00", align 8
@.str.768 = private unnamed_addr constant [6 x i8] c"calc:\00", align 8
@.str.769 = private unnamed_addr constant [33 x i8] c"  %is_neg = icmp slt i64 %val, 0\00", align 8
@.str.770 = private unnamed_addr constant [29 x i8] c"  %neg_val = sub i64 0, %val\00", align 8
@.str.771 = private unnamed_addr constant [55 x i8] c"  %abs_val = select i1 %is_neg, i64 %neg_val, i64 %val\00", align 8
@.str.772 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.773 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.774 = private unnamed_addr constant [60 x i8] c"  %curr = phi i64 [ %abs_val, %calc ], [ %next_val, %loop ]\00", align 8
@.str.775 = private unnamed_addr constant [53 x i8] c"  %idx = phi i64 [ 30, %calc ], [ %next_idx, %loop ]\00", align 8
@.str.776 = private unnamed_addr constant [28 x i8] c"  %rem = srem i64 %curr, 10\00", align 8
@.str.777 = private unnamed_addr constant [27 x i8] c"  %char = add i64 %rem, 48\00", align 8
@.str.778 = private unnamed_addr constant [30 x i8] c"  %c8 = trunc i64 %char to i8\00", align 8
@.str.779 = private unnamed_addr constant [47 x i8] c"  %slot = getelementptr i8, i8* %ptr, i64 %idx\00", align 8
@.str.780 = private unnamed_addr constant [26 x i8] c"  store i8 %c8, i8* %slot\00", align 8
@.str.781 = private unnamed_addr constant [33 x i8] c"  %next_val = sdiv i64 %curr, 10\00", align 8
@.str.782 = private unnamed_addr constant [30 x i8] c"  %next_idx = sub i64 %idx, 1\00", align 8
@.str.783 = private unnamed_addr constant [35 x i8] c"  %stop = icmp eq i64 %next_val, 0\00", align 8
@.str.784 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %loop\00", align 8
@.str.785 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.786 = private unnamed_addr constant [36 x i8] c"  %start_idx = add i64 %next_idx, 1\00", align 8
@.str.787 = private unnamed_addr constant [45 x i8] c"  br i1 %is_neg, label %add_neg, label %copy\00", align 8
@.str.788 = private unnamed_addr constant [9 x i8] c"add_neg:\00", align 8
@.str.789 = private unnamed_addr constant [56 x i8] c"  %neg_slot = getelementptr i8, i8* %ptr, i64 %next_idx\00", align 8
@.str.790 = private unnamed_addr constant [29 x i8] c"  store i8 45, i8* %neg_slot\00", align 8
@.str.791 = private unnamed_addr constant [17 x i8] c"  br label %copy\00", align 8
@.str.792 = private unnamed_addr constant [6 x i8] c"copy:\00", align 8
@.str.793 = private unnamed_addr constant [72 x i8] c"  %final_start = phi i64 [ %start_idx, %done ], [ %next_idx, %add_neg ]\00", align 8
@.str.794 = private unnamed_addr constant [50 x i8] c"  %term_slot = getelementptr i8, i8* %ptr, i64 31\00", align 8
@.str.795 = private unnamed_addr constant [29 x i8] c"  store i8 0, i8* %term_slot\00", align 8
@.str.796 = private unnamed_addr constant [58 x i8] c"  %ret_ptr = getelementptr i8, i8* %ptr, i64 %final_start\00", align 8
@.str.797 = private unnamed_addr constant [42 x i8] c"  %ret_int = ptrtoint i8* %ret_ptr to i64\00", align 8
@.str.798 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.799 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.800 = private unnamed_addr constant [35 x i8] c"define i64 @_add(i64 %a, i64 %b) {\00", align 8
@.str.801 = private unnamed_addr constant [32 x i8] c"  %is_ptr_a = icmp sgt i64 %a, \00", align 8
@.str.802 = private unnamed_addr constant [32 x i8] c"  %is_ptr_b = icmp sgt i64 %b, \00", align 8
@.str.803 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.804 = private unnamed_addr constant [40 x i8] c"  %any_ptr = or i1 %is_ptr_a, %is_ptr_b\00", align 8
@.str.805 = private unnamed_addr constant [55 x i8] c"  br i1 %both_ptr, label %check_list, label %check_str\00", align 8
@.str.806 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.807 = private unnamed_addr constant [34 x i8] c"  %ptr_a = inttoptr i64 %a to i8*\00", align 8
@.str.808 = private unnamed_addr constant [32 x i8] c"  %type_a = load i8, i8* %ptr_a\00", align 8
@.str.809 = private unnamed_addr constant [35 x i8] c"  %is_list = icmp eq i8 %type_a, 3\00", align 8
@.str.810 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_str\00", align 8
@.str.811 = private unnamed_addr constant [11 x i8] c"check_str:\00", align 8
@.str.812 = private unnamed_addr constant [44 x i8] c"  br i1 %any_ptr, label %do_str, label %int\00", align 8
@.str.813 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.814 = private unnamed_addr constant [36 x i8] c"  %sa = call i64 @to_string(i64 %a)\00", align 8
@.str.815 = private unnamed_addr constant [36 x i8] c"  %sb = call i64 @to_string(i64 %b)\00", align 8
@.str.816 = private unnamed_addr constant [50 x i8] c"  %ret_str = call i64 @_str_cat(i64 %sa, i64 %sb)\00", align 8
@.str.817 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.818 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.819 = private unnamed_addr constant [36 x i8] c"  %new_list = call i64 @_list_new()\00", align 8
@.str.820 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %a)\00", align 8
@.str.821 = private unnamed_addr constant [47 x i8] c"  call void @_list_copy(i64 %new_list, i64 %b)\00", align 8
@.str.822 = private unnamed_addr constant [20 x i8] c"  ret i64 %new_list\00", align 8
@.str.823 = private unnamed_addr constant [5 x i8] c"int:\00", align 8
@.str.824 = private unnamed_addr constant [28 x i8] c"  %ret_int = add i64 %a, %b\00", align 8
@.str.825 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.826 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.827 = private unnamed_addr constant [47 x i8] c"define void @_list_copy(i64 %dest, i64 %src) {\00", align 8
@.str.828 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %src to i64*\00", align 8
@.str.829 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.830 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.831 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.832 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.833 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.834 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.835 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.836 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]\00", align 8
@.str.837 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.838 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.839 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.840 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.841 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.842 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %dest, i64 %val)\00", align 8
@.str.843 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.844 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.845 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.846 = private unnamed_addr constant [11 x i8] c"  ret void\00", align 8
@.str.847 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.848 = private unnamed_addr constant [48 x i8] c"define i64 @_append_poly(i64 %list, i64 %val) {\00", align 8
@.str.849 = private unnamed_addr constant [32 x i8] c"  %is_ptr = icmp sgt i64 %val, \00", align 8
@.str.850 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_list, label %push_one\00", align 8
@.str.851 = private unnamed_addr constant [12 x i8] c"check_list:\00", align 8
@.str.852 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.853 = private unnamed_addr constant [28 x i8] c"  %type = load i8, i8* %ptr\00", align 8
@.str.854 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.855 = private unnamed_addr constant [48 x i8] c"  br i1 %is_list, label %merge, label %push_one\00", align 8
@.str.856 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.857 = private unnamed_addr constant [45 x i8] c"  call void @_list_copy(i64 %list, i64 %val)\00", align 8
@.str.858 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.859 = private unnamed_addr constant [10 x i8] c"push_one:\00", align 8
@.str.860 = private unnamed_addr constant [44 x i8] c"  call i64 @_list_push(i64 %list, i64 %val)\00", align 8
@.str.861 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.862 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.863 = private unnamed_addr constant [34 x i8] c"define i64 @_eq(i64 %a, i64 %b) {\00", align 8
@.str.864 = private unnamed_addr constant [32 x i8] c"  %a_is_ptr = icmp sgt i64 %a, \00", align 8
@.str.865 = private unnamed_addr constant [32 x i8] c"  %b_is_ptr = icmp sgt i64 %b, \00", align 8
@.str.866 = private unnamed_addr constant [42 x i8] c"  %both_ptr = and i1 %a_is_ptr, %b_is_ptr\00", align 8
@.str.867 = private unnamed_addr constant [53 x i8] c"  br i1 %both_ptr, label %check_null, label %cmp_int\00", align 8
@.str.868 = private unnamed_addr constant [12 x i8] c"check_null:\00", align 8
@.str.869 = private unnamed_addr constant [30 x i8] c"  %a_null = icmp eq i64 %a, 0\00", align 8
@.str.870 = private unnamed_addr constant [30 x i8] c"  %b_null = icmp eq i64 %b, 0\00", align 8
@.str.871 = private unnamed_addr constant [37 x i8] c"  %any_null = or i1 %a_null, %b_null\00", align 8
@.str.872 = private unnamed_addr constant [50 x i8] c"  br i1 %any_null, label %cmp_int, label %cmp_str\00", align 8
@.str.873 = private unnamed_addr constant [9 x i8] c"cmp_str:\00", align 8
@.str.874 = private unnamed_addr constant [31 x i8] c"  %sa = inttoptr i64 %a to i8*\00", align 8
@.str.875 = private unnamed_addr constant [31 x i8] c"  %sb = inttoptr i64 %b to i8*\00", align 8
@.str.876 = private unnamed_addr constant [44 x i8] c"  %res = call i32 @strcmp(i8* %sa, i8* %sb)\00", align 8
@.str.877 = private unnamed_addr constant [30 x i8] c"  %iseq = icmp eq i32 %res, 0\00", align 8
@.str.878 = private unnamed_addr constant [34 x i8] c"  %ret_str = zext i1 %iseq to i64\00", align 8
@.str.879 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.880 = private unnamed_addr constant [9 x i8] c"cmp_int:\00", align 8
@.str.881 = private unnamed_addr constant [33 x i8] c"  %iseq_int = icmp eq i64 %a, %b\00", align 8
@.str.882 = private unnamed_addr constant [38 x i8] c"  %ret_int = zext i1 %iseq_int to i64\00", align 8
@.str.883 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_int\00", align 8
@.str.884 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.885 = private unnamed_addr constant [26 x i8] c"define i64 @_list_new() {\00", align 8
@.str.886 = private unnamed_addr constant [34 x i8] c"  %mem = call i64 @malloc(i64 24)\00", align 8
@.str.887 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %mem to i64*\00", align 8
@.str.888 = private unnamed_addr constant [25 x i8] c"  store i64 3, i64* %ptr\00", align 8
@.str.889 = private unnamed_addr constant [45 x i8] c"  %cnt = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.890 = private unnamed_addr constant [25 x i8] c"  store i64 0, i64* %cnt\00", align 8
@.str.891 = private unnamed_addr constant [46 x i8] c"  %data = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.892 = private unnamed_addr constant [26 x i8] c"  store i64 0, i64* %data\00", align 8
@.str.893 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.894 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.895 = private unnamed_addr constant [50 x i8] c"define i64 @_list_set(i64 %l, i64 %idx, i64 %v) {\00", align 8
@.str.896 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.897 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.898 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.899 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.900 = private unnamed_addr constant [54 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %idx\00", align 8
@.str.901 = private unnamed_addr constant [27 x i8] c"  store i64 %v, i64* %slot\00", align 8
@.str.902 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.903 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.904 = private unnamed_addr constant [41 x i8] c"define i64 @_list_push(i64 %l, i64 %v) {\00", align 8
@.str.905 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %l to i64*\00", align 8
@.str.906 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.907 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.908 = private unnamed_addr constant [29 x i8] c"  %new_cnt = add i64 %cnt, 1\00", align 8
@.str.909 = private unnamed_addr constant [36 x i8] c"  store i64 %new_cnt, i64* %cnt_ptr\00", align 8
@.str.910 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.911 = private unnamed_addr constant [40 x i8] c"  %old_mem_i = load i64, i64* %data_ptr\00", align 8
@.str.912 = private unnamed_addr constant [35 x i8] c"  %req_bytes = mul i64 %new_cnt, 8\00", align 8
@.str.913 = private unnamed_addr constant [44 x i8] c"  %old_ptr = inttoptr i64 %old_mem_i to i8*\00", align 8
@.str.914 = private unnamed_addr constant [61 x i8] c"  %new_ptr = call i8* @realloc(i8* %old_ptr, i64 %req_bytes)\00", align 8
@.str.915 = private unnamed_addr constant [42 x i8] c"  %new_mem = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.916 = private unnamed_addr constant [37 x i8] c"  store i64 %new_mem, i64* %data_ptr\00", align 8
@.str.917 = private unnamed_addr constant [44 x i8] c"  %base_ptr = inttoptr i64 %new_mem to i64*\00", align 8
@.str.918 = private unnamed_addr constant [53 x i8] c"  %idx = getelementptr i64, i64* %base_ptr, i64 %cnt\00", align 8
@.str.919 = private unnamed_addr constant [26 x i8] c"  store i64 %v, i64* %idx\00", align 8
@.str.920 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.921 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.922 = private unnamed_addr constant [25 x i8] c"define i64 @_map_new() {\00", align 8
@.str.923 = private unnamed_addr constant [29 x i8] c"  %m = call i64 @_list_new()\00", align 8
@.str.924 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.925 = private unnamed_addr constant [25 x i8] c"  store i64 4, i64* %ptr\00", align 8
@.str.926 = private unnamed_addr constant [13 x i8] c"  ret i64 %m\00", align 8
@.str.927 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.928 = private unnamed_addr constant [47 x i8] c"define i64 @_map_set(i64 %m, i64 %k, i64 %v) {\00", align 8
@.str.929 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %k)\00", align 8
@.str.930 = private unnamed_addr constant [39 x i8] c"  call i64 @_list_push(i64 %m, i64 %v)\00", align 8
@.str.931 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.932 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.933 = private unnamed_addr constant [47 x i8] c"define i64 @_set(i64 %col, i64 %idx, i64 %v) {\00", align 8
@.str.934 = private unnamed_addr constant [35 x i8] c"  %ptr = inttoptr i64 %col to i64*\00", align 8
@.str.935 = private unnamed_addr constant [30 x i8] c"  %type = load i64, i64* %ptr\00", align 8
@.str.936 = private unnamed_addr constant [33 x i8] c"  %is_map = icmp eq i64 %type, 4\00", align 8
@.str.937 = private unnamed_addr constant [47 x i8] c"  br i1 %is_map, label %do_map, label %do_list\00", align 8
@.str.938 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.939 = private unnamed_addr constant [50 x i8] c"  call i64 @_list_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.940 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.941 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.942 = private unnamed_addr constant [49 x i8] c"  call i64 @_map_set(i64 %col, i64 %idx, i64 %v)\00", align 8
@.str.943 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.944 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.945 = private unnamed_addr constant [41 x i8] c"define i64 @_map_get(i64 %m, i64 %key) {\00", align 8
@.str.946 = private unnamed_addr constant [33 x i8] c"  %ptr = inttoptr i64 %m to i64*\00", align 8
@.str.947 = private unnamed_addr constant [49 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr, i64 1\00", align 8
@.str.948 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.949 = private unnamed_addr constant [50 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr, i64 2\00", align 8
@.str.950 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.951 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.952 = private unnamed_addr constant [36 x i8] c"  %key_s = inttoptr i64 %key to i8*\00", align 8
@.str.953 = private unnamed_addr constant [29 x i8] c"  %start_i = sub i64 %cnt, 2\00", align 8
@.str.954 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.955 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.956 = private unnamed_addr constant [52 x i8] c"  %i = phi i64 [ %start_i, %0 ], [ %next_i, %next ]\00", align 8
@.str.957 = private unnamed_addr constant [29 x i8] c"  %cond = icmp sge i64 %i, 0\00", align 8
@.str.958 = private unnamed_addr constant [50 x i8] c"  br i1 %cond, label %check_key, label %not_found\00", align 8
@.str.959 = private unnamed_addr constant [11 x i8] c"check_key:\00", align 8
@.str.960 = private unnamed_addr constant [54 x i8] c"  %k_slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.961 = private unnamed_addr constant [34 x i8] c"  %k_val = load i64, i64* %k_slot\00", align 8
@.str.962 = private unnamed_addr constant [38 x i8] c"  %k_str = inttoptr i64 %k_val to i8*\00", align 8
@.str.963 = private unnamed_addr constant [50 x i8] c"  %cmp = call i32 @strcmp(i8* %k_str, i8* %key_s)\00", align 8
@.str.964 = private unnamed_addr constant [31 x i8] c"  %match = icmp eq i32 %cmp, 0\00", align 8
@.str.965 = private unnamed_addr constant [42 x i8] c"  br i1 %match, label %found, label %next\00", align 8
@.str.966 = private unnamed_addr constant [6 x i8] c"next:\00", align 8
@.str.967 = private unnamed_addr constant [26 x i8] c"  %next_i = sub i64 %i, 2\00", align 8
@.str.968 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.969 = private unnamed_addr constant [7 x i8] c"found:\00", align 8
@.str.970 = private unnamed_addr constant [25 x i8] c"  %v_idx = add i64 %i, 1\00", align 8
@.str.971 = private unnamed_addr constant [58 x i8] c"  %v_slot = getelementptr i64, i64* %base_ptr, i64 %v_idx\00", align 8
@.str.972 = private unnamed_addr constant [32 x i8] c"  %ret = load i64, i64* %v_slot\00", align 8
@.str.973 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.974 = private unnamed_addr constant [11 x i8] c"not_found:\00", align 8
@.str.975 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.976 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.977 = private unnamed_addr constant [39 x i8] c"define i64 @_get(i64 %col, i64 %idx) {\00", align 8
@.str.978 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %col, 0\00", align 8
@.str.979 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %err, label %check\00", align 8
@.str.980 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.981 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %col to i8*\00", align 8
@.str.982 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.983 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.984 = private unnamed_addr constant [51 x i8] c"  br i1 %is_list, label %do_list, label %check_map\00", align 8
@.str.985 = private unnamed_addr constant [11 x i8] c"check_map:\00", align 8
@.str.986 = private unnamed_addr constant [31 x i8] c"  %is_map = icmp eq i8 %tag, 4\00", align 8
@.str.987 = private unnamed_addr constant [46 x i8] c"  br i1 %is_map, label %do_map, label %do_str\00", align 8
@.str.988 = private unnamed_addr constant [8 x i8] c"do_str:\00", align 8
@.str.989 = private unnamed_addr constant [39 x i8] c"  %str_base = inttoptr i64 %col to i8*\00", align 8
@.str.990 = private unnamed_addr constant [56 x i8] c"  %char_ptr = getelementptr i8, i8* %str_base, i64 %idx\00", align 8
@.str.991 = private unnamed_addr constant [33 x i8] c"  %char = load i8, i8* %char_ptr\00", align 8
@.str.992 = private unnamed_addr constant [37 x i8] c"  %new_mem = call i64 @malloc(i64 2)\00", align 8
@.str.993 = private unnamed_addr constant [42 x i8] c"  %new_ptr = inttoptr i64 %new_mem to i8*\00", align 8
@.str.994 = private unnamed_addr constant [31 x i8] c"  store i8 %char, i8* %new_ptr\00", align 8
@.str.995 = private unnamed_addr constant [48 x i8] c"  %term = getelementptr i8, i8* %new_ptr, i64 1\00", align 8
@.str.996 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.997 = private unnamed_addr constant [42 x i8] c"  %ret_str = ptrtoint i8* %new_ptr to i64\00", align 8
@.str.998 = private unnamed_addr constant [19 x i8] c"  ret i64 %ret_str\00", align 8
@.str.999 = private unnamed_addr constant [8 x i8] c"do_map:\00", align 8
@.str.1000 = private unnamed_addr constant [52 x i8] c"  %map_val = call i64 @_map_get(i64 %col, i64 %idx)\00", align 8
@.str.1001 = private unnamed_addr constant [19 x i8] c"  ret i64 %map_val\00", align 8
@.str.1002 = private unnamed_addr constant [9 x i8] c"do_list:\00", align 8
@.str.1003 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %col to i64*\00", align 8
@.str.1004 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.1005 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.1006 = private unnamed_addr constant [36 x i8] c"  %arr = inttoptr i64 %base to i64*\00", align 8
@.str.1007 = private unnamed_addr constant [49 x i8] c"  %slot = getelementptr i64, i64* %arr, i64 %idx\00", align 8
@.str.1008 = private unnamed_addr constant [30 x i8] c"  %val = load i64, i64* %slot\00", align 8
@.str.1009 = private unnamed_addr constant [15 x i8] c"  ret i64 %val\00", align 8
@.str.1010 = private unnamed_addr constant [15 x i8] c"err: ret i64 0\00", align 8
@.str.1011 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1012 = private unnamed_addr constant [34 x i8] c"define i64 @_get_argv(i64 %idx) {\00", align 8
@.str.1013 = private unnamed_addr constant [37 x i8] c"  %argc = load i32, i32* @__sys_argc\00", align 8
@.str.1014 = private unnamed_addr constant [34 x i8] c"  %argc64 = sext i32 %argc to i64\00", align 8
@.str.1015 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %idx, %argc64\00", align 8
@.str.1016 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %err, label %ok\00", align 8
@.str.1017 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.1018 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1019 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1020 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1021 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1022 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.1023 = private unnamed_addr constant [39 x i8] c"  %argv = load i8**, i8*** @__sys_argv\00", align 8
@.str.1024 = private unnamed_addr constant [49 x i8] c"  %ptr = getelementptr i8*, i8** %argv, i64 %idx\00", align 8
@.str.1025 = private unnamed_addr constant [29 x i8] c"  %str = load i8*, i8** %ptr\00", align 8
@.str.1026 = private unnamed_addr constant [34 x i8] c"  %ret = ptrtoint i8* %str to i64\00", align 8
@.str.1027 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.1028 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1029 = private unnamed_addr constant [36 x i8] c"define i64 @revelare(i64 %path_i) {\00", align 8
@.str.1030 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.1031 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_r, i64 0, i64 0\00", align 8
@.str.1032 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.1033 = private unnamed_addr constant [34 x i8] c"  %f_int = ptrtoint i8* %f to i64\00", align 8
@.str.1034 = private unnamed_addr constant [33 x i8] c"  %valid = icmp ne i64 %f_int, 0\00", align 8
@.str.1035 = private unnamed_addr constant [40 x i8] c"  br i1 %valid, label %read, label %err\00", align 8
@.str.1036 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1037 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 2)\00", align 8
@.str.1038 = private unnamed_addr constant [33 x i8] c"  %len = call i64 @ftell(i8* %f)\00", align 8
@.str.1039 = private unnamed_addr constant [40 x i8] c"  call i32 @fseek(i8* %f, i64 0, i32 0)\00", align 8
@.str.1040 = private unnamed_addr constant [30 x i8] c"  %alloc_sz = add i64 %len, 1\00", align 8
@.str.1041 = private unnamed_addr constant [41 x i8] c"  %buf = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.1042 = private unnamed_addr constant [38 x i8] c"  %buf_ptr = inttoptr i64 %buf to i8*\00", align 8
@.str.1043 = private unnamed_addr constant [57 x i8] c"  call i64 @fread(i8* %buf_ptr, i64 1, i64 %len, i8* %f)\00", align 8
@.str.1044 = private unnamed_addr constant [51 x i8] c"  %term = getelementptr i8, i8* %buf_ptr, i64 %len\00", align 8
@.str.1045 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1046 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.1047 = private unnamed_addr constant [15 x i8] c"  ret i64 %buf\00", align 8
@.str.1048 = private unnamed_addr constant [5 x i8] c"err:\00", align 8
@.str.1049 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1050 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1051 = private unnamed_addr constant [52 x i8] c"define i64 @inscribo(i64 %path_i, i64 %content_i) {\00", align 8
@.str.1052 = private unnamed_addr constant [38 x i8] c"  %path = inttoptr i64 %path_i to i8*\00", align 8
@.str.1053 = private unnamed_addr constant [44 x i8] c"  %content = inttoptr i64 %content_i to i8*\00", align 8
@.str.1054 = private unnamed_addr constant [67 x i8] c"  %mode = getelementptr [2 x i8], [2 x i8]* @.mode_w, i64 0, i64 0\00", align 8
@.str.1055 = private unnamed_addr constant [45 x i8] c"  %f = call i8* @fopen(i8* %path, i8* %mode)\00", align 8
@.str.1056 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %content)\00", align 8
@.str.1057 = private unnamed_addr constant [58 x i8] c"  call i64 @fwrite(i8* %content, i64 1, i64 %len, i8* %f)\00", align 8
@.str.1058 = private unnamed_addr constant [27 x i8] c"  call i32 @fclose(i8* %f)\00", align 8
@.str.1059 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1060 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1061 = private unnamed_addr constant [34 x i8] c"define i64 @print_any(i64 %val) {\00", align 8
@.str.1062 = private unnamed_addr constant [7 x i8] c"entry:\00", align 8
@.str.1063 = private unnamed_addr constant [32 x i8] c"  %is_ptr = icmp sgt i64 %val, \00", align 8
@.str.1064 = private unnamed_addr constant [52 x i8] c"  br i1 %is_ptr, label %check_obj, label %print_int\00", align 8
@.str.1065 = private unnamed_addr constant [11 x i8] c"check_obj:\00", align 8
@.str.1066 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.1067 = private unnamed_addr constant [28 x i8] c"  %tag = load i8, i8* %ptr8\00", align 8
@.str.1068 = private unnamed_addr constant [32 x i8] c"  %is_list = icmp eq i8 %tag, 3\00", align 8
@.str.1069 = private unnamed_addr constant [54 x i8] c"  br i1 %is_list, label %print_list, label %print_str\00", align 8
@.str.1070 = private unnamed_addr constant [12 x i8] c"print_list:\00", align 8
@.str.1071 = private unnamed_addr constant [70 x i8] c"  %f_s1 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.1072 = private unnamed_addr constant [67 x i8] c"  %b_l = getelementptr [2 x i8], [2 x i8]* @.m_brk_l, i64 0, i64 0\00", align 8
@.str.1073 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s1, i8* %b_l)\00", align 8
@.str.1074 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1075 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.1076 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1077 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1078 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.1079 = private unnamed_addr constant [50 x i8] c"  br i1 %is_empty, label %done, label %setup_loop\00", align 8
@.str.1080 = private unnamed_addr constant [12 x i8] c"setup_loop:\00", align 8
@.str.1081 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.1082 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.1083 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.1084 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1085 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1086 = private unnamed_addr constant [58 x i8] c"  %i = phi i64 [ 0, %setup_loop ], [ %next_i, %loop_end ]\00", align 8
@.str.1087 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.1088 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.1089 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1090 = private unnamed_addr constant [33 x i8] c"  %not_first = icmp ne i64 %i, 0\00", align 8
@.str.1091 = private unnamed_addr constant [51 x i8] c"  br i1 %not_first, label %comma, label %val_print\00", align 8
@.str.1092 = private unnamed_addr constant [7 x i8] c"comma:\00", align 8
@.str.1093 = private unnamed_addr constant [70 x i8] c"  %f_s2 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.1094 = private unnamed_addr constant [67 x i8] c"  %com = getelementptr [3 x i8], [3 x i8]* @.m_comma, i64 0, i64 0\00", align 8
@.str.1095 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s2, i8* %com)\00", align 8
@.str.1096 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1097 = private unnamed_addr constant [22 x i8] c"  br label %val_print\00", align 8
@.str.1098 = private unnamed_addr constant [11 x i8] c"val_print:\00", align 8
@.str.1099 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.1100 = private unnamed_addr constant [28 x i8] c"  %v = load i64, i64* %slot\00", align 8
@.str.1101 = private unnamed_addr constant [32 x i8] c"  %v_is_ptr = icmp sgt i64 %v, \00", align 8
@.str.1102 = private unnamed_addr constant [52 x i8] c"  br i1 %v_is_ptr, label %v_ptr_check, label %v_int\00", align 8
@.str.1103 = private unnamed_addr constant [13 x i8] c"v_ptr_check:\00", align 8
@.str.1104 = private unnamed_addr constant [36 x i8] c"  %vs_ptr8 = inttoptr i64 %v to i8*\00", align 8
@.str.1105 = private unnamed_addr constant [34 x i8] c"  %in_tag = load i8, i8* %vs_ptr8\00", align 8
@.str.1106 = private unnamed_addr constant [38 x i8] c"  %in_is_list = icmp eq i8 %in_tag, 3\00", align 8
@.str.1107 = private unnamed_addr constant [55 x i8] c"  br i1 %in_is_list, label %v_nested, label %v_raw_str\00", align 8
@.str.1108 = private unnamed_addr constant [10 x i8] c"v_nested:\00", align 8
@.str.1109 = private unnamed_addr constant [30 x i8] c"  call i64 @print_any(i64 %v)\00", align 8
@.str.1110 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.1111 = private unnamed_addr constant [11 x i8] c"v_raw_str:\00", align 8
@.str.1112 = private unnamed_addr constant [70 x i8] c"  %f_s3 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.1113 = private unnamed_addr constant [35 x i8] c"  %vs_str = inttoptr i64 %v to i8*\00", align 8
@.str.1114 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s3, i8* %vs_str)\00", align 8
@.str.1115 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1116 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.1117 = private unnamed_addr constant [7 x i8] c"v_int:\00", align 8
@.str.1118 = private unnamed_addr constant [69 x i8] c"  %f_i = getelementptr [4 x i8], [4 x i8]* @.fmt_raw_i, i64 0, i64 0\00", align 8
@.str.1119 = private unnamed_addr constant [48 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i, i64 %v)\00", align 8
@.str.1120 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1121 = private unnamed_addr constant [21 x i8] c"  br label %loop_end\00", align 8
@.str.1122 = private unnamed_addr constant [10 x i8] c"loop_end:\00", align 8
@.str.1123 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1124 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1125 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1126 = private unnamed_addr constant [70 x i8] c"  %f_s4 = getelementptr [3 x i8], [3 x i8]* @.fmt_raw_s, i64 0, i64 0\00", align 8
@.str.1127 = private unnamed_addr constant [67 x i8] c"  %b_r = getelementptr [3 x i8], [3 x i8]* @.m_brk_r, i64 0, i64 0\00", align 8
@.str.1128 = private unnamed_addr constant [51 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s4, i8* %b_r)\00", align 8
@.str.1129 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1130 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1131 = private unnamed_addr constant [11 x i8] c"print_int:\00", align 8
@.str.1132 = private unnamed_addr constant [71 x i8] c"  %f_i_end = getelementptr [5 x i8], [5 x i8]* @.fmt_int, i64 0, i64 0\00", align 8
@.str.1133 = private unnamed_addr constant [54 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_i_end, i64 %val)\00", align 8
@.str.1134 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1135 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1136 = private unnamed_addr constant [11 x i8] c"print_str:\00", align 8
@.str.1137 = private unnamed_addr constant [71 x i8] c"  %f_s_end = getelementptr [4 x i8], [4 x i8]* @.fmt_str, i64 0, i64 0\00", align 8
@.str.1138 = private unnamed_addr constant [36 x i8] c"  %str_p = inttoptr i64 %val to i8*\00", align 8
@.str.1139 = private unnamed_addr constant [56 x i8] c"  call i32 (i8*, ...) @printf(i8* %f_s_end, i8* %str_p)\00", align 8
@.str.1140 = private unnamed_addr constant [29 x i8] c"  call i32 @fflush(i8* null)\00", align 8
@.str.1141 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1142 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1143 = private unnamed_addr constant [30 x i8] c"define i64 @codex(i64 %val) {\00", align 8
@.str.1144 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %val to i8*\00", align 8
@.str.1145 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.1146 = private unnamed_addr constant [27 x i8] c"  %ret = zext i8 %c to i64\00", align 8
@.str.1147 = private unnamed_addr constant [15 x i8] c"  ret i64 %ret\00", align 8
@.str.1148 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1149 = private unnamed_addr constant [51 x i8] c"define i64 @pars(i64 %str, i64 %start, i64 %len) {\00", align 8
@.str.1150 = private unnamed_addr constant [34 x i8] c"  %src = inttoptr i64 %str to i8*\00", align 8
@.str.1151 = private unnamed_addr constant [37 x i8] c"  %slen = call i64 @strlen(i8* %src)\00", align 8
@.str.1152 = private unnamed_addr constant [39 x i8] c"  %is_oob = icmp sge i64 %start, %slen\00", align 8
@.str.1153 = private unnamed_addr constant [39 x i8] c"  br i1 %is_oob, label %oob, label %ok\00", align 8
@.str.1154 = private unnamed_addr constant [5 x i8] c"oob:\00", align 8
@.str.1155 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1156 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1157 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1158 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1159 = private unnamed_addr constant [4 x i8] c"ok:\00", align 8
@.str.1160 = private unnamed_addr constant [31 x i8] c"  %rem = sub i64 %slen, %start\00", align 8
@.str.1161 = private unnamed_addr constant [37 x i8] c"  %is_long = icmp sgt i64 %len, %rem\00", align 8
@.str.1162 = private unnamed_addr constant [53 x i8] c"  %safe_len = select i1 %is_long, i64 %rem, i64 %len\00", align 8
@.str.1163 = private unnamed_addr constant [52 x i8] c"  %src_off = getelementptr i8, i8* %src, i64 %start\00", align 8
@.str.1164 = private unnamed_addr constant [35 x i8] c"  %alloc_sz = add i64 %safe_len, 1\00", align 8
@.str.1165 = private unnamed_addr constant [42 x i8] c"  %dest = call i64 @malloc(i64 %alloc_sz)\00", align 8
@.str.1166 = private unnamed_addr constant [40 x i8] c"  %dest_ptr = inttoptr i64 %dest to i8*\00", align 8
@.str.1167 = private unnamed_addr constant [64 x i8] c"  call i8* @strncpy(i8* %dest_ptr, i8* %src_off, i64 %safe_len)\00", align 8
@.str.1168 = private unnamed_addr constant [57 x i8] c"  %term = getelementptr i8, i8* %dest_ptr, i64 %safe_len\00", align 8
@.str.1169 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1170 = private unnamed_addr constant [16 x i8] c"  ret i64 %dest\00", align 8
@.str.1171 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1172 = private unnamed_addr constant [34 x i8] c"define i64 @signum_ex(i64 %val) {\00", align 8
@.str.1173 = private unnamed_addr constant [33 x i8] c"  %mem = call i64 @malloc(i64 2)\00", align 8
@.str.1174 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1175 = private unnamed_addr constant [28 x i8] c"  %c = trunc i64 %val to i8\00", align 8
@.str.1176 = private unnamed_addr constant [24 x i8] c"  store i8 %c, i8* %ptr\00", align 8
@.str.1177 = private unnamed_addr constant [44 x i8] c"  %term = getelementptr i8, i8* %ptr, i64 1\00", align 8
@.str.1178 = private unnamed_addr constant [24 x i8] c"  store i8 0, i8* %term\00", align 8
@.str.1179 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1180 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1181 = private unnamed_addr constant [32 x i8] c"define i64 @mensura(i64 %val) {\00", align 8
@.str.1182 = private unnamed_addr constant [33 x i8] c"  %is_null = icmp eq i64 %val, 0\00", align 8
@.str.1183 = private unnamed_addr constant [47 x i8] c"  br i1 %is_null, label %ret_zero, label %read\00", align 8
@.str.1184 = private unnamed_addr constant [10 x i8] c"ret_zero:\00", align 8
@.str.1185 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1186 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1187 = private unnamed_addr constant [35 x i8] c"  %ptr8 = inttoptr i64 %val to i8*\00", align 8
@.str.1188 = private unnamed_addr constant [29 x i8] c"  %type = load i8, i8* %ptr8\00", align 8
@.str.1189 = private unnamed_addr constant [33 x i8] c"  %is_list = icmp eq i8 %type, 3\00", align 8
@.str.1190 = private unnamed_addr constant [32 x i8] c"  %is_map = icmp eq i8 %type, 4\00", align 8
@.str.1191 = private unnamed_addr constant [36 x i8] c"  %is_col = or i1 %is_list, %is_map\00", align 8
@.str.1192 = private unnamed_addr constant [48 x i8] c"  br i1 %is_col, label %get_cnt, label %get_str\00", align 8
@.str.1193 = private unnamed_addr constant [9 x i8] c"get_cnt:\00", align 8
@.str.1194 = private unnamed_addr constant [37 x i8] c"  %ptr64 = inttoptr i64 %val to i64*\00", align 8
@.str.1195 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1196 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1197 = private unnamed_addr constant [15 x i8] c"  ret i64 %cnt\00", align 8
@.str.1198 = private unnamed_addr constant [9 x i8] c"get_str:\00", align 8
@.str.1199 = private unnamed_addr constant [38 x i8] c"  %str_ptr = inttoptr i64 %val to i8*\00", align 8
@.str.1200 = private unnamed_addr constant [40 x i8] c"  %len = call i64 @strlen(i8* %str_ptr)\00", align 8
@.str.1201 = private unnamed_addr constant [15 x i8] c"  ret i64 %len\00", align 8
@.str.1202 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1203 = private unnamed_addr constant [22 x i8] c"define i64 @capio() {\00", align 8
@.str.1204 = private unnamed_addr constant [36 x i8] c"  %mem = call i64 @malloc(i64 4096)\00", align 8
@.str.1205 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %mem to i8*\00", align 8
@.str.1206 = private unnamed_addr constant [17 x i8] c"  br label %read\00", align 8
@.str.1207 = private unnamed_addr constant [6 x i8] c"read:\00", align 8
@.str.1208 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %cont ]\00", align 8
@.str.1209 = private unnamed_addr constant [27 x i8] c"  %c = call i32 @getchar()\00", align 8
@.str.1210 = private unnamed_addr constant [31 x i8] c"  %is_eof = icmp eq i32 %c, -1\00", align 8
@.str.1211 = private unnamed_addr constant [30 x i8] c"  %is_nl = icmp eq i32 %c, 10\00", align 8
@.str.1212 = private unnamed_addr constant [32 x i8] c"  %stop = or i1 %is_eof, %is_nl\00", align 8
@.str.1213 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %cont\00", align 8
@.str.1214 = private unnamed_addr constant [6 x i8] c"cont:\00", align 8
@.str.1215 = private unnamed_addr constant [29 x i8] c"  %char = trunc i32 %c to i8\00", align 8
@.str.1216 = private unnamed_addr constant [45 x i8] c"  %slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1217 = private unnamed_addr constant [28 x i8] c"  store i8 %char, i8* %slot\00", align 8
@.str.1218 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1219 = private unnamed_addr constant [38 x i8] c"  %limit = icmp slt i64 %next_i, 4095\00", align 8
@.str.1220 = private unnamed_addr constant [41 x i8] c"  br i1 %limit, label %read, label %done\00", align 8
@.str.1221 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1222 = private unnamed_addr constant [50 x i8] c"  %term_slot = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1223 = private unnamed_addr constant [29 x i8] c"  store i8 0, i8* %term_slot\00", align 8
@.str.1224 = private unnamed_addr constant [15 x i8] c"  ret i64 %mem\00", align 8
@.str.1225 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1226 = private unnamed_addr constant [33 x i8] c"define i64 @imperium(i64 %cmd) {\00", align 8
@.str.1227 = private unnamed_addr constant [32 x i8] c"  %p = inttoptr i64 %cmd to i8*\00", align 8
@.str.1228 = private unnamed_addr constant [34 x i8] c"  %res = call i32 @system(i8* %p)\00", align 8
@.str.1229 = private unnamed_addr constant [30 x i8] c"  %ext = sext i32 %res to i64\00", align 8
@.str.1230 = private unnamed_addr constant [15 x i8] c"  ret i64 %ext\00", align 8
@.str.1231 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1232 = private unnamed_addr constant [31 x i8] c"define i64 @dormire(i64 %ms) {\00", align 8
@.str.1233 = private unnamed_addr constant [26 x i8] c"  %us = mul i64 %ms, 1000\00", align 8
@.str.1234 = private unnamed_addr constant [31 x i8] c"  %us32 = trunc i64 %us to i32\00", align 8
@.str.1235 = private unnamed_addr constant [30 x i8] c"  call i32 @usleep(i32 %us32)\00", align 8
@.str.1236 = private unnamed_addr constant [12 x i8] c"  ret i64 0\00", align 8
@.str.1237 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1238 = private unnamed_addr constant [32 x i8] c"define i64 @numerus(i64 %str) {\00", align 8
@.str.1239 = private unnamed_addr constant [34 x i8] c"  %ptr = inttoptr i64 %str to i8*\00", align 8
@.str.1240 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1241 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1242 = private unnamed_addr constant [45 x i8] c"  %i = phi i64 [ 0, %0 ], [ %next_i, %body ]\00", align 8
@.str.1243 = private unnamed_addr constant [49 x i8] c"  %acc = phi i64 [ 0, %0 ], [ %next_acc, %body ]\00", align 8
@.str.1244 = private unnamed_addr constant [49 x i8] c"  %char_ptr = getelementptr i8, i8* %ptr, i64 %i\00", align 8
@.str.1245 = private unnamed_addr constant [30 x i8] c"  %c = load i8, i8* %char_ptr\00", align 8
@.str.1246 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1247 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %body\00", align 8
@.str.1248 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1249 = private unnamed_addr constant [29 x i8] c"  %c_ext = zext i8 %c to i64\00", align 8
@.str.1250 = private unnamed_addr constant [30 x i8] c"  %digit = sub i64 %c_ext, 48\00", align 8
@.str.1251 = private unnamed_addr constant [28 x i8] c"  %mul10 = mul i64 %acc, 10\00", align 8
@.str.1252 = private unnamed_addr constant [37 x i8] c"  %next_acc = add i64 %mul10, %digit\00", align 8
@.str.1253 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1254 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1255 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1256 = private unnamed_addr constant [15 x i8] c"  ret i64 %acc\00", align 8
@.str.1257 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1258 = private unnamed_addr constant [45 x i8] c"define i64 @scindere(i64 %str, i64 %delim) {\00", align 8
@.str.1259 = private unnamed_addr constant [32 x i8] c"  %list = call i64 @_list_new()\00", align 8
@.str.1260 = private unnamed_addr constant [34 x i8] c"  %s_p = inttoptr i64 %str to i8*\00", align 8
@.str.1261 = private unnamed_addr constant [36 x i8] c"  %d_p = inttoptr i64 %delim to i8*\00", align 8
@.str.1262 = private unnamed_addr constant [36 x i8] c"  %len = call i64 @strlen(i8* %s_p)\00", align 8
@.str.1263 = private unnamed_addr constant [24 x i8] c"  %sz = add i64 %len, 1\00", align 8
@.str.1264 = private unnamed_addr constant [35 x i8] c"  %mem = call i64 @malloc(i64 %sz)\00", align 8
@.str.1265 = private unnamed_addr constant [33 x i8] c"  %cp = inttoptr i64 %mem to i8*\00", align 8
@.str.1266 = private unnamed_addr constant [38 x i8] c"  call i8* @strcpy(i8* %cp, i8* %s_p)\00", align 8
@.str.1267 = private unnamed_addr constant [45 x i8] c"  %tok = call i8* @strtok(i8* %cp, i8* %d_p)\00", align 8
@.str.1268 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1269 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1270 = private unnamed_addr constant [48 x i8] c"  %curr = phi i8* [ %tok, %0 ], [ %nxt, %body ]\00", align 8
@.str.1271 = private unnamed_addr constant [37 x i8] c"  %is_null = icmp eq i8* %curr, null\00", align 8
@.str.1272 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %body\00", align 8
@.str.1273 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1274 = private unnamed_addr constant [37 x i8] c"  %t_val = ptrtoint i8* %curr to i64\00", align 8
@.str.1275 = private unnamed_addr constant [46 x i8] c"  call i64 @_list_push(i64 %list, i64 %t_val)\00", align 8
@.str.1276 = private unnamed_addr constant [46 x i8] c"  %nxt = call i8* @strtok(i8* null, i8* %d_p)\00", align 8
@.str.1277 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1278 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1279 = private unnamed_addr constant [16 x i8] c"  ret i64 %list\00", align 8
@.str.1280 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1281 = private unnamed_addr constant [50 x i8] c"define i64 @iunctura(i64 %list_ptr, i64 %delim) {\00", align 8
@.str.1282 = private unnamed_addr constant [38 x i8] c"  %is_null = icmp eq i64 %list_ptr, 0\00", align 8
@.str.1283 = private unnamed_addr constant [49 x i8] c"  br i1 %is_null, label %ret_empty, label %check\00", align 8
@.str.1284 = private unnamed_addr constant [7 x i8] c"check:\00", align 8
@.str.1285 = private unnamed_addr constant [42 x i8] c"  %ptr64 = inttoptr i64 %list_ptr to i64*\00", align 8
@.str.1286 = private unnamed_addr constant [51 x i8] c"  %cnt_ptr = getelementptr i64, i64* %ptr64, i64 1\00", align 8
@.str.1287 = private unnamed_addr constant [33 x i8] c"  %cnt = load i64, i64* %cnt_ptr\00", align 8
@.str.1288 = private unnamed_addr constant [34 x i8] c"  %is_empty = icmp eq i64 %cnt, 0\00", align 8
@.str.1289 = private unnamed_addr constant [49 x i8] c"  br i1 %is_empty, label %ret_empty, label %calc\00", align 8
@.str.1290 = private unnamed_addr constant [11 x i8] c"ret_empty:\00", align 8
@.str.1291 = private unnamed_addr constant [33 x i8] c"  %emp = call i64 @malloc(i64 1)\00", align 8
@.str.1292 = private unnamed_addr constant [36 x i8] c"  %emp_p = inttoptr i64 %emp to i8*\00", align 8
@.str.1293 = private unnamed_addr constant [25 x i8] c"  store i8 0, i8* %emp_p\00", align 8
@.str.1294 = private unnamed_addr constant [15 x i8] c"  ret i64 %emp\00", align 8
@.str.1295 = private unnamed_addr constant [6 x i8] c"calc:\00", align 8
@.str.1296 = private unnamed_addr constant [52 x i8] c"  %data_ptr = getelementptr i64, i64* %ptr64, i64 2\00", align 8
@.str.1297 = private unnamed_addr constant [35 x i8] c"  %base = load i64, i64* %data_ptr\00", align 8
@.str.1298 = private unnamed_addr constant [41 x i8] c"  %base_ptr = inttoptr i64 %base to i64*\00", align 8
@.str.1299 = private unnamed_addr constant [35 x i8] c"  %res_0 = call i64 @malloc(i64 1)\00", align 8
@.str.1300 = private unnamed_addr constant [40 x i8] c"  %res_0_p = inttoptr i64 %res_0 to i8*\00", align 8
@.str.1301 = private unnamed_addr constant [27 x i8] c"  store i8 0, i8* %res_0_p\00", align 8
@.str.1302 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1303 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1304 = private unnamed_addr constant [49 x i8] c"  %i = phi i64 [ 0, %calc ], [ %next_i, %merge ]\00", align 8
@.str.1305 = private unnamed_addr constant [63 x i8] c"  %curr_str = phi i64 [ %res_0, %calc ], [ %next_str, %merge ]\00", align 8
@.str.1306 = private unnamed_addr constant [32 x i8] c"  %cond = icmp slt i64 %i, %cnt\00", align 8
@.str.1307 = private unnamed_addr constant [40 x i8] c"  br i1 %cond, label %body, label %done\00", align 8
@.str.1308 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1309 = private unnamed_addr constant [52 x i8] c"  %slot = getelementptr i64, i64* %base_ptr, i64 %i\00", align 8
@.str.1310 = private unnamed_addr constant [31 x i8] c"  %item = load i64, i64* %slot\00", align 8
@.str.1311 = private unnamed_addr constant [43 x i8] c"  %item_s = call i64 @to_string(i64 %item)\00", align 8
@.str.1312 = private unnamed_addr constant [58 x i8] c"  %added = call i64 @_str_cat(i64 %curr_str, i64 %item_s)\00", align 8
@.str.1313 = private unnamed_addr constant [30 x i8] c"  %last_idx = sub i64 %cnt, 1\00", align 8
@.str.1314 = private unnamed_addr constant [39 x i8] c"  %is_last = icmp eq i64 %i, %last_idx\00", align 8
@.str.1315 = private unnamed_addr constant [54 x i8] c"  br i1 %is_last, label %skip_delim, label %add_delim\00", align 8
@.str.1316 = private unnamed_addr constant [11 x i8] c"add_delim:\00", align 8
@.str.1317 = private unnamed_addr constant [59 x i8] c"  %with_delim = call i64 @_str_cat(i64 %added, i64 %delim)\00", align 8
@.str.1318 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1319 = private unnamed_addr constant [12 x i8] c"skip_delim:\00", align 8
@.str.1320 = private unnamed_addr constant [18 x i8] c"  br label %merge\00", align 8
@.str.1321 = private unnamed_addr constant [7 x i8] c"merge:\00", align 8
@.str.1322 = private unnamed_addr constant [75 x i8] c"  %next_str = phi i64 [ %with_delim, %add_delim ], [ %added, %skip_delim ]\00", align 8
@.str.1323 = private unnamed_addr constant [26 x i8] c"  %next_i = add i64 %i, 1\00", align 8
@.str.1324 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1325 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1326 = private unnamed_addr constant [20 x i8] c"  ret i64 %curr_str\00", align 8
@.str.1327 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1328 = private unnamed_addr constant [90 x i8] c"define i64 @syscall6(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) {\00", align 8
@.str.1329 = private unnamed_addr constant [184 x i8] c"  %res = call i64 asm sideeffect \22syscall\22, \22={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11},~{memory}\22(i64 %sys_no, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6)\00", align 8
@.str.1330 = private unnamed_addr constant [15 x i8] c"  ret i64 %res\00", align 8
@.str.1331 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1332 = private unnamed_addr constant [31 x i8] c"define i64 @strlen(i8* %str) {\00", align 8
@.str.1333 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1334 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1335 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1336 = private unnamed_addr constant [44 x i8] c"  %ptr = getelementptr i8, i8* %str, i64 %i\00", align 8
@.str.1337 = private unnamed_addr constant [25 x i8] c"  %c = load i8, i8* %ptr\00", align 8
@.str.1338 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1339 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1340 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1341 = private unnamed_addr constant [17 x i8] c"done: ret i64 %i\00", align 8
@.str.1342 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1343 = private unnamed_addr constant [39 x i8] c"define i32 @strcmp(i8* %s1, i8* %s2) {\00", align 8
@.str.1344 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1345 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1346 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1347 = private unnamed_addr constant [42 x i8] c"  %p1 = getelementptr i8, i8* %s1, i64 %i\00", align 8
@.str.1348 = private unnamed_addr constant [42 x i8] c"  %p2 = getelementptr i8, i8* %s2, i64 %i\00", align 8
@.str.1349 = private unnamed_addr constant [25 x i8] c"  %c1 = load i8, i8* %p1\00", align 8
@.str.1350 = private unnamed_addr constant [25 x i8] c"  %c2 = load i8, i8* %p2\00", align 8
@.str.1351 = private unnamed_addr constant [32 x i8] c"  %not_eq = icmp ne i8 %c1, %c2\00", align 8
@.str.1352 = private unnamed_addr constant [31 x i8] c"  %is_null = icmp eq i8 %c1, 0\00", align 8
@.str.1353 = private unnamed_addr constant [34 x i8] c"  %stop = or i1 %not_eq, %is_null\00", align 8
@.str.1354 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1355 = private unnamed_addr constant [40 x i8] c"  br i1 %stop, label %done, label %loop\00", align 8
@.str.1356 = private unnamed_addr constant [6 x i8] c"done:\00", align 8
@.str.1357 = private unnamed_addr constant [27 x i8] c"  %z1 = zext i8 %c1 to i32\00", align 8
@.str.1358 = private unnamed_addr constant [27 x i8] c"  %z2 = zext i8 %c2 to i32\00", align 8
@.str.1359 = private unnamed_addr constant [27 x i8] c"  %diff = sub i32 %z1, %z2\00", align 8
@.str.1360 = private unnamed_addr constant [16 x i8] c"  ret i32 %diff\00", align 8
@.str.1361 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1362 = private unnamed_addr constant [42 x i8] c"define i8* @strcpy(i8* %dest, i8* %src) {\00", align 8
@.str.1363 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1364 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1365 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %loop ]\00", align 8
@.str.1366 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1367 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1368 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1369 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1370 = private unnamed_addr constant [30 x i8] c"  %is_null = icmp eq i8 %c, 0\00", align 8
@.str.1371 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1372 = private unnamed_addr constant [43 x i8] c"  br i1 %is_null, label %done, label %loop\00", align 8
@.str.1373 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1374 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1375 = private unnamed_addr constant [51 x i8] c"define i8* @strncpy(i8* %dest, i8* %src, i64 %n) {\00", align 8
@.str.1376 = private unnamed_addr constant [22 x i8] c"entry: br label %loop\00", align 8
@.str.1377 = private unnamed_addr constant [6 x i8] c"loop:\00", align 8
@.str.1378 = private unnamed_addr constant [46 x i8] c"  %i = phi i64 [ 0, %entry ], [ %nxt, %body ]\00", align 8
@.str.1379 = private unnamed_addr constant [29 x i8] c"  %cmp = icmp slt i64 %i, %n\00", align 8
@.str.1380 = private unnamed_addr constant [39 x i8] c"  br i1 %cmp, label %body, label %done\00", align 8
@.str.1381 = private unnamed_addr constant [6 x i8] c"body:\00", align 8
@.str.1382 = private unnamed_addr constant [43 x i8] c"  %ps = getelementptr i8, i8* %src, i64 %i\00", align 8
@.str.1383 = private unnamed_addr constant [44 x i8] c"  %pd = getelementptr i8, i8* %dest, i64 %i\00", align 8
@.str.1384 = private unnamed_addr constant [24 x i8] c"  %c = load i8, i8* %ps\00", align 8
@.str.1385 = private unnamed_addr constant [23 x i8] c"  store i8 %c, i8* %pd\00", align 8
@.str.1386 = private unnamed_addr constant [23 x i8] c"  %nxt = add i64 %i, 1\00", align 8
@.str.1387 = private unnamed_addr constant [17 x i8] c"  br label %loop\00", align 8
@.str.1388 = private unnamed_addr constant [20 x i8] c"done: ret i8* %dest\00", align 8
@.str.1389 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1390 = private unnamed_addr constant [42 x i8] c"define i8* @strcat(i8* %dest, i8* %src) {\00", align 8
@.str.1391 = private unnamed_addr constant [37 x i8] c"  %len = call i64 @strlen(i8* %dest)\00", align 8
@.str.1392 = private unnamed_addr constant [49 x i8] c"  %d_end = getelementptr i8, i8* %dest, i64 %len\00", align 8
@.str.1393 = private unnamed_addr constant [41 x i8] c"  call i8* @strcpy(i8* %d_end, i8* %src)\00", align 8
@.str.1394 = private unnamed_addr constant [16 x i8] c"  ret i8* %dest\00", align 8
@.str.1395 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1396 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1397 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1398 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1399 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1400 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1401 = private unnamed_addr constant [41 x i8] c"💀 FATAL LINKER ERROR: Could not read \00", align 8
@.str.1402 = private unnamed_addr constant [61 x i8] c"⚔️  ACHLYS -> LLVM COMPILER (STAGE 1.8.4 - FREESTANDING)\00", align 8
@.str.1403 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1404 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1405 = private unnamed_addr constant [15 x i8] c"--freestanding\00", align 8
@.str.1406 = private unnamed_addr constant [8 x i8] c"--arm64\00", align 8
@.str.1407 = private unnamed_addr constant [52 x i8] c"Usage: ./mate <file.nox> [--freestanding] [--arm64]\00", align 8
@.str.1408 = private unnamed_addr constant [25 x i8] c"⚠️  File not found: \00", align 8
@.str.1409 = private unnamed_addr constant [16 x i8] c"[1/3] Lexing...\00", align 8
@.str.1410 = private unnamed_addr constant [19 x i8] c"[DEBUG] Main sees \00", align 8
@.str.1411 = private unnamed_addr constant [9 x i8] c" tokens.\00", align 8
@.str.1412 = private unnamed_addr constant [4 x i8] c" T[\00", align 8
@.str.1413 = private unnamed_addr constant [4 x i8] c"]: \00", align 8
@.str.1414 = private unnamed_addr constant [5 x i8] c"text\00", align 8
@.str.1415 = private unnamed_addr constant [3 x i8] c" (\00", align 8
@.str.1416 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1417 = private unnamed_addr constant [2 x i8] c")\00", align 8
@.str.1418 = private unnamed_addr constant [17 x i8] c"[2/3] Parsing...\00", align 8
@.str.1419 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1420 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1421 = private unnamed_addr constant [24 x i8] c"❌ Compilation Failed.\00", align 8
@.str.1422 = private unnamed_addr constant [28 x i8] c"[3/3] Generating LLVM IR...\00", align 8
@.str.1423 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.sc.1424 = global i64 0
@.str.1425 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1426 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1427 = private unnamed_addr constant [2 x i8] c"@\00", align 8
@.str.1428 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1429 = private unnamed_addr constant [16 x i8] c" = global i64 0\00", align 8
@.str.1430 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1431 = private unnamed_addr constant [5 x i8] c"type\00", align 8
@.str.1432 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1433 = private unnamed_addr constant [5 x i8] c"name\00", align 8
@.str.1434 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1435 = private unnamed_addr constant [4 x i8] c"val\00", align 8
@.str.1436 = private unnamed_addr constant [42 x i8] c"define i32 @main(i32 %argc, i8** %argv) {\00", align 8
@.str.1437 = private unnamed_addr constant [36 x i8] c"  store i32 %argc, i32* @__sys_argc\00", align 8
@.str.1438 = private unnamed_addr constant [38 x i8] c"  store i8** %argv, i8*** @__sys_argv\00", align 8
@.str.1439 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1440 = private unnamed_addr constant [55 x i8] c"  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* \00", align 8
@.str.1441 = private unnamed_addr constant [15 x i8] c", i64 0, i64 0\00", align 8
@.str.1442 = private unnamed_addr constant [52 x i8] c"  %boot_msg_int = ptrtoint i8* %boot_msg_ptr to i64\00", align 8
@.str.1443 = private unnamed_addr constant [41 x i8] c"  call i64 @print_any(i64 %boot_msg_int)\00", align 8
@.str.1444 = private unnamed_addr constant [30 x i8] c"define void @_achlys_init() {\00", align 8
@.str.1445 = private unnamed_addr constant [31 x i8] c"[DEBUG] Top Level Statements: \00", align 8
@.str.1446 = private unnamed_addr constant [10 x i8] c"ret i32 0\00", align 8
@.str.1447 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1448 = private unnamed_addr constant [36 x i8] c"  %os_res = call i64 @achlys_main()\00", align 8
@.str.1449 = private unnamed_addr constant [11 x i8] c"  ret void\00", align 8
@.str.1450 = private unnamed_addr constant [2 x i8] c"}\00", align 8
@.str.1451 = private unnamed_addr constant [10 x i8] c"Achlys.ll\00", align 8
@.str.1452 = private unnamed_addr constant [36 x i8] c"✅ SUCCESS. 'Achlys.ll' generated.\00", align 8
@.str.1453 = private unnamed_addr constant [16 x i8] c">> EXECUTING <<\00", align 8
@.str.1454 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1455 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1456 = private unnamed_addr constant [1 x i8] c"\00", align 8
@.str.1457 = private unnamed_addr constant [1 x i8] c"\00", align 8
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
  %r25 = or i64 %r22, %r24
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
  %r37 = or i64 %r34, %r36
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
  %r49 = or i64 %r46, %r48
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
  %r85 = getelementptr [2 x i8], [2 x i8]* @.str.27, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = call i64 @_eq(i64 %r84, i64 %r86)
  store i64 0, i64* @.sc.26
  %r89 = icmp ne i64 %r87, 0
  br i1 %r89, label %L130, label %L131
L130:
  %r90 = load i64, i64* %ptr_src
  %r91 = load i64, i64* %ptr_i
  %r92 = call i64 @_add(i64 %r91, i64 1)
  %r93 = call i64 @pars(i64 %r90, i64 %r92, i64 1)
  %r94 = getelementptr [2 x i8], [2 x i8]* @.str.28, i64 0, i64 0
  %r95 = ptrtoint i8* %r94 to i64
  %r96 = call i64 @_eq(i64 %r93, i64 %r95)
  %r97 = icmp ne i64 %r96, 0
  %r98 = zext i1 %r97 to i64
  store i64 %r98, i64* @.sc.26
  br label %L131
L131:
  %r88 = load i64, i64* @.sc.26
  %r99 = icmp ne i64 %r88, 0
  br i1 %r99, label %L132, label %L134
L132:
  %r100 = load i64, i64* %ptr_i
  %r101 = call i64 @_add(i64 %r100, i64 2)
  store i64 %r101, i64* %ptr_i
  store i64 0, i64* %ptr_run_blk
  br label %L134
L134:
  %r102 = load i64, i64* %ptr_run_blk
  %r103 = icmp ne i64 %r102, 0
  br i1 %r103, label %L135, label %L137
L135:
  %r104 = load i64, i64* %ptr_i
  %r105 = call i64 @_add(i64 %r104, i64 1)
  store i64 %r105, i64* %ptr_i
  br label %L137
L137:
  br label %L129
L129:
  br label %L121
L123:
  br label %L120
L119:
  %r106 = load i64, i64* @TOK_OP
  %r107 = getelementptr [2 x i8], [2 x i8]* @.str.29, i64 0, i64 0
  %r108 = ptrtoint i8* %r107 to i64
  %r109 = call i64 @make_token(i64 %r106, i64 %r108)
  %r110 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r110, i64 %r109)
  %r111 = load i64, i64* %ptr_i
  %r112 = call i64 @_add(i64 %r111, i64 1)
  store i64 %r112, i64* %ptr_i
  br label %L120
L120:
  br label %L102
L102:
  br label %L99
L98:
  %r113 = load i64, i64* %ptr_c
  %r114 = getelementptr [2 x i8], [2 x i8]* @.str.30, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_eq(i64 %r113, i64 %r115)
  %r117 = icmp ne i64 %r116, 0
  br i1 %r117, label %L138, label %L139
L138:
  %r118 = load i64, i64* %ptr_i
  %r119 = call i64 @_add(i64 %r118, i64 1)
  store i64 %r119, i64* %ptr_i
  %r120 = getelementptr [1 x i8], [1 x i8]* @.str.31, i64 0, i64 0
  %r121 = ptrtoint i8* %r120 to i64
  store i64 %r121, i64* %ptr_txt
  store i64 1, i64* %ptr_run_str
  br label %L141
L141:
  %r122 = load i64, i64* %ptr_run_str
  %r123 = icmp ne i64 %r122, 0
  br i1 %r123, label %L142, label %L143
L142:
  %r124 = load i64, i64* %ptr_i
  %r125 = load i64, i64* %ptr_len
  %r127 = icmp sge i64 %r124, %r125
  %r126 = zext i1 %r127 to i64
  %r128 = icmp ne i64 %r126, 0
  br i1 %r128, label %L144, label %L146
L144:
  store i64 0, i64* %ptr_run_str
  br label %L146
L146:
  %r129 = load i64, i64* %ptr_run_str
  %r130 = icmp ne i64 %r129, 0
  br i1 %r130, label %L147, label %L149
L147:
  %r131 = load i64, i64* %ptr_src
  %r132 = load i64, i64* %ptr_i
  %r133 = call i64 @pars(i64 %r131, i64 %r132, i64 1)
  store i64 %r133, i64* %ptr_loop_c
  %r134 = load i64, i64* %ptr_loop_c
  %r135 = getelementptr [2 x i8], [2 x i8]* @.str.32, i64 0, i64 0
  %r136 = ptrtoint i8* %r135 to i64
  %r137 = call i64 @_eq(i64 %r134, i64 %r136)
  %r138 = icmp ne i64 %r137, 0
  br i1 %r138, label %L150, label %L152
L150:
  store i64 0, i64* %ptr_run_str
  br label %L152
L152:
  %r139 = load i64, i64* %ptr_run_str
  %r140 = icmp ne i64 %r139, 0
  br i1 %r140, label %L153, label %L155
L153:
  %r141 = load i64, i64* %ptr_loop_c
  %r142 = getelementptr [2 x i8], [2 x i8]* @.str.33, i64 0, i64 0
  %r143 = ptrtoint i8* %r142 to i64
  %r144 = call i64 @_eq(i64 %r141, i64 %r143)
  %r145 = icmp ne i64 %r144, 0
  br i1 %r145, label %L156, label %L157
L156:
  %r146 = load i64, i64* %ptr_i
  %r147 = call i64 @_add(i64 %r146, i64 1)
  store i64 %r147, i64* %ptr_i
  %r148 = load i64, i64* %ptr_src
  %r149 = load i64, i64* %ptr_i
  %r150 = call i64 @pars(i64 %r148, i64 %r149, i64 1)
  store i64 %r150, i64* %ptr_esc
  %r151 = load i64, i64* %ptr_esc
  %r152 = getelementptr [2 x i8], [2 x i8]* @.str.34, i64 0, i64 0
  %r153 = ptrtoint i8* %r152 to i64
  %r154 = call i64 @_eq(i64 %r151, i64 %r153)
  %r155 = icmp ne i64 %r154, 0
  br i1 %r155, label %L159, label %L160
L159:
  %r156 = load i64, i64* %ptr_txt
  %r157 = call i64 @signum_ex(i64 10)
  %r158 = call i64 @_add(i64 %r156, i64 %r157)
  store i64 %r158, i64* %ptr_txt
  br label %L161
L160:
  %r159 = load i64, i64* %ptr_esc
  %r160 = getelementptr [2 x i8], [2 x i8]* @.str.35, i64 0, i64 0
  %r161 = ptrtoint i8* %r160 to i64
  %r162 = call i64 @_eq(i64 %r159, i64 %r161)
  %r163 = icmp ne i64 %r162, 0
  br i1 %r163, label %L162, label %L163
L162:
  %r164 = load i64, i64* %ptr_txt
  %r165 = call i64 @signum_ex(i64 9)
  %r166 = call i64 @_add(i64 %r164, i64 %r165)
  store i64 %r166, i64* %ptr_txt
  br label %L164
L163:
  %r167 = load i64, i64* %ptr_esc
  %r168 = getelementptr [2 x i8], [2 x i8]* @.str.36, i64 0, i64 0
  %r169 = ptrtoint i8* %r168 to i64
  %r170 = call i64 @_eq(i64 %r167, i64 %r169)
  %r171 = icmp ne i64 %r170, 0
  br i1 %r171, label %L165, label %L166
L165:
  %r172 = load i64, i64* %ptr_txt
  %r173 = getelementptr [2 x i8], [2 x i8]* @.str.37, i64 0, i64 0
  %r174 = ptrtoint i8* %r173 to i64
  %r175 = call i64 @_add(i64 %r172, i64 %r174)
  store i64 %r175, i64* %ptr_txt
  br label %L167
L166:
  %r176 = load i64, i64* %ptr_esc
  %r177 = getelementptr [2 x i8], [2 x i8]* @.str.38, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = call i64 @_eq(i64 %r176, i64 %r178)
  %r180 = icmp ne i64 %r179, 0
  br i1 %r180, label %L168, label %L169
L168:
  %r181 = load i64, i64* %ptr_txt
  %r182 = getelementptr [2 x i8], [2 x i8]* @.str.39, i64 0, i64 0
  %r183 = ptrtoint i8* %r182 to i64
  %r184 = call i64 @_add(i64 %r181, i64 %r183)
  store i64 %r184, i64* %ptr_txt
  br label %L170
L169:
  %r185 = load i64, i64* %ptr_txt
  %r186 = load i64, i64* %ptr_esc
  %r187 = call i64 @_add(i64 %r185, i64 %r186)
  store i64 %r187, i64* %ptr_txt
  br label %L170
L170:
  br label %L167
L167:
  br label %L164
L164:
  br label %L161
L161:
  br label %L158
L157:
  %r188 = load i64, i64* %ptr_txt
  %r189 = load i64, i64* %ptr_loop_c
  %r190 = call i64 @_add(i64 %r188, i64 %r189)
  store i64 %r190, i64* %ptr_txt
  br label %L158
L158:
  %r191 = load i64, i64* %ptr_i
  %r192 = call i64 @_add(i64 %r191, i64 1)
  store i64 %r192, i64* %ptr_i
  br label %L155
L155:
  br label %L149
L149:
  br label %L141
L143:
  %r193 = load i64, i64* @TOK_STRING
  %r194 = load i64, i64* %ptr_txt
  %r195 = call i64 @make_token(i64 %r193, i64 %r194)
  %r196 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r196, i64 %r195)
  %r197 = load i64, i64* %ptr_i
  %r198 = call i64 @_add(i64 %r197, i64 1)
  store i64 %r198, i64* %ptr_i
  br label %L140
L139:
  %r199 = load i64, i64* %ptr_c
  %r200 = call i64 @is_digit(i64 %r199)
  %r201 = icmp ne i64 %r200, 0
  br i1 %r201, label %L171, label %L172
L171:
  %r202 = load i64, i64* %ptr_i
  store i64 %r202, i64* %ptr_start
  store i64 0, i64* %ptr_is_hex
  %r203 = load i64, i64* %ptr_c
  %r204 = getelementptr [2 x i8], [2 x i8]* @.str.40, i64 0, i64 0
  %r205 = ptrtoint i8* %r204 to i64
  %r206 = call i64 @_eq(i64 %r203, i64 %r205)
  %r207 = icmp ne i64 %r206, 0
  br i1 %r207, label %L174, label %L176
L174:
  %r208 = load i64, i64* %ptr_src
  %r209 = load i64, i64* %ptr_i
  %r210 = call i64 @_add(i64 %r209, i64 1)
  %r211 = call i64 @pars(i64 %r208, i64 %r210, i64 1)
  store i64 %r211, i64* %ptr_next_char
  %r212 = load i64, i64* %ptr_next_char
  %r213 = getelementptr [2 x i8], [2 x i8]* @.str.41, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  %r215 = call i64 @_eq(i64 %r212, i64 %r214)
  %r216 = icmp ne i64 %r215, 0
  br i1 %r216, label %L177, label %L179
L177:
  store i64 1, i64* %ptr_is_hex
  br label %L179
L179:
  %r217 = load i64, i64* %ptr_next_char
  %r218 = getelementptr [2 x i8], [2 x i8]* @.str.42, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @_eq(i64 %r217, i64 %r219)
  %r221 = icmp ne i64 %r220, 0
  br i1 %r221, label %L180, label %L182
L180:
  store i64 1, i64* %ptr_is_hex
  br label %L182
L182:
  br label %L176
L176:
  %r222 = load i64, i64* %ptr_is_hex
  %r223 = icmp ne i64 %r222, 0
  br i1 %r223, label %L183, label %L184
L183:
  %r224 = load i64, i64* %ptr_i
  %r225 = call i64 @_add(i64 %r224, i64 2)
  store i64 %r225, i64* %ptr_i
  %r226 = load i64, i64* %ptr_i
  store i64 %r226, i64* %ptr_start
  store i64 1, i64* %ptr_run_hex
  br label %L186
L186:
  %r227 = load i64, i64* %ptr_run_hex
  %r228 = icmp ne i64 %r227, 0
  br i1 %r228, label %L187, label %L188
L187:
  %r229 = load i64, i64* %ptr_i
  %r230 = load i64, i64* %ptr_len
  %r232 = icmp sge i64 %r229, %r230
  %r231 = zext i1 %r232 to i64
  %r233 = icmp ne i64 %r231, 0
  br i1 %r233, label %L189, label %L191
L189:
  store i64 0, i64* %ptr_run_hex
  br label %L191
L191:
  %r234 = load i64, i64* %ptr_run_hex
  %r235 = icmp ne i64 %r234, 0
  br i1 %r235, label %L192, label %L194
L192:
  %r236 = load i64, i64* %ptr_src
  %r237 = load i64, i64* %ptr_i
  %r238 = call i64 @pars(i64 %r236, i64 %r237, i64 1)
  store i64 %r238, i64* %ptr_loop_c
  %r239 = load i64, i64* %ptr_loop_c
  %r240 = call i64 @is_alnum(i64 %r239)
  %r241 = call i64 @_eq(i64 %r240, i64 0)
  %r242 = icmp ne i64 %r241, 0
  br i1 %r242, label %L195, label %L197
L195:
  store i64 0, i64* %ptr_run_hex
  br label %L197
L197:
  %r243 = load i64, i64* %ptr_run_hex
  %r244 = icmp ne i64 %r243, 0
  br i1 %r244, label %L198, label %L200
L198:
  %r245 = load i64, i64* %ptr_i
  %r246 = call i64 @_add(i64 %r245, i64 1)
  store i64 %r246, i64* %ptr_i
  br label %L200
L200:
  br label %L194
L194:
  br label %L186
L188:
  %r247 = load i64, i64* %ptr_src
  %r248 = load i64, i64* %ptr_start
  %r249 = load i64, i64* %ptr_i
  %r250 = load i64, i64* %ptr_start
  %r251 = sub i64 %r249, %r250
  %r252 = call i64 @pars(i64 %r247, i64 %r248, i64 %r251)
  store i64 %r252, i64* %ptr_hex_str
  %r253 = load i64, i64* @TOK_INT
  %r254 = load i64, i64* %ptr_hex_str
  %r255 = call i64 @hex_to_dec(i64 %r254)
  %r256 = call i64 @int_to_str(i64 %r255)
  %r257 = call i64 @make_token(i64 %r253, i64 %r256)
  %r258 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r258, i64 %r257)
  br label %L185
L184:
  store i64 1, i64* %ptr_run_num
  br label %L201
L201:
  %r259 = load i64, i64* %ptr_run_num
  %r260 = icmp ne i64 %r259, 0
  br i1 %r260, label %L202, label %L203
L202:
  %r261 = load i64, i64* %ptr_i
  %r262 = load i64, i64* %ptr_len
  %r264 = icmp sge i64 %r261, %r262
  %r263 = zext i1 %r264 to i64
  %r265 = icmp ne i64 %r263, 0
  br i1 %r265, label %L204, label %L206
L204:
  store i64 0, i64* %ptr_run_num
  br label %L206
L206:
  %r266 = load i64, i64* %ptr_run_num
  %r267 = icmp ne i64 %r266, 0
  br i1 %r267, label %L207, label %L209
L207:
  %r268 = load i64, i64* %ptr_src
  %r269 = load i64, i64* %ptr_i
  %r270 = call i64 @pars(i64 %r268, i64 %r269, i64 1)
  store i64 %r270, i64* %ptr_loop_c
  store i64 0, i64* %ptr_keep
  %r271 = load i64, i64* %ptr_loop_c
  %r272 = call i64 @is_digit(i64 %r271)
  %r273 = icmp ne i64 %r272, 0
  br i1 %r273, label %L210, label %L212
L210:
  store i64 1, i64* %ptr_keep
  br label %L212
L212:
  %r274 = load i64, i64* %ptr_loop_c
  %r275 = getelementptr [2 x i8], [2 x i8]* @.str.43, i64 0, i64 0
  %r276 = ptrtoint i8* %r275 to i64
  %r277 = call i64 @_eq(i64 %r274, i64 %r276)
  %r278 = icmp ne i64 %r277, 0
  br i1 %r278, label %L213, label %L215
L213:
  store i64 1, i64* %ptr_keep
  br label %L215
L215:
  %r279 = load i64, i64* %ptr_keep
  %r280 = call i64 @_eq(i64 %r279, i64 0)
  %r281 = icmp ne i64 %r280, 0
  br i1 %r281, label %L216, label %L218
L216:
  store i64 0, i64* %ptr_run_num
  br label %L218
L218:
  %r282 = load i64, i64* %ptr_run_num
  %r283 = icmp ne i64 %r282, 0
  br i1 %r283, label %L219, label %L221
L219:
  %r284 = load i64, i64* %ptr_i
  %r285 = call i64 @_add(i64 %r284, i64 1)
  store i64 %r285, i64* %ptr_i
  br label %L221
L221:
  br label %L209
L209:
  br label %L201
L203:
  %r286 = load i64, i64* %ptr_src
  %r287 = load i64, i64* %ptr_start
  %r288 = load i64, i64* %ptr_i
  %r289 = load i64, i64* %ptr_start
  %r290 = sub i64 %r288, %r289
  %r291 = call i64 @pars(i64 %r286, i64 %r287, i64 %r290)
  store i64 %r291, i64* %ptr_txt
  %r292 = load i64, i64* @TOK_INT
  %r293 = load i64, i64* %ptr_txt
  %r294 = call i64 @make_token(i64 %r292, i64 %r293)
  %r295 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r295, i64 %r294)
  br label %L185
L185:
  br label %L173
L172:
  %r296 = load i64, i64* %ptr_c
  %r297 = call i64 @is_alpha(i64 %r296)
  %r298 = icmp ne i64 %r297, 0
  br i1 %r298, label %L222, label %L223
L222:
  %r299 = load i64, i64* %ptr_i
  store i64 %r299, i64* %ptr_start
  store i64 1, i64* %ptr_run_id
  br label %L225
L225:
  %r300 = load i64, i64* %ptr_run_id
  %r301 = icmp ne i64 %r300, 0
  br i1 %r301, label %L226, label %L227
L226:
  %r302 = load i64, i64* %ptr_i
  %r303 = load i64, i64* %ptr_len
  %r305 = icmp sge i64 %r302, %r303
  %r304 = zext i1 %r305 to i64
  %r306 = icmp ne i64 %r304, 0
  br i1 %r306, label %L228, label %L230
L228:
  store i64 0, i64* %ptr_run_id
  br label %L230
L230:
  %r307 = load i64, i64* %ptr_run_id
  %r308 = icmp ne i64 %r307, 0
  br i1 %r308, label %L231, label %L233
L231:
  %r309 = load i64, i64* %ptr_src
  %r310 = load i64, i64* %ptr_i
  %r311 = call i64 @pars(i64 %r309, i64 %r310, i64 1)
  store i64 %r311, i64* %ptr_loop_c
  %r312 = load i64, i64* %ptr_loop_c
  %r313 = call i64 @codex(i64 %r312)
  store i64 %r313, i64* %ptr_lcode
  store i64 0, i64* %ptr_ok
  %r314 = load i64, i64* %ptr_lcode
  %r316 = icmp sge i64 %r314, 48
  %r315 = zext i1 %r316 to i64
  %r317 = icmp ne i64 %r315, 0
  br i1 %r317, label %L234, label %L236
L234:
  %r318 = load i64, i64* %ptr_lcode
  %r320 = icmp sle i64 %r318, 57
  %r319 = zext i1 %r320 to i64
  %r321 = icmp ne i64 %r319, 0
  br i1 %r321, label %L237, label %L239
L237:
  store i64 1, i64* %ptr_ok
  br label %L239
L239:
  br label %L236
L236:
  %r322 = load i64, i64* %ptr_lcode
  %r324 = icmp sge i64 %r322, 65
  %r323 = zext i1 %r324 to i64
  %r325 = icmp ne i64 %r323, 0
  br i1 %r325, label %L240, label %L242
L240:
  %r326 = load i64, i64* %ptr_lcode
  %r328 = icmp sle i64 %r326, 90
  %r327 = zext i1 %r328 to i64
  %r329 = icmp ne i64 %r327, 0
  br i1 %r329, label %L243, label %L245
L243:
  store i64 1, i64* %ptr_ok
  br label %L245
L245:
  br label %L242
L242:
  %r330 = load i64, i64* %ptr_lcode
  %r332 = icmp sge i64 %r330, 97
  %r331 = zext i1 %r332 to i64
  %r333 = icmp ne i64 %r331, 0
  br i1 %r333, label %L246, label %L248
L246:
  %r334 = load i64, i64* %ptr_lcode
  %r336 = icmp sle i64 %r334, 122
  %r335 = zext i1 %r336 to i64
  %r337 = icmp ne i64 %r335, 0
  br i1 %r337, label %L249, label %L251
L249:
  store i64 1, i64* %ptr_ok
  br label %L251
L251:
  br label %L248
L248:
  %r338 = load i64, i64* %ptr_lcode
  %r339 = call i64 @_eq(i64 %r338, i64 95)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L252, label %L254
L252:
  store i64 1, i64* %ptr_ok
  br label %L254
L254:
  %r341 = load i64, i64* %ptr_ok
  %r342 = call i64 @_eq(i64 %r341, i64 0)
  %r343 = icmp ne i64 %r342, 0
  br i1 %r343, label %L255, label %L257
L255:
  store i64 0, i64* %ptr_run_id
  br label %L257
L257:
  %r344 = load i64, i64* %ptr_run_id
  %r345 = icmp ne i64 %r344, 0
  br i1 %r345, label %L258, label %L260
L258:
  %r346 = load i64, i64* %ptr_i
  %r347 = call i64 @_add(i64 %r346, i64 1)
  store i64 %r347, i64* %ptr_i
  br label %L260
L260:
  br label %L233
L233:
  br label %L225
L227:
  %r348 = load i64, i64* %ptr_src
  %r349 = load i64, i64* %ptr_start
  %r350 = load i64, i64* %ptr_i
  %r351 = load i64, i64* %ptr_start
  %r352 = sub i64 %r350, %r351
  %r353 = call i64 @pars(i64 %r348, i64 %r349, i64 %r352)
  store i64 %r353, i64* %ptr_txt
  store i64 4, i64* %ptr_type
  %r354 = load i64, i64* %ptr_txt
  %r355 = getelementptr [4 x i8], [4 x i8]* @.str.44, i64 0, i64 0
  %r356 = ptrtoint i8* %r355 to i64
  %r357 = call i64 @_eq(i64 %r354, i64 %r356)
  %r358 = icmp ne i64 %r357, 0
  br i1 %r358, label %L261, label %L263
L261:
  store i64 5, i64* %ptr_type
  br label %L263
L263:
  %r359 = load i64, i64* %ptr_txt
  %r360 = getelementptr [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %r361 = ptrtoint i8* %r360 to i64
  %r362 = call i64 @_eq(i64 %r359, i64 %r361)
  %r363 = icmp ne i64 %r362, 0
  br i1 %r363, label %L264, label %L266
L264:
  store i64 5, i64* %ptr_type
  br label %L266
L266:
  %r364 = load i64, i64* %ptr_txt
  %r365 = getelementptr [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %r366 = ptrtoint i8* %r365 to i64
  %r367 = call i64 @_eq(i64 %r364, i64 %r366)
  %r368 = icmp ne i64 %r367, 0
  br i1 %r368, label %L267, label %L269
L267:
  store i64 5, i64* %ptr_type
  br label %L269
L269:
  %r369 = load i64, i64* %ptr_txt
  %r370 = getelementptr [7 x i8], [7 x i8]* @.str.47, i64 0, i64 0
  %r371 = ptrtoint i8* %r370 to i64
  %r372 = call i64 @_eq(i64 %r369, i64 %r371)
  %r373 = icmp ne i64 %r372, 0
  br i1 %r373, label %L270, label %L272
L270:
  store i64 6, i64* %ptr_type
  br label %L272
L272:
  %r374 = load i64, i64* %ptr_txt
  %r375 = getelementptr [8 x i8], [8 x i8]* @.str.48, i64 0, i64 0
  %r376 = ptrtoint i8* %r375 to i64
  %r377 = call i64 @_eq(i64 %r374, i64 %r376)
  %r378 = icmp ne i64 %r377, 0
  br i1 %r378, label %L273, label %L275
L273:
  store i64 6, i64* %ptr_type
  br label %L275
L275:
  %r379 = load i64, i64* %ptr_txt
  %r380 = getelementptr [10 x i8], [10 x i8]* @.str.49, i64 0, i64 0
  %r381 = ptrtoint i8* %r380 to i64
  %r382 = call i64 @_eq(i64 %r379, i64 %r381)
  %r383 = icmp ne i64 %r382, 0
  br i1 %r383, label %L276, label %L278
L276:
  store i64 6, i64* %ptr_type
  br label %L278
L278:
  %r384 = load i64, i64* %ptr_txt
  %r385 = getelementptr [3 x i8], [3 x i8]* @.str.50, i64 0, i64 0
  %r386 = ptrtoint i8* %r385 to i64
  %r387 = call i64 @_eq(i64 %r384, i64 %r386)
  %r388 = icmp ne i64 %r387, 0
  br i1 %r388, label %L279, label %L281
L279:
  store i64 7, i64* %ptr_type
  br label %L281
L281:
  %r389 = load i64, i64* %ptr_txt
  %r390 = getelementptr [7 x i8], [7 x i8]* @.str.51, i64 0, i64 0
  %r391 = ptrtoint i8* %r390 to i64
  %r392 = call i64 @_eq(i64 %r389, i64 %r391)
  %r393 = icmp ne i64 %r392, 0
  br i1 %r393, label %L282, label %L284
L282:
  store i64 8, i64* %ptr_type
  br label %L284
L284:
  %r394 = load i64, i64* %ptr_txt
  %r395 = getelementptr [4 x i8], [4 x i8]* @.str.52, i64 0, i64 0
  %r396 = ptrtoint i8* %r395 to i64
  %r397 = call i64 @_eq(i64 %r394, i64 %r396)
  %r398 = icmp ne i64 %r397, 0
  br i1 %r398, label %L285, label %L287
L285:
  store i64 9, i64* %ptr_type
  br label %L287
L287:
  %r399 = load i64, i64* %ptr_txt
  %r400 = getelementptr [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %r401 = ptrtoint i8* %r400 to i64
  %r402 = call i64 @_eq(i64 %r399, i64 %r401)
  %r403 = icmp ne i64 %r402, 0
  br i1 %r403, label %L288, label %L290
L288:
  store i64 10, i64* %ptr_type
  br label %L290
L290:
  %r404 = load i64, i64* %ptr_txt
  %r405 = getelementptr [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %r406 = ptrtoint i8* %r405 to i64
  %r407 = call i64 @_eq(i64 %r404, i64 %r406)
  %r408 = icmp ne i64 %r407, 0
  br i1 %r408, label %L291, label %L293
L291:
  store i64 11, i64* %ptr_type
  br label %L293
L293:
  %r409 = load i64, i64* %ptr_txt
  %r410 = getelementptr [10 x i8], [10 x i8]* @.str.55, i64 0, i64 0
  %r411 = ptrtoint i8* %r410 to i64
  %r412 = call i64 @_eq(i64 %r409, i64 %r411)
  %r413 = icmp ne i64 %r412, 0
  br i1 %r413, label %L294, label %L296
L294:
  store i64 12, i64* %ptr_type
  br label %L296
L296:
  %r414 = load i64, i64* %ptr_txt
  %r415 = getelementptr [8 x i8], [8 x i8]* @.str.56, i64 0, i64 0
  %r416 = ptrtoint i8* %r415 to i64
  %r417 = call i64 @_eq(i64 %r414, i64 %r416)
  %r418 = icmp ne i64 %r417, 0
  br i1 %r418, label %L297, label %L299
L297:
  store i64 13, i64* %ptr_type
  br label %L299
L299:
  %r419 = load i64, i64* %ptr_txt
  %r420 = getelementptr [10 x i8], [10 x i8]* @.str.57, i64 0, i64 0
  %r421 = ptrtoint i8* %r420 to i64
  %r422 = call i64 @_eq(i64 %r419, i64 %r421)
  %r423 = icmp ne i64 %r422, 0
  br i1 %r423, label %L300, label %L302
L300:
  store i64 20, i64* %ptr_type
  br label %L302
L302:
  %r424 = load i64, i64* %ptr_txt
  %r425 = getelementptr [9 x i8], [9 x i8]* @.str.58, i64 0, i64 0
  %r426 = ptrtoint i8* %r425 to i64
  %r427 = call i64 @_eq(i64 %r424, i64 %r426)
  %r428 = icmp ne i64 %r427, 0
  br i1 %r428, label %L303, label %L305
L303:
  store i64 35, i64* %ptr_type
  br label %L305
L305:
  %r429 = load i64, i64* %ptr_txt
  %r430 = getelementptr [9 x i8], [9 x i8]* @.str.59, i64 0, i64 0
  %r431 = ptrtoint i8* %r430 to i64
  %r432 = call i64 @_eq(i64 %r429, i64 %r431)
  %r433 = icmp ne i64 %r432, 0
  br i1 %r433, label %L306, label %L308
L306:
  store i64 36, i64* %ptr_type
  br label %L308
L308:
  %r434 = load i64, i64* %ptr_txt
  %r435 = getelementptr [4 x i8], [4 x i8]* @.str.60, i64 0, i64 0
  %r436 = ptrtoint i8* %r435 to i64
  %r437 = call i64 @_eq(i64 %r434, i64 %r436)
  %r438 = icmp ne i64 %r437, 0
  br i1 %r438, label %L309, label %L311
L309:
  store i64 37, i64* %ptr_type
  %r439 = getelementptr [2 x i8], [2 x i8]* @.str.61, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  store i64 %r440, i64* %ptr_txt
  br label %L311
L311:
  %r441 = load i64, i64* %ptr_txt
  %r442 = getelementptr [3 x i8], [3 x i8]* @.str.62, i64 0, i64 0
  %r443 = ptrtoint i8* %r442 to i64
  %r444 = call i64 @_eq(i64 %r441, i64 %r443)
  %r445 = icmp ne i64 %r444, 0
  br i1 %r445, label %L312, label %L314
L312:
  store i64 33, i64* %ptr_type
  br label %L314
L314:
  %r446 = load i64, i64* %ptr_txt
  %r447 = getelementptr [4 x i8], [4 x i8]* @.str.63, i64 0, i64 0
  %r448 = ptrtoint i8* %r447 to i64
  %r449 = call i64 @_eq(i64 %r446, i64 %r448)
  %r450 = icmp ne i64 %r449, 0
  br i1 %r450, label %L315, label %L317
L315:
  store i64 34, i64* %ptr_type
  br label %L317
L317:
  %r451 = load i64, i64* %ptr_txt
  %r452 = getelementptr [6 x i8], [6 x i8]* @.str.64, i64 0, i64 0
  %r453 = ptrtoint i8* %r452 to i64
  %r454 = call i64 @_eq(i64 %r451, i64 %r453)
  %r455 = icmp ne i64 %r454, 0
  br i1 %r455, label %L318, label %L320
L318:
  store i64 1, i64* %ptr_type
  %r456 = getelementptr [2 x i8], [2 x i8]* @.str.65, i64 0, i64 0
  %r457 = ptrtoint i8* %r456 to i64
  store i64 %r457, i64* %ptr_txt
  br label %L320
L320:
  %r458 = load i64, i64* %ptr_txt
  %r459 = getelementptr [7 x i8], [7 x i8]* @.str.66, i64 0, i64 0
  %r460 = ptrtoint i8* %r459 to i64
  %r461 = call i64 @_eq(i64 %r458, i64 %r460)
  %r462 = icmp ne i64 %r461, 0
  br i1 %r462, label %L321, label %L323
L321:
  store i64 1, i64* %ptr_type
  %r463 = getelementptr [2 x i8], [2 x i8]* @.str.67, i64 0, i64 0
  %r464 = ptrtoint i8* %r463 to i64
  store i64 %r464, i64* %ptr_txt
  br label %L323
L323:
  %r465 = load i64, i64* %ptr_type
  %r466 = load i64, i64* %ptr_txt
  %r467 = call i64 @make_token(i64 %r465, i64 %r466)
  %r468 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r468, i64 %r467)
  br label %L224
L223:
  store i64 0, i64* %ptr_type
  store i64 1, i64* %ptr_adv
  %r469 = load i64, i64* %ptr_c
  %r470 = getelementptr [2 x i8], [2 x i8]* @.str.68, i64 0, i64 0
  %r471 = ptrtoint i8* %r470 to i64
  %r472 = call i64 @_eq(i64 %r469, i64 %r471)
  %r473 = icmp ne i64 %r472, 0
  br i1 %r473, label %L324, label %L326
L324:
  %r474 = load i64, i64* @TOK_LPAREN
  store i64 %r474, i64* %ptr_type
  br label %L326
L326:
  %r475 = load i64, i64* %ptr_c
  %r476 = getelementptr [2 x i8], [2 x i8]* @.str.69, i64 0, i64 0
  %r477 = ptrtoint i8* %r476 to i64
  %r478 = call i64 @_eq(i64 %r475, i64 %r477)
  %r479 = icmp ne i64 %r478, 0
  br i1 %r479, label %L327, label %L329
L327:
  %r480 = load i64, i64* @TOK_RPAREN
  store i64 %r480, i64* %ptr_type
  br label %L329
L329:
  %r481 = load i64, i64* %ptr_c
  %r482 = getelementptr [2 x i8], [2 x i8]* @.str.70, i64 0, i64 0
  %r483 = ptrtoint i8* %r482 to i64
  %r484 = call i64 @_eq(i64 %r481, i64 %r483)
  %r485 = icmp ne i64 %r484, 0
  br i1 %r485, label %L330, label %L332
L330:
  %r486 = load i64, i64* @TOK_LBRACE
  store i64 %r486, i64* %ptr_type
  br label %L332
L332:
  %r487 = load i64, i64* %ptr_c
  %r488 = getelementptr [2 x i8], [2 x i8]* @.str.71, i64 0, i64 0
  %r489 = ptrtoint i8* %r488 to i64
  %r490 = call i64 @_eq(i64 %r487, i64 %r489)
  %r491 = icmp ne i64 %r490, 0
  br i1 %r491, label %L333, label %L335
L333:
  %r492 = load i64, i64* @TOK_RBRACE
  store i64 %r492, i64* %ptr_type
  br label %L335
L335:
  %r493 = load i64, i64* %ptr_c
  %r494 = getelementptr [2 x i8], [2 x i8]* @.str.72, i64 0, i64 0
  %r495 = ptrtoint i8* %r494 to i64
  %r496 = call i64 @_eq(i64 %r493, i64 %r495)
  %r497 = icmp ne i64 %r496, 0
  br i1 %r497, label %L336, label %L338
L336:
  %r498 = load i64, i64* @TOK_LBRACKET
  store i64 %r498, i64* %ptr_type
  br label %L338
L338:
  %r499 = load i64, i64* %ptr_c
  %r500 = getelementptr [2 x i8], [2 x i8]* @.str.73, i64 0, i64 0
  %r501 = ptrtoint i8* %r500 to i64
  %r502 = call i64 @_eq(i64 %r499, i64 %r501)
  %r503 = icmp ne i64 %r502, 0
  br i1 %r503, label %L339, label %L341
L339:
  %r504 = load i64, i64* @TOK_RBRACKET
  store i64 %r504, i64* %ptr_type
  br label %L341
L341:
  %r505 = load i64, i64* %ptr_c
  %r506 = getelementptr [2 x i8], [2 x i8]* @.str.74, i64 0, i64 0
  %r507 = ptrtoint i8* %r506 to i64
  %r508 = call i64 @_eq(i64 %r505, i64 %r507)
  %r509 = icmp ne i64 %r508, 0
  br i1 %r509, label %L342, label %L344
L342:
  %r510 = load i64, i64* @TOK_COLON
  store i64 %r510, i64* %ptr_type
  br label %L344
L344:
  %r511 = load i64, i64* %ptr_c
  %r512 = getelementptr [2 x i8], [2 x i8]* @.str.75, i64 0, i64 0
  %r513 = ptrtoint i8* %r512 to i64
  %r514 = call i64 @_eq(i64 %r511, i64 %r513)
  %r515 = icmp ne i64 %r514, 0
  br i1 %r515, label %L345, label %L347
L345:
  %r516 = load i64, i64* @TOK_CARET
  store i64 %r516, i64* %ptr_type
  br label %L347
L347:
  %r517 = load i64, i64* %ptr_c
  %r518 = getelementptr [2 x i8], [2 x i8]* @.str.76, i64 0, i64 0
  %r519 = ptrtoint i8* %r518 to i64
  %r520 = call i64 @_eq(i64 %r517, i64 %r519)
  %r521 = icmp ne i64 %r520, 0
  br i1 %r521, label %L348, label %L350
L348:
  %r522 = load i64, i64* @TOK_DOT
  store i64 %r522, i64* %ptr_type
  br label %L350
L350:
  %r523 = load i64, i64* %ptr_c
  %r524 = getelementptr [2 x i8], [2 x i8]* @.str.77, i64 0, i64 0
  %r525 = ptrtoint i8* %r524 to i64
  %r526 = call i64 @_eq(i64 %r523, i64 %r525)
  %r527 = icmp ne i64 %r526, 0
  br i1 %r527, label %L351, label %L353
L351:
  %r528 = load i64, i64* @TOK_COMMA
  store i64 %r528, i64* %ptr_type
  br label %L353
L353:
  %r529 = load i64, i64* %ptr_type
  %r530 = call i64 @_eq(i64 %r529, i64 0)
  %r531 = icmp ne i64 %r530, 0
  br i1 %r531, label %L354, label %L356
L354:
  %r532 = load i64, i64* @TOK_OP
  store i64 %r532, i64* %ptr_type
  %r533 = load i64, i64* %ptr_src
  %r534 = load i64, i64* %ptr_i
  %r535 = call i64 @_add(i64 %r534, i64 1)
  %r536 = call i64 @pars(i64 %r533, i64 %r535, i64 1)
  store i64 %r536, i64* %ptr_next
  %r537 = load i64, i64* %ptr_c
  %r538 = getelementptr [2 x i8], [2 x i8]* @.str.78, i64 0, i64 0
  %r539 = ptrtoint i8* %r538 to i64
  %r540 = call i64 @_eq(i64 %r537, i64 %r539)
  %r541 = icmp ne i64 %r540, 0
  br i1 %r541, label %L357, label %L359
L357:
  %r542 = load i64, i64* %ptr_next
  %r543 = getelementptr [2 x i8], [2 x i8]* @.str.79, i64 0, i64 0
  %r544 = ptrtoint i8* %r543 to i64
  %r545 = call i64 @_eq(i64 %r542, i64 %r544)
  %r546 = icmp ne i64 %r545, 0
  br i1 %r546, label %L360, label %L362
L360:
  %r547 = load i64, i64* @TOK_ARROW
  store i64 %r547, i64* %ptr_type
  %r548 = getelementptr [3 x i8], [3 x i8]* @.str.80, i64 0, i64 0
  %r549 = ptrtoint i8* %r548 to i64
  store i64 %r549, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L362
L362:
  br label %L359
L359:
  %r550 = load i64, i64* %ptr_c
  %r551 = getelementptr [2 x i8], [2 x i8]* @.str.81, i64 0, i64 0
  %r552 = ptrtoint i8* %r551 to i64
  %r553 = call i64 @_eq(i64 %r550, i64 %r552)
  %r554 = icmp ne i64 %r553, 0
  br i1 %r554, label %L363, label %L365
L363:
  %r555 = load i64, i64* %ptr_next
  %r556 = getelementptr [2 x i8], [2 x i8]* @.str.82, i64 0, i64 0
  %r557 = ptrtoint i8* %r556 to i64
  %r558 = call i64 @_eq(i64 %r555, i64 %r557)
  %r559 = icmp ne i64 %r558, 0
  br i1 %r559, label %L366, label %L368
L366:
  %r560 = getelementptr [3 x i8], [3 x i8]* @.str.83, i64 0, i64 0
  %r561 = ptrtoint i8* %r560 to i64
  store i64 %r561, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L368
L368:
  br label %L365
L365:
  %r562 = load i64, i64* %ptr_c
  %r563 = getelementptr [2 x i8], [2 x i8]* @.str.84, i64 0, i64 0
  %r564 = ptrtoint i8* %r563 to i64
  %r565 = call i64 @_eq(i64 %r562, i64 %r564)
  %r566 = icmp ne i64 %r565, 0
  br i1 %r566, label %L369, label %L371
L369:
  %r567 = load i64, i64* %ptr_next
  %r568 = getelementptr [2 x i8], [2 x i8]* @.str.85, i64 0, i64 0
  %r569 = ptrtoint i8* %r568 to i64
  %r570 = call i64 @_eq(i64 %r567, i64 %r569)
  %r571 = icmp ne i64 %r570, 0
  br i1 %r571, label %L372, label %L374
L372:
  %r572 = getelementptr [3 x i8], [3 x i8]* @.str.86, i64 0, i64 0
  %r573 = ptrtoint i8* %r572 to i64
  store i64 %r573, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L374
L374:
  br label %L371
L371:
  %r574 = load i64, i64* %ptr_c
  %r575 = getelementptr [2 x i8], [2 x i8]* @.str.87, i64 0, i64 0
  %r576 = ptrtoint i8* %r575 to i64
  %r577 = call i64 @_eq(i64 %r574, i64 %r576)
  %r578 = icmp ne i64 %r577, 0
  br i1 %r578, label %L375, label %L377
L375:
  %r579 = load i64, i64* %ptr_src
  %r580 = load i64, i64* %ptr_i
  %r581 = call i64 @_add(i64 %r580, i64 2)
  %r582 = call i64 @pars(i64 %r579, i64 %r581, i64 1)
  store i64 %r582, i64* %ptr_next2
  %r583 = load i64, i64* %ptr_next
  %r584 = getelementptr [2 x i8], [2 x i8]* @.str.88, i64 0, i64 0
  %r585 = ptrtoint i8* %r584 to i64
  %r586 = call i64 @_eq(i64 %r583, i64 %r585)
  %r587 = icmp ne i64 %r586, 0
  br i1 %r587, label %L378, label %L379
L378:
  %r588 = load i64, i64* %ptr_next2
  %r589 = getelementptr [2 x i8], [2 x i8]* @.str.89, i64 0, i64 0
  %r590 = ptrtoint i8* %r589 to i64
  %r591 = call i64 @_eq(i64 %r588, i64 %r590)
  %r592 = icmp ne i64 %r591, 0
  br i1 %r592, label %L381, label %L382
L381:
  store i64 37, i64* %ptr_type
  %r593 = getelementptr [4 x i8], [4 x i8]* @.str.90, i64 0, i64 0
  %r594 = ptrtoint i8* %r593 to i64
  store i64 %r594, i64* %ptr_c
  store i64 3, i64* %ptr_adv
  br label %L383
L382:
  %r595 = load i64, i64* @TOK_APPEND
  store i64 %r595, i64* %ptr_type
  %r596 = getelementptr [3 x i8], [3 x i8]* @.str.91, i64 0, i64 0
  %r597 = ptrtoint i8* %r596 to i64
  store i64 %r597, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L383
L383:
  br label %L380
L379:
  %r598 = load i64, i64* %ptr_next
  %r599 = getelementptr [2 x i8], [2 x i8]* @.str.92, i64 0, i64 0
  %r600 = ptrtoint i8* %r599 to i64
  %r601 = call i64 @_eq(i64 %r598, i64 %r600)
  %r602 = icmp ne i64 %r601, 0
  br i1 %r602, label %L384, label %L386
L384:
  %r603 = load i64, i64* @TOK_OP
  store i64 %r603, i64* %ptr_type
  %r604 = getelementptr [3 x i8], [3 x i8]* @.str.93, i64 0, i64 0
  %r605 = ptrtoint i8* %r604 to i64
  store i64 %r605, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L386
L386:
  br label %L380
L380:
  br label %L377
L377:
  %r606 = load i64, i64* %ptr_c
  %r607 = getelementptr [2 x i8], [2 x i8]* @.str.94, i64 0, i64 0
  %r608 = ptrtoint i8* %r607 to i64
  %r609 = call i64 @_eq(i64 %r606, i64 %r608)
  %r610 = icmp ne i64 %r609, 0
  br i1 %r610, label %L387, label %L389
L387:
  %r611 = load i64, i64* %ptr_src
  %r612 = load i64, i64* %ptr_i
  %r613 = call i64 @_add(i64 %r612, i64 2)
  %r614 = call i64 @pars(i64 %r611, i64 %r613, i64 1)
  store i64 %r614, i64* %ptr_next2
  %r615 = load i64, i64* %ptr_next
  %r616 = getelementptr [2 x i8], [2 x i8]* @.str.95, i64 0, i64 0
  %r617 = ptrtoint i8* %r616 to i64
  %r618 = call i64 @_eq(i64 %r615, i64 %r617)
  %r619 = icmp ne i64 %r618, 0
  br i1 %r619, label %L390, label %L391
L390:
  %r620 = load i64, i64* %ptr_next2
  %r621 = getelementptr [2 x i8], [2 x i8]* @.str.96, i64 0, i64 0
  %r622 = ptrtoint i8* %r621 to i64
  %r623 = call i64 @_eq(i64 %r620, i64 %r622)
  %r624 = icmp ne i64 %r623, 0
  br i1 %r624, label %L393, label %L394
L393:
  store i64 37, i64* %ptr_type
  %r625 = getelementptr [4 x i8], [4 x i8]* @.str.97, i64 0, i64 0
  %r626 = ptrtoint i8* %r625 to i64
  store i64 %r626, i64* %ptr_c
  store i64 3, i64* %ptr_adv
  br label %L395
L394:
  %r627 = load i64, i64* @TOK_EXTRACT
  store i64 %r627, i64* %ptr_type
  %r628 = getelementptr [3 x i8], [3 x i8]* @.str.98, i64 0, i64 0
  %r629 = ptrtoint i8* %r628 to i64
  store i64 %r629, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L395
L395:
  br label %L392
L391:
  %r630 = load i64, i64* %ptr_next
  %r631 = getelementptr [2 x i8], [2 x i8]* @.str.99, i64 0, i64 0
  %r632 = ptrtoint i8* %r631 to i64
  %r633 = call i64 @_eq(i64 %r630, i64 %r632)
  %r634 = icmp ne i64 %r633, 0
  br i1 %r634, label %L396, label %L398
L396:
  %r635 = load i64, i64* @TOK_OP
  store i64 %r635, i64* %ptr_type
  %r636 = getelementptr [3 x i8], [3 x i8]* @.str.100, i64 0, i64 0
  %r637 = ptrtoint i8* %r636 to i64
  store i64 %r637, i64* %ptr_c
  store i64 2, i64* %ptr_adv
  br label %L398
L398:
  br label %L392
L392:
  br label %L389
L389:
  br label %L356
L356:
  %r638 = load i64, i64* %ptr_type
  %r639 = load i64, i64* %ptr_c
  %r640 = call i64 @make_token(i64 %r638, i64 %r639)
  %r641 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r641, i64 %r640)
  %r642 = load i64, i64* %ptr_i
  %r643 = load i64, i64* %ptr_adv
  %r644 = call i64 @_add(i64 %r642, i64 %r643)
  store i64 %r644, i64* %ptr_i
  br label %L224
L224:
  br label %L173
L173:
  br label %L140
L140:
  br label %L99
L99:
  br label %L96
L96:
  br label %L91
L93:
  %r645 = load i64, i64* @TOK_EOF
  %r646 = getelementptr [4 x i8], [4 x i8]* @.str.101, i64 0, i64 0
  %r647 = ptrtoint i8* %r646 to i64
  %r648 = call i64 @make_token(i64 %r645, i64 %r647)
  %r649 = load i64, i64* %ptr_tokens
  call i64 @_append_poly(i64 %r649, i64 %r648)
  %r650 = getelementptr [39 x i8], [39 x i8]* @.str.102, i64 0, i64 0
  %r651 = ptrtoint i8* %r650 to i64
  %r652 = load i64, i64* %ptr_tokens
  %r653 = call i64 @mensura(i64 %r652)
  %r654 = call i64 @int_to_str(i64 %r653)
  %r655 = call i64 @_add(i64 %r651, i64 %r654)
  call i64 @print_any(i64 %r655)
  %r656 = load i64, i64* %ptr_tokens
  ret i64 %r656
  ret i64 0
}
define i64 @peek() {
  %r1 = load i64, i64* @p_pos
  %r2 = load i64, i64* @global_tokens
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp sge i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L399, label %L401
L399:
  %r7 = call i64 @_map_new()
  %r8 = getelementptr [5 x i8], [5 x i8]* @.str.103, i64 0, i64 0
  %r9 = ptrtoint i8* %r8 to i64
  %r10 = load i64, i64* @TOK_EOF
  call i64 @_map_set(i64 %r7, i64 %r9, i64 %r10)
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.104, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = getelementptr [4 x i8], [4 x i8]* @.str.105, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  call i64 @_map_set(i64 %r7, i64 %r12, i64 %r14)
  ret i64 %r7
  br label %L401
L401:
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
  %r3 = getelementptr [5 x i8], [5 x i8]* @.str.106, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = call i64 @_get(i64 %r2, i64 %r4)
  %r6 = load i64, i64* @TOK_EOF
  %r8 = call i64 @_eq(i64 %r5, i64 %r6)
  %r7 = xor i64 %r8, 1
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L402, label %L404
L402:
  %r10 = load i64, i64* @p_pos
  %r11 = call i64 @_add(i64 %r10, i64 1)
  store i64 %r11, i64* @p_pos
  br label %L404
L404:
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
  %r3 = getelementptr [5 x i8], [5 x i8]* @.str.107, i64 0, i64 0
  %r4 = ptrtoint i8* %r3 to i64
  %r5 = call i64 @_get(i64 %r2, i64 %r4)
  %r6 = load i64, i64* %ptr_type
  %r7 = call i64 @_eq(i64 %r5, i64 %r6)
  %r8 = icmp ne i64 %r7, 0
  br i1 %r8, label %L405, label %L407
L405:
  %r9 = call i64 @advance()
  ret i64 1
  br label %L407
L407:
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
  br i1 %r3, label %L408, label %L410
L408:
  ret i64 1
  br label %L410
L410:
  %r4 = call i64 @peek()
  store i64 %r4, i64* %ptr_t
  %r5 = getelementptr [21 x i8], [21 x i8]* @.str.108, i64 0, i64 0
  %r6 = ptrtoint i8* %r5 to i64
  %r7 = load i64, i64* %ptr_type
  %r8 = call i64 @int_to_str(i64 %r7)
  %r9 = call i64 @_add(i64 %r6, i64 %r8)
  %r10 = getelementptr [10 x i8], [10 x i8]* @.str.109, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  %r12 = call i64 @_add(i64 %r9, i64 %r11)
  %r13 = load i64, i64* %ptr_t
  %r14 = getelementptr [5 x i8], [5 x i8]* @.str.110, i64 0, i64 0
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
  br i1 %r4, label %L411, label %L413
L411:
  %r5 = call i64 @_map_new()
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.111, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r5, i64 %r7, i64 %r8)
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.112, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = load i64, i64* %ptr_t
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.113, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  call i64 @_map_set(i64 %r5, i64 %r10, i64 %r14)
  ret i64 %r5
  br label %L413
L413:
  %r15 = load i64, i64* @TOK_STRING
  %r16 = call i64 @consume(i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L414, label %L416
L414:
  %r18 = call i64 @_map_new()
  %r19 = getelementptr [5 x i8], [5 x i8]* @.str.114, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = load i64, i64* @EXPR_STRING
  call i64 @_map_set(i64 %r18, i64 %r20, i64 %r21)
  %r22 = getelementptr [4 x i8], [4 x i8]* @.str.115, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = load i64, i64* %ptr_t
  %r25 = getelementptr [5 x i8], [5 x i8]* @.str.116, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = call i64 @_get(i64 %r24, i64 %r26)
  call i64 @_map_set(i64 %r18, i64 %r23, i64 %r27)
  ret i64 %r18
  br label %L416
L416:
  %r28 = load i64, i64* @TOK_IDENT
  %r29 = call i64 @consume(i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L417, label %L419
L417:
  %r31 = load i64, i64* %ptr_t
  %r32 = getelementptr [5 x i8], [5 x i8]* @.str.117, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_get(i64 %r31, i64 %r33)
  store i64 %r34, i64* %ptr_name
  %r35 = load i64, i64* @TOK_LPAREN
  %r36 = call i64 @consume(i64 %r35)
  %r37 = icmp ne i64 %r36, 0
  br i1 %r37, label %L420, label %L422
L420:
  %r38 = call i64 @_list_new()
  store i64 %r38, i64* %ptr_args
  %r39 = call i64 @peek()
  %r40 = getelementptr [5 x i8], [5 x i8]* @.str.118, i64 0, i64 0
  %r41 = ptrtoint i8* %r40 to i64
  %r42 = call i64 @_get(i64 %r39, i64 %r41)
  %r43 = load i64, i64* @TOK_RPAREN
  %r45 = call i64 @_eq(i64 %r42, i64 %r43)
  %r44 = xor i64 %r45, 1
  %r46 = icmp ne i64 %r44, 0
  br i1 %r46, label %L423, label %L425
L423:
  %r47 = call i64 @parse_expr()
  %r48 = load i64, i64* %ptr_args
  call i64 @_append_poly(i64 %r48, i64 %r47)
  br label %L426
L426:
  %r49 = load i64, i64* @TOK_COMMA
  %r50 = call i64 @consume(i64 %r49)
  %r51 = icmp ne i64 %r50, 0
  br i1 %r51, label %L427, label %L428
L427:
  %r52 = call i64 @parse_expr()
  %r53 = load i64, i64* %ptr_args
  call i64 @_append_poly(i64 %r53, i64 %r52)
  br label %L426
L428:
  br label %L425
L425:
  %r54 = load i64, i64* @TOK_RPAREN
  %r55 = call i64 @expect(i64 %r54)
  %r56 = call i64 @_map_new()
  %r57 = getelementptr [5 x i8], [5 x i8]* @.str.119, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = load i64, i64* @EXPR_CALL
  call i64 @_map_set(i64 %r56, i64 %r58, i64 %r59)
  %r60 = getelementptr [5 x i8], [5 x i8]* @.str.120, i64 0, i64 0
  %r61 = ptrtoint i8* %r60 to i64
  %r62 = load i64, i64* %ptr_name
  call i64 @_map_set(i64 %r56, i64 %r61, i64 %r62)
  %r63 = getelementptr [5 x i8], [5 x i8]* @.str.121, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = load i64, i64* %ptr_args
  call i64 @_map_set(i64 %r56, i64 %r64, i64 %r65)
  ret i64 %r56
  br label %L422
L422:
  %r66 = call i64 @_map_new()
  %r67 = getelementptr [5 x i8], [5 x i8]* @.str.122, i64 0, i64 0
  %r68 = ptrtoint i8* %r67 to i64
  %r69 = load i64, i64* @EXPR_VAR
  call i64 @_map_set(i64 %r66, i64 %r68, i64 %r69)
  %r70 = getelementptr [5 x i8], [5 x i8]* @.str.123, i64 0, i64 0
  %r71 = ptrtoint i8* %r70 to i64
  %r72 = load i64, i64* %ptr_name
  call i64 @_map_set(i64 %r66, i64 %r71, i64 %r72)
  ret i64 %r66
  br label %L419
L419:
  %r73 = load i64, i64* @TOK_LPAREN
  %r74 = call i64 @consume(i64 %r73)
  %r75 = icmp ne i64 %r74, 0
  br i1 %r75, label %L429, label %L431
L429:
  %r76 = call i64 @parse_expr()
  store i64 %r76, i64* %ptr_expr
  %r77 = load i64, i64* @TOK_RPAREN
  %r78 = call i64 @expect(i64 %r77)
  %r79 = load i64, i64* %ptr_expr
  ret i64 %r79
  br label %L431
L431:
  %r80 = load i64, i64* @TOK_LBRACKET
  %r81 = call i64 @consume(i64 %r80)
  %r82 = icmp ne i64 %r81, 0
  br i1 %r82, label %L432, label %L434
L432:
  %r83 = call i64 @_list_new()
  store i64 %r83, i64* %ptr_items
  %r84 = call i64 @peek()
  %r85 = getelementptr [5 x i8], [5 x i8]* @.str.124, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = call i64 @_get(i64 %r84, i64 %r86)
  %r88 = load i64, i64* @TOK_RBRACKET
  %r90 = call i64 @_eq(i64 %r87, i64 %r88)
  %r89 = xor i64 %r90, 1
  %r91 = icmp ne i64 %r89, 0
  br i1 %r91, label %L435, label %L437
L435:
  %r92 = call i64 @parse_expr()
  %r93 = load i64, i64* %ptr_items
  call i64 @_append_poly(i64 %r93, i64 %r92)
  br label %L438
L438:
  %r94 = load i64, i64* @TOK_COMMA
  %r95 = call i64 @consume(i64 %r94)
  %r96 = icmp ne i64 %r95, 0
  br i1 %r96, label %L439, label %L440
L439:
  %r97 = call i64 @parse_expr()
  %r98 = load i64, i64* %ptr_items
  call i64 @_append_poly(i64 %r98, i64 %r97)
  br label %L438
L440:
  br label %L437
L437:
  %r99 = load i64, i64* @TOK_RBRACKET
  %r100 = call i64 @expect(i64 %r99)
  %r101 = call i64 @_map_new()
  %r102 = getelementptr [5 x i8], [5 x i8]* @.str.125, i64 0, i64 0
  %r103 = ptrtoint i8* %r102 to i64
  %r104 = load i64, i64* @EXPR_LIST
  call i64 @_map_set(i64 %r101, i64 %r103, i64 %r104)
  %r105 = getelementptr [6 x i8], [6 x i8]* @.str.126, i64 0, i64 0
  %r106 = ptrtoint i8* %r105 to i64
  %r107 = load i64, i64* %ptr_items
  call i64 @_map_set(i64 %r101, i64 %r106, i64 %r107)
  ret i64 %r101
  br label %L434
L434:
  %r108 = load i64, i64* @TOK_LBRACE
  %r109 = call i64 @consume(i64 %r108)
  %r110 = icmp ne i64 %r109, 0
  br i1 %r110, label %L441, label %L443
L441:
  %r111 = call i64 @_list_new()
  store i64 %r111, i64* %ptr_keys
  %r112 = call i64 @_list_new()
  store i64 %r112, i64* %ptr_vals
  br label %L444
L444:
  %r113 = call i64 @peek()
  %r114 = getelementptr [5 x i8], [5 x i8]* @.str.127, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_get(i64 %r113, i64 %r115)
  %r117 = load i64, i64* @TOK_RBRACE
  %r119 = call i64 @_eq(i64 %r116, i64 %r117)
  %r118 = xor i64 %r119, 1
  %r120 = icmp ne i64 %r118, 0
  br i1 %r120, label %L445, label %L446
L445:
  %r121 = call i64 @advance()
  store i64 %r121, i64* %ptr_k
  %r122 = load i64, i64* @TOK_COLON
  %r123 = call i64 @expect(i64 %r122)
  %r124 = call i64 @parse_expr()
  store i64 %r124, i64* %ptr_v
  %r125 = load i64, i64* %ptr_k
  %r126 = getelementptr [5 x i8], [5 x i8]* @.str.128, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = load i64, i64* %ptr_keys
  call i64 @_append_poly(i64 %r129, i64 %r128)
  %r130 = load i64, i64* %ptr_v
  %r131 = load i64, i64* %ptr_vals
  call i64 @_append_poly(i64 %r131, i64 %r130)
  %r132 = load i64, i64* @TOK_COMMA
  %r133 = call i64 @consume(i64 %r132)
  br label %L444
L446:
  %r134 = load i64, i64* @TOK_RBRACE
  %r135 = call i64 @expect(i64 %r134)
  %r136 = call i64 @_map_new()
  %r137 = getelementptr [5 x i8], [5 x i8]* @.str.129, i64 0, i64 0
  %r138 = ptrtoint i8* %r137 to i64
  %r139 = load i64, i64* @EXPR_MAP
  call i64 @_map_set(i64 %r136, i64 %r138, i64 %r139)
  %r140 = getelementptr [5 x i8], [5 x i8]* @.str.130, i64 0, i64 0
  %r141 = ptrtoint i8* %r140 to i64
  %r142 = load i64, i64* %ptr_keys
  call i64 @_map_set(i64 %r136, i64 %r141, i64 %r142)
  %r143 = getelementptr [5 x i8], [5 x i8]* @.str.131, i64 0, i64 0
  %r144 = ptrtoint i8* %r143 to i64
  %r145 = load i64, i64* %ptr_vals
  call i64 @_map_set(i64 %r136, i64 %r144, i64 %r145)
  ret i64 %r136
  br label %L443
L443:
  %r146 = load i64, i64* %ptr_t
  %r147 = getelementptr [5 x i8], [5 x i8]* @.str.133, i64 0, i64 0
  %r148 = ptrtoint i8* %r147 to i64
  %r149 = call i64 @_get(i64 %r146, i64 %r148)
  %r150 = load i64, i64* @TOK_OP
  %r151 = call i64 @_eq(i64 %r149, i64 %r150)
  store i64 0, i64* @.sc.132
  %r153 = icmp ne i64 %r151, 0
  br i1 %r153, label %L447, label %L448
L447:
  %r154 = load i64, i64* %ptr_t
  %r155 = getelementptr [5 x i8], [5 x i8]* @.str.134, i64 0, i64 0
  %r156 = ptrtoint i8* %r155 to i64
  %r157 = call i64 @_get(i64 %r154, i64 %r156)
  %r158 = getelementptr [2 x i8], [2 x i8]* @.str.135, i64 0, i64 0
  %r159 = ptrtoint i8* %r158 to i64
  %r160 = call i64 @_eq(i64 %r157, i64 %r159)
  %r161 = icmp ne i64 %r160, 0
  %r162 = zext i1 %r161 to i64
  store i64 %r162, i64* @.sc.132
  br label %L448
L448:
  %r152 = load i64, i64* @.sc.132
  %r163 = icmp ne i64 %r152, 0
  br i1 %r163, label %L449, label %L451
L449:
  %r164 = call i64 @advance()
  %r165 = call i64 @parse_primary()
  store i64 %r165, i64* %ptr_right
  %r166 = call i64 @_map_new()
  %r167 = getelementptr [5 x i8], [5 x i8]* @.str.136, i64 0, i64 0
  %r168 = ptrtoint i8* %r167 to i64
  %r169 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r166, i64 %r168, i64 %r169)
  %r170 = getelementptr [3 x i8], [3 x i8]* @.str.137, i64 0, i64 0
  %r171 = ptrtoint i8* %r170 to i64
  %r172 = getelementptr [2 x i8], [2 x i8]* @.str.138, i64 0, i64 0
  %r173 = ptrtoint i8* %r172 to i64
  call i64 @_map_set(i64 %r166, i64 %r171, i64 %r173)
  %r174 = getelementptr [5 x i8], [5 x i8]* @.str.139, i64 0, i64 0
  %r175 = ptrtoint i8* %r174 to i64
  %r176 = call i64 @_map_new()
  %r177 = getelementptr [5 x i8], [5 x i8]* @.str.140, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r176, i64 %r178, i64 %r179)
  %r180 = getelementptr [4 x i8], [4 x i8]* @.str.141, i64 0, i64 0
  %r181 = ptrtoint i8* %r180 to i64
  %r182 = getelementptr [2 x i8], [2 x i8]* @.str.142, i64 0, i64 0
  %r183 = ptrtoint i8* %r182 to i64
  call i64 @_map_set(i64 %r176, i64 %r181, i64 %r183)
  call i64 @_map_set(i64 %r166, i64 %r175, i64 %r176)
  %r184 = getelementptr [6 x i8], [6 x i8]* @.str.143, i64 0, i64 0
  %r185 = ptrtoint i8* %r184 to i64
  %r186 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r166, i64 %r185, i64 %r186)
  ret i64 %r166
  br label %L451
L451:
  %r187 = load i64, i64* %ptr_t
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.145, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = call i64 @_get(i64 %r187, i64 %r189)
  %r191 = load i64, i64* @TOK_OP
  %r192 = call i64 @_eq(i64 %r190, i64 %r191)
  store i64 0, i64* @.sc.144
  %r194 = icmp ne i64 %r192, 0
  br i1 %r194, label %L452, label %L453
L452:
  %r195 = load i64, i64* %ptr_t
  %r196 = getelementptr [5 x i8], [5 x i8]* @.str.146, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = call i64 @_get(i64 %r195, i64 %r197)
  %r199 = getelementptr [2 x i8], [2 x i8]* @.str.147, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_eq(i64 %r198, i64 %r200)
  %r202 = icmp ne i64 %r201, 0
  %r203 = zext i1 %r202 to i64
  store i64 %r203, i64* @.sc.144
  br label %L453
L453:
  %r193 = load i64, i64* @.sc.144
  %r204 = icmp ne i64 %r193, 0
  br i1 %r204, label %L454, label %L456
L454:
  %r205 = call i64 @advance()
  %r206 = call i64 @parse_primary()
  store i64 %r206, i64* %ptr_right
  %r207 = call i64 @_map_new()
  %r208 = getelementptr [5 x i8], [5 x i8]* @.str.148, i64 0, i64 0
  %r209 = ptrtoint i8* %r208 to i64
  %r210 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r207, i64 %r209, i64 %r210)
  %r211 = getelementptr [3 x i8], [3 x i8]* @.str.149, i64 0, i64 0
  %r212 = ptrtoint i8* %r211 to i64
  %r213 = getelementptr [3 x i8], [3 x i8]* @.str.150, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  call i64 @_map_set(i64 %r207, i64 %r212, i64 %r214)
  %r215 = getelementptr [5 x i8], [5 x i8]* @.str.151, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r207, i64 %r216, i64 %r217)
  %r218 = getelementptr [6 x i8], [6 x i8]* @.str.152, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @_map_new()
  %r221 = getelementptr [5 x i8], [5 x i8]* @.str.153, i64 0, i64 0
  %r222 = ptrtoint i8* %r221 to i64
  %r223 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r220, i64 %r222, i64 %r223)
  %r224 = getelementptr [4 x i8], [4 x i8]* @.str.154, i64 0, i64 0
  %r225 = ptrtoint i8* %r224 to i64
  %r226 = getelementptr [2 x i8], [2 x i8]* @.str.155, i64 0, i64 0
  %r227 = ptrtoint i8* %r226 to i64
  call i64 @_map_set(i64 %r220, i64 %r225, i64 %r227)
  call i64 @_map_set(i64 %r207, i64 %r219, i64 %r220)
  ret i64 %r207
  br label %L456
L456:
  %r228 = load i64, i64* %ptr_t
  %r229 = getelementptr [5 x i8], [5 x i8]* @.str.156, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @_get(i64 %r228, i64 %r230)
  %r232 = load i64, i64* @TOK_EOF
  %r234 = call i64 @_eq(i64 %r231, i64 %r232)
  %r233 = xor i64 %r234, 1
  %r235 = icmp ne i64 %r233, 0
  br i1 %r235, label %L457, label %L459
L457:
  %r236 = call i64 @advance()
  br label %L459
L459:
  %r237 = getelementptr [19 x i8], [19 x i8]* @.str.157, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = load i64, i64* %ptr_t
  %r240 = getelementptr [5 x i8], [5 x i8]* @.str.158, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_get(i64 %r239, i64 %r241)
  %r243 = call i64 @_add(i64 %r238, i64 %r242)
  %r244 = call i64 @error_report(i64 %r243)
  %r245 = call i64 @_map_new()
  %r246 = getelementptr [5 x i8], [5 x i8]* @.str.159, i64 0, i64 0
  %r247 = ptrtoint i8* %r246 to i64
  %r248 = load i64, i64* @EXPR_INT
  call i64 @_map_set(i64 %r245, i64 %r247, i64 %r248)
  %r249 = getelementptr [4 x i8], [4 x i8]* @.str.160, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = getelementptr [2 x i8], [2 x i8]* @.str.161, i64 0, i64 0
  %r252 = ptrtoint i8* %r251 to i64
  call i64 @_map_set(i64 %r245, i64 %r250, i64 %r252)
  ret i64 %r245
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
  br label %L460
L460:
  %r2 = load i64, i64* %ptr_running
  %r3 = icmp ne i64 %r2, 0
  br i1 %r3, label %L461, label %L462
L461:
  %r4 = load i64, i64* @TOK_LBRACKET
  %r5 = call i64 @consume(i64 %r4)
  %r6 = icmp ne i64 %r5, 0
  br i1 %r6, label %L463, label %L464
L463:
  %r7 = call i64 @parse_expr()
  store i64 %r7, i64* %ptr_idx
  %r8 = load i64, i64* @TOK_RBRACKET
  %r9 = call i64 @expect(i64 %r8)
  %r10 = call i64 @_map_new()
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.162, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = load i64, i64* @EXPR_INDEX
  call i64 @_map_set(i64 %r10, i64 %r12, i64 %r13)
  %r14 = getelementptr [4 x i8], [4 x i8]* @.str.163, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r10, i64 %r15, i64 %r16)
  %r17 = getelementptr [4 x i8], [4 x i8]* @.str.164, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = load i64, i64* %ptr_idx
  call i64 @_map_set(i64 %r10, i64 %r18, i64 %r19)
  store i64 %r10, i64* %ptr_expr
  br label %L465
L464:
  %r20 = load i64, i64* @TOK_DOT
  %r21 = call i64 @consume(i64 %r20)
  %r22 = icmp ne i64 %r21, 0
  br i1 %r22, label %L466, label %L467
L466:
  %r23 = call i64 @advance()
  store i64 %r23, i64* %ptr_t
  %r24 = call i64 @_map_new()
  %r25 = getelementptr [5 x i8], [5 x i8]* @.str.165, i64 0, i64 0
  %r26 = ptrtoint i8* %r25 to i64
  %r27 = load i64, i64* @EXPR_GET
  call i64 @_map_set(i64 %r24, i64 %r26, i64 %r27)
  %r28 = getelementptr [4 x i8], [4 x i8]* @.str.166, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r24, i64 %r29, i64 %r30)
  %r31 = getelementptr [5 x i8], [5 x i8]* @.str.167, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = load i64, i64* %ptr_t
  %r34 = getelementptr [5 x i8], [5 x i8]* @.str.168, i64 0, i64 0
  %r35 = ptrtoint i8* %r34 to i64
  %r36 = call i64 @_get(i64 %r33, i64 %r35)
  call i64 @_map_set(i64 %r24, i64 %r32, i64 %r36)
  store i64 %r24, i64* %ptr_expr
  br label %L468
L467:
  store i64 0, i64* %ptr_running
  br label %L468
L468:
  br label %L465
L465:
  br label %L460
L462:
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
  br label %L469
L469:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L470, label %L471
L470:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.169, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L472, label %L474
L472:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.170, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.171, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L475, label %L477
L475:
  store i64 1, i64* %ptr_is_op
  br label %L477
L477:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.172, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L478, label %L480
L478:
  store i64 1, i64* %ptr_is_op
  br label %L480
L480:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.173, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L481, label %L483
L481:
  store i64 1, i64* %ptr_is_op
  br label %L483
L483:
  br label %L474
L474:
  %r31 = load i64, i64* %ptr_is_op
  %r32 = icmp ne i64 %r31, 0
  br i1 %r32, label %L484, label %L485
L484:
  %r33 = load i64, i64* %ptr_t
  %r34 = getelementptr [5 x i8], [5 x i8]* @.str.174, i64 0, i64 0
  %r35 = ptrtoint i8* %r34 to i64
  %r36 = call i64 @_get(i64 %r33, i64 %r35)
  store i64 %r36, i64* %ptr_op
  %r37 = call i64 @advance()
  %r38 = call i64 @parse_postfix()
  store i64 %r38, i64* %ptr_right
  %r39 = call i64 @_map_new()
  %r40 = getelementptr [5 x i8], [5 x i8]* @.str.175, i64 0, i64 0
  %r41 = ptrtoint i8* %r40 to i64
  %r42 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r39, i64 %r41, i64 %r42)
  %r43 = getelementptr [3 x i8], [3 x i8]* @.str.176, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r39, i64 %r44, i64 %r45)
  %r46 = getelementptr [5 x i8], [5 x i8]* @.str.177, i64 0, i64 0
  %r47 = ptrtoint i8* %r46 to i64
  %r48 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r39, i64 %r47, i64 %r48)
  %r49 = getelementptr [6 x i8], [6 x i8]* @.str.178, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r39, i64 %r50, i64 %r51)
  store i64 %r39, i64* %ptr_left
  %r52 = call i64 @peek()
  store i64 %r52, i64* %ptr_t
  br label %L486
L485:
  store i64 0, i64* %ptr_running
  br label %L486
L486:
  br label %L469
L471:
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
  br label %L487
L487:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L488, label %L489
L488:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.179, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L490, label %L492
L490:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.180, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.181, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L493, label %L495
L493:
  store i64 1, i64* %ptr_is_op
  br label %L495
L495:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.182, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L496, label %L498
L496:
  store i64 1, i64* %ptr_is_op
  br label %L498
L498:
  br label %L492
L492:
  %r26 = load i64, i64* %ptr_is_op
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L499, label %L500
L499:
  %r28 = load i64, i64* %ptr_t
  %r29 = getelementptr [5 x i8], [5 x i8]* @.str.183, i64 0, i64 0
  %r30 = ptrtoint i8* %r29 to i64
  %r31 = call i64 @_get(i64 %r28, i64 %r30)
  store i64 %r31, i64* %ptr_op
  %r32 = call i64 @advance()
  %r33 = call i64 @parse_term()
  store i64 %r33, i64* %ptr_right
  %r34 = call i64 @_map_new()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.184, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r34, i64 %r36, i64 %r37)
  %r38 = getelementptr [3 x i8], [3 x i8]* @.str.185, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r34, i64 %r39, i64 %r40)
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.186, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r34, i64 %r42, i64 %r43)
  %r44 = getelementptr [6 x i8], [6 x i8]* @.str.187, i64 0, i64 0
  %r45 = ptrtoint i8* %r44 to i64
  %r46 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r34, i64 %r45, i64 %r46)
  store i64 %r34, i64* %ptr_left
  %r47 = call i64 @peek()
  store i64 %r47, i64* %ptr_t
  br label %L501
L500:
  store i64 0, i64* %ptr_running
  br label %L501
L501:
  br label %L487
L489:
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
  br label %L502
L502:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L503, label %L504
L503:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.188, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  store i64 %r8, i64* %ptr_op
  %r9 = load i64, i64* %ptr_t
  %r10 = getelementptr [5 x i8], [5 x i8]* @.str.189, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  %r12 = call i64 @_get(i64 %r9, i64 %r11)
  %r13 = load i64, i64* @TOK_OP
  %r14 = call i64 @_eq(i64 %r12, i64 %r13)
  %r15 = icmp ne i64 %r14, 0
  br i1 %r15, label %L505, label %L507
L505:
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [2 x i8], [2 x i8]* @.str.190, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L508, label %L510
L508:
  store i64 1, i64* %ptr_is_op
  br label %L510
L510:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [2 x i8], [2 x i8]* @.str.191, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L511, label %L513
L511:
  store i64 1, i64* %ptr_is_op
  br label %L513
L513:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.192, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L514, label %L516
L514:
  store i64 1, i64* %ptr_is_op
  br label %L516
L516:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [4 x i8], [4 x i8]* @.str.193, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L517, label %L519
L517:
  store i64 1, i64* %ptr_is_op
  br label %L519
L519:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [4 x i8], [4 x i8]* @.str.194, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L520, label %L522
L520:
  store i64 1, i64* %ptr_is_op
  br label %L522
L522:
  br label %L507
L507:
  %r41 = load i64, i64* %ptr_t
  %r42 = getelementptr [5 x i8], [5 x i8]* @.str.195, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_get(i64 %r41, i64 %r43)
  %r45 = load i64, i64* @TOK_IDENT
  %r46 = call i64 @_eq(i64 %r44, i64 %r45)
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L523, label %L525
L523:
  %r48 = load i64, i64* %ptr_op
  %r49 = getelementptr [4 x i8], [4 x i8]* @.str.196, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_eq(i64 %r48, i64 %r50)
  %r52 = icmp ne i64 %r51, 0
  br i1 %r52, label %L526, label %L528
L526:
  store i64 1, i64* %ptr_is_op
  %r53 = getelementptr [2 x i8], [2 x i8]* @.str.197, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  store i64 %r54, i64* %ptr_op
  br label %L528
L528:
  br label %L525
L525:
  %r55 = load i64, i64* %ptr_is_op
  %r56 = icmp ne i64 %r55, 0
  br i1 %r56, label %L529, label %L530
L529:
  %r57 = call i64 @advance()
  %r58 = call i64 @parse_math()
  store i64 %r58, i64* %ptr_right
  %r59 = call i64 @_map_new()
  %r60 = getelementptr [5 x i8], [5 x i8]* @.str.198, i64 0, i64 0
  %r61 = ptrtoint i8* %r60 to i64
  %r62 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r59, i64 %r61, i64 %r62)
  %r63 = getelementptr [3 x i8], [3 x i8]* @.str.199, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r59, i64 %r64, i64 %r65)
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.200, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r59, i64 %r67, i64 %r68)
  %r69 = getelementptr [6 x i8], [6 x i8]* @.str.201, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r59, i64 %r70, i64 %r71)
  store i64 %r59, i64* %ptr_left
  %r72 = call i64 @peek()
  store i64 %r72, i64* %ptr_t
  br label %L531
L530:
  store i64 0, i64* %ptr_running
  br label %L531
L531:
  br label %L502
L504:
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
  br label %L532
L532:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L533, label %L534
L533:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.202, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_OP
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L535, label %L537
L535:
  %r12 = load i64, i64* %ptr_t
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.203, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  store i64 %r15, i64* %ptr_op
  %r16 = load i64, i64* %ptr_op
  %r17 = getelementptr [3 x i8], [3 x i8]* @.str.204, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L538, label %L540
L538:
  store i64 1, i64* %ptr_is_op
  br label %L540
L540:
  %r21 = load i64, i64* %ptr_op
  %r22 = getelementptr [3 x i8], [3 x i8]* @.str.205, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L541, label %L543
L541:
  store i64 1, i64* %ptr_is_op
  br label %L543
L543:
  %r26 = load i64, i64* %ptr_op
  %r27 = getelementptr [2 x i8], [2 x i8]* @.str.206, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_eq(i64 %r26, i64 %r28)
  %r30 = icmp ne i64 %r29, 0
  br i1 %r30, label %L544, label %L546
L544:
  store i64 1, i64* %ptr_is_op
  br label %L546
L546:
  %r31 = load i64, i64* %ptr_op
  %r32 = getelementptr [2 x i8], [2 x i8]* @.str.207, i64 0, i64 0
  %r33 = ptrtoint i8* %r32 to i64
  %r34 = call i64 @_eq(i64 %r31, i64 %r33)
  %r35 = icmp ne i64 %r34, 0
  br i1 %r35, label %L547, label %L549
L547:
  store i64 1, i64* %ptr_is_op
  br label %L549
L549:
  %r36 = load i64, i64* %ptr_op
  %r37 = getelementptr [3 x i8], [3 x i8]* @.str.208, i64 0, i64 0
  %r38 = ptrtoint i8* %r37 to i64
  %r39 = call i64 @_eq(i64 %r36, i64 %r38)
  %r40 = icmp ne i64 %r39, 0
  br i1 %r40, label %L550, label %L552
L550:
  store i64 1, i64* %ptr_is_op
  br label %L552
L552:
  %r41 = load i64, i64* %ptr_op
  %r42 = getelementptr [3 x i8], [3 x i8]* @.str.209, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_eq(i64 %r41, i64 %r43)
  %r45 = icmp ne i64 %r44, 0
  br i1 %r45, label %L553, label %L555
L553:
  store i64 1, i64* %ptr_is_op
  br label %L555
L555:
  br label %L537
L537:
  %r46 = load i64, i64* %ptr_is_op
  %r47 = icmp ne i64 %r46, 0
  br i1 %r47, label %L556, label %L557
L556:
  %r48 = load i64, i64* %ptr_t
  %r49 = getelementptr [5 x i8], [5 x i8]* @.str.210, i64 0, i64 0
  %r50 = ptrtoint i8* %r49 to i64
  %r51 = call i64 @_get(i64 %r48, i64 %r50)
  store i64 %r51, i64* %ptr_op
  %r52 = call i64 @advance()
  %r53 = call i64 @parse_bitwise()
  store i64 %r53, i64* %ptr_right
  %r54 = call i64 @_map_new()
  %r55 = getelementptr [5 x i8], [5 x i8]* @.str.211, i64 0, i64 0
  %r56 = ptrtoint i8* %r55 to i64
  %r57 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r54, i64 %r56, i64 %r57)
  %r58 = getelementptr [3 x i8], [3 x i8]* @.str.212, i64 0, i64 0
  %r59 = ptrtoint i8* %r58 to i64
  %r60 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r54, i64 %r59, i64 %r60)
  %r61 = getelementptr [5 x i8], [5 x i8]* @.str.213, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r54, i64 %r62, i64 %r63)
  %r64 = getelementptr [6 x i8], [6 x i8]* @.str.214, i64 0, i64 0
  %r65 = ptrtoint i8* %r64 to i64
  %r66 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r54, i64 %r65, i64 %r66)
  store i64 %r54, i64* %ptr_left
  %r67 = call i64 @peek()
  store i64 %r67, i64* %ptr_t
  br label %L558
L557:
  store i64 0, i64* %ptr_running
  br label %L558
L558:
  br label %L532
L534:
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
  br label %L559
L559:
  %r3 = load i64, i64* %ptr_running
  %r4 = icmp ne i64 %r3, 0
  br i1 %r4, label %L560, label %L561
L560:
  store i64 0, i64* %ptr_is_op
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.216, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_AND
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  store i64 1, i64* @.sc.215
  %r12 = icmp eq i64 %r10, 0
  br i1 %r12, label %L562, label %L563
L562:
  %r13 = load i64, i64* %ptr_t
  %r14 = getelementptr [5 x i8], [5 x i8]* @.str.217, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_get(i64 %r13, i64 %r15)
  %r17 = load i64, i64* @TOK_OR
  %r18 = call i64 @_eq(i64 %r16, i64 %r17)
  %r19 = icmp ne i64 %r18, 0
  %r20 = zext i1 %r19 to i64
  store i64 %r20, i64* @.sc.215
  br label %L563
L563:
  %r11 = load i64, i64* @.sc.215
  %r21 = icmp ne i64 %r11, 0
  br i1 %r21, label %L564, label %L566
L564:
  store i64 1, i64* %ptr_is_op
  br label %L566
L566:
  %r22 = load i64, i64* %ptr_is_op
  %r23 = icmp ne i64 %r22, 0
  br i1 %r23, label %L567, label %L568
L567:
  %r24 = getelementptr [3 x i8], [3 x i8]* @.str.218, i64 0, i64 0
  %r25 = ptrtoint i8* %r24 to i64
  store i64 %r25, i64* %ptr_op
  %r26 = load i64, i64* %ptr_t
  %r27 = getelementptr [5 x i8], [5 x i8]* @.str.219, i64 0, i64 0
  %r28 = ptrtoint i8* %r27 to i64
  %r29 = call i64 @_get(i64 %r26, i64 %r28)
  %r30 = load i64, i64* @TOK_OR
  %r31 = call i64 @_eq(i64 %r29, i64 %r30)
  %r32 = icmp ne i64 %r31, 0
  br i1 %r32, label %L570, label %L572
L570:
  %r33 = getelementptr [4 x i8], [4 x i8]* @.str.220, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  store i64 %r34, i64* %ptr_op
  br label %L572
L572:
  %r35 = call i64 @advance()
  %r36 = call i64 @parse_cmp()
  store i64 %r36, i64* %ptr_right
  %r37 = call i64 @_map_new()
  %r38 = getelementptr [5 x i8], [5 x i8]* @.str.221, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = load i64, i64* @EXPR_BINARY
  call i64 @_map_set(i64 %r37, i64 %r39, i64 %r40)
  %r41 = getelementptr [3 x i8], [3 x i8]* @.str.222, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = load i64, i64* %ptr_op
  call i64 @_map_set(i64 %r37, i64 %r42, i64 %r43)
  %r44 = getelementptr [5 x i8], [5 x i8]* @.str.223, i64 0, i64 0
  %r45 = ptrtoint i8* %r44 to i64
  %r46 = load i64, i64* %ptr_left
  call i64 @_map_set(i64 %r37, i64 %r45, i64 %r46)
  %r47 = getelementptr [6 x i8], [6 x i8]* @.str.224, i64 0, i64 0
  %r48 = ptrtoint i8* %r47 to i64
  %r49 = load i64, i64* %ptr_right
  call i64 @_map_set(i64 %r37, i64 %r48, i64 %r49)
  store i64 %r37, i64* %ptr_left
  %r50 = call i64 @peek()
  store i64 %r50, i64* %ptr_t
  br label %L569
L568:
  store i64 0, i64* %ptr_running
  br label %L569
L569:
  br label %L559
L561:
  %r51 = load i64, i64* %ptr_left
  ret i64 %r51
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
  %r1 = getelementptr [24 x i8], [24 x i8]* @.str.225, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  call i64 @print_any(i64 %r2)
  %r3 = call i64 @peek()
  store i64 %r3, i64* %ptr_t
  %r4 = sub i64 0, 1
  store i64 %r4, i64* %ptr_stmt_type
  %r5 = load i64, i64* %ptr_t
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.226, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_get(i64 %r5, i64 %r7)
  %r9 = load i64, i64* @TOK_LET
  %r10 = call i64 @_eq(i64 %r8, i64 %r9)
  %r11 = icmp ne i64 %r10, 0
  br i1 %r11, label %L573, label %L574
L573:
  %r12 = load i64, i64* @STMT_LET
  store i64 %r12, i64* %ptr_stmt_type
  %r13 = load i64, i64* @TOK_LET
  %r14 = call i64 @consume(i64 %r13)
  br label %L575
L574:
  %r15 = load i64, i64* %ptr_t
  %r16 = getelementptr [5 x i8], [5 x i8]* @.str.227, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  %r18 = call i64 @_get(i64 %r15, i64 %r17)
  %r19 = load i64, i64* @TOK_SHARED
  %r20 = call i64 @_eq(i64 %r18, i64 %r19)
  %r21 = icmp ne i64 %r20, 0
  br i1 %r21, label %L576, label %L577
L576:
  %r22 = load i64, i64* @STMT_SHARED
  store i64 %r22, i64* %ptr_stmt_type
  %r23 = load i64, i64* @TOK_SHARED
  %r24 = call i64 @consume(i64 %r23)
  br label %L578
L577:
  %r25 = load i64, i64* %ptr_t
  %r26 = getelementptr [5 x i8], [5 x i8]* @.str.228, i64 0, i64 0
  %r27 = ptrtoint i8* %r26 to i64
  %r28 = call i64 @_get(i64 %r25, i64 %r27)
  %r29 = load i64, i64* @TOK_CONST
  %r30 = call i64 @_eq(i64 %r28, i64 %r29)
  %r31 = icmp ne i64 %r30, 0
  br i1 %r31, label %L579, label %L581
L579:
  %r32 = load i64, i64* @STMT_CONST
  store i64 %r32, i64* %ptr_stmt_type
  %r33 = load i64, i64* @TOK_CONST
  %r34 = call i64 @consume(i64 %r33)
  br label %L581
L581:
  br label %L578
L578:
  br label %L575
L575:
  %r35 = load i64, i64* %ptr_stmt_type
  %r36 = sub i64 0, 1
  %r38 = call i64 @_eq(i64 %r35, i64 %r36)
  %r37 = xor i64 %r38, 1
  %r39 = icmp ne i64 %r37, 0
  br i1 %r39, label %L582, label %L584
L582:
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
  %r50 = getelementptr [5 x i8], [5 x i8]* @.str.229, i64 0, i64 0
  %r51 = ptrtoint i8* %r50 to i64
  %r52 = load i64, i64* %ptr_stmt_type
  call i64 @_map_set(i64 %r49, i64 %r51, i64 %r52)
  %r53 = getelementptr [5 x i8], [5 x i8]* @.str.230, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = load i64, i64* %ptr_name
  %r56 = getelementptr [5 x i8], [5 x i8]* @.str.231, i64 0, i64 0
  %r57 = ptrtoint i8* %r56 to i64
  %r58 = call i64 @_get(i64 %r55, i64 %r57)
  call i64 @_map_set(i64 %r49, i64 %r54, i64 %r58)
  %r59 = getelementptr [4 x i8], [4 x i8]* @.str.232, i64 0, i64 0
  %r60 = ptrtoint i8* %r59 to i64
  %r61 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r49, i64 %r60, i64 %r61)
  ret i64 %r49
  br label %L584
L584:
  %r62 = load i64, i64* @TOK_PRINT
  %r63 = call i64 @consume(i64 %r62)
  %r64 = icmp ne i64 %r63, 0
  br i1 %r64, label %L585, label %L587
L585:
  %r65 = load i64, i64* @TOK_LPAREN
  %r66 = call i64 @expect(i64 %r65)
  %r67 = call i64 @parse_expr()
  store i64 %r67, i64* %ptr_val
  %r68 = load i64, i64* @TOK_RPAREN
  %r69 = call i64 @expect(i64 %r68)
  %r70 = load i64, i64* @TOK_CARET
  %r71 = call i64 @expect(i64 %r70)
  %r72 = call i64 @_map_new()
  %r73 = getelementptr [5 x i8], [5 x i8]* @.str.233, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = load i64, i64* @STMT_PRINT
  call i64 @_map_set(i64 %r72, i64 %r74, i64 %r75)
  %r76 = getelementptr [4 x i8], [4 x i8]* @.str.234, i64 0, i64 0
  %r77 = ptrtoint i8* %r76 to i64
  %r78 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r72, i64 %r77, i64 %r78)
  ret i64 %r72
  br label %L587
L587:
  %r79 = load i64, i64* @TOK_IF
  %r80 = call i64 @consume(i64 %r79)
  %r81 = icmp ne i64 %r80, 0
  br i1 %r81, label %L588, label %L590
L588:
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
  br label %L591
L591:
  %r90 = call i64 @peek()
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.235, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = load i64, i64* @TOK_RBRACE
  %r96 = call i64 @_eq(i64 %r93, i64 %r94)
  %r95 = xor i64 %r96, 1
  %r97 = icmp ne i64 %r95, 0
  br i1 %r97, label %L592, label %L593
L592:
  %r98 = call i64 @peek()
  %r99 = getelementptr [5 x i8], [5 x i8]* @.str.236, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_get(i64 %r98, i64 %r100)
  %r102 = load i64, i64* @TOK_CARET
  %r103 = call i64 @_eq(i64 %r101, i64 %r102)
  %r104 = icmp ne i64 %r103, 0
  br i1 %r104, label %L594, label %L596
L594:
  %r105 = call i64 @advance()
  br label %L591
L596:
  %r106 = call i64 @parse_stmt()
  %r107 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r107, i64 %r106)
  br label %L591
L593:
  %r108 = load i64, i64* @TOK_RBRACE
  %r109 = call i64 @expect(i64 %r108)
  %r110 = call i64 @_list_new()
  store i64 %r110, i64* %ptr_else_body
  %r111 = load i64, i64* @TOK_ELSE
  %r112 = call i64 @consume(i64 %r111)
  %r113 = icmp ne i64 %r112, 0
  br i1 %r113, label %L597, label %L599
L597:
  %r114 = call i64 @peek()
  %r115 = getelementptr [5 x i8], [5 x i8]* @.str.237, i64 0, i64 0
  %r116 = ptrtoint i8* %r115 to i64
  %r117 = call i64 @_get(i64 %r114, i64 %r116)
  %r118 = load i64, i64* @TOK_IF
  %r119 = call i64 @_eq(i64 %r117, i64 %r118)
  %r120 = icmp ne i64 %r119, 0
  br i1 %r120, label %L600, label %L601
L600:
  %r121 = call i64 @parse_stmt()
  %r122 = load i64, i64* %ptr_else_body
  call i64 @_append_poly(i64 %r122, i64 %r121)
  br label %L602
L601:
  %r123 = load i64, i64* @TOK_LBRACE
  %r124 = call i64 @expect(i64 %r123)
  br label %L603
L603:
  %r125 = call i64 @peek()
  %r126 = getelementptr [5 x i8], [5 x i8]* @.str.238, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = load i64, i64* @TOK_RBRACE
  %r131 = call i64 @_eq(i64 %r128, i64 %r129)
  %r130 = xor i64 %r131, 1
  %r132 = icmp ne i64 %r130, 0
  br i1 %r132, label %L604, label %L605
L604:
  %r133 = call i64 @peek()
  %r134 = getelementptr [5 x i8], [5 x i8]* @.str.239, i64 0, i64 0
  %r135 = ptrtoint i8* %r134 to i64
  %r136 = call i64 @_get(i64 %r133, i64 %r135)
  %r137 = load i64, i64* @TOK_CARET
  %r138 = call i64 @_eq(i64 %r136, i64 %r137)
  %r139 = icmp ne i64 %r138, 0
  br i1 %r139, label %L606, label %L608
L606:
  %r140 = call i64 @advance()
  br label %L603
L608:
  %r141 = call i64 @parse_stmt()
  %r142 = load i64, i64* %ptr_else_body
  call i64 @_append_poly(i64 %r142, i64 %r141)
  br label %L603
L605:
  %r143 = load i64, i64* @TOK_RBRACE
  %r144 = call i64 @expect(i64 %r143)
  br label %L602
L602:
  br label %L599
L599:
  %r145 = call i64 @_map_new()
  %r146 = getelementptr [5 x i8], [5 x i8]* @.str.240, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = load i64, i64* @STMT_IF
  call i64 @_map_set(i64 %r145, i64 %r147, i64 %r148)
  %r149 = getelementptr [5 x i8], [5 x i8]* @.str.241, i64 0, i64 0
  %r150 = ptrtoint i8* %r149 to i64
  %r151 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r145, i64 %r150, i64 %r151)
  %r152 = getelementptr [5 x i8], [5 x i8]* @.str.242, i64 0, i64 0
  %r153 = ptrtoint i8* %r152 to i64
  %r154 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r145, i64 %r153, i64 %r154)
  %r155 = getelementptr [5 x i8], [5 x i8]* @.str.243, i64 0, i64 0
  %r156 = ptrtoint i8* %r155 to i64
  %r157 = load i64, i64* %ptr_else_body
  call i64 @_map_set(i64 %r145, i64 %r156, i64 %r157)
  ret i64 %r145
  br label %L590
L590:
  %r158 = load i64, i64* @TOK_WHILE
  %r159 = call i64 @consume(i64 %r158)
  %r160 = icmp ne i64 %r159, 0
  br i1 %r160, label %L609, label %L611
L609:
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
  br label %L612
L612:
  %r169 = call i64 @peek()
  %r170 = getelementptr [5 x i8], [5 x i8]* @.str.244, i64 0, i64 0
  %r171 = ptrtoint i8* %r170 to i64
  %r172 = call i64 @_get(i64 %r169, i64 %r171)
  %r173 = load i64, i64* @TOK_RBRACE
  %r175 = call i64 @_eq(i64 %r172, i64 %r173)
  %r174 = xor i64 %r175, 1
  %r176 = icmp ne i64 %r174, 0
  br i1 %r176, label %L613, label %L614
L613:
  %r177 = call i64 @parse_stmt()
  %r178 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r178, i64 %r177)
  br label %L612
L614:
  %r179 = load i64, i64* @TOK_RBRACE
  %r180 = call i64 @expect(i64 %r179)
  %r181 = call i64 @_map_new()
  %r182 = getelementptr [5 x i8], [5 x i8]* @.str.245, i64 0, i64 0
  %r183 = ptrtoint i8* %r182 to i64
  %r184 = load i64, i64* @STMT_WHILE
  call i64 @_map_set(i64 %r181, i64 %r183, i64 %r184)
  %r185 = getelementptr [5 x i8], [5 x i8]* @.str.246, i64 0, i64 0
  %r186 = ptrtoint i8* %r185 to i64
  %r187 = load i64, i64* %ptr_cond
  call i64 @_map_set(i64 %r181, i64 %r186, i64 %r187)
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.247, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r181, i64 %r189, i64 %r190)
  ret i64 %r181
  br label %L611
L611:
  %r191 = load i64, i64* @TOK_OPUS
  %r192 = call i64 @consume(i64 %r191)
  %r193 = icmp ne i64 %r192, 0
  br i1 %r193, label %L615, label %L617
L615:
  %r194 = call i64 @advance()
  store i64 %r194, i64* %ptr_name
  %r195 = load i64, i64* @TOK_LPAREN
  %r196 = call i64 @expect(i64 %r195)
  %r197 = call i64 @_list_new()
  store i64 %r197, i64* %ptr_params
  %r198 = call i64 @peek()
  %r199 = getelementptr [5 x i8], [5 x i8]* @.str.248, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  %r202 = load i64, i64* @TOK_RPAREN
  %r204 = call i64 @_eq(i64 %r201, i64 %r202)
  %r203 = xor i64 %r204, 1
  %r205 = icmp ne i64 %r203, 0
  br i1 %r205, label %L618, label %L620
L618:
  %r206 = call i64 @advance()
  store i64 %r206, i64* %ptr_p
  %r207 = load i64, i64* %ptr_p
  %r208 = getelementptr [5 x i8], [5 x i8]* @.str.249, i64 0, i64 0
  %r209 = ptrtoint i8* %r208 to i64
  %r210 = call i64 @_get(i64 %r207, i64 %r209)
  %r211 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r211, i64 %r210)
  br label %L621
L621:
  %r212 = load i64, i64* @TOK_COMMA
  %r213 = call i64 @consume(i64 %r212)
  %r214 = icmp ne i64 %r213, 0
  br i1 %r214, label %L622, label %L623
L622:
  %r215 = call i64 @advance()
  store i64 %r215, i64* %ptr_p
  %r216 = load i64, i64* %ptr_p
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.250, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_get(i64 %r216, i64 %r218)
  %r220 = load i64, i64* %ptr_params
  call i64 @_append_poly(i64 %r220, i64 %r219)
  br label %L621
L623:
  br label %L620
L620:
  %r221 = load i64, i64* @TOK_RPAREN
  %r222 = call i64 @expect(i64 %r221)
  %r223 = load i64, i64* @TOK_LBRACE
  %r224 = call i64 @expect(i64 %r223)
  %r225 = call i64 @_list_new()
  store i64 %r225, i64* %ptr_body
  br label %L624
L624:
  %r226 = call i64 @peek()
  %r227 = getelementptr [5 x i8], [5 x i8]* @.str.251, i64 0, i64 0
  %r228 = ptrtoint i8* %r227 to i64
  %r229 = call i64 @_get(i64 %r226, i64 %r228)
  %r230 = load i64, i64* @TOK_RBRACE
  %r232 = call i64 @_eq(i64 %r229, i64 %r230)
  %r231 = xor i64 %r232, 1
  %r233 = icmp ne i64 %r231, 0
  br i1 %r233, label %L625, label %L626
L625:
  %r234 = call i64 @parse_stmt()
  %r235 = load i64, i64* %ptr_body
  call i64 @_append_poly(i64 %r235, i64 %r234)
  br label %L624
L626:
  %r236 = load i64, i64* @TOK_RBRACE
  %r237 = call i64 @expect(i64 %r236)
  %r238 = call i64 @_map_new()
  %r239 = getelementptr [5 x i8], [5 x i8]* @.str.252, i64 0, i64 0
  %r240 = ptrtoint i8* %r239 to i64
  %r241 = load i64, i64* @STMT_FUNC
  call i64 @_map_set(i64 %r238, i64 %r240, i64 %r241)
  %r242 = getelementptr [5 x i8], [5 x i8]* @.str.253, i64 0, i64 0
  %r243 = ptrtoint i8* %r242 to i64
  %r244 = load i64, i64* %ptr_name
  %r245 = getelementptr [5 x i8], [5 x i8]* @.str.254, i64 0, i64 0
  %r246 = ptrtoint i8* %r245 to i64
  %r247 = call i64 @_get(i64 %r244, i64 %r246)
  call i64 @_map_set(i64 %r238, i64 %r243, i64 %r247)
  %r248 = getelementptr [7 x i8], [7 x i8]* @.str.255, i64 0, i64 0
  %r249 = ptrtoint i8* %r248 to i64
  %r250 = load i64, i64* %ptr_params
  call i64 @_map_set(i64 %r238, i64 %r249, i64 %r250)
  %r251 = getelementptr [5 x i8], [5 x i8]* @.str.256, i64 0, i64 0
  %r252 = ptrtoint i8* %r251 to i64
  %r253 = load i64, i64* %ptr_body
  call i64 @_map_set(i64 %r238, i64 %r252, i64 %r253)
  ret i64 %r238
  br label %L617
L617:
  %r254 = load i64, i64* @TOK_REDDO
  %r255 = call i64 @consume(i64 %r254)
  %r256 = icmp ne i64 %r255, 0
  br i1 %r256, label %L627, label %L629
L627:
  %r257 = call i64 @parse_expr()
  store i64 %r257, i64* %ptr_val
  %r258 = load i64, i64* @TOK_CARET
  %r259 = call i64 @expect(i64 %r258)
  %r260 = call i64 @_map_new()
  %r261 = getelementptr [5 x i8], [5 x i8]* @.str.257, i64 0, i64 0
  %r262 = ptrtoint i8* %r261 to i64
  %r263 = load i64, i64* @STMT_RETURN
  call i64 @_map_set(i64 %r260, i64 %r262, i64 %r263)
  %r264 = getelementptr [4 x i8], [4 x i8]* @.str.258, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r260, i64 %r265, i64 %r266)
  ret i64 %r260
  br label %L629
L629:
  %r267 = load i64, i64* @TOK_BREAK
  %r268 = call i64 @consume(i64 %r267)
  %r269 = icmp ne i64 %r268, 0
  br i1 %r269, label %L630, label %L632
L630:
  %r270 = load i64, i64* @TOK_CARET
  %r271 = call i64 @expect(i64 %r270)
  %r272 = call i64 @_map_new()
  %r273 = getelementptr [5 x i8], [5 x i8]* @.str.259, i64 0, i64 0
  %r274 = ptrtoint i8* %r273 to i64
  %r275 = load i64, i64* @STMT_BREAK
  call i64 @_map_set(i64 %r272, i64 %r274, i64 %r275)
  ret i64 %r272
  br label %L632
L632:
  %r276 = load i64, i64* @TOK_CONTINUE
  %r277 = call i64 @consume(i64 %r276)
  %r278 = icmp ne i64 %r277, 0
  br i1 %r278, label %L633, label %L635
L633:
  %r279 = load i64, i64* @TOK_CARET
  %r280 = call i64 @expect(i64 %r279)
  %r281 = call i64 @_map_new()
  %r282 = getelementptr [5 x i8], [5 x i8]* @.str.260, i64 0, i64 0
  %r283 = ptrtoint i8* %r282 to i64
  %r284 = load i64, i64* @STMT_CONTINUE
  call i64 @_map_set(i64 %r281, i64 %r283, i64 %r284)
  ret i64 %r281
  br label %L635
L635:
  %r285 = load i64, i64* @TOK_IMPORT
  %r286 = call i64 @consume(i64 %r285)
  %r287 = icmp ne i64 %r286, 0
  br i1 %r287, label %L636, label %L638
L636:
  %r288 = load i64, i64* @TOK_LPAREN
  %r289 = call i64 @expect(i64 %r288)
  %r290 = call i64 @parse_expr()
  store i64 %r290, i64* %ptr_path
  %r291 = load i64, i64* @TOK_RPAREN
  %r292 = call i64 @expect(i64 %r291)
  %r293 = load i64, i64* @TOK_CARET
  %r294 = call i64 @expect(i64 %r293)
  %r295 = call i64 @_map_new()
  %r296 = getelementptr [5 x i8], [5 x i8]* @.str.261, i64 0, i64 0
  %r297 = ptrtoint i8* %r296 to i64
  %r298 = load i64, i64* @STMT_IMPORT
  call i64 @_map_set(i64 %r295, i64 %r297, i64 %r298)
  %r299 = getelementptr [4 x i8], [4 x i8]* @.str.262, i64 0, i64 0
  %r300 = ptrtoint i8* %r299 to i64
  %r301 = load i64, i64* %ptr_path
  call i64 @_map_set(i64 %r295, i64 %r300, i64 %r301)
  ret i64 %r295
  br label %L638
L638:
  %r302 = load i64, i64* %ptr_t
  %r303 = getelementptr [5 x i8], [5 x i8]* @.str.263, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_get(i64 %r302, i64 %r304)
  %r306 = load i64, i64* @TOK_IDENT
  %r307 = call i64 @_eq(i64 %r305, i64 %r306)
  %r308 = icmp ne i64 %r307, 0
  br i1 %r308, label %L639, label %L641
L639:
  %r309 = load i64, i64* @p_pos
  %r310 = call i64 @_add(i64 %r309, i64 1)
  store i64 %r310, i64* %ptr_next_idx
  %r311 = load i64, i64* %ptr_next_idx
  %r312 = load i64, i64* @global_tokens
  %r313 = call i64 @mensura(i64 %r312)
  %r315 = icmp sge i64 %r311, %r313
  %r314 = zext i1 %r315 to i64
  %r316 = icmp ne i64 %r314, 0
  br i1 %r316, label %L642, label %L644
L642:
  %r317 = getelementptr [15 x i8], [15 x i8]* @.str.264, i64 0, i64 0
  %r318 = ptrtoint i8* %r317 to i64
  %r319 = call i64 @error_report(i64 %r318)
  %r320 = call i64 @_map_new()
  %r321 = getelementptr [5 x i8], [5 x i8]* @.str.265, i64 0, i64 0
  %r322 = ptrtoint i8* %r321 to i64
  %r323 = sub i64 0, 1
  call i64 @_map_set(i64 %r320, i64 %r322, i64 %r323)
  ret i64 %r320
  br label %L644
L644:
  %r324 = load i64, i64* @global_tokens
  %r325 = load i64, i64* %ptr_next_idx
  %r326 = call i64 @_get(i64 %r324, i64 %r325)
  store i64 %r326, i64* %ptr_next
  %r327 = load i64, i64* %ptr_next
  %r328 = getelementptr [5 x i8], [5 x i8]* @.str.266, i64 0, i64 0
  %r329 = ptrtoint i8* %r328 to i64
  %r330 = call i64 @_get(i64 %r327, i64 %r329)
  %r331 = load i64, i64* @TOK_ARROW
  %r332 = call i64 @_eq(i64 %r330, i64 %r331)
  %r333 = icmp ne i64 %r332, 0
  br i1 %r333, label %L645, label %L647
L645:
  %r334 = call i64 @advance()
  store i64 %r334, i64* %ptr_name
  %r335 = call i64 @advance()
  %r336 = call i64 @parse_expr()
  store i64 %r336, i64* %ptr_val
  %r337 = load i64, i64* @TOK_CARET
  %r338 = call i64 @expect(i64 %r337)
  %r339 = call i64 @_map_new()
  %r340 = getelementptr [5 x i8], [5 x i8]* @.str.267, i64 0, i64 0
  %r341 = ptrtoint i8* %r340 to i64
  %r342 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r339, i64 %r341, i64 %r342)
  %r343 = getelementptr [5 x i8], [5 x i8]* @.str.268, i64 0, i64 0
  %r344 = ptrtoint i8* %r343 to i64
  %r345 = load i64, i64* %ptr_name
  %r346 = getelementptr [5 x i8], [5 x i8]* @.str.269, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = call i64 @_get(i64 %r345, i64 %r347)
  call i64 @_map_set(i64 %r339, i64 %r344, i64 %r348)
  %r349 = getelementptr [4 x i8], [4 x i8]* @.str.270, i64 0, i64 0
  %r350 = ptrtoint i8* %r349 to i64
  %r351 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r339, i64 %r350, i64 %r351)
  ret i64 %r339
  br label %L647
L647:
  %r352 = load i64, i64* %ptr_next
  %r353 = getelementptr [5 x i8], [5 x i8]* @.str.271, i64 0, i64 0
  %r354 = ptrtoint i8* %r353 to i64
  %r355 = call i64 @_get(i64 %r352, i64 %r354)
  %r356 = load i64, i64* @TOK_APPEND
  %r357 = call i64 @_eq(i64 %r355, i64 %r356)
  %r358 = icmp ne i64 %r357, 0
  br i1 %r358, label %L648, label %L650
L648:
  %r359 = call i64 @advance()
  store i64 %r359, i64* %ptr_name
  %r360 = call i64 @advance()
  %r361 = call i64 @parse_expr()
  store i64 %r361, i64* %ptr_val
  %r362 = load i64, i64* @TOK_CARET
  %r363 = call i64 @expect(i64 %r362)
  %r364 = call i64 @_map_new()
  %r365 = getelementptr [5 x i8], [5 x i8]* @.str.272, i64 0, i64 0
  %r366 = ptrtoint i8* %r365 to i64
  %r367 = load i64, i64* @STMT_APPEND
  call i64 @_map_set(i64 %r364, i64 %r366, i64 %r367)
  %r368 = getelementptr [5 x i8], [5 x i8]* @.str.273, i64 0, i64 0
  %r369 = ptrtoint i8* %r368 to i64
  %r370 = load i64, i64* %ptr_name
  %r371 = getelementptr [5 x i8], [5 x i8]* @.str.274, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_get(i64 %r370, i64 %r372)
  call i64 @_map_set(i64 %r364, i64 %r369, i64 %r373)
  %r374 = getelementptr [4 x i8], [4 x i8]* @.str.275, i64 0, i64 0
  %r375 = ptrtoint i8* %r374 to i64
  %r376 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r364, i64 %r375, i64 %r376)
  ret i64 %r364
  br label %L650
L650:
  %r377 = load i64, i64* %ptr_next
  %r378 = getelementptr [5 x i8], [5 x i8]* @.str.276, i64 0, i64 0
  %r379 = ptrtoint i8* %r378 to i64
  %r380 = call i64 @_get(i64 %r377, i64 %r379)
  %r381 = load i64, i64* @TOK_LBRACKET
  %r382 = call i64 @_eq(i64 %r380, i64 %r381)
  %r383 = icmp ne i64 %r382, 0
  br i1 %r383, label %L651, label %L653
L651:
  %r384 = call i64 @parse_expr()
  store i64 %r384, i64* %ptr_lhs
  %r385 = load i64, i64* @TOK_ARROW
  %r386 = call i64 @consume(i64 %r385)
  %r387 = icmp ne i64 %r386, 0
  br i1 %r387, label %L654, label %L656
L654:
  %r388 = call i64 @parse_expr()
  store i64 %r388, i64* %ptr_val
  %r389 = load i64, i64* @TOK_CARET
  %r390 = call i64 @expect(i64 %r389)
  %r391 = load i64, i64* %ptr_lhs
  %r392 = getelementptr [5 x i8], [5 x i8]* @.str.277, i64 0, i64 0
  %r393 = ptrtoint i8* %r392 to i64
  %r394 = call i64 @_get(i64 %r391, i64 %r393)
  %r395 = load i64, i64* @EXPR_INDEX
  %r396 = call i64 @_eq(i64 %r394, i64 %r395)
  %r397 = icmp ne i64 %r396, 0
  br i1 %r397, label %L657, label %L659
L657:
  %r398 = load i64, i64* %ptr_lhs
  %r399 = getelementptr [4 x i8], [4 x i8]* @.str.278, i64 0, i64 0
  %r400 = ptrtoint i8* %r399 to i64
  %r401 = call i64 @_get(i64 %r398, i64 %r400)
  store i64 %r401, i64* %ptr_arr_nm
  %r402 = call i64 @_map_new()
  %r403 = getelementptr [5 x i8], [5 x i8]* @.str.279, i64 0, i64 0
  %r404 = ptrtoint i8* %r403 to i64
  %r405 = load i64, i64* @STMT_SET_INDEX
  call i64 @_map_set(i64 %r402, i64 %r404, i64 %r405)
  %r406 = getelementptr [5 x i8], [5 x i8]* @.str.280, i64 0, i64 0
  %r407 = ptrtoint i8* %r406 to i64
  %r408 = load i64, i64* %ptr_arr_nm
  %r409 = getelementptr [5 x i8], [5 x i8]* @.str.281, i64 0, i64 0
  %r410 = ptrtoint i8* %r409 to i64
  %r411 = call i64 @_get(i64 %r408, i64 %r410)
  call i64 @_map_set(i64 %r402, i64 %r407, i64 %r411)
  %r412 = getelementptr [4 x i8], [4 x i8]* @.str.282, i64 0, i64 0
  %r413 = ptrtoint i8* %r412 to i64
  %r414 = load i64, i64* %ptr_lhs
  %r415 = getelementptr [4 x i8], [4 x i8]* @.str.283, i64 0, i64 0
  %r416 = ptrtoint i8* %r415 to i64
  %r417 = call i64 @_get(i64 %r414, i64 %r416)
  call i64 @_map_set(i64 %r402, i64 %r413, i64 %r417)
  %r418 = getelementptr [4 x i8], [4 x i8]* @.str.284, i64 0, i64 0
  %r419 = ptrtoint i8* %r418 to i64
  %r420 = load i64, i64* %ptr_val
  call i64 @_map_set(i64 %r402, i64 %r419, i64 %r420)
  ret i64 %r402
  br label %L659
L659:
  br label %L656
L656:
  br label %L653
L653:
  %r421 = load i64, i64* %ptr_next
  %r422 = getelementptr [5 x i8], [5 x i8]* @.str.285, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_get(i64 %r421, i64 %r423)
  %r425 = load i64, i64* @TOK_LPAREN
  %r426 = call i64 @_eq(i64 %r424, i64 %r425)
  %r427 = icmp ne i64 %r426, 0
  br i1 %r427, label %L660, label %L662
L660:
  %r428 = call i64 @parse_expr()
  store i64 %r428, i64* %ptr_expr
  %r429 = load i64, i64* @TOK_CARET
  %r430 = call i64 @expect(i64 %r429)
  %r431 = call i64 @_map_new()
  %r432 = getelementptr [5 x i8], [5 x i8]* @.str.286, i64 0, i64 0
  %r433 = ptrtoint i8* %r432 to i64
  %r434 = load i64, i64* @STMT_EXPR
  call i64 @_map_set(i64 %r431, i64 %r433, i64 %r434)
  %r435 = getelementptr [5 x i8], [5 x i8]* @.str.287, i64 0, i64 0
  %r436 = ptrtoint i8* %r435 to i64
  %r437 = load i64, i64* %ptr_expr
  call i64 @_map_set(i64 %r431, i64 %r436, i64 %r437)
  ret i64 %r431
  br label %L662
L662:
  br label %L641
L641:
  %r438 = load i64, i64* %ptr_t
  %r439 = getelementptr [5 x i8], [5 x i8]* @.str.288, i64 0, i64 0
  %r440 = ptrtoint i8* %r439 to i64
  %r441 = call i64 @_get(i64 %r438, i64 %r440)
  %r442 = load i64, i64* @TOK_EOF
  %r444 = call i64 @_eq(i64 %r441, i64 %r442)
  %r443 = xor i64 %r444, 1
  %r445 = icmp ne i64 %r443, 0
  br i1 %r445, label %L663, label %L665
L663:
  %r446 = call i64 @advance()
  br label %L665
L665:
  %r447 = call i64 @_map_new()
  %r448 = getelementptr [5 x i8], [5 x i8]* @.str.289, i64 0, i64 0
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
  %r3 = getelementptr [3 x i8], [3 x i8]* @.str.290, i64 0, i64 0
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
  %r3 = getelementptr [2 x i8], [2 x i8]* @.str.291, i64 0, i64 0
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
  %r2 = getelementptr [3 x i8], [3 x i8]* @.str.292, i64 0, i64 0
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
  %r1 = getelementptr [1 x i8], [1 x i8]* @.str.293, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  store i64 %r2, i64* %ptr_out
  %r3 = load i64, i64* %ptr_s
  %r4 = call i64 @mensura(i64 %r3)
  store i64 %r4, i64* %ptr_len
  store i64 0, i64* %ptr_i
  br label %L666
L666:
  %r5 = load i64, i64* %ptr_i
  %r6 = load i64, i64* %ptr_len
  %r8 = icmp slt i64 %r5, %r6
  %r7 = zext i1 %r8 to i64
  %r9 = icmp ne i64 %r7, 0
  br i1 %r9, label %L667, label %L668
L667:
  %r10 = load i64, i64* %ptr_s
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @pars(i64 %r10, i64 %r11, i64 1)
  store i64 %r12, i64* %ptr_c
  %r13 = load i64, i64* %ptr_c
  %r14 = getelementptr [2 x i8], [2 x i8]* @.str.294, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_eq(i64 %r13, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L669, label %L670
L669:
  %r18 = load i64, i64* %ptr_out
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.295, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  store i64 %r21, i64* %ptr_out
  br label %L671
L670:
  %r22 = load i64, i64* %ptr_c
  %r23 = getelementptr [2 x i8], [2 x i8]* @.str.296, i64 0, i64 0
  %r24 = ptrtoint i8* %r23 to i64
  %r25 = call i64 @_eq(i64 %r22, i64 %r24)
  %r26 = icmp ne i64 %r25, 0
  br i1 %r26, label %L672, label %L673
L672:
  %r27 = load i64, i64* %ptr_out
  %r28 = getelementptr [4 x i8], [4 x i8]* @.str.297, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = call i64 @_add(i64 %r27, i64 %r29)
  store i64 %r30, i64* %ptr_out
  br label %L674
L673:
  %r31 = load i64, i64* %ptr_c
  %r32 = call i64 @codex(i64 %r31)
  %r33 = call i64 @_eq(i64 %r32, i64 10)
  %r34 = icmp ne i64 %r33, 0
  br i1 %r34, label %L675, label %L676
L675:
  %r35 = load i64, i64* %ptr_out
  %r36 = getelementptr [4 x i8], [4 x i8]* @.str.298, i64 0, i64 0
  %r37 = ptrtoint i8* %r36 to i64
  %r38 = call i64 @_add(i64 %r35, i64 %r37)
  store i64 %r38, i64* %ptr_out
  br label %L677
L676:
  %r39 = load i64, i64* %ptr_out
  %r40 = load i64, i64* %ptr_c
  %r41 = call i64 @_add(i64 %r39, i64 %r40)
  store i64 %r41, i64* %ptr_out
  br label %L677
L677:
  br label %L674
L674:
  br label %L671
L671:
  %r42 = load i64, i64* %ptr_i
  %r43 = call i64 @_add(i64 %r42, i64 1)
  store i64 %r43, i64* %ptr_i
  br label %L666
L668:
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
  %r3 = getelementptr [7 x i8], [7 x i8]* @.str.299, i64 0, i64 0
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
  %r14 = getelementptr [35 x i8], [35 x i8]* @.str.300, i64 0, i64 0
  %r15 = ptrtoint i8* %r14 to i64
  %r16 = call i64 @_add(i64 %r13, i64 %r15)
  %r17 = load i64, i64* %ptr_len
  %r18 = call i64 @int_to_str(i64 %r17)
  %r19 = call i64 @_add(i64 %r16, i64 %r18)
  %r20 = getelementptr [10 x i8], [10 x i8]* @.str.301, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_add(i64 %r19, i64 %r21)
  %r23 = load i64, i64* %ptr_safe_txt
  %r24 = call i64 @_add(i64 %r22, i64 %r23)
  %r25 = getelementptr [14 x i8], [14 x i8]* @.str.302, i64 0, i64 0
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
  br i1 %r8, label %L678, label %L680
L678:
  %r9 = load i64, i64* %ptr_ptr
  ret i64 %r9
  br label %L680
L680:
  %r10 = load i64, i64* @global_map
  %r11 = load i64, i64* %ptr_name
  %r12 = call i64 @_get(i64 %r10, i64 %r11)
  store i64 %r12, i64* %ptr_ptr
  %r13 = load i64, i64* %ptr_ptr
  %r14 = call i64 @mensura(i64 %r13)
  %r16 = icmp sgt i64 %r14, 0
  %r15 = zext i1 %r16 to i64
  %r17 = icmp ne i64 %r15, 0
  br i1 %r17, label %L681, label %L683
L681:
  %r18 = load i64, i64* %ptr_ptr
  ret i64 %r18
  br label %L683
L683:
  %r19 = getelementptr [1 x i8], [1 x i8]* @.str.303, i64 0, i64 0
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
  %ptr_op = alloca i64
  %ptr_g_ptr = alloca i64
  %ptr_l_lhs = alloca i64
  %ptr_l_res = alloca i64
  %ptr_l_right = alloca i64
  %ptr_l_end = alloca i64
  %ptr_bool_l = alloca i64
  %ptr_l_rhs = alloca i64
  %ptr_bool_r = alloca i64
  %ptr_final_b = alloca i64
  %ptr_v_lhs = alloca i64
  %ptr_v_res = alloca i64
  %ptr_v_right = alloca i64
  %ptr_v_end = alloca i64
  %ptr_v_bool_l = alloca i64
  %ptr_v_rhs = alloca i64
  %ptr_v_bool_r = alloca i64
  %ptr_v_final_b = alloca i64
  %ptr_lhs = alloca i64
  %ptr_rhs = alloca i64
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
  %ptr_port_reg = alloca i64
  %ptr_port16 = alloca i64
  %ptr_val8 = alloca i64
  %ptr_res8 = alloca i64
  %ptr_res64 = alloca i64
  %ptr_val32 = alloca i64
  %ptr_res32 = alloca i64
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
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.304, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @EXPR_INT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L684, label %L686
L684:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.305, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  ret i64 %r11
  br label %L686
L686:
  %r12 = load i64, i64* %ptr_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.306, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_VAR
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L687, label %L689
L687:
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [5 x i8], [5 x i8]* @.str.307, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @get_var_ptr(i64 %r22)
  store i64 %r23, i64* %ptr_ptr
  %r24 = load i64, i64* %ptr_ptr
  %r25 = call i64 @mensura(i64 %r24)
  %r26 = call i64 @_eq(i64 %r25, i64 0)
  %r27 = icmp ne i64 %r26, 0
  br i1 %r27, label %L690, label %L692
L690:
  %r28 = getelementptr [33 x i8], [33 x i8]* @.str.308, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_node
  %r31 = getelementptr [5 x i8], [5 x i8]* @.str.309, i64 0, i64 0
  %r32 = ptrtoint i8* %r31 to i64
  %r33 = call i64 @_get(i64 %r30, i64 %r32)
  %r34 = call i64 @_add(i64 %r29, i64 %r33)
  %r35 = getelementptr [2 x i8], [2 x i8]* @.str.310, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_add(i64 %r34, i64 %r36)
  call i64 @print_any(i64 %r37)
  %r38 = getelementptr [2 x i8], [2 x i8]* @.str.311, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  ret i64 %r39
  br label %L692
L692:
  %r40 = call i64 @next_reg()
  store i64 %r40, i64* %ptr_res
  %r41 = load i64, i64* %ptr_res
  %r42 = getelementptr [19 x i8], [19 x i8]* @.str.312, i64 0, i64 0
  %r43 = ptrtoint i8* %r42 to i64
  %r44 = call i64 @_add(i64 %r41, i64 %r43)
  %r45 = load i64, i64* %ptr_ptr
  %r46 = call i64 @_add(i64 %r44, i64 %r45)
  %r47 = call i64 @emit(i64 %r46)
  %r48 = load i64, i64* %ptr_res
  ret i64 %r48
  br label %L689
L689:
  %r49 = load i64, i64* %ptr_node
  %r50 = getelementptr [5 x i8], [5 x i8]* @.str.313, i64 0, i64 0
  %r51 = ptrtoint i8* %r50 to i64
  %r52 = call i64 @_get(i64 %r49, i64 %r51)
  %r53 = load i64, i64* @EXPR_STRING
  %r54 = call i64 @_eq(i64 %r52, i64 %r53)
  %r55 = icmp ne i64 %r54, 0
  br i1 %r55, label %L693, label %L695
L693:
  %r56 = load i64, i64* %ptr_node
  %r57 = getelementptr [4 x i8], [4 x i8]* @.str.314, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = call i64 @_get(i64 %r56, i64 %r58)
  %r60 = call i64 @add_global_string(i64 %r59)
  store i64 %r60, i64* %ptr_global_ptr
  %r61 = call i64 @next_reg()
  store i64 %r61, i64* %ptr_res
  %r62 = load i64, i64* %ptr_node
  %r63 = getelementptr [4 x i8], [4 x i8]* @.str.315, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = call i64 @_get(i64 %r62, i64 %r64)
  %r66 = call i64 @mensura(i64 %r65)
  %r67 = call i64 @_add(i64 %r66, i64 1)
  store i64 %r67, i64* %ptr_len
  %r68 = load i64, i64* %ptr_res
  %r69 = getelementptr [19 x i8], [19 x i8]* @.str.316, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = call i64 @_add(i64 %r68, i64 %r70)
  %r72 = load i64, i64* %ptr_len
  %r73 = call i64 @int_to_str(i64 %r72)
  %r74 = call i64 @_add(i64 %r71, i64 %r73)
  %r75 = getelementptr [10 x i8], [10 x i8]* @.str.317, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = call i64 @_add(i64 %r74, i64 %r76)
  %r78 = load i64, i64* %ptr_len
  %r79 = call i64 @int_to_str(i64 %r78)
  %r80 = call i64 @_add(i64 %r77, i64 %r79)
  %r81 = getelementptr [9 x i8], [9 x i8]* @.str.318, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_add(i64 %r80, i64 %r82)
  %r84 = load i64, i64* %ptr_global_ptr
  %r85 = call i64 @_add(i64 %r83, i64 %r84)
  %r86 = getelementptr [15 x i8], [15 x i8]* @.str.319, i64 0, i64 0
  %r87 = ptrtoint i8* %r86 to i64
  %r88 = call i64 @_add(i64 %r85, i64 %r87)
  %r89 = call i64 @emit(i64 %r88)
  %r90 = call i64 @next_reg()
  store i64 %r90, i64* %ptr_cast_res
  %r91 = load i64, i64* %ptr_cast_res
  %r92 = getelementptr [17 x i8], [17 x i8]* @.str.320, i64 0, i64 0
  %r93 = ptrtoint i8* %r92 to i64
  %r94 = call i64 @_add(i64 %r91, i64 %r93)
  %r95 = load i64, i64* %ptr_res
  %r96 = call i64 @_add(i64 %r94, i64 %r95)
  %r97 = getelementptr [8 x i8], [8 x i8]* @.str.321, i64 0, i64 0
  %r98 = ptrtoint i8* %r97 to i64
  %r99 = call i64 @_add(i64 %r96, i64 %r98)
  %r100 = call i64 @emit(i64 %r99)
  %r101 = load i64, i64* %ptr_cast_res
  ret i64 %r101
  br label %L695
L695:
  %r102 = load i64, i64* %ptr_node
  %r103 = getelementptr [5 x i8], [5 x i8]* @.str.322, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = call i64 @_get(i64 %r102, i64 %r104)
  %r106 = load i64, i64* @EXPR_BINARY
  %r107 = call i64 @_eq(i64 %r105, i64 %r106)
  %r108 = icmp ne i64 %r107, 0
  br i1 %r108, label %L696, label %L698
L696:
  %r109 = load i64, i64* %ptr_node
  %r110 = getelementptr [3 x i8], [3 x i8]* @.str.323, i64 0, i64 0
  %r111 = ptrtoint i8* %r110 to i64
  %r112 = call i64 @_get(i64 %r109, i64 %r111)
  store i64 %r112, i64* %ptr_op
  %r113 = load i64, i64* %ptr_op
  %r114 = getelementptr [3 x i8], [3 x i8]* @.str.324, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_eq(i64 %r113, i64 %r115)
  %r117 = icmp ne i64 %r116, 0
  br i1 %r117, label %L699, label %L700
L699:
  %r118 = load i64, i64* @str_count
  %r119 = call i64 @_add(i64 %r118, i64 1)
  store i64 %r119, i64* @str_count
  %r120 = getelementptr [6 x i8], [6 x i8]* @.str.325, i64 0, i64 0
  %r121 = ptrtoint i8* %r120 to i64
  %r122 = load i64, i64* @str_count
  %r123 = call i64 @int_to_str(i64 %r122)
  %r124 = call i64 @_add(i64 %r121, i64 %r123)
  store i64 %r124, i64* %ptr_g_ptr
  %r125 = load i64, i64* @out_data
  %r126 = load i64, i64* %ptr_g_ptr
  %r127 = call i64 @_add(i64 %r125, i64 %r126)
  %r128 = getelementptr [16 x i8], [16 x i8]* @.str.326, i64 0, i64 0
  %r129 = ptrtoint i8* %r128 to i64
  %r130 = call i64 @_add(i64 %r127, i64 %r129)
  %r131 = call i64 @signum_ex(i64 10)
  %r132 = call i64 @_add(i64 %r130, i64 %r131)
  store i64 %r132, i64* @out_data
  %r133 = load i64, i64* %ptr_node
  %r134 = getelementptr [5 x i8], [5 x i8]* @.str.327, i64 0, i64 0
  %r135 = ptrtoint i8* %r134 to i64
  %r136 = call i64 @_get(i64 %r133, i64 %r135)
  %r137 = call i64 @compile_expr(i64 %r136)
  store i64 %r137, i64* %ptr_l_lhs
  %r138 = call i64 @next_reg()
  store i64 %r138, i64* %ptr_l_res
  %r139 = call i64 @next_label()
  store i64 %r139, i64* %ptr_l_right
  %r140 = call i64 @next_label()
  store i64 %r140, i64* %ptr_l_end
  %r141 = getelementptr [19 x i8], [19 x i8]* @.str.328, i64 0, i64 0
  %r142 = ptrtoint i8* %r141 to i64
  %r143 = load i64, i64* %ptr_g_ptr
  %r144 = call i64 @_add(i64 %r142, i64 %r143)
  %r145 = call i64 @emit(i64 %r144)
  %r146 = call i64 @next_reg()
  store i64 %r146, i64* %ptr_bool_l
  %r147 = load i64, i64* %ptr_bool_l
  %r148 = getelementptr [16 x i8], [16 x i8]* @.str.329, i64 0, i64 0
  %r149 = ptrtoint i8* %r148 to i64
  %r150 = call i64 @_add(i64 %r147, i64 %r149)
  %r151 = load i64, i64* %ptr_l_lhs
  %r152 = call i64 @_add(i64 %r150, i64 %r151)
  %r153 = getelementptr [4 x i8], [4 x i8]* @.str.330, i64 0, i64 0
  %r154 = ptrtoint i8* %r153 to i64
  %r155 = call i64 @_add(i64 %r152, i64 %r154)
  %r156 = call i64 @emit(i64 %r155)
  %r157 = getelementptr [7 x i8], [7 x i8]* @.str.331, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = load i64, i64* %ptr_bool_l
  %r160 = call i64 @_add(i64 %r158, i64 %r159)
  %r161 = getelementptr [10 x i8], [10 x i8]* @.str.332, i64 0, i64 0
  %r162 = ptrtoint i8* %r161 to i64
  %r163 = call i64 @_add(i64 %r160, i64 %r162)
  %r164 = load i64, i64* %ptr_l_right
  %r165 = call i64 @_add(i64 %r163, i64 %r164)
  %r166 = getelementptr [10 x i8], [10 x i8]* @.str.333, i64 0, i64 0
  %r167 = ptrtoint i8* %r166 to i64
  %r168 = call i64 @_add(i64 %r165, i64 %r167)
  %r169 = load i64, i64* %ptr_l_end
  %r170 = call i64 @_add(i64 %r168, i64 %r169)
  %r171 = call i64 @emit(i64 %r170)
  %r172 = load i64, i64* %ptr_l_right
  %r173 = getelementptr [2 x i8], [2 x i8]* @.str.334, i64 0, i64 0
  %r174 = ptrtoint i8* %r173 to i64
  %r175 = call i64 @_add(i64 %r172, i64 %r174)
  %r176 = call i64 @emit_raw(i64 %r175)
  %r177 = load i64, i64* %ptr_node
  %r178 = getelementptr [6 x i8], [6 x i8]* @.str.335, i64 0, i64 0
  %r179 = ptrtoint i8* %r178 to i64
  %r180 = call i64 @_get(i64 %r177, i64 %r179)
  %r181 = call i64 @compile_expr(i64 %r180)
  store i64 %r181, i64* %ptr_l_rhs
  %r182 = call i64 @next_reg()
  store i64 %r182, i64* %ptr_bool_r
  %r183 = load i64, i64* %ptr_bool_r
  %r184 = getelementptr [16 x i8], [16 x i8]* @.str.336, i64 0, i64 0
  %r185 = ptrtoint i8* %r184 to i64
  %r186 = call i64 @_add(i64 %r183, i64 %r185)
  %r187 = load i64, i64* %ptr_l_rhs
  %r188 = call i64 @_add(i64 %r186, i64 %r187)
  %r189 = getelementptr [4 x i8], [4 x i8]* @.str.337, i64 0, i64 0
  %r190 = ptrtoint i8* %r189 to i64
  %r191 = call i64 @_add(i64 %r188, i64 %r190)
  %r192 = call i64 @emit(i64 %r191)
  %r193 = call i64 @next_reg()
  store i64 %r193, i64* %ptr_final_b
  %r194 = load i64, i64* %ptr_final_b
  %r195 = getelementptr [12 x i8], [12 x i8]* @.str.338, i64 0, i64 0
  %r196 = ptrtoint i8* %r195 to i64
  %r197 = call i64 @_add(i64 %r194, i64 %r196)
  %r198 = load i64, i64* %ptr_bool_r
  %r199 = call i64 @_add(i64 %r197, i64 %r198)
  %r200 = getelementptr [8 x i8], [8 x i8]* @.str.339, i64 0, i64 0
  %r201 = ptrtoint i8* %r200 to i64
  %r202 = call i64 @_add(i64 %r199, i64 %r201)
  %r203 = call i64 @emit(i64 %r202)
  %r204 = getelementptr [11 x i8], [11 x i8]* @.str.340, i64 0, i64 0
  %r205 = ptrtoint i8* %r204 to i64
  %r206 = load i64, i64* %ptr_final_b
  %r207 = call i64 @_add(i64 %r205, i64 %r206)
  %r208 = getelementptr [8 x i8], [8 x i8]* @.str.341, i64 0, i64 0
  %r209 = ptrtoint i8* %r208 to i64
  %r210 = call i64 @_add(i64 %r207, i64 %r209)
  %r211 = load i64, i64* %ptr_g_ptr
  %r212 = call i64 @_add(i64 %r210, i64 %r211)
  %r213 = call i64 @emit(i64 %r212)
  %r214 = getelementptr [11 x i8], [11 x i8]* @.str.342, i64 0, i64 0
  %r215 = ptrtoint i8* %r214 to i64
  %r216 = load i64, i64* %ptr_l_end
  %r217 = call i64 @_add(i64 %r215, i64 %r216)
  %r218 = call i64 @emit(i64 %r217)
  %r219 = load i64, i64* %ptr_l_end
  %r220 = getelementptr [2 x i8], [2 x i8]* @.str.343, i64 0, i64 0
  %r221 = ptrtoint i8* %r220 to i64
  %r222 = call i64 @_add(i64 %r219, i64 %r221)
  %r223 = call i64 @emit_raw(i64 %r222)
  %r224 = load i64, i64* %ptr_l_res
  %r225 = getelementptr [19 x i8], [19 x i8]* @.str.344, i64 0, i64 0
  %r226 = ptrtoint i8* %r225 to i64
  %r227 = call i64 @_add(i64 %r224, i64 %r226)
  %r228 = load i64, i64* %ptr_g_ptr
  %r229 = call i64 @_add(i64 %r227, i64 %r228)
  %r230 = call i64 @emit(i64 %r229)
  %r231 = load i64, i64* %ptr_l_res
  ret i64 %r231
  br label %L701
L700:
  %r232 = load i64, i64* %ptr_op
  %r233 = getelementptr [4 x i8], [4 x i8]* @.str.345, i64 0, i64 0
  %r234 = ptrtoint i8* %r233 to i64
  %r235 = call i64 @_eq(i64 %r232, i64 %r234)
  %r236 = icmp ne i64 %r235, 0
  br i1 %r236, label %L702, label %L703
L702:
  %r237 = load i64, i64* @str_count
  %r238 = call i64 @_add(i64 %r237, i64 1)
  store i64 %r238, i64* @str_count
  %r239 = getelementptr [6 x i8], [6 x i8]* @.str.346, i64 0, i64 0
  %r240 = ptrtoint i8* %r239 to i64
  %r241 = load i64, i64* @str_count
  %r242 = call i64 @int_to_str(i64 %r241)
  %r243 = call i64 @_add(i64 %r240, i64 %r242)
  store i64 %r243, i64* %ptr_g_ptr
  %r244 = load i64, i64* @out_data
  %r245 = load i64, i64* %ptr_g_ptr
  %r246 = call i64 @_add(i64 %r244, i64 %r245)
  %r247 = getelementptr [16 x i8], [16 x i8]* @.str.347, i64 0, i64 0
  %r248 = ptrtoint i8* %r247 to i64
  %r249 = call i64 @_add(i64 %r246, i64 %r248)
  %r250 = call i64 @signum_ex(i64 10)
  %r251 = call i64 @_add(i64 %r249, i64 %r250)
  store i64 %r251, i64* @out_data
  %r252 = load i64, i64* %ptr_node
  %r253 = getelementptr [5 x i8], [5 x i8]* @.str.348, i64 0, i64 0
  %r254 = ptrtoint i8* %r253 to i64
  %r255 = call i64 @_get(i64 %r252, i64 %r254)
  %r256 = call i64 @compile_expr(i64 %r255)
  store i64 %r256, i64* %ptr_v_lhs
  %r257 = call i64 @next_reg()
  store i64 %r257, i64* %ptr_v_res
  %r258 = call i64 @next_label()
  store i64 %r258, i64* %ptr_v_right
  %r259 = call i64 @next_label()
  store i64 %r259, i64* %ptr_v_end
  %r260 = getelementptr [19 x i8], [19 x i8]* @.str.349, i64 0, i64 0
  %r261 = ptrtoint i8* %r260 to i64
  %r262 = load i64, i64* %ptr_g_ptr
  %r263 = call i64 @_add(i64 %r261, i64 %r262)
  %r264 = call i64 @emit(i64 %r263)
  %r265 = call i64 @next_reg()
  store i64 %r265, i64* %ptr_v_bool_l
  %r266 = load i64, i64* %ptr_v_bool_l
  %r267 = getelementptr [16 x i8], [16 x i8]* @.str.350, i64 0, i64 0
  %r268 = ptrtoint i8* %r267 to i64
  %r269 = call i64 @_add(i64 %r266, i64 %r268)
  %r270 = load i64, i64* %ptr_v_lhs
  %r271 = call i64 @_add(i64 %r269, i64 %r270)
  %r272 = getelementptr [4 x i8], [4 x i8]* @.str.351, i64 0, i64 0
  %r273 = ptrtoint i8* %r272 to i64
  %r274 = call i64 @_add(i64 %r271, i64 %r273)
  %r275 = call i64 @emit(i64 %r274)
  %r276 = getelementptr [7 x i8], [7 x i8]* @.str.352, i64 0, i64 0
  %r277 = ptrtoint i8* %r276 to i64
  %r278 = load i64, i64* %ptr_v_bool_l
  %r279 = call i64 @_add(i64 %r277, i64 %r278)
  %r280 = getelementptr [10 x i8], [10 x i8]* @.str.353, i64 0, i64 0
  %r281 = ptrtoint i8* %r280 to i64
  %r282 = call i64 @_add(i64 %r279, i64 %r281)
  %r283 = load i64, i64* %ptr_v_right
  %r284 = call i64 @_add(i64 %r282, i64 %r283)
  %r285 = getelementptr [10 x i8], [10 x i8]* @.str.354, i64 0, i64 0
  %r286 = ptrtoint i8* %r285 to i64
  %r287 = call i64 @_add(i64 %r284, i64 %r286)
  %r288 = load i64, i64* %ptr_v_end
  %r289 = call i64 @_add(i64 %r287, i64 %r288)
  %r290 = call i64 @emit(i64 %r289)
  %r291 = load i64, i64* %ptr_v_right
  %r292 = getelementptr [2 x i8], [2 x i8]* @.str.355, i64 0, i64 0
  %r293 = ptrtoint i8* %r292 to i64
  %r294 = call i64 @_add(i64 %r291, i64 %r293)
  %r295 = call i64 @emit_raw(i64 %r294)
  %r296 = load i64, i64* %ptr_node
  %r297 = getelementptr [6 x i8], [6 x i8]* @.str.356, i64 0, i64 0
  %r298 = ptrtoint i8* %r297 to i64
  %r299 = call i64 @_get(i64 %r296, i64 %r298)
  %r300 = call i64 @compile_expr(i64 %r299)
  store i64 %r300, i64* %ptr_v_rhs
  %r301 = call i64 @next_reg()
  store i64 %r301, i64* %ptr_v_bool_r
  %r302 = load i64, i64* %ptr_v_bool_r
  %r303 = getelementptr [16 x i8], [16 x i8]* @.str.357, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_add(i64 %r302, i64 %r304)
  %r306 = load i64, i64* %ptr_v_rhs
  %r307 = call i64 @_add(i64 %r305, i64 %r306)
  %r308 = getelementptr [4 x i8], [4 x i8]* @.str.358, i64 0, i64 0
  %r309 = ptrtoint i8* %r308 to i64
  %r310 = call i64 @_add(i64 %r307, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  %r312 = call i64 @next_reg()
  store i64 %r312, i64* %ptr_v_final_b
  %r313 = load i64, i64* %ptr_v_final_b
  %r314 = getelementptr [12 x i8], [12 x i8]* @.str.359, i64 0, i64 0
  %r315 = ptrtoint i8* %r314 to i64
  %r316 = call i64 @_add(i64 %r313, i64 %r315)
  %r317 = load i64, i64* %ptr_v_bool_r
  %r318 = call i64 @_add(i64 %r316, i64 %r317)
  %r319 = getelementptr [8 x i8], [8 x i8]* @.str.360, i64 0, i64 0
  %r320 = ptrtoint i8* %r319 to i64
  %r321 = call i64 @_add(i64 %r318, i64 %r320)
  %r322 = call i64 @emit(i64 %r321)
  %r323 = getelementptr [11 x i8], [11 x i8]* @.str.361, i64 0, i64 0
  %r324 = ptrtoint i8* %r323 to i64
  %r325 = load i64, i64* %ptr_v_final_b
  %r326 = call i64 @_add(i64 %r324, i64 %r325)
  %r327 = getelementptr [8 x i8], [8 x i8]* @.str.362, i64 0, i64 0
  %r328 = ptrtoint i8* %r327 to i64
  %r329 = call i64 @_add(i64 %r326, i64 %r328)
  %r330 = load i64, i64* %ptr_g_ptr
  %r331 = call i64 @_add(i64 %r329, i64 %r330)
  %r332 = call i64 @emit(i64 %r331)
  %r333 = getelementptr [11 x i8], [11 x i8]* @.str.363, i64 0, i64 0
  %r334 = ptrtoint i8* %r333 to i64
  %r335 = load i64, i64* %ptr_v_end
  %r336 = call i64 @_add(i64 %r334, i64 %r335)
  %r337 = call i64 @emit(i64 %r336)
  %r338 = load i64, i64* %ptr_v_end
  %r339 = getelementptr [2 x i8], [2 x i8]* @.str.364, i64 0, i64 0
  %r340 = ptrtoint i8* %r339 to i64
  %r341 = call i64 @_add(i64 %r338, i64 %r340)
  %r342 = call i64 @emit_raw(i64 %r341)
  %r343 = load i64, i64* %ptr_v_res
  %r344 = getelementptr [19 x i8], [19 x i8]* @.str.365, i64 0, i64 0
  %r345 = ptrtoint i8* %r344 to i64
  %r346 = call i64 @_add(i64 %r343, i64 %r345)
  %r347 = load i64, i64* %ptr_g_ptr
  %r348 = call i64 @_add(i64 %r346, i64 %r347)
  %r349 = call i64 @emit(i64 %r348)
  %r350 = load i64, i64* %ptr_v_res
  ret i64 %r350
  br label %L704
L703:
  %r351 = load i64, i64* %ptr_node
  %r352 = getelementptr [5 x i8], [5 x i8]* @.str.366, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_get(i64 %r351, i64 %r353)
  %r355 = call i64 @compile_expr(i64 %r354)
  store i64 %r355, i64* %ptr_lhs
  %r356 = load i64, i64* %ptr_node
  %r357 = getelementptr [6 x i8], [6 x i8]* @.str.367, i64 0, i64 0
  %r358 = ptrtoint i8* %r357 to i64
  %r359 = call i64 @_get(i64 %r356, i64 %r358)
  %r360 = call i64 @compile_expr(i64 %r359)
  store i64 %r360, i64* %ptr_rhs
  %r361 = call i64 @next_reg()
  store i64 %r361, i64* %ptr_res
  store i64 0, i64* %ptr_defined
  %r362 = load i64, i64* %ptr_op
  %r363 = getelementptr [2 x i8], [2 x i8]* @.str.368, i64 0, i64 0
  %r364 = ptrtoint i8* %r363 to i64
  %r365 = call i64 @_eq(i64 %r362, i64 %r364)
  %r366 = icmp ne i64 %r365, 0
  br i1 %r366, label %L705, label %L707
L705:
  %r367 = load i64, i64* %ptr_res
  %r368 = getelementptr [23 x i8], [23 x i8]* @.str.369, i64 0, i64 0
  %r369 = ptrtoint i8* %r368 to i64
  %r370 = call i64 @_add(i64 %r367, i64 %r369)
  %r371 = load i64, i64* %ptr_lhs
  %r372 = call i64 @_add(i64 %r370, i64 %r371)
  %r373 = getelementptr [7 x i8], [7 x i8]* @.str.370, i64 0, i64 0
  %r374 = ptrtoint i8* %r373 to i64
  %r375 = call i64 @_add(i64 %r372, i64 %r374)
  %r376 = load i64, i64* %ptr_rhs
  %r377 = call i64 @_add(i64 %r375, i64 %r376)
  %r378 = getelementptr [2 x i8], [2 x i8]* @.str.371, i64 0, i64 0
  %r379 = ptrtoint i8* %r378 to i64
  %r380 = call i64 @_add(i64 %r377, i64 %r379)
  %r381 = call i64 @emit(i64 %r380)
  store i64 1, i64* %ptr_defined
  br label %L707
L707:
  %r382 = load i64, i64* %ptr_defined
  %r383 = call i64 @_eq(i64 %r382, i64 0)
  %r384 = icmp ne i64 %r383, 0
  br i1 %r384, label %L708, label %L710
L708:
  %r385 = load i64, i64* %ptr_op
  %r386 = getelementptr [2 x i8], [2 x i8]* @.str.372, i64 0, i64 0
  %r387 = ptrtoint i8* %r386 to i64
  %r388 = call i64 @_eq(i64 %r385, i64 %r387)
  %r389 = icmp ne i64 %r388, 0
  br i1 %r389, label %L711, label %L713
L711:
  %r390 = load i64, i64* %ptr_res
  %r391 = getelementptr [12 x i8], [12 x i8]* @.str.373, i64 0, i64 0
  %r392 = ptrtoint i8* %r391 to i64
  %r393 = call i64 @_add(i64 %r390, i64 %r392)
  %r394 = load i64, i64* %ptr_lhs
  %r395 = call i64 @_add(i64 %r393, i64 %r394)
  %r396 = getelementptr [3 x i8], [3 x i8]* @.str.374, i64 0, i64 0
  %r397 = ptrtoint i8* %r396 to i64
  %r398 = call i64 @_add(i64 %r395, i64 %r397)
  %r399 = load i64, i64* %ptr_rhs
  %r400 = call i64 @_add(i64 %r398, i64 %r399)
  %r401 = call i64 @emit(i64 %r400)
  store i64 1, i64* %ptr_defined
  br label %L713
L713:
  br label %L710
L710:
  %r402 = load i64, i64* %ptr_defined
  %r403 = call i64 @_eq(i64 %r402, i64 0)
  %r404 = icmp ne i64 %r403, 0
  br i1 %r404, label %L714, label %L716
L714:
  %r405 = load i64, i64* %ptr_op
  %r406 = getelementptr [2 x i8], [2 x i8]* @.str.375, i64 0, i64 0
  %r407 = ptrtoint i8* %r406 to i64
  %r408 = call i64 @_eq(i64 %r405, i64 %r407)
  %r409 = icmp ne i64 %r408, 0
  br i1 %r409, label %L717, label %L719
L717:
  %r410 = load i64, i64* %ptr_res
  %r411 = getelementptr [12 x i8], [12 x i8]* @.str.376, i64 0, i64 0
  %r412 = ptrtoint i8* %r411 to i64
  %r413 = call i64 @_add(i64 %r410, i64 %r412)
  %r414 = load i64, i64* %ptr_lhs
  %r415 = call i64 @_add(i64 %r413, i64 %r414)
  %r416 = getelementptr [3 x i8], [3 x i8]* @.str.377, i64 0, i64 0
  %r417 = ptrtoint i8* %r416 to i64
  %r418 = call i64 @_add(i64 %r415, i64 %r417)
  %r419 = load i64, i64* %ptr_rhs
  %r420 = call i64 @_add(i64 %r418, i64 %r419)
  %r421 = call i64 @emit(i64 %r420)
  store i64 1, i64* %ptr_defined
  br label %L719
L719:
  br label %L716
L716:
  %r422 = load i64, i64* %ptr_defined
  %r423 = call i64 @_eq(i64 %r422, i64 0)
  %r424 = icmp ne i64 %r423, 0
  br i1 %r424, label %L720, label %L722
L720:
  %r425 = load i64, i64* %ptr_op
  %r426 = getelementptr [2 x i8], [2 x i8]* @.str.378, i64 0, i64 0
  %r427 = ptrtoint i8* %r426 to i64
  %r428 = call i64 @_eq(i64 %r425, i64 %r427)
  %r429 = icmp ne i64 %r428, 0
  br i1 %r429, label %L723, label %L725
L723:
  %r430 = load i64, i64* %ptr_res
  %r431 = getelementptr [13 x i8], [13 x i8]* @.str.379, i64 0, i64 0
  %r432 = ptrtoint i8* %r431 to i64
  %r433 = call i64 @_add(i64 %r430, i64 %r432)
  %r434 = load i64, i64* %ptr_lhs
  %r435 = call i64 @_add(i64 %r433, i64 %r434)
  %r436 = getelementptr [3 x i8], [3 x i8]* @.str.380, i64 0, i64 0
  %r437 = ptrtoint i8* %r436 to i64
  %r438 = call i64 @_add(i64 %r435, i64 %r437)
  %r439 = load i64, i64* %ptr_rhs
  %r440 = call i64 @_add(i64 %r438, i64 %r439)
  %r441 = call i64 @emit(i64 %r440)
  store i64 1, i64* %ptr_defined
  br label %L725
L725:
  br label %L722
L722:
  %r442 = load i64, i64* %ptr_defined
  %r443 = call i64 @_eq(i64 %r442, i64 0)
  %r444 = icmp ne i64 %r443, 0
  br i1 %r444, label %L726, label %L728
L726:
  %r445 = load i64, i64* %ptr_op
  %r446 = getelementptr [2 x i8], [2 x i8]* @.str.381, i64 0, i64 0
  %r447 = ptrtoint i8* %r446 to i64
  %r448 = call i64 @_eq(i64 %r445, i64 %r447)
  %r449 = icmp ne i64 %r448, 0
  br i1 %r449, label %L729, label %L731
L729:
  %r450 = load i64, i64* %ptr_res
  %r451 = getelementptr [13 x i8], [13 x i8]* @.str.382, i64 0, i64 0
  %r452 = ptrtoint i8* %r451 to i64
  %r453 = call i64 @_add(i64 %r450, i64 %r452)
  %r454 = load i64, i64* %ptr_lhs
  %r455 = call i64 @_add(i64 %r453, i64 %r454)
  %r456 = getelementptr [3 x i8], [3 x i8]* @.str.383, i64 0, i64 0
  %r457 = ptrtoint i8* %r456 to i64
  %r458 = call i64 @_add(i64 %r455, i64 %r457)
  %r459 = load i64, i64* %ptr_rhs
  %r460 = call i64 @_add(i64 %r458, i64 %r459)
  %r461 = call i64 @emit(i64 %r460)
  store i64 1, i64* %ptr_defined
  br label %L731
L731:
  br label %L728
L728:
  %r462 = load i64, i64* %ptr_defined
  %r463 = call i64 @_eq(i64 %r462, i64 0)
  %r464 = icmp ne i64 %r463, 0
  br i1 %r464, label %L732, label %L734
L732:
  %r465 = load i64, i64* %ptr_op
  %r466 = getelementptr [2 x i8], [2 x i8]* @.str.384, i64 0, i64 0
  %r467 = ptrtoint i8* %r466 to i64
  %r468 = call i64 @_eq(i64 %r465, i64 %r467)
  %r469 = icmp ne i64 %r468, 0
  br i1 %r469, label %L735, label %L737
L735:
  %r470 = load i64, i64* %ptr_res
  %r471 = getelementptr [12 x i8], [12 x i8]* @.str.385, i64 0, i64 0
  %r472 = ptrtoint i8* %r471 to i64
  %r473 = call i64 @_add(i64 %r470, i64 %r472)
  %r474 = load i64, i64* %ptr_lhs
  %r475 = call i64 @_add(i64 %r473, i64 %r474)
  %r476 = getelementptr [3 x i8], [3 x i8]* @.str.386, i64 0, i64 0
  %r477 = ptrtoint i8* %r476 to i64
  %r478 = call i64 @_add(i64 %r475, i64 %r477)
  %r479 = load i64, i64* %ptr_rhs
  %r480 = call i64 @_add(i64 %r478, i64 %r479)
  %r481 = call i64 @emit(i64 %r480)
  store i64 1, i64* %ptr_defined
  br label %L737
L737:
  br label %L734
L734:
  %r482 = load i64, i64* %ptr_defined
  %r483 = call i64 @_eq(i64 %r482, i64 0)
  %r484 = icmp ne i64 %r483, 0
  br i1 %r484, label %L738, label %L740
L738:
  %r485 = load i64, i64* %ptr_op
  %r486 = getelementptr [2 x i8], [2 x i8]* @.str.387, i64 0, i64 0
  %r487 = ptrtoint i8* %r486 to i64
  %r488 = call i64 @_eq(i64 %r485, i64 %r487)
  %r489 = icmp ne i64 %r488, 0
  br i1 %r489, label %L741, label %L743
L741:
  %r490 = load i64, i64* %ptr_res
  %r491 = getelementptr [11 x i8], [11 x i8]* @.str.388, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_add(i64 %r490, i64 %r492)
  %r494 = load i64, i64* %ptr_lhs
  %r495 = call i64 @_add(i64 %r493, i64 %r494)
  %r496 = getelementptr [3 x i8], [3 x i8]* @.str.389, i64 0, i64 0
  %r497 = ptrtoint i8* %r496 to i64
  %r498 = call i64 @_add(i64 %r495, i64 %r497)
  %r499 = load i64, i64* %ptr_rhs
  %r500 = call i64 @_add(i64 %r498, i64 %r499)
  %r501 = call i64 @emit(i64 %r500)
  store i64 1, i64* %ptr_defined
  br label %L743
L743:
  br label %L740
L740:
  %r502 = load i64, i64* %ptr_defined
  %r503 = call i64 @_eq(i64 %r502, i64 0)
  %r504 = icmp ne i64 %r503, 0
  br i1 %r504, label %L744, label %L746
L744:
  %r505 = load i64, i64* %ptr_op
  %r506 = getelementptr [2 x i8], [2 x i8]* @.str.390, i64 0, i64 0
  %r507 = ptrtoint i8* %r506 to i64
  %r508 = call i64 @_eq(i64 %r505, i64 %r507)
  %r509 = icmp ne i64 %r508, 0
  br i1 %r509, label %L747, label %L749
L747:
  %r510 = load i64, i64* %ptr_res
  %r511 = getelementptr [12 x i8], [12 x i8]* @.str.391, i64 0, i64 0
  %r512 = ptrtoint i8* %r511 to i64
  %r513 = call i64 @_add(i64 %r510, i64 %r512)
  %r514 = load i64, i64* %ptr_lhs
  %r515 = call i64 @_add(i64 %r513, i64 %r514)
  %r516 = getelementptr [3 x i8], [3 x i8]* @.str.392, i64 0, i64 0
  %r517 = ptrtoint i8* %r516 to i64
  %r518 = call i64 @_add(i64 %r515, i64 %r517)
  %r519 = load i64, i64* %ptr_rhs
  %r520 = call i64 @_add(i64 %r518, i64 %r519)
  %r521 = call i64 @emit(i64 %r520)
  store i64 1, i64* %ptr_defined
  br label %L749
L749:
  br label %L746
L746:
  %r522 = load i64, i64* %ptr_defined
  %r523 = call i64 @_eq(i64 %r522, i64 0)
  %r524 = icmp ne i64 %r523, 0
  br i1 %r524, label %L750, label %L752
L750:
  %r525 = load i64, i64* %ptr_op
  %r526 = getelementptr [4 x i8], [4 x i8]* @.str.393, i64 0, i64 0
  %r527 = ptrtoint i8* %r526 to i64
  %r528 = call i64 @_eq(i64 %r525, i64 %r527)
  %r529 = icmp ne i64 %r528, 0
  br i1 %r529, label %L753, label %L755
L753:
  %r530 = load i64, i64* %ptr_res
  %r531 = getelementptr [12 x i8], [12 x i8]* @.str.394, i64 0, i64 0
  %r532 = ptrtoint i8* %r531 to i64
  %r533 = call i64 @_add(i64 %r530, i64 %r532)
  %r534 = load i64, i64* %ptr_lhs
  %r535 = call i64 @_add(i64 %r533, i64 %r534)
  %r536 = getelementptr [3 x i8], [3 x i8]* @.str.395, i64 0, i64 0
  %r537 = ptrtoint i8* %r536 to i64
  %r538 = call i64 @_add(i64 %r535, i64 %r537)
  %r539 = load i64, i64* %ptr_rhs
  %r540 = call i64 @_add(i64 %r538, i64 %r539)
  %r541 = call i64 @emit(i64 %r540)
  store i64 1, i64* %ptr_defined
  br label %L755
L755:
  br label %L752
L752:
  %r542 = load i64, i64* %ptr_defined
  %r543 = call i64 @_eq(i64 %r542, i64 0)
  %r544 = icmp ne i64 %r543, 0
  br i1 %r544, label %L756, label %L758
L756:
  %r545 = load i64, i64* %ptr_op
  %r546 = getelementptr [2 x i8], [2 x i8]* @.str.396, i64 0, i64 0
  %r547 = ptrtoint i8* %r546 to i64
  %r548 = call i64 @_eq(i64 %r545, i64 %r547)
  %r549 = icmp ne i64 %r548, 0
  br i1 %r549, label %L759, label %L761
L759:
  %r550 = load i64, i64* %ptr_res
  %r551 = getelementptr [12 x i8], [12 x i8]* @.str.397, i64 0, i64 0
  %r552 = ptrtoint i8* %r551 to i64
  %r553 = call i64 @_add(i64 %r550, i64 %r552)
  %r554 = load i64, i64* %ptr_lhs
  %r555 = call i64 @_add(i64 %r553, i64 %r554)
  %r556 = getelementptr [5 x i8], [5 x i8]* @.str.398, i64 0, i64 0
  %r557 = ptrtoint i8* %r556 to i64
  %r558 = call i64 @_add(i64 %r555, i64 %r557)
  %r559 = call i64 @emit(i64 %r558)
  store i64 1, i64* %ptr_defined
  br label %L761
L761:
  br label %L758
L758:
  %r560 = load i64, i64* %ptr_defined
  %r561 = call i64 @_eq(i64 %r560, i64 0)
  %r562 = icmp ne i64 %r561, 0
  br i1 %r562, label %L762, label %L764
L762:
  %r563 = load i64, i64* %ptr_op
  %r564 = getelementptr [4 x i8], [4 x i8]* @.str.399, i64 0, i64 0
  %r565 = ptrtoint i8* %r564 to i64
  %r566 = call i64 @_eq(i64 %r563, i64 %r565)
  %r567 = icmp ne i64 %r566, 0
  br i1 %r567, label %L765, label %L767
L765:
  %r568 = load i64, i64* %ptr_res
  %r569 = getelementptr [12 x i8], [12 x i8]* @.str.400, i64 0, i64 0
  %r570 = ptrtoint i8* %r569 to i64
  %r571 = call i64 @_add(i64 %r568, i64 %r570)
  %r572 = load i64, i64* %ptr_lhs
  %r573 = call i64 @_add(i64 %r571, i64 %r572)
  %r574 = getelementptr [3 x i8], [3 x i8]* @.str.401, i64 0, i64 0
  %r575 = ptrtoint i8* %r574 to i64
  %r576 = call i64 @_add(i64 %r573, i64 %r575)
  %r577 = load i64, i64* %ptr_rhs
  %r578 = call i64 @_add(i64 %r576, i64 %r577)
  %r579 = call i64 @emit(i64 %r578)
  store i64 1, i64* %ptr_defined
  br label %L767
L767:
  br label %L764
L764:
  %r580 = load i64, i64* %ptr_defined
  %r581 = call i64 @_eq(i64 %r580, i64 0)
  %r582 = icmp ne i64 %r581, 0
  br i1 %r582, label %L768, label %L770
L768:
  %r583 = load i64, i64* %ptr_op
  %r584 = getelementptr [4 x i8], [4 x i8]* @.str.402, i64 0, i64 0
  %r585 = ptrtoint i8* %r584 to i64
  %r586 = call i64 @_eq(i64 %r583, i64 %r585)
  %r587 = icmp ne i64 %r586, 0
  br i1 %r587, label %L771, label %L773
L771:
  %r588 = load i64, i64* %ptr_res
  %r589 = getelementptr [13 x i8], [13 x i8]* @.str.403, i64 0, i64 0
  %r590 = ptrtoint i8* %r589 to i64
  %r591 = call i64 @_add(i64 %r588, i64 %r590)
  %r592 = load i64, i64* %ptr_lhs
  %r593 = call i64 @_add(i64 %r591, i64 %r592)
  %r594 = getelementptr [3 x i8], [3 x i8]* @.str.404, i64 0, i64 0
  %r595 = ptrtoint i8* %r594 to i64
  %r596 = call i64 @_add(i64 %r593, i64 %r595)
  %r597 = load i64, i64* %ptr_rhs
  %r598 = call i64 @_add(i64 %r596, i64 %r597)
  %r599 = call i64 @emit(i64 %r598)
  store i64 1, i64* %ptr_defined
  br label %L773
L773:
  br label %L770
L770:
  %r600 = load i64, i64* %ptr_defined
  %r601 = call i64 @_eq(i64 %r600, i64 0)
  %r602 = icmp ne i64 %r601, 0
  br i1 %r602, label %L774, label %L776
L774:
  %r603 = load i64, i64* %ptr_op
  %r604 = getelementptr [3 x i8], [3 x i8]* @.str.405, i64 0, i64 0
  %r605 = ptrtoint i8* %r604 to i64
  %r606 = call i64 @_eq(i64 %r603, i64 %r605)
  %r607 = icmp ne i64 %r606, 0
  br i1 %r607, label %L777, label %L779
L777:
  %r608 = load i64, i64* %ptr_res
  %r609 = getelementptr [22 x i8], [22 x i8]* @.str.406, i64 0, i64 0
  %r610 = ptrtoint i8* %r609 to i64
  %r611 = call i64 @_add(i64 %r608, i64 %r610)
  %r612 = load i64, i64* %ptr_lhs
  %r613 = call i64 @_add(i64 %r611, i64 %r612)
  %r614 = getelementptr [7 x i8], [7 x i8]* @.str.407, i64 0, i64 0
  %r615 = ptrtoint i8* %r614 to i64
  %r616 = call i64 @_add(i64 %r613, i64 %r615)
  %r617 = load i64, i64* %ptr_rhs
  %r618 = call i64 @_add(i64 %r616, i64 %r617)
  %r619 = getelementptr [2 x i8], [2 x i8]* @.str.408, i64 0, i64 0
  %r620 = ptrtoint i8* %r619 to i64
  %r621 = call i64 @_add(i64 %r618, i64 %r620)
  %r622 = call i64 @emit(i64 %r621)
  store i64 1, i64* %ptr_defined
  br label %L779
L779:
  br label %L776
L776:
  %r623 = load i64, i64* %ptr_defined
  %r624 = call i64 @_eq(i64 %r623, i64 0)
  %r625 = icmp ne i64 %r624, 0
  br i1 %r625, label %L780, label %L782
L780:
  %r626 = load i64, i64* %ptr_op
  %r627 = getelementptr [3 x i8], [3 x i8]* @.str.409, i64 0, i64 0
  %r628 = ptrtoint i8* %r627 to i64
  %r629 = call i64 @_eq(i64 %r626, i64 %r628)
  %r630 = icmp ne i64 %r629, 0
  br i1 %r630, label %L783, label %L785
L783:
  %r631 = call i64 @next_reg()
  store i64 %r631, i64* %ptr_tmp
  %r632 = load i64, i64* %ptr_tmp
  %r633 = getelementptr [22 x i8], [22 x i8]* @.str.410, i64 0, i64 0
  %r634 = ptrtoint i8* %r633 to i64
  %r635 = call i64 @_add(i64 %r632, i64 %r634)
  %r636 = load i64, i64* %ptr_lhs
  %r637 = call i64 @_add(i64 %r635, i64 %r636)
  %r638 = getelementptr [7 x i8], [7 x i8]* @.str.411, i64 0, i64 0
  %r639 = ptrtoint i8* %r638 to i64
  %r640 = call i64 @_add(i64 %r637, i64 %r639)
  %r641 = load i64, i64* %ptr_rhs
  %r642 = call i64 @_add(i64 %r640, i64 %r641)
  %r643 = getelementptr [2 x i8], [2 x i8]* @.str.412, i64 0, i64 0
  %r644 = ptrtoint i8* %r643 to i64
  %r645 = call i64 @_add(i64 %r642, i64 %r644)
  %r646 = call i64 @emit(i64 %r645)
  %r647 = load i64, i64* %ptr_res
  %r648 = getelementptr [12 x i8], [12 x i8]* @.str.413, i64 0, i64 0
  %r649 = ptrtoint i8* %r648 to i64
  %r650 = call i64 @_add(i64 %r647, i64 %r649)
  %r651 = load i64, i64* %ptr_tmp
  %r652 = call i64 @_add(i64 %r650, i64 %r651)
  %r653 = getelementptr [4 x i8], [4 x i8]* @.str.414, i64 0, i64 0
  %r654 = ptrtoint i8* %r653 to i64
  %r655 = call i64 @_add(i64 %r652, i64 %r654)
  %r656 = call i64 @emit(i64 %r655)
  store i64 1, i64* %ptr_defined
  br label %L785
L785:
  br label %L782
L782:
  %r657 = load i64, i64* %ptr_defined
  %r658 = call i64 @_eq(i64 %r657, i64 0)
  %r659 = icmp ne i64 %r658, 0
  br i1 %r659, label %L786, label %L788
L786:
  %r660 = getelementptr [1 x i8], [1 x i8]* @.str.415, i64 0, i64 0
  %r661 = ptrtoint i8* %r660 to i64
  store i64 %r661, i64* %ptr_cmp
  %r662 = load i64, i64* %ptr_op
  %r663 = getelementptr [2 x i8], [2 x i8]* @.str.416, i64 0, i64 0
  %r664 = ptrtoint i8* %r663 to i64
  %r665 = call i64 @_eq(i64 %r662, i64 %r664)
  %r666 = icmp ne i64 %r665, 0
  br i1 %r666, label %L789, label %L791
L789:
  %r667 = getelementptr [4 x i8], [4 x i8]* @.str.417, i64 0, i64 0
  %r668 = ptrtoint i8* %r667 to i64
  store i64 %r668, i64* %ptr_cmp
  br label %L791
L791:
  %r669 = load i64, i64* %ptr_op
  %r670 = getelementptr [2 x i8], [2 x i8]* @.str.418, i64 0, i64 0
  %r671 = ptrtoint i8* %r670 to i64
  %r672 = call i64 @_eq(i64 %r669, i64 %r671)
  %r673 = icmp ne i64 %r672, 0
  br i1 %r673, label %L792, label %L794
L792:
  %r674 = getelementptr [4 x i8], [4 x i8]* @.str.419, i64 0, i64 0
  %r675 = ptrtoint i8* %r674 to i64
  store i64 %r675, i64* %ptr_cmp
  br label %L794
L794:
  %r676 = load i64, i64* %ptr_op
  %r677 = getelementptr [3 x i8], [3 x i8]* @.str.420, i64 0, i64 0
  %r678 = ptrtoint i8* %r677 to i64
  %r679 = call i64 @_eq(i64 %r676, i64 %r678)
  %r680 = icmp ne i64 %r679, 0
  br i1 %r680, label %L795, label %L797
L795:
  %r681 = getelementptr [4 x i8], [4 x i8]* @.str.421, i64 0, i64 0
  %r682 = ptrtoint i8* %r681 to i64
  store i64 %r682, i64* %ptr_cmp
  br label %L797
L797:
  %r683 = load i64, i64* %ptr_op
  %r684 = getelementptr [3 x i8], [3 x i8]* @.str.422, i64 0, i64 0
  %r685 = ptrtoint i8* %r684 to i64
  %r686 = call i64 @_eq(i64 %r683, i64 %r685)
  %r687 = icmp ne i64 %r686, 0
  br i1 %r687, label %L798, label %L800
L798:
  %r688 = getelementptr [4 x i8], [4 x i8]* @.str.423, i64 0, i64 0
  %r689 = ptrtoint i8* %r688 to i64
  store i64 %r689, i64* %ptr_cmp
  br label %L800
L800:
  %r690 = load i64, i64* %ptr_cmp
  %r691 = call i64 @mensura(i64 %r690)
  %r693 = icmp sgt i64 %r691, 0
  %r692 = zext i1 %r693 to i64
  %r694 = icmp ne i64 %r692, 0
  br i1 %r694, label %L801, label %L802
L801:
  %r695 = call i64 @next_reg()
  store i64 %r695, i64* %ptr_b
  %r696 = load i64, i64* %ptr_b
  %r697 = getelementptr [9 x i8], [9 x i8]* @.str.424, i64 0, i64 0
  %r698 = ptrtoint i8* %r697 to i64
  %r699 = call i64 @_add(i64 %r696, i64 %r698)
  %r700 = load i64, i64* %ptr_cmp
  %r701 = call i64 @_add(i64 %r699, i64 %r700)
  %r702 = getelementptr [6 x i8], [6 x i8]* @.str.425, i64 0, i64 0
  %r703 = ptrtoint i8* %r702 to i64
  %r704 = call i64 @_add(i64 %r701, i64 %r703)
  %r705 = load i64, i64* %ptr_lhs
  %r706 = call i64 @_add(i64 %r704, i64 %r705)
  %r707 = getelementptr [3 x i8], [3 x i8]* @.str.426, i64 0, i64 0
  %r708 = ptrtoint i8* %r707 to i64
  %r709 = call i64 @_add(i64 %r706, i64 %r708)
  %r710 = load i64, i64* %ptr_rhs
  %r711 = call i64 @_add(i64 %r709, i64 %r710)
  %r712 = call i64 @emit(i64 %r711)
  %r713 = load i64, i64* %ptr_res
  %r714 = getelementptr [12 x i8], [12 x i8]* @.str.427, i64 0, i64 0
  %r715 = ptrtoint i8* %r714 to i64
  %r716 = call i64 @_add(i64 %r713, i64 %r715)
  %r717 = load i64, i64* %ptr_b
  %r718 = call i64 @_add(i64 %r716, i64 %r717)
  %r719 = getelementptr [8 x i8], [8 x i8]* @.str.428, i64 0, i64 0
  %r720 = ptrtoint i8* %r719 to i64
  %r721 = call i64 @_add(i64 %r718, i64 %r720)
  %r722 = call i64 @emit(i64 %r721)
  br label %L803
L802:
  %r723 = load i64, i64* %ptr_res
  %r724 = getelementptr [16 x i8], [16 x i8]* @.str.429, i64 0, i64 0
  %r725 = ptrtoint i8* %r724 to i64
  %r726 = call i64 @_add(i64 %r723, i64 %r725)
  %r727 = call i64 @emit(i64 %r726)
  br label %L803
L803:
  br label %L788
L788:
  %r728 = load i64, i64* %ptr_res
  ret i64 %r728
  br label %L704
L704:
  br label %L701
L701:
  br label %L698
L698:
  %r729 = load i64, i64* %ptr_node
  %r730 = getelementptr [5 x i8], [5 x i8]* @.str.430, i64 0, i64 0
  %r731 = ptrtoint i8* %r730 to i64
  %r732 = call i64 @_get(i64 %r729, i64 %r731)
  %r733 = load i64, i64* @EXPR_LIST
  %r734 = call i64 @_eq(i64 %r732, i64 %r733)
  %r735 = icmp ne i64 %r734, 0
  br i1 %r735, label %L804, label %L806
L804:
  %r736 = call i64 @next_reg()
  store i64 %r736, i64* %ptr_res
  %r737 = load i64, i64* %ptr_res
  %r738 = getelementptr [25 x i8], [25 x i8]* @.str.431, i64 0, i64 0
  %r739 = ptrtoint i8* %r738 to i64
  %r740 = call i64 @_add(i64 %r737, i64 %r739)
  %r741 = call i64 @emit(i64 %r740)
  %r742 = load i64, i64* %ptr_node
  %r743 = getelementptr [6 x i8], [6 x i8]* @.str.432, i64 0, i64 0
  %r744 = ptrtoint i8* %r743 to i64
  %r745 = call i64 @_get(i64 %r742, i64 %r744)
  store i64 %r745, i64* %ptr_items
  store i64 0, i64* %ptr_i
  br label %L807
L807:
  %r746 = load i64, i64* %ptr_i
  %r747 = load i64, i64* %ptr_items
  %r748 = call i64 @mensura(i64 %r747)
  %r750 = icmp slt i64 %r746, %r748
  %r749 = zext i1 %r750 to i64
  %r751 = icmp ne i64 %r749, 0
  br i1 %r751, label %L808, label %L809
L808:
  %r752 = load i64, i64* %ptr_items
  %r753 = load i64, i64* %ptr_i
  %r754 = call i64 @_get(i64 %r752, i64 %r753)
  %r755 = call i64 @compile_expr(i64 %r754)
  store i64 %r755, i64* %ptr_val
  %r756 = getelementptr [26 x i8], [26 x i8]* @.str.433, i64 0, i64 0
  %r757 = ptrtoint i8* %r756 to i64
  %r758 = load i64, i64* %ptr_res
  %r759 = call i64 @_add(i64 %r757, i64 %r758)
  %r760 = getelementptr [7 x i8], [7 x i8]* @.str.434, i64 0, i64 0
  %r761 = ptrtoint i8* %r760 to i64
  %r762 = call i64 @_add(i64 %r759, i64 %r761)
  %r763 = load i64, i64* %ptr_val
  %r764 = call i64 @_add(i64 %r762, i64 %r763)
  %r765 = getelementptr [2 x i8], [2 x i8]* @.str.435, i64 0, i64 0
  %r766 = ptrtoint i8* %r765 to i64
  %r767 = call i64 @_add(i64 %r764, i64 %r766)
  %r768 = call i64 @emit(i64 %r767)
  %r769 = load i64, i64* %ptr_i
  %r770 = call i64 @_add(i64 %r769, i64 1)
  store i64 %r770, i64* %ptr_i
  br label %L807
L809:
  %r771 = load i64, i64* %ptr_res
  ret i64 %r771
  br label %L806
L806:
  %r772 = load i64, i64* %ptr_node
  %r773 = getelementptr [5 x i8], [5 x i8]* @.str.436, i64 0, i64 0
  %r774 = ptrtoint i8* %r773 to i64
  %r775 = call i64 @_get(i64 %r772, i64 %r774)
  %r776 = load i64, i64* @EXPR_MAP
  %r777 = call i64 @_eq(i64 %r775, i64 %r776)
  %r778 = icmp ne i64 %r777, 0
  br i1 %r778, label %L810, label %L812
L810:
  %r779 = call i64 @next_reg()
  store i64 %r779, i64* %ptr_res
  %r780 = load i64, i64* %ptr_res
  %r781 = getelementptr [24 x i8], [24 x i8]* @.str.437, i64 0, i64 0
  %r782 = ptrtoint i8* %r781 to i64
  %r783 = call i64 @_add(i64 %r780, i64 %r782)
  %r784 = call i64 @emit(i64 %r783)
  %r785 = load i64, i64* %ptr_node
  %r786 = getelementptr [5 x i8], [5 x i8]* @.str.438, i64 0, i64 0
  %r787 = ptrtoint i8* %r786 to i64
  %r788 = call i64 @_get(i64 %r785, i64 %r787)
  store i64 %r788, i64* %ptr_keys
  %r789 = load i64, i64* %ptr_node
  %r790 = getelementptr [5 x i8], [5 x i8]* @.str.439, i64 0, i64 0
  %r791 = ptrtoint i8* %r790 to i64
  %r792 = call i64 @_get(i64 %r789, i64 %r791)
  store i64 %r792, i64* %ptr_vals
  store i64 0, i64* %ptr_i
  br label %L813
L813:
  %r793 = load i64, i64* %ptr_i
  %r794 = load i64, i64* %ptr_keys
  %r795 = call i64 @mensura(i64 %r794)
  %r797 = icmp slt i64 %r793, %r795
  %r796 = zext i1 %r797 to i64
  %r798 = icmp ne i64 %r796, 0
  br i1 %r798, label %L814, label %L815
L814:
  %r799 = load i64, i64* %ptr_keys
  %r800 = load i64, i64* %ptr_i
  %r801 = call i64 @_get(i64 %r799, i64 %r800)
  store i64 %r801, i64* %ptr_k
  %r802 = load i64, i64* %ptr_k
  %r803 = call i64 @add_global_string(i64 %r802)
  store i64 %r803, i64* %ptr_key_ptr
  %r804 = call i64 @next_reg()
  store i64 %r804, i64* %ptr_key_reg
  %r805 = load i64, i64* %ptr_k
  %r806 = call i64 @mensura(i64 %r805)
  %r807 = call i64 @_add(i64 %r806, i64 1)
  store i64 %r807, i64* %ptr_len
  %r808 = load i64, i64* %ptr_key_reg
  %r809 = getelementptr [19 x i8], [19 x i8]* @.str.440, i64 0, i64 0
  %r810 = ptrtoint i8* %r809 to i64
  %r811 = call i64 @_add(i64 %r808, i64 %r810)
  %r812 = load i64, i64* %ptr_len
  %r813 = call i64 @int_to_str(i64 %r812)
  %r814 = call i64 @_add(i64 %r811, i64 %r813)
  %r815 = getelementptr [10 x i8], [10 x i8]* @.str.441, i64 0, i64 0
  %r816 = ptrtoint i8* %r815 to i64
  %r817 = call i64 @_add(i64 %r814, i64 %r816)
  %r818 = load i64, i64* %ptr_len
  %r819 = call i64 @int_to_str(i64 %r818)
  %r820 = call i64 @_add(i64 %r817, i64 %r819)
  %r821 = getelementptr [9 x i8], [9 x i8]* @.str.442, i64 0, i64 0
  %r822 = ptrtoint i8* %r821 to i64
  %r823 = call i64 @_add(i64 %r820, i64 %r822)
  %r824 = load i64, i64* %ptr_key_ptr
  %r825 = call i64 @_add(i64 %r823, i64 %r824)
  %r826 = getelementptr [15 x i8], [15 x i8]* @.str.443, i64 0, i64 0
  %r827 = ptrtoint i8* %r826 to i64
  %r828 = call i64 @_add(i64 %r825, i64 %r827)
  %r829 = call i64 @emit(i64 %r828)
  %r830 = call i64 @next_reg()
  store i64 %r830, i64* %ptr_key_int
  %r831 = load i64, i64* %ptr_key_int
  %r832 = getelementptr [17 x i8], [17 x i8]* @.str.444, i64 0, i64 0
  %r833 = ptrtoint i8* %r832 to i64
  %r834 = call i64 @_add(i64 %r831, i64 %r833)
  %r835 = load i64, i64* %ptr_key_reg
  %r836 = call i64 @_add(i64 %r834, i64 %r835)
  %r837 = getelementptr [8 x i8], [8 x i8]* @.str.445, i64 0, i64 0
  %r838 = ptrtoint i8* %r837 to i64
  %r839 = call i64 @_add(i64 %r836, i64 %r838)
  %r840 = call i64 @emit(i64 %r839)
  %r841 = load i64, i64* %ptr_vals
  %r842 = load i64, i64* %ptr_i
  %r843 = call i64 @_get(i64 %r841, i64 %r842)
  store i64 %r843, i64* %ptr_v
  %r844 = load i64, i64* %ptr_v
  %r845 = call i64 @compile_expr(i64 %r844)
  store i64 %r845, i64* %ptr_val_reg
  %r846 = getelementptr [24 x i8], [24 x i8]* @.str.446, i64 0, i64 0
  %r847 = ptrtoint i8* %r846 to i64
  %r848 = load i64, i64* %ptr_res
  %r849 = call i64 @_add(i64 %r847, i64 %r848)
  %r850 = getelementptr [7 x i8], [7 x i8]* @.str.447, i64 0, i64 0
  %r851 = ptrtoint i8* %r850 to i64
  %r852 = call i64 @_add(i64 %r849, i64 %r851)
  %r853 = load i64, i64* %ptr_key_int
  %r854 = call i64 @_add(i64 %r852, i64 %r853)
  %r855 = getelementptr [7 x i8], [7 x i8]* @.str.448, i64 0, i64 0
  %r856 = ptrtoint i8* %r855 to i64
  %r857 = call i64 @_add(i64 %r854, i64 %r856)
  %r858 = load i64, i64* %ptr_val_reg
  %r859 = call i64 @_add(i64 %r857, i64 %r858)
  %r860 = getelementptr [2 x i8], [2 x i8]* @.str.449, i64 0, i64 0
  %r861 = ptrtoint i8* %r860 to i64
  %r862 = call i64 @_add(i64 %r859, i64 %r861)
  %r863 = call i64 @emit(i64 %r862)
  %r864 = load i64, i64* %ptr_i
  %r865 = call i64 @_add(i64 %r864, i64 1)
  store i64 %r865, i64* %ptr_i
  br label %L813
L815:
  %r866 = load i64, i64* %ptr_res
  ret i64 %r866
  br label %L812
L812:
  %r867 = load i64, i64* %ptr_node
  %r868 = getelementptr [5 x i8], [5 x i8]* @.str.451, i64 0, i64 0
  %r869 = ptrtoint i8* %r868 to i64
  %r870 = call i64 @_get(i64 %r867, i64 %r869)
  %r871 = load i64, i64* @EXPR_INDEX
  %r872 = call i64 @_eq(i64 %r870, i64 %r871)
  store i64 1, i64* @.sc.450
  %r874 = icmp eq i64 %r872, 0
  br i1 %r874, label %L816, label %L817
L816:
  %r875 = load i64, i64* %ptr_node
  %r876 = getelementptr [5 x i8], [5 x i8]* @.str.452, i64 0, i64 0
  %r877 = ptrtoint i8* %r876 to i64
  %r878 = call i64 @_get(i64 %r875, i64 %r877)
  %r879 = load i64, i64* @EXPR_GET
  %r880 = call i64 @_eq(i64 %r878, i64 %r879)
  %r881 = icmp ne i64 %r880, 0
  %r882 = zext i1 %r881 to i64
  store i64 %r882, i64* @.sc.450
  br label %L817
L817:
  %r873 = load i64, i64* @.sc.450
  %r883 = icmp ne i64 %r873, 0
  br i1 %r883, label %L818, label %L820
L818:
  %r884 = call i64 @_map_new()
  store i64 %r884, i64* %ptr_obj_node
  %r885 = call i64 @_map_new()
  store i64 %r885, i64* %ptr_idx_node
  %r886 = load i64, i64* %ptr_node
  %r887 = getelementptr [5 x i8], [5 x i8]* @.str.453, i64 0, i64 0
  %r888 = ptrtoint i8* %r887 to i64
  %r889 = call i64 @_get(i64 %r886, i64 %r888)
  %r890 = load i64, i64* @EXPR_INDEX
  %r891 = call i64 @_eq(i64 %r889, i64 %r890)
  %r892 = icmp ne i64 %r891, 0
  br i1 %r892, label %L821, label %L822
L821:
  %r893 = load i64, i64* %ptr_node
  %r894 = getelementptr [4 x i8], [4 x i8]* @.str.454, i64 0, i64 0
  %r895 = ptrtoint i8* %r894 to i64
  %r896 = call i64 @_get(i64 %r893, i64 %r895)
  store i64 %r896, i64* %ptr_obj_node
  %r897 = load i64, i64* %ptr_node
  %r898 = getelementptr [4 x i8], [4 x i8]* @.str.455, i64 0, i64 0
  %r899 = ptrtoint i8* %r898 to i64
  %r900 = call i64 @_get(i64 %r897, i64 %r899)
  store i64 %r900, i64* %ptr_idx_node
  br label %L823
L822:
  %r901 = load i64, i64* %ptr_node
  %r902 = getelementptr [4 x i8], [4 x i8]* @.str.456, i64 0, i64 0
  %r903 = ptrtoint i8* %r902 to i64
  %r904 = call i64 @_get(i64 %r901, i64 %r903)
  store i64 %r904, i64* %ptr_obj_node
  %r905 = call i64 @_map_new()
  %r906 = getelementptr [5 x i8], [5 x i8]* @.str.457, i64 0, i64 0
  %r907 = ptrtoint i8* %r906 to i64
  %r908 = load i64, i64* @EXPR_STRING
  call i64 @_map_set(i64 %r905, i64 %r907, i64 %r908)
  %r909 = getelementptr [4 x i8], [4 x i8]* @.str.458, i64 0, i64 0
  %r910 = ptrtoint i8* %r909 to i64
  %r911 = load i64, i64* %ptr_node
  %r912 = getelementptr [5 x i8], [5 x i8]* @.str.459, i64 0, i64 0
  %r913 = ptrtoint i8* %r912 to i64
  %r914 = call i64 @_get(i64 %r911, i64 %r913)
  call i64 @_map_set(i64 %r905, i64 %r910, i64 %r914)
  store i64 %r905, i64* %ptr_idx_node
  br label %L823
L823:
  %r915 = load i64, i64* %ptr_obj_node
  %r916 = call i64 @compile_expr(i64 %r915)
  store i64 %r916, i64* %ptr_obj_reg
  %r917 = load i64, i64* %ptr_idx_node
  %r918 = call i64 @compile_expr(i64 %r917)
  store i64 %r918, i64* %ptr_idx_reg
  %r919 = call i64 @next_reg()
  store i64 %r919, i64* %ptr_res
  %r920 = load i64, i64* %ptr_res
  %r921 = getelementptr [23 x i8], [23 x i8]* @.str.460, i64 0, i64 0
  %r922 = ptrtoint i8* %r921 to i64
  %r923 = call i64 @_add(i64 %r920, i64 %r922)
  %r924 = load i64, i64* %ptr_obj_reg
  %r925 = call i64 @_add(i64 %r923, i64 %r924)
  %r926 = getelementptr [7 x i8], [7 x i8]* @.str.461, i64 0, i64 0
  %r927 = ptrtoint i8* %r926 to i64
  %r928 = call i64 @_add(i64 %r925, i64 %r927)
  %r929 = load i64, i64* %ptr_idx_reg
  %r930 = call i64 @_add(i64 %r928, i64 %r929)
  %r931 = getelementptr [2 x i8], [2 x i8]* @.str.462, i64 0, i64 0
  %r932 = ptrtoint i8* %r931 to i64
  %r933 = call i64 @_add(i64 %r930, i64 %r932)
  %r934 = call i64 @emit(i64 %r933)
  %r935 = load i64, i64* %ptr_res
  ret i64 %r935
  br label %L820
L820:
  %r936 = load i64, i64* %ptr_node
  %r937 = getelementptr [5 x i8], [5 x i8]* @.str.463, i64 0, i64 0
  %r938 = ptrtoint i8* %r937 to i64
  %r939 = call i64 @_get(i64 %r936, i64 %r938)
  %r940 = load i64, i64* @EXPR_CALL
  %r941 = call i64 @_eq(i64 %r939, i64 %r940)
  %r942 = icmp ne i64 %r941, 0
  br i1 %r942, label %L824, label %L826
L824:
  %r943 = load i64, i64* %ptr_node
  %r944 = getelementptr [5 x i8], [5 x i8]* @.str.464, i64 0, i64 0
  %r945 = ptrtoint i8* %r944 to i64
  %r946 = call i64 @_get(i64 %r943, i64 %r945)
  store i64 %r946, i64* %ptr_name
  %r947 = load i64, i64* %ptr_name
  %r948 = getelementptr [5 x i8], [5 x i8]* @.str.465, i64 0, i64 0
  %r949 = ptrtoint i8* %r948 to i64
  %r950 = call i64 @_eq(i64 %r947, i64 %r949)
  %r951 = icmp ne i64 %r950, 0
  br i1 %r951, label %L827, label %L829
L827:
  %r952 = getelementptr [12 x i8], [12 x i8]* @.str.466, i64 0, i64 0
  %r953 = ptrtoint i8* %r952 to i64
  store i64 %r953, i64* %ptr_name
  br label %L829
L829:
  %r954 = load i64, i64* %ptr_name
  %r955 = getelementptr [4 x i8], [4 x i8]* @.str.467, i64 0, i64 0
  %r956 = ptrtoint i8* %r955 to i64
  %r957 = call i64 @_eq(i64 %r954, i64 %r956)
  %r958 = icmp ne i64 %r957, 0
  br i1 %r958, label %L830, label %L832
L830:
  %r959 = getelementptr [9 x i8], [9 x i8]* @.str.468, i64 0, i64 0
  %r960 = ptrtoint i8* %r959 to i64
  store i64 %r960, i64* %ptr_name
  br label %L832
L832:
  %r961 = load i64, i64* %ptr_name
  %r962 = getelementptr [9 x i8], [9 x i8]* @.str.469, i64 0, i64 0
  %r963 = ptrtoint i8* %r962 to i64
  %r964 = call i64 @_eq(i64 %r961, i64 %r963)
  %r965 = icmp ne i64 %r964, 0
  br i1 %r965, label %L833, label %L835
L833:
  %r966 = load i64, i64* %ptr_node
  %r967 = getelementptr [5 x i8], [5 x i8]* @.str.470, i64 0, i64 0
  %r968 = ptrtoint i8* %r967 to i64
  %r969 = call i64 @_get(i64 %r966, i64 %r968)
  %r970 = call i64 @_get(i64 %r969, i64 0)
  %r971 = call i64 @compile_expr(i64 %r970)
  store i64 %r971, i64* %ptr_addr_reg
  %r972 = call i64 @next_reg()
  store i64 %r972, i64* %ptr_ptr_reg
  %r973 = load i64, i64* %ptr_ptr_reg
  %r974 = getelementptr [17 x i8], [17 x i8]* @.str.471, i64 0, i64 0
  %r975 = ptrtoint i8* %r974 to i64
  %r976 = call i64 @_add(i64 %r973, i64 %r975)
  %r977 = load i64, i64* %ptr_addr_reg
  %r978 = call i64 @_add(i64 %r976, i64 %r977)
  %r979 = getelementptr [8 x i8], [8 x i8]* @.str.472, i64 0, i64 0
  %r980 = ptrtoint i8* %r979 to i64
  %r981 = call i64 @_add(i64 %r978, i64 %r980)
  %r982 = call i64 @emit(i64 %r981)
  %r983 = call i64 @next_reg()
  store i64 %r983, i64* %ptr_val_reg
  %r984 = load i64, i64* %ptr_val_reg
  %r985 = getelementptr [17 x i8], [17 x i8]* @.str.473, i64 0, i64 0
  %r986 = ptrtoint i8* %r985 to i64
  %r987 = call i64 @_add(i64 %r984, i64 %r986)
  %r988 = load i64, i64* %ptr_ptr_reg
  %r989 = call i64 @_add(i64 %r987, i64 %r988)
  %r990 = call i64 @emit(i64 %r989)
  %r991 = call i64 @next_reg()
  store i64 %r991, i64* %ptr_mem_res
  %r992 = load i64, i64* %ptr_mem_res
  %r993 = getelementptr [12 x i8], [12 x i8]* @.str.474, i64 0, i64 0
  %r994 = ptrtoint i8* %r993 to i64
  %r995 = call i64 @_add(i64 %r992, i64 %r994)
  %r996 = load i64, i64* %ptr_val_reg
  %r997 = call i64 @_add(i64 %r995, i64 %r996)
  %r998 = getelementptr [8 x i8], [8 x i8]* @.str.475, i64 0, i64 0
  %r999 = ptrtoint i8* %r998 to i64
  %r1000 = call i64 @_add(i64 %r997, i64 %r999)
  %r1001 = call i64 @emit(i64 %r1000)
  %r1002 = load i64, i64* %ptr_mem_res
  ret i64 %r1002
  br label %L835
L835:
  %r1003 = load i64, i64* %ptr_name
  %r1004 = getelementptr [11 x i8], [11 x i8]* @.str.476, i64 0, i64 0
  %r1005 = ptrtoint i8* %r1004 to i64
  %r1006 = call i64 @_eq(i64 %r1003, i64 %r1005)
  %r1007 = icmp ne i64 %r1006, 0
  br i1 %r1007, label %L836, label %L838
L836:
  %r1008 = load i64, i64* %ptr_node
  %r1009 = getelementptr [5 x i8], [5 x i8]* @.str.477, i64 0, i64 0
  %r1010 = ptrtoint i8* %r1009 to i64
  %r1011 = call i64 @_get(i64 %r1008, i64 %r1010)
  %r1012 = call i64 @_get(i64 %r1011, i64 0)
  %r1013 = call i64 @compile_expr(i64 %r1012)
  store i64 %r1013, i64* %ptr_addr_reg
  %r1014 = load i64, i64* %ptr_node
  %r1015 = getelementptr [5 x i8], [5 x i8]* @.str.478, i64 0, i64 0
  %r1016 = ptrtoint i8* %r1015 to i64
  %r1017 = call i64 @_get(i64 %r1014, i64 %r1016)
  %r1018 = call i64 @_get(i64 %r1017, i64 1)
  %r1019 = call i64 @compile_expr(i64 %r1018)
  store i64 %r1019, i64* %ptr_val_reg
  %r1020 = call i64 @next_reg()
  store i64 %r1020, i64* %ptr_ptr_reg
  %r1021 = load i64, i64* %ptr_ptr_reg
  %r1022 = getelementptr [17 x i8], [17 x i8]* @.str.479, i64 0, i64 0
  %r1023 = ptrtoint i8* %r1022 to i64
  %r1024 = call i64 @_add(i64 %r1021, i64 %r1023)
  %r1025 = load i64, i64* %ptr_addr_reg
  %r1026 = call i64 @_add(i64 %r1024, i64 %r1025)
  %r1027 = getelementptr [8 x i8], [8 x i8]* @.str.480, i64 0, i64 0
  %r1028 = ptrtoint i8* %r1027 to i64
  %r1029 = call i64 @_add(i64 %r1026, i64 %r1028)
  %r1030 = call i64 @emit(i64 %r1029)
  %r1031 = call i64 @next_reg()
  store i64 %r1031, i64* %ptr_trunc_reg
  %r1032 = load i64, i64* %ptr_trunc_reg
  %r1033 = getelementptr [14 x i8], [14 x i8]* @.str.481, i64 0, i64 0
  %r1034 = ptrtoint i8* %r1033 to i64
  %r1035 = call i64 @_add(i64 %r1032, i64 %r1034)
  %r1036 = load i64, i64* %ptr_val_reg
  %r1037 = call i64 @_add(i64 %r1035, i64 %r1036)
  %r1038 = getelementptr [7 x i8], [7 x i8]* @.str.482, i64 0, i64 0
  %r1039 = ptrtoint i8* %r1038 to i64
  %r1040 = call i64 @_add(i64 %r1037, i64 %r1039)
  %r1041 = call i64 @emit(i64 %r1040)
  %r1042 = getelementptr [19 x i8], [19 x i8]* @.str.483, i64 0, i64 0
  %r1043 = ptrtoint i8* %r1042 to i64
  %r1044 = load i64, i64* %ptr_trunc_reg
  %r1045 = call i64 @_add(i64 %r1043, i64 %r1044)
  %r1046 = getelementptr [7 x i8], [7 x i8]* @.str.484, i64 0, i64 0
  %r1047 = ptrtoint i8* %r1046 to i64
  %r1048 = call i64 @_add(i64 %r1045, i64 %r1047)
  %r1049 = load i64, i64* %ptr_ptr_reg
  %r1050 = call i64 @_add(i64 %r1048, i64 %r1049)
  %r1051 = call i64 @emit(i64 %r1050)
  %r1052 = getelementptr [2 x i8], [2 x i8]* @.str.485, i64 0, i64 0
  %r1053 = ptrtoint i8* %r1052 to i64
  ret i64 %r1053
  br label %L838
L838:
  %r1054 = load i64, i64* %ptr_name
  %r1055 = getelementptr [10 x i8], [10 x i8]* @.str.486, i64 0, i64 0
  %r1056 = ptrtoint i8* %r1055 to i64
  %r1057 = call i64 @_eq(i64 %r1054, i64 %r1056)
  %r1058 = icmp ne i64 %r1057, 0
  br i1 %r1058, label %L839, label %L841
L839:
  %r1059 = load i64, i64* %ptr_node
  %r1060 = getelementptr [5 x i8], [5 x i8]* @.str.487, i64 0, i64 0
  %r1061 = ptrtoint i8* %r1060 to i64
  %r1062 = call i64 @_get(i64 %r1059, i64 %r1061)
  %r1063 = call i64 @_get(i64 %r1062, i64 0)
  %r1064 = call i64 @compile_expr(i64 %r1063)
  store i64 %r1064, i64* %ptr_sz_reg
  %r1065 = call i64 @next_reg()
  store i64 %r1065, i64* %ptr_res
  %r1066 = load i64, i64* %ptr_res
  %r1067 = getelementptr [25 x i8], [25 x i8]* @.str.488, i64 0, i64 0
  %r1068 = ptrtoint i8* %r1067 to i64
  %r1069 = call i64 @_add(i64 %r1066, i64 %r1068)
  %r1070 = load i64, i64* %ptr_sz_reg
  %r1071 = call i64 @_add(i64 %r1069, i64 %r1070)
  %r1072 = getelementptr [2 x i8], [2 x i8]* @.str.489, i64 0, i64 0
  %r1073 = ptrtoint i8* %r1072 to i64
  %r1074 = call i64 @_add(i64 %r1071, i64 %r1073)
  %r1075 = call i64 @emit(i64 %r1074)
  %r1076 = load i64, i64* %ptr_res
  ret i64 %r1076
  br label %L841
L841:
  %r1077 = load i64, i64* %ptr_name
  %r1078 = getelementptr [8 x i8], [8 x i8]* @.str.490, i64 0, i64 0
  %r1079 = ptrtoint i8* %r1078 to i64
  %r1080 = call i64 @_eq(i64 %r1077, i64 %r1079)
  %r1081 = icmp ne i64 %r1080, 0
  br i1 %r1081, label %L842, label %L844
L842:
  %r1082 = load i64, i64* %ptr_node
  %r1083 = getelementptr [5 x i8], [5 x i8]* @.str.491, i64 0, i64 0
  %r1084 = ptrtoint i8* %r1083 to i64
  %r1085 = call i64 @_get(i64 %r1082, i64 %r1084)
  %r1086 = call i64 @_get(i64 %r1085, i64 0)
  %r1087 = call i64 @compile_expr(i64 %r1086)
  store i64 %r1087, i64* %ptr_ptr_reg
  %r1088 = load i64, i64* %ptr_node
  %r1089 = getelementptr [5 x i8], [5 x i8]* @.str.492, i64 0, i64 0
  %r1090 = ptrtoint i8* %r1089 to i64
  %r1091 = call i64 @_get(i64 %r1088, i64 %r1090)
  %r1092 = call i64 @_get(i64 %r1091, i64 1)
  %r1093 = call i64 @compile_expr(i64 %r1092)
  store i64 %r1093, i64* %ptr_off_reg
  %r1094 = call i64 @next_reg()
  store i64 %r1094, i64* %ptr_res
  %r1095 = load i64, i64* %ptr_res
  %r1096 = getelementptr [12 x i8], [12 x i8]* @.str.493, i64 0, i64 0
  %r1097 = ptrtoint i8* %r1096 to i64
  %r1098 = call i64 @_add(i64 %r1095, i64 %r1097)
  %r1099 = load i64, i64* %ptr_ptr_reg
  %r1100 = call i64 @_add(i64 %r1098, i64 %r1099)
  %r1101 = getelementptr [3 x i8], [3 x i8]* @.str.494, i64 0, i64 0
  %r1102 = ptrtoint i8* %r1101 to i64
  %r1103 = call i64 @_add(i64 %r1100, i64 %r1102)
  %r1104 = load i64, i64* %ptr_off_reg
  %r1105 = call i64 @_add(i64 %r1103, i64 %r1104)
  %r1106 = call i64 @emit(i64 %r1105)
  %r1107 = load i64, i64* %ptr_res
  ret i64 %r1107
  br label %L844
L844:
  %r1108 = load i64, i64* %ptr_name
  %r1109 = getelementptr [9 x i8], [9 x i8]* @.str.495, i64 0, i64 0
  %r1110 = ptrtoint i8* %r1109 to i64
  %r1111 = call i64 @_eq(i64 %r1108, i64 %r1110)
  %r1112 = icmp ne i64 %r1111, 0
  br i1 %r1112, label %L845, label %L847
L845:
  %r1113 = load i64, i64* %ptr_node
  %r1114 = getelementptr [5 x i8], [5 x i8]* @.str.496, i64 0, i64 0
  %r1115 = ptrtoint i8* %r1114 to i64
  %r1116 = call i64 @_get(i64 %r1113, i64 %r1115)
  %r1117 = call i64 @_get(i64 %r1116, i64 0)
  %r1118 = call i64 @compile_expr(i64 %r1117)
  store i64 %r1118, i64* %ptr_port_reg
  %r1119 = load i64, i64* %ptr_node
  %r1120 = getelementptr [5 x i8], [5 x i8]* @.str.497, i64 0, i64 0
  %r1121 = ptrtoint i8* %r1120 to i64
  %r1122 = call i64 @_get(i64 %r1119, i64 %r1121)
  %r1123 = call i64 @_get(i64 %r1122, i64 1)
  %r1124 = call i64 @compile_expr(i64 %r1123)
  store i64 %r1124, i64* %ptr_val_reg
  %r1125 = call i64 @next_reg()
  store i64 %r1125, i64* %ptr_port16
  %r1126 = load i64, i64* %ptr_port16
  %r1127 = getelementptr [14 x i8], [14 x i8]* @.str.498, i64 0, i64 0
  %r1128 = ptrtoint i8* %r1127 to i64
  %r1129 = call i64 @_add(i64 %r1126, i64 %r1128)
  %r1130 = load i64, i64* %ptr_port_reg
  %r1131 = call i64 @_add(i64 %r1129, i64 %r1130)
  %r1132 = getelementptr [8 x i8], [8 x i8]* @.str.499, i64 0, i64 0
  %r1133 = ptrtoint i8* %r1132 to i64
  %r1134 = call i64 @_add(i64 %r1131, i64 %r1133)
  %r1135 = call i64 @emit(i64 %r1134)
  %r1136 = call i64 @next_reg()
  store i64 %r1136, i64* %ptr_val8
  %r1137 = load i64, i64* %ptr_val8
  %r1138 = getelementptr [14 x i8], [14 x i8]* @.str.500, i64 0, i64 0
  %r1139 = ptrtoint i8* %r1138 to i64
  %r1140 = call i64 @_add(i64 %r1137, i64 %r1139)
  %r1141 = load i64, i64* %ptr_val_reg
  %r1142 = call i64 @_add(i64 %r1140, i64 %r1141)
  %r1143 = getelementptr [7 x i8], [7 x i8]* @.str.501, i64 0, i64 0
  %r1144 = ptrtoint i8* %r1143 to i64
  %r1145 = call i64 @_add(i64 %r1142, i64 %r1144)
  %r1146 = call i64 @emit(i64 %r1145)
  %r1147 = getelementptr [86 x i8], [86 x i8]* @.str.502, i64 0, i64 0
  %r1148 = ptrtoint i8* %r1147 to i64
  %r1149 = load i64, i64* %ptr_val8
  %r1150 = call i64 @_add(i64 %r1148, i64 %r1149)
  %r1151 = getelementptr [7 x i8], [7 x i8]* @.str.503, i64 0, i64 0
  %r1152 = ptrtoint i8* %r1151 to i64
  %r1153 = call i64 @_add(i64 %r1150, i64 %r1152)
  %r1154 = load i64, i64* %ptr_port16
  %r1155 = call i64 @_add(i64 %r1153, i64 %r1154)
  %r1156 = getelementptr [2 x i8], [2 x i8]* @.str.504, i64 0, i64 0
  %r1157 = ptrtoint i8* %r1156 to i64
  %r1158 = call i64 @_add(i64 %r1155, i64 %r1157)
  %r1159 = call i64 @emit(i64 %r1158)
  %r1160 = getelementptr [2 x i8], [2 x i8]* @.str.505, i64 0, i64 0
  %r1161 = ptrtoint i8* %r1160 to i64
  ret i64 %r1161
  br label %L847
L847:
  %r1162 = load i64, i64* %ptr_name
  %r1163 = getelementptr [8 x i8], [8 x i8]* @.str.506, i64 0, i64 0
  %r1164 = ptrtoint i8* %r1163 to i64
  %r1165 = call i64 @_eq(i64 %r1162, i64 %r1164)
  %r1166 = icmp ne i64 %r1165, 0
  br i1 %r1166, label %L848, label %L850
L848:
  %r1167 = load i64, i64* %ptr_node
  %r1168 = getelementptr [5 x i8], [5 x i8]* @.str.507, i64 0, i64 0
  %r1169 = ptrtoint i8* %r1168 to i64
  %r1170 = call i64 @_get(i64 %r1167, i64 %r1169)
  %r1171 = call i64 @_get(i64 %r1170, i64 0)
  %r1172 = call i64 @compile_expr(i64 %r1171)
  store i64 %r1172, i64* %ptr_port_reg
  %r1173 = call i64 @next_reg()
  store i64 %r1173, i64* %ptr_port16
  %r1174 = load i64, i64* %ptr_port16
  %r1175 = getelementptr [14 x i8], [14 x i8]* @.str.508, i64 0, i64 0
  %r1176 = ptrtoint i8* %r1175 to i64
  %r1177 = call i64 @_add(i64 %r1174, i64 %r1176)
  %r1178 = load i64, i64* %ptr_port_reg
  %r1179 = call i64 @_add(i64 %r1177, i64 %r1178)
  %r1180 = getelementptr [8 x i8], [8 x i8]* @.str.509, i64 0, i64 0
  %r1181 = ptrtoint i8* %r1180 to i64
  %r1182 = call i64 @_add(i64 %r1179, i64 %r1181)
  %r1183 = call i64 @emit(i64 %r1182)
  %r1184 = call i64 @next_reg()
  store i64 %r1184, i64* %ptr_res8
  %r1185 = load i64, i64* %ptr_res8
  %r1186 = getelementptr [88 x i8], [88 x i8]* @.str.510, i64 0, i64 0
  %r1187 = ptrtoint i8* %r1186 to i64
  %r1188 = call i64 @_add(i64 %r1185, i64 %r1187)
  %r1189 = load i64, i64* %ptr_port16
  %r1190 = call i64 @_add(i64 %r1188, i64 %r1189)
  %r1191 = getelementptr [2 x i8], [2 x i8]* @.str.511, i64 0, i64 0
  %r1192 = ptrtoint i8* %r1191 to i64
  %r1193 = call i64 @_add(i64 %r1190, i64 %r1192)
  %r1194 = call i64 @emit(i64 %r1193)
  %r1195 = call i64 @next_reg()
  store i64 %r1195, i64* %ptr_res64
  %r1196 = load i64, i64* %ptr_res64
  %r1197 = getelementptr [12 x i8], [12 x i8]* @.str.512, i64 0, i64 0
  %r1198 = ptrtoint i8* %r1197 to i64
  %r1199 = call i64 @_add(i64 %r1196, i64 %r1198)
  %r1200 = load i64, i64* %ptr_res8
  %r1201 = call i64 @_add(i64 %r1199, i64 %r1200)
  %r1202 = getelementptr [8 x i8], [8 x i8]* @.str.513, i64 0, i64 0
  %r1203 = ptrtoint i8* %r1202 to i64
  %r1204 = call i64 @_add(i64 %r1201, i64 %r1203)
  %r1205 = call i64 @emit(i64 %r1204)
  %r1206 = load i64, i64* %ptr_res64
  ret i64 %r1206
  br label %L850
L850:
  %r1207 = load i64, i64* %ptr_name
  %r1208 = getelementptr [12 x i8], [12 x i8]* @.str.514, i64 0, i64 0
  %r1209 = ptrtoint i8* %r1208 to i64
  %r1210 = call i64 @_eq(i64 %r1207, i64 %r1209)
  %r1211 = icmp ne i64 %r1210, 0
  br i1 %r1211, label %L851, label %L853
L851:
  %r1212 = load i64, i64* %ptr_node
  %r1213 = getelementptr [5 x i8], [5 x i8]* @.str.515, i64 0, i64 0
  %r1214 = ptrtoint i8* %r1213 to i64
  %r1215 = call i64 @_get(i64 %r1212, i64 %r1214)
  %r1216 = call i64 @_get(i64 %r1215, i64 0)
  %r1217 = call i64 @compile_expr(i64 %r1216)
  store i64 %r1217, i64* %ptr_port_reg
  %r1218 = load i64, i64* %ptr_node
  %r1219 = getelementptr [5 x i8], [5 x i8]* @.str.516, i64 0, i64 0
  %r1220 = ptrtoint i8* %r1219 to i64
  %r1221 = call i64 @_get(i64 %r1218, i64 %r1220)
  %r1222 = call i64 @_get(i64 %r1221, i64 1)
  %r1223 = call i64 @compile_expr(i64 %r1222)
  store i64 %r1223, i64* %ptr_val_reg
  %r1224 = call i64 @next_reg()
  store i64 %r1224, i64* %ptr_port16
  %r1225 = load i64, i64* %ptr_port16
  %r1226 = getelementptr [14 x i8], [14 x i8]* @.str.517, i64 0, i64 0
  %r1227 = ptrtoint i8* %r1226 to i64
  %r1228 = call i64 @_add(i64 %r1225, i64 %r1227)
  %r1229 = load i64, i64* %ptr_port_reg
  %r1230 = call i64 @_add(i64 %r1228, i64 %r1229)
  %r1231 = getelementptr [8 x i8], [8 x i8]* @.str.518, i64 0, i64 0
  %r1232 = ptrtoint i8* %r1231 to i64
  %r1233 = call i64 @_add(i64 %r1230, i64 %r1232)
  %r1234 = call i64 @emit(i64 %r1233)
  %r1235 = call i64 @next_reg()
  store i64 %r1235, i64* %ptr_val32
  %r1236 = load i64, i64* %ptr_val32
  %r1237 = getelementptr [14 x i8], [14 x i8]* @.str.519, i64 0, i64 0
  %r1238 = ptrtoint i8* %r1237 to i64
  %r1239 = call i64 @_add(i64 %r1236, i64 %r1238)
  %r1240 = load i64, i64* %ptr_val_reg
  %r1241 = call i64 @_add(i64 %r1239, i64 %r1240)
  %r1242 = getelementptr [8 x i8], [8 x i8]* @.str.520, i64 0, i64 0
  %r1243 = ptrtoint i8* %r1242 to i64
  %r1244 = call i64 @_add(i64 %r1241, i64 %r1243)
  %r1245 = call i64 @emit(i64 %r1244)
  %r1246 = getelementptr [89 x i8], [89 x i8]* @.str.521, i64 0, i64 0
  %r1247 = ptrtoint i8* %r1246 to i64
  %r1248 = load i64, i64* %ptr_val32
  %r1249 = call i64 @_add(i64 %r1247, i64 %r1248)
  %r1250 = getelementptr [7 x i8], [7 x i8]* @.str.522, i64 0, i64 0
  %r1251 = ptrtoint i8* %r1250 to i64
  %r1252 = call i64 @_add(i64 %r1249, i64 %r1251)
  %r1253 = load i64, i64* %ptr_port16
  %r1254 = call i64 @_add(i64 %r1252, i64 %r1253)
  %r1255 = getelementptr [2 x i8], [2 x i8]* @.str.523, i64 0, i64 0
  %r1256 = ptrtoint i8* %r1255 to i64
  %r1257 = call i64 @_add(i64 %r1254, i64 %r1256)
  %r1258 = call i64 @emit(i64 %r1257)
  %r1259 = getelementptr [2 x i8], [2 x i8]* @.str.524, i64 0, i64 0
  %r1260 = ptrtoint i8* %r1259 to i64
  ret i64 %r1260
  br label %L853
L853:
  %r1261 = load i64, i64* %ptr_name
  %r1262 = getelementptr [11 x i8], [11 x i8]* @.str.525, i64 0, i64 0
  %r1263 = ptrtoint i8* %r1262 to i64
  %r1264 = call i64 @_eq(i64 %r1261, i64 %r1263)
  %r1265 = icmp ne i64 %r1264, 0
  br i1 %r1265, label %L854, label %L856
L854:
  %r1266 = load i64, i64* %ptr_node
  %r1267 = getelementptr [5 x i8], [5 x i8]* @.str.526, i64 0, i64 0
  %r1268 = ptrtoint i8* %r1267 to i64
  %r1269 = call i64 @_get(i64 %r1266, i64 %r1268)
  %r1270 = call i64 @_get(i64 %r1269, i64 0)
  %r1271 = call i64 @compile_expr(i64 %r1270)
  store i64 %r1271, i64* %ptr_port_reg
  %r1272 = call i64 @next_reg()
  store i64 %r1272, i64* %ptr_port16
  %r1273 = load i64, i64* %ptr_port16
  %r1274 = getelementptr [14 x i8], [14 x i8]* @.str.527, i64 0, i64 0
  %r1275 = ptrtoint i8* %r1274 to i64
  %r1276 = call i64 @_add(i64 %r1273, i64 %r1275)
  %r1277 = load i64, i64* %ptr_port_reg
  %r1278 = call i64 @_add(i64 %r1276, i64 %r1277)
  %r1279 = getelementptr [8 x i8], [8 x i8]* @.str.528, i64 0, i64 0
  %r1280 = ptrtoint i8* %r1279 to i64
  %r1281 = call i64 @_add(i64 %r1278, i64 %r1280)
  %r1282 = call i64 @emit(i64 %r1281)
  %r1283 = call i64 @next_reg()
  store i64 %r1283, i64* %ptr_res32
  %r1284 = load i64, i64* %ptr_res32
  %r1285 = getelementptr [91 x i8], [91 x i8]* @.str.529, i64 0, i64 0
  %r1286 = ptrtoint i8* %r1285 to i64
  %r1287 = call i64 @_add(i64 %r1284, i64 %r1286)
  %r1288 = load i64, i64* %ptr_port16
  %r1289 = call i64 @_add(i64 %r1287, i64 %r1288)
  %r1290 = getelementptr [2 x i8], [2 x i8]* @.str.530, i64 0, i64 0
  %r1291 = ptrtoint i8* %r1290 to i64
  %r1292 = call i64 @_add(i64 %r1289, i64 %r1291)
  %r1293 = call i64 @emit(i64 %r1292)
  %r1294 = call i64 @next_reg()
  store i64 %r1294, i64* %ptr_res64
  %r1295 = load i64, i64* %ptr_res64
  %r1296 = getelementptr [13 x i8], [13 x i8]* @.str.531, i64 0, i64 0
  %r1297 = ptrtoint i8* %r1296 to i64
  %r1298 = call i64 @_add(i64 %r1295, i64 %r1297)
  %r1299 = load i64, i64* %ptr_res32
  %r1300 = call i64 @_add(i64 %r1298, i64 %r1299)
  %r1301 = getelementptr [8 x i8], [8 x i8]* @.str.532, i64 0, i64 0
  %r1302 = ptrtoint i8* %r1301 to i64
  %r1303 = call i64 @_add(i64 %r1300, i64 %r1302)
  %r1304 = call i64 @emit(i64 %r1303)
  %r1305 = load i64, i64* %ptr_res64
  ret i64 %r1305
  br label %L856
L856:
  %r1306 = load i64, i64* %ptr_name
  %r1307 = getelementptr [12 x i8], [12 x i8]* @.str.533, i64 0, i64 0
  %r1308 = ptrtoint i8* %r1307 to i64
  %r1309 = call i64 @_eq(i64 %r1306, i64 %r1308)
  %r1310 = icmp ne i64 %r1309, 0
  br i1 %r1310, label %L857, label %L859
L857:
  %r1311 = load i64, i64* %ptr_node
  %r1312 = getelementptr [5 x i8], [5 x i8]* @.str.534, i64 0, i64 0
  %r1313 = ptrtoint i8* %r1312 to i64
  %r1314 = call i64 @_get(i64 %r1311, i64 %r1313)
  %r1315 = call i64 @_get(i64 %r1314, i64 0)
  %r1316 = call i64 @compile_expr(i64 %r1315)
  store i64 %r1316, i64* %ptr_addr_reg
  %r1317 = call i64 @next_reg()
  store i64 %r1317, i64* %ptr_ptr_reg
  %r1318 = load i64, i64* %ptr_ptr_reg
  %r1319 = getelementptr [17 x i8], [17 x i8]* @.str.535, i64 0, i64 0
  %r1320 = ptrtoint i8* %r1319 to i64
  %r1321 = call i64 @_add(i64 %r1318, i64 %r1320)
  %r1322 = load i64, i64* %ptr_addr_reg
  %r1323 = call i64 @_add(i64 %r1321, i64 %r1322)
  %r1324 = getelementptr [9 x i8], [9 x i8]* @.str.536, i64 0, i64 0
  %r1325 = ptrtoint i8* %r1324 to i64
  %r1326 = call i64 @_add(i64 %r1323, i64 %r1325)
  %r1327 = call i64 @emit(i64 %r1326)
  %r1328 = call i64 @next_reg()
  store i64 %r1328, i64* %ptr_val32
  %r1329 = load i64, i64* %ptr_val32
  %r1330 = getelementptr [28 x i8], [28 x i8]* @.str.537, i64 0, i64 0
  %r1331 = ptrtoint i8* %r1330 to i64
  %r1332 = call i64 @_add(i64 %r1329, i64 %r1331)
  %r1333 = load i64, i64* %ptr_ptr_reg
  %r1334 = call i64 @_add(i64 %r1332, i64 %r1333)
  %r1335 = call i64 @emit(i64 %r1334)
  %r1336 = call i64 @next_reg()
  store i64 %r1336, i64* %ptr_res64
  %r1337 = load i64, i64* %ptr_res64
  %r1338 = getelementptr [13 x i8], [13 x i8]* @.str.538, i64 0, i64 0
  %r1339 = ptrtoint i8* %r1338 to i64
  %r1340 = call i64 @_add(i64 %r1337, i64 %r1339)
  %r1341 = load i64, i64* %ptr_val32
  %r1342 = call i64 @_add(i64 %r1340, i64 %r1341)
  %r1343 = getelementptr [8 x i8], [8 x i8]* @.str.539, i64 0, i64 0
  %r1344 = ptrtoint i8* %r1343 to i64
  %r1345 = call i64 @_add(i64 %r1342, i64 %r1344)
  %r1346 = call i64 @emit(i64 %r1345)
  %r1347 = load i64, i64* %ptr_res64
  ret i64 %r1347
  br label %L859
L859:
  %r1348 = load i64, i64* %ptr_name
  %r1349 = getelementptr [13 x i8], [13 x i8]* @.str.540, i64 0, i64 0
  %r1350 = ptrtoint i8* %r1349 to i64
  %r1351 = call i64 @_eq(i64 %r1348, i64 %r1350)
  %r1352 = icmp ne i64 %r1351, 0
  br i1 %r1352, label %L860, label %L862
L860:
  %r1353 = load i64, i64* %ptr_node
  %r1354 = getelementptr [5 x i8], [5 x i8]* @.str.541, i64 0, i64 0
  %r1355 = ptrtoint i8* %r1354 to i64
  %r1356 = call i64 @_get(i64 %r1353, i64 %r1355)
  %r1357 = call i64 @_get(i64 %r1356, i64 0)
  %r1358 = call i64 @compile_expr(i64 %r1357)
  store i64 %r1358, i64* %ptr_addr_reg
  %r1359 = load i64, i64* %ptr_node
  %r1360 = getelementptr [5 x i8], [5 x i8]* @.str.542, i64 0, i64 0
  %r1361 = ptrtoint i8* %r1360 to i64
  %r1362 = call i64 @_get(i64 %r1359, i64 %r1361)
  %r1363 = call i64 @_get(i64 %r1362, i64 1)
  %r1364 = call i64 @compile_expr(i64 %r1363)
  store i64 %r1364, i64* %ptr_val_reg
  %r1365 = call i64 @next_reg()
  store i64 %r1365, i64* %ptr_ptr_reg
  %r1366 = load i64, i64* %ptr_ptr_reg
  %r1367 = getelementptr [17 x i8], [17 x i8]* @.str.543, i64 0, i64 0
  %r1368 = ptrtoint i8* %r1367 to i64
  %r1369 = call i64 @_add(i64 %r1366, i64 %r1368)
  %r1370 = load i64, i64* %ptr_addr_reg
  %r1371 = call i64 @_add(i64 %r1369, i64 %r1370)
  %r1372 = getelementptr [9 x i8], [9 x i8]* @.str.544, i64 0, i64 0
  %r1373 = ptrtoint i8* %r1372 to i64
  %r1374 = call i64 @_add(i64 %r1371, i64 %r1373)
  %r1375 = call i64 @emit(i64 %r1374)
  %r1376 = call i64 @next_reg()
  store i64 %r1376, i64* %ptr_val32
  %r1377 = load i64, i64* %ptr_val32
  %r1378 = getelementptr [14 x i8], [14 x i8]* @.str.545, i64 0, i64 0
  %r1379 = ptrtoint i8* %r1378 to i64
  %r1380 = call i64 @_add(i64 %r1377, i64 %r1379)
  %r1381 = load i64, i64* %ptr_val_reg
  %r1382 = call i64 @_add(i64 %r1380, i64 %r1381)
  %r1383 = getelementptr [8 x i8], [8 x i8]* @.str.546, i64 0, i64 0
  %r1384 = ptrtoint i8* %r1383 to i64
  %r1385 = call i64 @_add(i64 %r1382, i64 %r1384)
  %r1386 = call i64 @emit(i64 %r1385)
  %r1387 = getelementptr [20 x i8], [20 x i8]* @.str.547, i64 0, i64 0
  %r1388 = ptrtoint i8* %r1387 to i64
  %r1389 = load i64, i64* %ptr_val32
  %r1390 = call i64 @_add(i64 %r1388, i64 %r1389)
  %r1391 = getelementptr [8 x i8], [8 x i8]* @.str.548, i64 0, i64 0
  %r1392 = ptrtoint i8* %r1391 to i64
  %r1393 = call i64 @_add(i64 %r1390, i64 %r1392)
  %r1394 = load i64, i64* %ptr_ptr_reg
  %r1395 = call i64 @_add(i64 %r1393, i64 %r1394)
  %r1396 = call i64 @emit(i64 %r1395)
  %r1397 = getelementptr [2 x i8], [2 x i8]* @.str.549, i64 0, i64 0
  %r1398 = ptrtoint i8* %r1397 to i64
  ret i64 %r1398
  br label %L862
L862:
  %r1399 = load i64, i64* %ptr_name
  %r1400 = getelementptr [16 x i8], [16 x i8]* @.str.550, i64 0, i64 0
  %r1401 = ptrtoint i8* %r1400 to i64
  %r1402 = call i64 @_eq(i64 %r1399, i64 %r1401)
  %r1403 = icmp ne i64 %r1402, 0
  br i1 %r1403, label %L863, label %L865
L863:
  %r1404 = load i64, i64* %ptr_node
  %r1405 = getelementptr [5 x i8], [5 x i8]* @.str.551, i64 0, i64 0
  %r1406 = ptrtoint i8* %r1405 to i64
  %r1407 = call i64 @_get(i64 %r1404, i64 %r1406)
  store i64 %r1407, i64* %ptr_args
  %r1408 = getelementptr [2 x i8], [2 x i8]* @.str.552, i64 0, i64 0
  %r1409 = ptrtoint i8* %r1408 to i64
  store i64 %r1409, i64* %ptr_a0
  %r1410 = load i64, i64* %ptr_args
  %r1411 = call i64 @mensura(i64 %r1410)
  %r1413 = icmp sgt i64 %r1411, 0
  %r1412 = zext i1 %r1413 to i64
  %r1414 = icmp ne i64 %r1412, 0
  br i1 %r1414, label %L866, label %L868
L866:
  %r1415 = load i64, i64* %ptr_args
  %r1416 = call i64 @_get(i64 %r1415, i64 0)
  %r1417 = call i64 @compile_expr(i64 %r1416)
  store i64 %r1417, i64* %ptr_a0
  br label %L868
L868:
  %r1418 = getelementptr [2 x i8], [2 x i8]* @.str.553, i64 0, i64 0
  %r1419 = ptrtoint i8* %r1418 to i64
  store i64 %r1419, i64* %ptr_a1
  %r1420 = load i64, i64* %ptr_args
  %r1421 = call i64 @mensura(i64 %r1420)
  %r1423 = icmp sgt i64 %r1421, 1
  %r1422 = zext i1 %r1423 to i64
  %r1424 = icmp ne i64 %r1422, 0
  br i1 %r1424, label %L869, label %L871
L869:
  %r1425 = load i64, i64* %ptr_args
  %r1426 = call i64 @_get(i64 %r1425, i64 1)
  %r1427 = call i64 @compile_expr(i64 %r1426)
  store i64 %r1427, i64* %ptr_a1
  br label %L871
L871:
  %r1428 = getelementptr [2 x i8], [2 x i8]* @.str.554, i64 0, i64 0
  %r1429 = ptrtoint i8* %r1428 to i64
  store i64 %r1429, i64* %ptr_a2
  %r1430 = load i64, i64* %ptr_args
  %r1431 = call i64 @mensura(i64 %r1430)
  %r1433 = icmp sgt i64 %r1431, 2
  %r1432 = zext i1 %r1433 to i64
  %r1434 = icmp ne i64 %r1432, 0
  br i1 %r1434, label %L872, label %L874
L872:
  %r1435 = load i64, i64* %ptr_args
  %r1436 = call i64 @_get(i64 %r1435, i64 2)
  %r1437 = call i64 @compile_expr(i64 %r1436)
  store i64 %r1437, i64* %ptr_a2
  br label %L874
L874:
  %r1438 = getelementptr [2 x i8], [2 x i8]* @.str.555, i64 0, i64 0
  %r1439 = ptrtoint i8* %r1438 to i64
  store i64 %r1439, i64* %ptr_a3
  %r1440 = load i64, i64* %ptr_args
  %r1441 = call i64 @mensura(i64 %r1440)
  %r1443 = icmp sgt i64 %r1441, 3
  %r1442 = zext i1 %r1443 to i64
  %r1444 = icmp ne i64 %r1442, 0
  br i1 %r1444, label %L875, label %L877
L875:
  %r1445 = load i64, i64* %ptr_args
  %r1446 = call i64 @_get(i64 %r1445, i64 3)
  %r1447 = call i64 @compile_expr(i64 %r1446)
  store i64 %r1447, i64* %ptr_a3
  br label %L877
L877:
  %r1448 = getelementptr [2 x i8], [2 x i8]* @.str.556, i64 0, i64 0
  %r1449 = ptrtoint i8* %r1448 to i64
  store i64 %r1449, i64* %ptr_a4
  %r1450 = load i64, i64* %ptr_args
  %r1451 = call i64 @mensura(i64 %r1450)
  %r1453 = icmp sgt i64 %r1451, 4
  %r1452 = zext i1 %r1453 to i64
  %r1454 = icmp ne i64 %r1452, 0
  br i1 %r1454, label %L878, label %L880
L878:
  %r1455 = load i64, i64* %ptr_args
  %r1456 = call i64 @_get(i64 %r1455, i64 4)
  %r1457 = call i64 @compile_expr(i64 %r1456)
  store i64 %r1457, i64* %ptr_a4
  br label %L880
L880:
  %r1458 = getelementptr [2 x i8], [2 x i8]* @.str.557, i64 0, i64 0
  %r1459 = ptrtoint i8* %r1458 to i64
  store i64 %r1459, i64* %ptr_a5
  %r1460 = load i64, i64* %ptr_args
  %r1461 = call i64 @mensura(i64 %r1460)
  %r1463 = icmp sgt i64 %r1461, 5
  %r1462 = zext i1 %r1463 to i64
  %r1464 = icmp ne i64 %r1462, 0
  br i1 %r1464, label %L881, label %L883
L881:
  %r1465 = load i64, i64* %ptr_args
  %r1466 = call i64 @_get(i64 %r1465, i64 5)
  %r1467 = call i64 @compile_expr(i64 %r1466)
  store i64 %r1467, i64* %ptr_a5
  br label %L883
L883:
  %r1468 = getelementptr [2 x i8], [2 x i8]* @.str.558, i64 0, i64 0
  %r1469 = ptrtoint i8* %r1468 to i64
  store i64 %r1469, i64* %ptr_a6
  %r1470 = load i64, i64* %ptr_args
  %r1471 = call i64 @mensura(i64 %r1470)
  %r1473 = icmp sgt i64 %r1471, 6
  %r1472 = zext i1 %r1473 to i64
  %r1474 = icmp ne i64 %r1472, 0
  br i1 %r1474, label %L884, label %L886
L884:
  %r1475 = load i64, i64* %ptr_args
  %r1476 = call i64 @_get(i64 %r1475, i64 6)
  %r1477 = call i64 @compile_expr(i64 %r1476)
  store i64 %r1477, i64* %ptr_a6
  br label %L886
L886:
  %r1478 = call i64 @next_reg()
  store i64 %r1478, i64* %ptr_res
  %r1479 = load i64, i64* %ptr_res
  %r1480 = getelementptr [27 x i8], [27 x i8]* @.str.559, i64 0, i64 0
  %r1481 = ptrtoint i8* %r1480 to i64
  %r1482 = call i64 @_add(i64 %r1479, i64 %r1481)
  %r1483 = load i64, i64* %ptr_a0
  %r1484 = call i64 @_add(i64 %r1482, i64 %r1483)
  %r1485 = getelementptr [7 x i8], [7 x i8]* @.str.560, i64 0, i64 0
  %r1486 = ptrtoint i8* %r1485 to i64
  %r1487 = call i64 @_add(i64 %r1484, i64 %r1486)
  %r1488 = load i64, i64* %ptr_a1
  %r1489 = call i64 @_add(i64 %r1487, i64 %r1488)
  %r1490 = getelementptr [7 x i8], [7 x i8]* @.str.561, i64 0, i64 0
  %r1491 = ptrtoint i8* %r1490 to i64
  %r1492 = call i64 @_add(i64 %r1489, i64 %r1491)
  %r1493 = load i64, i64* %ptr_a2
  %r1494 = call i64 @_add(i64 %r1492, i64 %r1493)
  %r1495 = getelementptr [7 x i8], [7 x i8]* @.str.562, i64 0, i64 0
  %r1496 = ptrtoint i8* %r1495 to i64
  %r1497 = call i64 @_add(i64 %r1494, i64 %r1496)
  %r1498 = load i64, i64* %ptr_a3
  %r1499 = call i64 @_add(i64 %r1497, i64 %r1498)
  %r1500 = getelementptr [7 x i8], [7 x i8]* @.str.563, i64 0, i64 0
  %r1501 = ptrtoint i8* %r1500 to i64
  %r1502 = call i64 @_add(i64 %r1499, i64 %r1501)
  %r1503 = load i64, i64* %ptr_a4
  %r1504 = call i64 @_add(i64 %r1502, i64 %r1503)
  %r1505 = getelementptr [7 x i8], [7 x i8]* @.str.564, i64 0, i64 0
  %r1506 = ptrtoint i8* %r1505 to i64
  %r1507 = call i64 @_add(i64 %r1504, i64 %r1506)
  %r1508 = load i64, i64* %ptr_a5
  %r1509 = call i64 @_add(i64 %r1507, i64 %r1508)
  %r1510 = getelementptr [7 x i8], [7 x i8]* @.str.565, i64 0, i64 0
  %r1511 = ptrtoint i8* %r1510 to i64
  %r1512 = call i64 @_add(i64 %r1509, i64 %r1511)
  %r1513 = load i64, i64* %ptr_a6
  %r1514 = call i64 @_add(i64 %r1512, i64 %r1513)
  %r1515 = getelementptr [2 x i8], [2 x i8]* @.str.566, i64 0, i64 0
  %r1516 = ptrtoint i8* %r1515 to i64
  %r1517 = call i64 @_add(i64 %r1514, i64 %r1516)
  %r1518 = call i64 @emit(i64 %r1517)
  %r1519 = load i64, i64* %ptr_res
  ret i64 %r1519
  br label %L865
L865:
  %r1520 = load i64, i64* %ptr_name
  %r1521 = getelementptr [18 x i8], [18 x i8]* @.str.567, i64 0, i64 0
  %r1522 = ptrtoint i8* %r1521 to i64
  %r1523 = call i64 @_eq(i64 %r1520, i64 %r1522)
  %r1524 = icmp ne i64 %r1523, 0
  br i1 %r1524, label %L887, label %L889
L887:
  %r1525 = load i64, i64* %ptr_node
  %r1526 = getelementptr [5 x i8], [5 x i8]* @.str.568, i64 0, i64 0
  %r1527 = ptrtoint i8* %r1526 to i64
  %r1528 = call i64 @_get(i64 %r1525, i64 %r1527)
  %r1529 = call i64 @_get(i64 %r1528, i64 0)
  %r1530 = call i64 @compile_expr(i64 %r1529)
  store i64 %r1530, i64* %ptr_arg_idx
  %r1531 = call i64 @next_reg()
  store i64 %r1531, i64* %ptr_res
  %r1532 = load i64, i64* %ptr_res
  %r1533 = getelementptr [28 x i8], [28 x i8]* @.str.569, i64 0, i64 0
  %r1534 = ptrtoint i8* %r1533 to i64
  %r1535 = call i64 @_add(i64 %r1532, i64 %r1534)
  %r1536 = load i64, i64* %ptr_arg_idx
  %r1537 = call i64 @_add(i64 %r1535, i64 %r1536)
  %r1538 = getelementptr [2 x i8], [2 x i8]* @.str.570, i64 0, i64 0
  %r1539 = ptrtoint i8* %r1538 to i64
  %r1540 = call i64 @_add(i64 %r1537, i64 %r1539)
  %r1541 = call i64 @emit(i64 %r1540)
  %r1542 = load i64, i64* %ptr_res
  ret i64 %r1542
  br label %L889
L889:
  %r1543 = load i64, i64* %ptr_node
  %r1544 = getelementptr [5 x i8], [5 x i8]* @.str.571, i64 0, i64 0
  %r1545 = ptrtoint i8* %r1544 to i64
  %r1546 = call i64 @_get(i64 %r1543, i64 %r1545)
  store i64 %r1546, i64* %ptr_args
  %r1547 = getelementptr [1 x i8], [1 x i8]* @.str.572, i64 0, i64 0
  %r1548 = ptrtoint i8* %r1547 to i64
  store i64 %r1548, i64* %ptr_arg_str
  store i64 0, i64* %ptr_i
  br label %L890
L890:
  %r1549 = load i64, i64* %ptr_i
  %r1550 = load i64, i64* %ptr_args
  %r1551 = call i64 @mensura(i64 %r1550)
  %r1553 = icmp slt i64 %r1549, %r1551
  %r1552 = zext i1 %r1553 to i64
  %r1554 = icmp ne i64 %r1552, 0
  br i1 %r1554, label %L891, label %L892
L891:
  %r1555 = load i64, i64* %ptr_args
  %r1556 = load i64, i64* %ptr_i
  %r1557 = call i64 @_get(i64 %r1555, i64 %r1556)
  %r1558 = call i64 @compile_expr(i64 %r1557)
  store i64 %r1558, i64* %ptr_val
  %r1559 = load i64, i64* %ptr_arg_str
  %r1560 = getelementptr [5 x i8], [5 x i8]* @.str.573, i64 0, i64 0
  %r1561 = ptrtoint i8* %r1560 to i64
  %r1562 = call i64 @_add(i64 %r1559, i64 %r1561)
  %r1563 = load i64, i64* %ptr_val
  %r1564 = call i64 @_add(i64 %r1562, i64 %r1563)
  store i64 %r1564, i64* %ptr_arg_str
  %r1565 = load i64, i64* %ptr_i
  %r1566 = load i64, i64* %ptr_args
  %r1567 = call i64 @mensura(i64 %r1566)
  %r1568 = sub i64 %r1567, 1
  %r1570 = icmp slt i64 %r1565, %r1568
  %r1569 = zext i1 %r1570 to i64
  %r1571 = icmp ne i64 %r1569, 0
  br i1 %r1571, label %L893, label %L895
L893:
  %r1572 = load i64, i64* %ptr_arg_str
  %r1573 = getelementptr [3 x i8], [3 x i8]* @.str.574, i64 0, i64 0
  %r1574 = ptrtoint i8* %r1573 to i64
  %r1575 = call i64 @_add(i64 %r1572, i64 %r1574)
  store i64 %r1575, i64* %ptr_arg_str
  br label %L895
L895:
  %r1576 = load i64, i64* %ptr_i
  %r1577 = call i64 @_add(i64 %r1576, i64 1)
  store i64 %r1577, i64* %ptr_i
  br label %L890
L892:
  %r1578 = call i64 @next_reg()
  store i64 %r1578, i64* %ptr_res
  %r1579 = load i64, i64* %ptr_name
  %r1580 = getelementptr [7 x i8], [7 x i8]* @.str.575, i64 0, i64 0
  %r1581 = ptrtoint i8* %r1580 to i64
  %r1582 = call i64 @_eq(i64 %r1579, i64 %r1581)
  %r1583 = icmp ne i64 %r1582, 0
  br i1 %r1583, label %L896, label %L897
L896:
  %r1584 = load i64, i64* %ptr_res
  %r1585 = getelementptr [28 x i8], [28 x i8]* @.str.576, i64 0, i64 0
  %r1586 = ptrtoint i8* %r1585 to i64
  %r1587 = call i64 @_add(i64 %r1584, i64 %r1586)
  %r1588 = load i64, i64* %ptr_arg_str
  %r1589 = call i64 @_add(i64 %r1587, i64 %r1588)
  %r1590 = getelementptr [2 x i8], [2 x i8]* @.str.577, i64 0, i64 0
  %r1591 = ptrtoint i8* %r1590 to i64
  %r1592 = call i64 @_add(i64 %r1589, i64 %r1591)
  %r1593 = call i64 @emit(i64 %r1592)
  br label %L898
L897:
  %r1594 = load i64, i64* %ptr_res
  %r1595 = getelementptr [14 x i8], [14 x i8]* @.str.578, i64 0, i64 0
  %r1596 = ptrtoint i8* %r1595 to i64
  %r1597 = call i64 @_add(i64 %r1594, i64 %r1596)
  %r1598 = load i64, i64* %ptr_name
  %r1599 = call i64 @_add(i64 %r1597, i64 %r1598)
  %r1600 = getelementptr [2 x i8], [2 x i8]* @.str.579, i64 0, i64 0
  %r1601 = ptrtoint i8* %r1600 to i64
  %r1602 = call i64 @_add(i64 %r1599, i64 %r1601)
  %r1603 = load i64, i64* %ptr_arg_str
  %r1604 = call i64 @_add(i64 %r1602, i64 %r1603)
  %r1605 = getelementptr [2 x i8], [2 x i8]* @.str.580, i64 0, i64 0
  %r1606 = ptrtoint i8* %r1605 to i64
  %r1607 = call i64 @_add(i64 %r1604, i64 %r1606)
  %r1608 = call i64 @emit(i64 %r1607)
  br label %L898
L898:
  %r1609 = load i64, i64* %ptr_res
  ret i64 %r1609
  br label %L826
L826:
  %r1610 = getelementptr [2 x i8], [2 x i8]* @.str.581, i64 0, i64 0
  %r1611 = ptrtoint i8* %r1610 to i64
  ret i64 %r1611
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
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.582, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  %r5 = load i64, i64* @STMT_IMPORT
  %r6 = call i64 @_eq(i64 %r4, i64 %r5)
  %r7 = icmp ne i64 %r6, 0
  br i1 %r7, label %L899, label %L901
L899:
  %r8 = load i64, i64* %ptr_node
  %r9 = getelementptr [4 x i8], [4 x i8]* @.str.583, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  %r11 = call i64 @_get(i64 %r8, i64 %r10)
  store i64 %r11, i64* %ptr_path_node
  %r12 = load i64, i64* %ptr_path_node
  %r13 = getelementptr [5 x i8], [5 x i8]* @.str.584, i64 0, i64 0
  %r14 = ptrtoint i8* %r13 to i64
  %r15 = call i64 @_get(i64 %r12, i64 %r14)
  %r16 = load i64, i64* @EXPR_STRING
  %r17 = call i64 @_eq(i64 %r15, i64 %r16)
  %r18 = icmp ne i64 %r17, 0
  br i1 %r18, label %L902, label %L904
L902:
  %r19 = load i64, i64* %ptr_path_node
  %r20 = getelementptr [4 x i8], [4 x i8]* @.str.585, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  %r23 = call i64 @revelare(i64 %r22)
  store i64 %r23, i64* %ptr_f_src
  %r24 = load i64, i64* %ptr_f_src
  %r25 = call i64 @mensura(i64 %r24)
  %r27 = icmp sgt i64 %r25, 0
  %r26 = zext i1 %r27 to i64
  %r28 = icmp ne i64 %r26, 0
  br i1 %r28, label %L905, label %L906
L905:
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
  br label %L908
L908:
  %r34 = call i64 @peek()
  %r35 = getelementptr [5 x i8], [5 x i8]* @.str.586, i64 0, i64 0
  %r36 = ptrtoint i8* %r35 to i64
  %r37 = call i64 @_get(i64 %r34, i64 %r36)
  %r38 = load i64, i64* @TOK_EOF
  %r40 = call i64 @_eq(i64 %r37, i64 %r38)
  %r39 = xor i64 %r40, 1
  %r41 = icmp ne i64 %r39, 0
  br i1 %r41, label %L909, label %L910
L909:
  %r42 = call i64 @peek()
  %r43 = getelementptr [5 x i8], [5 x i8]* @.str.587, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = call i64 @_get(i64 %r42, i64 %r44)
  %r46 = load i64, i64* @TOK_CARET
  %r47 = call i64 @_eq(i64 %r45, i64 %r46)
  %r48 = icmp ne i64 %r47, 0
  br i1 %r48, label %L911, label %L912
L911:
  %r49 = call i64 @advance()
  br label %L913
L912:
  %r50 = call i64 @parse_stmt()
  %r51 = load i64, i64* %ptr_link_stmts
  call i64 @_append_poly(i64 %r51, i64 %r50)
  br label %L913
L913:
  br label %L908
L910:
  %r52 = load i64, i64* %ptr_link_stmts
  %r53 = call i64 @compile_block(i64 %r52)
  %r54 = load i64, i64* %ptr_old_tokens
  store i64 %r54, i64* @global_tokens
  %r55 = load i64, i64* %ptr_old_pos
  store i64 %r55, i64* @p_pos
  br label %L907
L906:
  %r56 = getelementptr [41 x i8], [41 x i8]* @.str.588, i64 0, i64 0
  %r57 = ptrtoint i8* %r56 to i64
  %r58 = load i64, i64* %ptr_path_node
  %r59 = getelementptr [4 x i8], [4 x i8]* @.str.589, i64 0, i64 0
  %r60 = ptrtoint i8* %r59 to i64
  %r61 = call i64 @_get(i64 %r58, i64 %r60)
  %r62 = call i64 @_add(i64 %r57, i64 %r61)
  call i64 @print_any(i64 %r62)
  br label %L907
L907:
  br label %L904
L904:
  br label %L901
L901:
  %r63 = load i64, i64* %ptr_node
  %r64 = getelementptr [5 x i8], [5 x i8]* @.str.590, i64 0, i64 0
  %r65 = ptrtoint i8* %r64 to i64
  %r66 = call i64 @_get(i64 %r63, i64 %r65)
  %r67 = load i64, i64* @STMT_LET
  %r68 = call i64 @_eq(i64 %r66, i64 %r67)
  %r69 = icmp ne i64 %r68, 0
  br i1 %r69, label %L914, label %L916
L914:
  %r70 = load i64, i64* %ptr_node
  %r71 = getelementptr [4 x i8], [4 x i8]* @.str.591, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_get(i64 %r70, i64 %r72)
  %r74 = call i64 @compile_expr(i64 %r73)
  store i64 %r74, i64* %ptr_val
  %r75 = load i64, i64* @var_map
  %r76 = load i64, i64* %ptr_node
  %r77 = getelementptr [5 x i8], [5 x i8]* @.str.592, i64 0, i64 0
  %r78 = ptrtoint i8* %r77 to i64
  %r79 = call i64 @_get(i64 %r76, i64 %r78)
  %r80 = call i64 @_get(i64 %r75, i64 %r79)
  store i64 %r80, i64* %ptr_ptr
  %r81 = load i64, i64* %ptr_ptr
  %r82 = call i64 @mensura(i64 %r81)
  %r83 = call i64 @_eq(i64 %r82, i64 0)
  %r84 = icmp ne i64 %r83, 0
  br i1 %r84, label %L917, label %L919
L917:
  %r85 = getelementptr [6 x i8], [6 x i8]* @.str.593, i64 0, i64 0
  %r86 = ptrtoint i8* %r85 to i64
  %r87 = load i64, i64* %ptr_node
  %r88 = getelementptr [5 x i8], [5 x i8]* @.str.594, i64 0, i64 0
  %r89 = ptrtoint i8* %r88 to i64
  %r90 = call i64 @_get(i64 %r87, i64 %r89)
  %r91 = call i64 @_add(i64 %r86, i64 %r90)
  store i64 %r91, i64* %ptr_ptr
  %r92 = load i64, i64* %ptr_ptr
  %r93 = getelementptr [14 x i8], [14 x i8]* @.str.595, i64 0, i64 0
  %r94 = ptrtoint i8* %r93 to i64
  %r95 = call i64 @_add(i64 %r92, i64 %r94)
  %r96 = call i64 @emit(i64 %r95)
  %r97 = load i64, i64* %ptr_ptr
  %r98 = load i64, i64* %ptr_node
  %r99 = getelementptr [5 x i8], [5 x i8]* @.str.596, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_get(i64 %r98, i64 %r100)
  %r102 = load i64, i64* @var_map
  call i64 @_set(i64 %r102, i64 %r101, i64 %r97)
  br label %L919
L919:
  %r103 = getelementptr [11 x i8], [11 x i8]* @.str.597, i64 0, i64 0
  %r104 = ptrtoint i8* %r103 to i64
  %r105 = load i64, i64* %ptr_val
  %r106 = call i64 @_add(i64 %r104, i64 %r105)
  %r107 = getelementptr [8 x i8], [8 x i8]* @.str.598, i64 0, i64 0
  %r108 = ptrtoint i8* %r107 to i64
  %r109 = call i64 @_add(i64 %r106, i64 %r108)
  %r110 = load i64, i64* %ptr_ptr
  %r111 = call i64 @_add(i64 %r109, i64 %r110)
  %r112 = call i64 @emit(i64 %r111)
  br label %L916
L916:
  %r113 = load i64, i64* %ptr_node
  %r114 = getelementptr [5 x i8], [5 x i8]* @.str.599, i64 0, i64 0
  %r115 = ptrtoint i8* %r114 to i64
  %r116 = call i64 @_get(i64 %r113, i64 %r115)
  %r117 = load i64, i64* @STMT_SET_INDEX
  %r118 = call i64 @_eq(i64 %r116, i64 %r117)
  %r119 = icmp ne i64 %r118, 0
  br i1 %r119, label %L920, label %L922
L920:
  %r120 = load i64, i64* %ptr_node
  %r121 = getelementptr [4 x i8], [4 x i8]* @.str.600, i64 0, i64 0
  %r122 = ptrtoint i8* %r121 to i64
  %r123 = call i64 @_get(i64 %r120, i64 %r122)
  %r124 = call i64 @compile_expr(i64 %r123)
  store i64 %r124, i64* %ptr_val
  %r125 = load i64, i64* %ptr_node
  %r126 = getelementptr [4 x i8], [4 x i8]* @.str.601, i64 0, i64 0
  %r127 = ptrtoint i8* %r126 to i64
  %r128 = call i64 @_get(i64 %r125, i64 %r127)
  %r129 = call i64 @compile_expr(i64 %r128)
  store i64 %r129, i64* %ptr_idx
  %r130 = load i64, i64* %ptr_node
  %r131 = getelementptr [5 x i8], [5 x i8]* @.str.602, i64 0, i64 0
  %r132 = ptrtoint i8* %r131 to i64
  %r133 = call i64 @_get(i64 %r130, i64 %r132)
  %r134 = call i64 @get_var_ptr(i64 %r133)
  store i64 %r134, i64* %ptr_list_ptr
  %r135 = load i64, i64* %ptr_list_ptr
  %r136 = call i64 @mensura(i64 %r135)
  %r137 = call i64 @_eq(i64 %r136, i64 0)
  %r138 = icmp ne i64 %r137, 0
  br i1 %r138, label %L923, label %L924
L923:
  %r139 = getelementptr [46 x i8], [46 x i8]* @.str.603, i64 0, i64 0
  %r140 = ptrtoint i8* %r139 to i64
  %r141 = load i64, i64* %ptr_node
  %r142 = getelementptr [5 x i8], [5 x i8]* @.str.604, i64 0, i64 0
  %r143 = ptrtoint i8* %r142 to i64
  %r144 = call i64 @_get(i64 %r141, i64 %r143)
  %r145 = call i64 @_add(i64 %r140, i64 %r144)
  %r146 = getelementptr [2 x i8], [2 x i8]* @.str.605, i64 0, i64 0
  %r147 = ptrtoint i8* %r146 to i64
  %r148 = call i64 @_add(i64 %r145, i64 %r147)
  call i64 @print_any(i64 %r148)
  br label %L925
L924:
  %r149 = call i64 @next_reg()
  store i64 %r149, i64* %ptr_list_reg
  %r150 = load i64, i64* %ptr_list_reg
  %r151 = getelementptr [19 x i8], [19 x i8]* @.str.606, i64 0, i64 0
  %r152 = ptrtoint i8* %r151 to i64
  %r153 = call i64 @_add(i64 %r150, i64 %r152)
  %r154 = load i64, i64* %ptr_list_ptr
  %r155 = call i64 @_add(i64 %r153, i64 %r154)
  %r156 = call i64 @emit(i64 %r155)
  %r157 = getelementptr [20 x i8], [20 x i8]* @.str.607, i64 0, i64 0
  %r158 = ptrtoint i8* %r157 to i64
  %r159 = load i64, i64* %ptr_list_reg
  %r160 = call i64 @_add(i64 %r158, i64 %r159)
  %r161 = getelementptr [7 x i8], [7 x i8]* @.str.608, i64 0, i64 0
  %r162 = ptrtoint i8* %r161 to i64
  %r163 = call i64 @_add(i64 %r160, i64 %r162)
  %r164 = load i64, i64* %ptr_idx
  %r165 = call i64 @_add(i64 %r163, i64 %r164)
  %r166 = getelementptr [7 x i8], [7 x i8]* @.str.609, i64 0, i64 0
  %r167 = ptrtoint i8* %r166 to i64
  %r168 = call i64 @_add(i64 %r165, i64 %r167)
  %r169 = load i64, i64* %ptr_val
  %r170 = call i64 @_add(i64 %r168, i64 %r169)
  %r171 = getelementptr [2 x i8], [2 x i8]* @.str.610, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_add(i64 %r170, i64 %r172)
  %r174 = call i64 @emit(i64 %r173)
  br label %L925
L925:
  br label %L922
L922:
  %r175 = load i64, i64* %ptr_node
  %r176 = getelementptr [5 x i8], [5 x i8]* @.str.611, i64 0, i64 0
  %r177 = ptrtoint i8* %r176 to i64
  %r178 = call i64 @_get(i64 %r175, i64 %r177)
  %r179 = load i64, i64* @STMT_ASSIGN
  %r180 = call i64 @_eq(i64 %r178, i64 %r179)
  %r181 = icmp ne i64 %r180, 0
  br i1 %r181, label %L926, label %L928
L926:
  %r182 = load i64, i64* %ptr_node
  %r183 = getelementptr [4 x i8], [4 x i8]* @.str.612, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_get(i64 %r182, i64 %r184)
  %r186 = call i64 @compile_expr(i64 %r185)
  store i64 %r186, i64* %ptr_val
  %r187 = load i64, i64* %ptr_node
  %r188 = getelementptr [5 x i8], [5 x i8]* @.str.613, i64 0, i64 0
  %r189 = ptrtoint i8* %r188 to i64
  %r190 = call i64 @_get(i64 %r187, i64 %r189)
  %r191 = call i64 @get_var_ptr(i64 %r190)
  store i64 %r191, i64* %ptr_ptr
  %r192 = load i64, i64* %ptr_ptr
  %r193 = call i64 @mensura(i64 %r192)
  %r194 = call i64 @_eq(i64 %r193, i64 0)
  %r195 = icmp ne i64 %r194, 0
  br i1 %r195, label %L929, label %L930
L929:
  %r196 = getelementptr [47 x i8], [47 x i8]* @.str.614, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = load i64, i64* %ptr_node
  %r199 = getelementptr [5 x i8], [5 x i8]* @.str.615, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = call i64 @_get(i64 %r198, i64 %r200)
  %r202 = call i64 @_add(i64 %r197, i64 %r201)
  %r203 = getelementptr [2 x i8], [2 x i8]* @.str.616, i64 0, i64 0
  %r204 = ptrtoint i8* %r203 to i64
  %r205 = call i64 @_add(i64 %r202, i64 %r204)
  call i64 @print_any(i64 %r205)
  br label %L931
L930:
  %r206 = getelementptr [11 x i8], [11 x i8]* @.str.617, i64 0, i64 0
  %r207 = ptrtoint i8* %r206 to i64
  %r208 = load i64, i64* %ptr_val
  %r209 = call i64 @_add(i64 %r207, i64 %r208)
  %r210 = getelementptr [8 x i8], [8 x i8]* @.str.618, i64 0, i64 0
  %r211 = ptrtoint i8* %r210 to i64
  %r212 = call i64 @_add(i64 %r209, i64 %r211)
  %r213 = load i64, i64* %ptr_ptr
  %r214 = call i64 @_add(i64 %r212, i64 %r213)
  %r215 = call i64 @emit(i64 %r214)
  br label %L931
L931:
  br label %L928
L928:
  %r216 = load i64, i64* %ptr_node
  %r217 = getelementptr [5 x i8], [5 x i8]* @.str.619, i64 0, i64 0
  %r218 = ptrtoint i8* %r217 to i64
  %r219 = call i64 @_get(i64 %r216, i64 %r218)
  %r220 = load i64, i64* @STMT_APPEND
  %r221 = call i64 @_eq(i64 %r219, i64 %r220)
  %r222 = icmp ne i64 %r221, 0
  br i1 %r222, label %L932, label %L934
L932:
  %r223 = load i64, i64* %ptr_node
  %r224 = getelementptr [4 x i8], [4 x i8]* @.str.620, i64 0, i64 0
  %r225 = ptrtoint i8* %r224 to i64
  %r226 = call i64 @_get(i64 %r223, i64 %r225)
  %r227 = call i64 @compile_expr(i64 %r226)
  store i64 %r227, i64* %ptr_val
  %r228 = load i64, i64* %ptr_node
  %r229 = getelementptr [5 x i8], [5 x i8]* @.str.621, i64 0, i64 0
  %r230 = ptrtoint i8* %r229 to i64
  %r231 = call i64 @_get(i64 %r228, i64 %r230)
  %r232 = call i64 @get_var_ptr(i64 %r231)
  store i64 %r232, i64* %ptr_list_ptr
  %r233 = load i64, i64* %ptr_list_ptr
  %r234 = call i64 @mensura(i64 %r233)
  %r235 = call i64 @_eq(i64 %r234, i64 0)
  %r236 = icmp ne i64 %r235, 0
  br i1 %r236, label %L935, label %L936
L935:
  %r237 = getelementptr [43 x i8], [43 x i8]* @.str.622, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = load i64, i64* %ptr_node
  %r240 = getelementptr [5 x i8], [5 x i8]* @.str.623, i64 0, i64 0
  %r241 = ptrtoint i8* %r240 to i64
  %r242 = call i64 @_get(i64 %r239, i64 %r241)
  %r243 = call i64 @_add(i64 %r238, i64 %r242)
  %r244 = getelementptr [2 x i8], [2 x i8]* @.str.624, i64 0, i64 0
  %r245 = ptrtoint i8* %r244 to i64
  %r246 = call i64 @_add(i64 %r243, i64 %r245)
  call i64 @print_any(i64 %r246)
  br label %L937
L936:
  %r247 = call i64 @next_reg()
  store i64 %r247, i64* %ptr_list_reg
  %r248 = load i64, i64* %ptr_list_reg
  %r249 = getelementptr [19 x i8], [19 x i8]* @.str.625, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = call i64 @_add(i64 %r248, i64 %r250)
  %r252 = load i64, i64* %ptr_list_ptr
  %r253 = call i64 @_add(i64 %r251, i64 %r252)
  %r254 = call i64 @emit(i64 %r253)
  %r255 = getelementptr [28 x i8], [28 x i8]* @.str.626, i64 0, i64 0
  %r256 = ptrtoint i8* %r255 to i64
  %r257 = load i64, i64* %ptr_list_reg
  %r258 = call i64 @_add(i64 %r256, i64 %r257)
  %r259 = getelementptr [7 x i8], [7 x i8]* @.str.627, i64 0, i64 0
  %r260 = ptrtoint i8* %r259 to i64
  %r261 = call i64 @_add(i64 %r258, i64 %r260)
  %r262 = load i64, i64* %ptr_val
  %r263 = call i64 @_add(i64 %r261, i64 %r262)
  %r264 = getelementptr [2 x i8], [2 x i8]* @.str.628, i64 0, i64 0
  %r265 = ptrtoint i8* %r264 to i64
  %r266 = call i64 @_add(i64 %r263, i64 %r265)
  %r267 = call i64 @emit(i64 %r266)
  br label %L937
L937:
  br label %L934
L934:
  %r268 = load i64, i64* %ptr_node
  %r269 = getelementptr [5 x i8], [5 x i8]* @.str.629, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @_get(i64 %r268, i64 %r270)
  %r272 = load i64, i64* @STMT_PRINT
  %r273 = call i64 @_eq(i64 %r271, i64 %r272)
  %r274 = icmp ne i64 %r273, 0
  br i1 %r274, label %L938, label %L940
L938:
  %r275 = getelementptr [29 x i8], [29 x i8]* @.str.630, i64 0, i64 0
  %r276 = ptrtoint i8* %r275 to i64
  call i64 @print_any(i64 %r276)
  %r277 = load i64, i64* %ptr_node
  %r278 = getelementptr [4 x i8], [4 x i8]* @.str.631, i64 0, i64 0
  %r279 = ptrtoint i8* %r278 to i64
  %r280 = call i64 @_get(i64 %r277, i64 %r279)
  %r281 = call i64 @compile_expr(i64 %r280)
  store i64 %r281, i64* %ptr_val
  %r282 = getelementptr [25 x i8], [25 x i8]* @.str.632, i64 0, i64 0
  %r283 = ptrtoint i8* %r282 to i64
  %r284 = load i64, i64* %ptr_val
  %r285 = call i64 @_add(i64 %r283, i64 %r284)
  %r286 = getelementptr [2 x i8], [2 x i8]* @.str.633, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = call i64 @_add(i64 %r285, i64 %r287)
  %r289 = call i64 @emit(i64 %r288)
  br label %L940
L940:
  %r290 = load i64, i64* %ptr_node
  %r291 = getelementptr [5 x i8], [5 x i8]* @.str.634, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_get(i64 %r290, i64 %r292)
  %r294 = load i64, i64* @STMT_BREAK
  %r295 = call i64 @_eq(i64 %r293, i64 %r294)
  %r296 = icmp ne i64 %r295, 0
  br i1 %r296, label %L941, label %L943
L941:
  %r297 = load i64, i64* @loop_end_stack
  %r298 = call i64 @mensura(i64 %r297)
  store i64 %r298, i64* %ptr_len
  %r299 = load i64, i64* %ptr_len
  %r301 = icmp sgt i64 %r299, 0
  %r300 = zext i1 %r301 to i64
  %r302 = icmp ne i64 %r300, 0
  br i1 %r302, label %L944, label %L946
L944:
  %r303 = load i64, i64* @loop_end_stack
  %r304 = load i64, i64* %ptr_len
  %r305 = sub i64 %r304, 1
  %r306 = call i64 @_get(i64 %r303, i64 %r305)
  store i64 %r306, i64* %ptr_lbl
  %r307 = getelementptr [11 x i8], [11 x i8]* @.str.635, i64 0, i64 0
  %r308 = ptrtoint i8* %r307 to i64
  %r309 = load i64, i64* %ptr_lbl
  %r310 = call i64 @_add(i64 %r308, i64 %r309)
  %r311 = call i64 @emit(i64 %r310)
  br label %L946
L946:
  store i64 1, i64* @block_terminated
  br label %L943
L943:
  %r312 = load i64, i64* %ptr_node
  %r313 = getelementptr [5 x i8], [5 x i8]* @.str.636, i64 0, i64 0
  %r314 = ptrtoint i8* %r313 to i64
  %r315 = call i64 @_get(i64 %r312, i64 %r314)
  %r316 = load i64, i64* @STMT_CONTINUE
  %r317 = call i64 @_eq(i64 %r315, i64 %r316)
  %r318 = icmp ne i64 %r317, 0
  br i1 %r318, label %L947, label %L949
L947:
  %r319 = load i64, i64* @loop_cond_stack
  %r320 = call i64 @mensura(i64 %r319)
  store i64 %r320, i64* %ptr_len
  %r321 = load i64, i64* %ptr_len
  %r323 = icmp sgt i64 %r321, 0
  %r322 = zext i1 %r323 to i64
  %r324 = icmp ne i64 %r322, 0
  br i1 %r324, label %L950, label %L952
L950:
  %r325 = load i64, i64* @loop_cond_stack
  %r326 = load i64, i64* %ptr_len
  %r327 = sub i64 %r326, 1
  %r328 = call i64 @_get(i64 %r325, i64 %r327)
  store i64 %r328, i64* %ptr_lbl
  %r329 = getelementptr [11 x i8], [11 x i8]* @.str.637, i64 0, i64 0
  %r330 = ptrtoint i8* %r329 to i64
  %r331 = load i64, i64* %ptr_lbl
  %r332 = call i64 @_add(i64 %r330, i64 %r331)
  %r333 = call i64 @emit(i64 %r332)
  br label %L952
L952:
  store i64 1, i64* @block_terminated
  br label %L949
L949:
  %r334 = load i64, i64* %ptr_node
  %r335 = getelementptr [5 x i8], [5 x i8]* @.str.638, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_get(i64 %r334, i64 %r336)
  %r338 = load i64, i64* @STMT_RETURN
  %r339 = call i64 @_eq(i64 %r337, i64 %r338)
  %r340 = icmp ne i64 %r339, 0
  br i1 %r340, label %L953, label %L955
L953:
  %r341 = load i64, i64* %ptr_node
  %r342 = getelementptr [4 x i8], [4 x i8]* @.str.639, i64 0, i64 0
  %r343 = ptrtoint i8* %r342 to i64
  %r344 = call i64 @_get(i64 %r341, i64 %r343)
  %r345 = call i64 @compile_expr(i64 %r344)
  store i64 %r345, i64* %ptr_val
  %r346 = getelementptr [9 x i8], [9 x i8]* @.str.640, i64 0, i64 0
  %r347 = ptrtoint i8* %r346 to i64
  %r348 = load i64, i64* %ptr_val
  %r349 = call i64 @_add(i64 %r347, i64 %r348)
  %r350 = call i64 @emit(i64 %r349)
  br label %L955
L955:
  %r351 = load i64, i64* %ptr_node
  %r352 = getelementptr [5 x i8], [5 x i8]* @.str.641, i64 0, i64 0
  %r353 = ptrtoint i8* %r352 to i64
  %r354 = call i64 @_get(i64 %r351, i64 %r353)
  %r355 = load i64, i64* @STMT_EXPR
  %r356 = call i64 @_eq(i64 %r354, i64 %r355)
  %r357 = icmp ne i64 %r356, 0
  br i1 %r357, label %L956, label %L958
L956:
  %r358 = load i64, i64* %ptr_node
  %r359 = getelementptr [5 x i8], [5 x i8]* @.str.642, i64 0, i64 0
  %r360 = ptrtoint i8* %r359 to i64
  %r361 = call i64 @_get(i64 %r358, i64 %r360)
  %r362 = call i64 @compile_expr(i64 %r361)
  br label %L958
L958:
  %r363 = load i64, i64* %ptr_node
  %r364 = getelementptr [5 x i8], [5 x i8]* @.str.643, i64 0, i64 0
  %r365 = ptrtoint i8* %r364 to i64
  %r366 = call i64 @_get(i64 %r363, i64 %r365)
  %r367 = load i64, i64* @STMT_IF
  %r368 = call i64 @_eq(i64 %r366, i64 %r367)
  %r369 = icmp ne i64 %r368, 0
  br i1 %r369, label %L959, label %L961
L959:
  %r370 = load i64, i64* %ptr_node
  %r371 = getelementptr [5 x i8], [5 x i8]* @.str.644, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_get(i64 %r370, i64 %r372)
  %r374 = call i64 @compile_expr(i64 %r373)
  store i64 %r374, i64* %ptr_cond
  %r375 = call i64 @next_reg()
  store i64 %r375, i64* %ptr_bool
  %r376 = load i64, i64* %ptr_bool
  %r377 = getelementptr [16 x i8], [16 x i8]* @.str.645, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_cond
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  %r382 = getelementptr [4 x i8], [4 x i8]* @.str.646, i64 0, i64 0
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
  %r390 = getelementptr [5 x i8], [5 x i8]* @.str.647, i64 0, i64 0
  %r391 = ptrtoint i8* %r390 to i64
  %r392 = call i64 @_get(i64 %r389, i64 %r391)
  %r393 = call i64 @mensura(i64 %r392)
  %r395 = icmp sgt i64 %r393, 0
  %r394 = zext i1 %r395 to i64
  store i64 %r394, i64* %ptr_has_else
  %r396 = load i64, i64* %ptr_has_else
  %r397 = icmp ne i64 %r396, 0
  br i1 %r397, label %L962, label %L963
L962:
  %r398 = getelementptr [7 x i8], [7 x i8]* @.str.648, i64 0, i64 0
  %r399 = ptrtoint i8* %r398 to i64
  %r400 = load i64, i64* %ptr_bool
  %r401 = call i64 @_add(i64 %r399, i64 %r400)
  %r402 = getelementptr [10 x i8], [10 x i8]* @.str.649, i64 0, i64 0
  %r403 = ptrtoint i8* %r402 to i64
  %r404 = call i64 @_add(i64 %r401, i64 %r403)
  %r405 = load i64, i64* %ptr_l_then
  %r406 = call i64 @_add(i64 %r404, i64 %r405)
  %r407 = getelementptr [10 x i8], [10 x i8]* @.str.650, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = call i64 @_add(i64 %r406, i64 %r408)
  %r410 = load i64, i64* %ptr_l_else
  %r411 = call i64 @_add(i64 %r409, i64 %r410)
  %r412 = call i64 @emit(i64 %r411)
  br label %L964
L963:
  %r413 = getelementptr [7 x i8], [7 x i8]* @.str.651, i64 0, i64 0
  %r414 = ptrtoint i8* %r413 to i64
  %r415 = load i64, i64* %ptr_bool
  %r416 = call i64 @_add(i64 %r414, i64 %r415)
  %r417 = getelementptr [10 x i8], [10 x i8]* @.str.652, i64 0, i64 0
  %r418 = ptrtoint i8* %r417 to i64
  %r419 = call i64 @_add(i64 %r416, i64 %r418)
  %r420 = load i64, i64* %ptr_l_then
  %r421 = call i64 @_add(i64 %r419, i64 %r420)
  %r422 = getelementptr [10 x i8], [10 x i8]* @.str.653, i64 0, i64 0
  %r423 = ptrtoint i8* %r422 to i64
  %r424 = call i64 @_add(i64 %r421, i64 %r423)
  %r425 = load i64, i64* %ptr_l_end
  %r426 = call i64 @_add(i64 %r424, i64 %r425)
  %r427 = call i64 @emit(i64 %r426)
  br label %L964
L964:
  %r428 = load i64, i64* %ptr_l_then
  %r429 = getelementptr [2 x i8], [2 x i8]* @.str.654, i64 0, i64 0
  %r430 = ptrtoint i8* %r429 to i64
  %r431 = call i64 @_add(i64 %r428, i64 %r430)
  %r432 = call i64 @emit_raw(i64 %r431)
  store i64 0, i64* @block_terminated
  %r433 = load i64, i64* %ptr_node
  %r434 = getelementptr [5 x i8], [5 x i8]* @.str.655, i64 0, i64 0
  %r435 = ptrtoint i8* %r434 to i64
  %r436 = call i64 @_get(i64 %r433, i64 %r435)
  %r437 = call i64 @compile_block(i64 %r436)
  %r438 = load i64, i64* @block_terminated
  %r439 = call i64 @_eq(i64 %r438, i64 0)
  %r440 = icmp ne i64 %r439, 0
  br i1 %r440, label %L965, label %L967
L965:
  %r441 = getelementptr [11 x i8], [11 x i8]* @.str.656, i64 0, i64 0
  %r442 = ptrtoint i8* %r441 to i64
  %r443 = load i64, i64* %ptr_l_end
  %r444 = call i64 @_add(i64 %r442, i64 %r443)
  %r445 = call i64 @emit(i64 %r444)
  br label %L967
L967:
  %r446 = load i64, i64* %ptr_has_else
  %r447 = icmp ne i64 %r446, 0
  br i1 %r447, label %L968, label %L970
L968:
  %r448 = load i64, i64* %ptr_l_else
  %r449 = getelementptr [2 x i8], [2 x i8]* @.str.657, i64 0, i64 0
  %r450 = ptrtoint i8* %r449 to i64
  %r451 = call i64 @_add(i64 %r448, i64 %r450)
  %r452 = call i64 @emit_raw(i64 %r451)
  store i64 0, i64* @block_terminated
  %r453 = load i64, i64* %ptr_node
  %r454 = getelementptr [5 x i8], [5 x i8]* @.str.658, i64 0, i64 0
  %r455 = ptrtoint i8* %r454 to i64
  %r456 = call i64 @_get(i64 %r453, i64 %r455)
  %r457 = call i64 @compile_block(i64 %r456)
  %r458 = load i64, i64* @block_terminated
  %r459 = call i64 @_eq(i64 %r458, i64 0)
  %r460 = icmp ne i64 %r459, 0
  br i1 %r460, label %L971, label %L973
L971:
  %r461 = getelementptr [11 x i8], [11 x i8]* @.str.659, i64 0, i64 0
  %r462 = ptrtoint i8* %r461 to i64
  %r463 = load i64, i64* %ptr_l_end
  %r464 = call i64 @_add(i64 %r462, i64 %r463)
  %r465 = call i64 @emit(i64 %r464)
  br label %L973
L973:
  br label %L970
L970:
  %r466 = load i64, i64* %ptr_l_end
  %r467 = getelementptr [2 x i8], [2 x i8]* @.str.660, i64 0, i64 0
  %r468 = ptrtoint i8* %r467 to i64
  %r469 = call i64 @_add(i64 %r466, i64 %r468)
  %r470 = call i64 @emit_raw(i64 %r469)
  store i64 0, i64* @block_terminated
  br label %L961
L961:
  %r471 = load i64, i64* %ptr_node
  %r472 = getelementptr [5 x i8], [5 x i8]* @.str.661, i64 0, i64 0
  %r473 = ptrtoint i8* %r472 to i64
  %r474 = call i64 @_get(i64 %r471, i64 %r473)
  %r475 = load i64, i64* @STMT_WHILE
  %r476 = call i64 @_eq(i64 %r474, i64 %r475)
  %r477 = icmp ne i64 %r476, 0
  br i1 %r477, label %L974, label %L976
L974:
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
  %r485 = getelementptr [11 x i8], [11 x i8]* @.str.662, i64 0, i64 0
  %r486 = ptrtoint i8* %r485 to i64
  %r487 = load i64, i64* %ptr_l_cond
  %r488 = call i64 @_add(i64 %r486, i64 %r487)
  %r489 = call i64 @emit(i64 %r488)
  %r490 = load i64, i64* %ptr_l_cond
  %r491 = getelementptr [2 x i8], [2 x i8]* @.str.663, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_add(i64 %r490, i64 %r492)
  %r494 = call i64 @emit_raw(i64 %r493)
  %r495 = load i64, i64* %ptr_node
  %r496 = getelementptr [5 x i8], [5 x i8]* @.str.664, i64 0, i64 0
  %r497 = ptrtoint i8* %r496 to i64
  %r498 = call i64 @_get(i64 %r495, i64 %r497)
  %r499 = call i64 @compile_expr(i64 %r498)
  store i64 %r499, i64* %ptr_cond
  %r500 = call i64 @next_reg()
  store i64 %r500, i64* %ptr_bool
  %r501 = load i64, i64* %ptr_bool
  %r502 = getelementptr [16 x i8], [16 x i8]* @.str.665, i64 0, i64 0
  %r503 = ptrtoint i8* %r502 to i64
  %r504 = call i64 @_add(i64 %r501, i64 %r503)
  %r505 = load i64, i64* %ptr_cond
  %r506 = call i64 @_add(i64 %r504, i64 %r505)
  %r507 = getelementptr [4 x i8], [4 x i8]* @.str.666, i64 0, i64 0
  %r508 = ptrtoint i8* %r507 to i64
  %r509 = call i64 @_add(i64 %r506, i64 %r508)
  %r510 = call i64 @emit(i64 %r509)
  %r511 = getelementptr [7 x i8], [7 x i8]* @.str.667, i64 0, i64 0
  %r512 = ptrtoint i8* %r511 to i64
  %r513 = load i64, i64* %ptr_bool
  %r514 = call i64 @_add(i64 %r512, i64 %r513)
  %r515 = getelementptr [10 x i8], [10 x i8]* @.str.668, i64 0, i64 0
  %r516 = ptrtoint i8* %r515 to i64
  %r517 = call i64 @_add(i64 %r514, i64 %r516)
  %r518 = load i64, i64* %ptr_l_body
  %r519 = call i64 @_add(i64 %r517, i64 %r518)
  %r520 = getelementptr [10 x i8], [10 x i8]* @.str.669, i64 0, i64 0
  %r521 = ptrtoint i8* %r520 to i64
  %r522 = call i64 @_add(i64 %r519, i64 %r521)
  %r523 = load i64, i64* %ptr_l_end
  %r524 = call i64 @_add(i64 %r522, i64 %r523)
  %r525 = call i64 @emit(i64 %r524)
  %r526 = load i64, i64* %ptr_l_body
  %r527 = getelementptr [2 x i8], [2 x i8]* @.str.670, i64 0, i64 0
  %r528 = ptrtoint i8* %r527 to i64
  %r529 = call i64 @_add(i64 %r526, i64 %r528)
  %r530 = call i64 @emit_raw(i64 %r529)
  %r531 = load i64, i64* %ptr_node
  %r532 = getelementptr [5 x i8], [5 x i8]* @.str.671, i64 0, i64 0
  %r533 = ptrtoint i8* %r532 to i64
  %r534 = call i64 @_get(i64 %r531, i64 %r533)
  %r535 = call i64 @compile_block(i64 %r534)
  %r536 = getelementptr [11 x i8], [11 x i8]* @.str.672, i64 0, i64 0
  %r537 = ptrtoint i8* %r536 to i64
  %r538 = load i64, i64* %ptr_l_cond
  %r539 = call i64 @_add(i64 %r537, i64 %r538)
  %r540 = call i64 @emit(i64 %r539)
  %r541 = load i64, i64* %ptr_l_end
  %r542 = getelementptr [2 x i8], [2 x i8]* @.str.673, i64 0, i64 0
  %r543 = ptrtoint i8* %r542 to i64
  %r544 = call i64 @_add(i64 %r541, i64 %r543)
  %r545 = call i64 @emit_raw(i64 %r544)
  store i64 0, i64* @block_terminated
  %r546 = load i64, i64* @loop_cond_stack
  %r547 = call i64 @mensura(i64 %r546)
  store i64 %r547, i64* %ptr_len
  %r548 = getelementptr [1 x i8], [1 x i8]* @.str.674, i64 0, i64 0
  %r549 = ptrtoint i8* %r548 to i64
  store i64 %r549, i64* %ptr_extract_dummy
  %r550 = call i64 @_list_new()
  store i64 %r550, i64* %ptr_popped_cond
  store i64 0, i64* %ptr_i
  br label %L977
L977:
  %r551 = load i64, i64* %ptr_i
  %r552 = load i64, i64* %ptr_len
  %r553 = sub i64 %r552, 1
  %r555 = icmp slt i64 %r551, %r553
  %r554 = zext i1 %r555 to i64
  %r556 = icmp ne i64 %r554, 0
  br i1 %r556, label %L978, label %L979
L978:
  %r557 = load i64, i64* @loop_cond_stack
  %r558 = load i64, i64* %ptr_i
  %r559 = call i64 @_get(i64 %r557, i64 %r558)
  %r560 = load i64, i64* %ptr_popped_cond
  call i64 @_append_poly(i64 %r560, i64 %r559)
  %r561 = load i64, i64* %ptr_i
  %r562 = call i64 @_add(i64 %r561, i64 1)
  store i64 %r562, i64* %ptr_i
  br label %L977
L979:
  %r563 = load i64, i64* %ptr_popped_cond
  store i64 %r563, i64* @loop_cond_stack
  %r564 = call i64 @_list_new()
  store i64 %r564, i64* %ptr_popped_end
  store i64 0, i64* %ptr_i
  br label %L980
L980:
  %r565 = load i64, i64* %ptr_i
  %r566 = load i64, i64* %ptr_len
  %r567 = sub i64 %r566, 1
  %r569 = icmp slt i64 %r565, %r567
  %r568 = zext i1 %r569 to i64
  %r570 = icmp ne i64 %r568, 0
  br i1 %r570, label %L981, label %L982
L981:
  %r571 = load i64, i64* @loop_end_stack
  %r572 = load i64, i64* %ptr_i
  %r573 = call i64 @_get(i64 %r571, i64 %r572)
  %r574 = load i64, i64* %ptr_popped_end
  call i64 @_append_poly(i64 %r574, i64 %r573)
  %r575 = load i64, i64* %ptr_i
  %r576 = call i64 @_add(i64 %r575, i64 1)
  store i64 %r576, i64* %ptr_i
  br label %L980
L982:
  %r577 = load i64, i64* %ptr_popped_end
  store i64 %r577, i64* @loop_end_stack
  br label %L976
L976:
  ret i64 0
}
define i64 @compile_block(i64 %arg_stmts) {
  %ptr_stmts = alloca i64
  store i64 %arg_stmts, i64* %ptr_stmts
  %ptr_i = alloca i64
  store i64 0, i64* %ptr_i
  br label %L983
L983:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L984, label %L985
L984:
  %r7 = load i64, i64* @block_terminated
  %r8 = call i64 @_eq(i64 %r7, i64 0)
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L986, label %L988
L986:
  %r10 = load i64, i64* %ptr_stmts
  %r11 = load i64, i64* %ptr_i
  %r12 = call i64 @_get(i64 %r10, i64 %r11)
  %r13 = call i64 @compile_stmt(i64 %r12)
  br label %L988
L988:
  %r14 = load i64, i64* %ptr_i
  %r15 = call i64 @_add(i64 %r14, i64 1)
  store i64 %r15, i64* %ptr_i
  br label %L983
L985:
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
  br label %L989
L989:
  %r1 = load i64, i64* %ptr_i
  %r2 = load i64, i64* %ptr_stmts
  %r3 = call i64 @mensura(i64 %r2)
  %r5 = icmp slt i64 %r1, %r3
  %r4 = zext i1 %r5 to i64
  %r6 = icmp ne i64 %r4, 0
  br i1 %r6, label %L990, label %L991
L990:
  %r7 = load i64, i64* %ptr_stmts
  %r8 = load i64, i64* %ptr_i
  %r9 = call i64 @_get(i64 %r7, i64 %r8)
  store i64 %r9, i64* %ptr_s
  %r10 = load i64, i64* %ptr_s
  %r11 = getelementptr [5 x i8], [5 x i8]* @.str.675, i64 0, i64 0
  %r12 = ptrtoint i8* %r11 to i64
  %r13 = call i64 @_get(i64 %r10, i64 %r12)
  %r14 = load i64, i64* @STMT_LET
  %r15 = call i64 @_eq(i64 %r13, i64 %r14)
  %r16 = icmp ne i64 %r15, 0
  br i1 %r16, label %L992, label %L994
L992:
  %r17 = load i64, i64* %ptr_s
  %r18 = getelementptr [5 x i8], [5 x i8]* @.str.676, i64 0, i64 0
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
  br i1 %r27, label %L995, label %L997
L995:
  %r28 = getelementptr [6 x i8], [6 x i8]* @.str.677, i64 0, i64 0
  %r29 = ptrtoint i8* %r28 to i64
  %r30 = load i64, i64* %ptr_nm
  %r31 = call i64 @_add(i64 %r29, i64 %r30)
  store i64 %r31, i64* %ptr_ptr
  %r32 = load i64, i64* %ptr_ptr
  %r33 = getelementptr [14 x i8], [14 x i8]* @.str.678, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_add(i64 %r32, i64 %r34)
  %r36 = call i64 @emit(i64 %r35)
  %r37 = load i64, i64* %ptr_ptr
  %r38 = load i64, i64* %ptr_nm
  %r39 = load i64, i64* @var_map
  call i64 @_set(i64 %r39, i64 %r38, i64 %r37)
  br label %L997
L997:
  br label %L994
L994:
  %r40 = load i64, i64* %ptr_s
  %r41 = getelementptr [5 x i8], [5 x i8]* @.str.679, i64 0, i64 0
  %r42 = ptrtoint i8* %r41 to i64
  %r43 = call i64 @_get(i64 %r40, i64 %r42)
  %r44 = load i64, i64* @STMT_IF
  %r45 = call i64 @_eq(i64 %r43, i64 %r44)
  %r46 = icmp ne i64 %r45, 0
  br i1 %r46, label %L998, label %L1000
L998:
  %r47 = load i64, i64* %ptr_s
  %r48 = getelementptr [5 x i8], [5 x i8]* @.str.680, i64 0, i64 0
  %r49 = ptrtoint i8* %r48 to i64
  %r50 = call i64 @_get(i64 %r47, i64 %r49)
  %r51 = call i64 @scan_for_vars(i64 %r50)
  %r52 = load i64, i64* %ptr_s
  %r53 = getelementptr [5 x i8], [5 x i8]* @.str.681, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = call i64 @_get(i64 %r52, i64 %r54)
  %r56 = call i64 @mensura(i64 %r55)
  %r58 = icmp sgt i64 %r56, 0
  %r57 = zext i1 %r58 to i64
  %r59 = icmp ne i64 %r57, 0
  br i1 %r59, label %L1001, label %L1003
L1001:
  %r60 = load i64, i64* %ptr_s
  %r61 = getelementptr [5 x i8], [5 x i8]* @.str.682, i64 0, i64 0
  %r62 = ptrtoint i8* %r61 to i64
  %r63 = call i64 @_get(i64 %r60, i64 %r62)
  %r64 = call i64 @scan_for_vars(i64 %r63)
  br label %L1003
L1003:
  br label %L1000
L1000:
  %r65 = load i64, i64* %ptr_s
  %r66 = getelementptr [5 x i8], [5 x i8]* @.str.683, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = call i64 @_get(i64 %r65, i64 %r67)
  %r69 = load i64, i64* @STMT_WHILE
  %r70 = call i64 @_eq(i64 %r68, i64 %r69)
  %r71 = icmp ne i64 %r70, 0
  br i1 %r71, label %L1004, label %L1006
L1004:
  %r72 = load i64, i64* %ptr_s
  %r73 = getelementptr [5 x i8], [5 x i8]* @.str.684, i64 0, i64 0
  %r74 = ptrtoint i8* %r73 to i64
  %r75 = call i64 @_get(i64 %r72, i64 %r74)
  %r76 = call i64 @scan_for_vars(i64 %r75)
  br label %L1006
L1006:
  %r77 = load i64, i64* %ptr_i
  %r78 = call i64 @_add(i64 %r77, i64 1)
  store i64 %r78, i64* %ptr_i
  br label %L989
L991:
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
  %r2 = getelementptr [5 x i8], [5 x i8]* @.str.685, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = call i64 @_get(i64 %r1, i64 %r3)
  store i64 %r4, i64* %ptr_name
  %r5 = load i64, i64* %ptr_name
  %r6 = getelementptr [5 x i8], [5 x i8]* @.str.686, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  %r8 = call i64 @_eq(i64 %r5, i64 %r7)
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L1007, label %L1009
L1007:
  %r10 = getelementptr [12 x i8], [12 x i8]* @.str.687, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  store i64 %r11, i64* %ptr_name
  br label %L1009
L1009:
  %r12 = getelementptr [13 x i8], [13 x i8]* @.str.688, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = load i64, i64* %ptr_name
  %r15 = call i64 @_add(i64 %r13, i64 %r14)
  %r16 = getelementptr [2 x i8], [2 x i8]* @.str.689, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  %r18 = call i64 @_add(i64 %r15, i64 %r17)
  store i64 %r18, i64* %ptr_header
  %r19 = load i64, i64* %ptr_node
  %r20 = getelementptr [7 x i8], [7 x i8]* @.str.690, i64 0, i64 0
  %r21 = ptrtoint i8* %r20 to i64
  %r22 = call i64 @_get(i64 %r19, i64 %r21)
  store i64 %r22, i64* %ptr_params
  store i64 0, i64* %ptr_i
  %r23 = call i64 @_map_new()
  store i64 %r23, i64* @var_map
  store i64 0, i64* @reg_count
  br label %L1010
L1010:
  %r24 = load i64, i64* %ptr_i
  %r25 = load i64, i64* %ptr_params
  %r26 = call i64 @mensura(i64 %r25)
  %r28 = icmp slt i64 %r24, %r26
  %r27 = zext i1 %r28 to i64
  %r29 = icmp ne i64 %r27, 0
  br i1 %r29, label %L1011, label %L1012
L1011:
  %r30 = load i64, i64* %ptr_header
  %r31 = getelementptr [10 x i8], [10 x i8]* @.str.691, i64 0, i64 0
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
  br i1 %r44, label %L1013, label %L1015
L1013:
  %r45 = load i64, i64* %ptr_header
  %r46 = getelementptr [3 x i8], [3 x i8]* @.str.692, i64 0, i64 0
  %r47 = ptrtoint i8* %r46 to i64
  %r48 = call i64 @_add(i64 %r45, i64 %r47)
  store i64 %r48, i64* %ptr_header
  br label %L1015
L1015:
  %r49 = load i64, i64* %ptr_i
  %r50 = call i64 @_add(i64 %r49, i64 1)
  store i64 %r50, i64* %ptr_i
  br label %L1010
L1012:
  %r51 = load i64, i64* %ptr_header
  %r52 = getelementptr [4 x i8], [4 x i8]* @.str.693, i64 0, i64 0
  %r53 = ptrtoint i8* %r52 to i64
  %r54 = call i64 @_add(i64 %r51, i64 %r53)
  store i64 %r54, i64* %ptr_header
  %r55 = load i64, i64* %ptr_header
  %r56 = call i64 @emit_raw(i64 %r55)
  store i64 0, i64* %ptr_i
  br label %L1016
L1016:
  %r57 = load i64, i64* %ptr_i
  %r58 = load i64, i64* %ptr_params
  %r59 = call i64 @mensura(i64 %r58)
  %r61 = icmp slt i64 %r57, %r59
  %r60 = zext i1 %r61 to i64
  %r62 = icmp ne i64 %r60, 0
  br i1 %r62, label %L1017, label %L1018
L1017:
  %r63 = load i64, i64* %ptr_params
  %r64 = load i64, i64* %ptr_i
  %r65 = call i64 @_get(i64 %r63, i64 %r64)
  store i64 %r65, i64* %ptr_p
  %r66 = getelementptr [6 x i8], [6 x i8]* @.str.694, i64 0, i64 0
  %r67 = ptrtoint i8* %r66 to i64
  %r68 = load i64, i64* %ptr_p
  %r69 = call i64 @_add(i64 %r67, i64 %r68)
  store i64 %r69, i64* %ptr_ptr
  %r70 = load i64, i64* %ptr_ptr
  %r71 = getelementptr [14 x i8], [14 x i8]* @.str.695, i64 0, i64 0
  %r72 = ptrtoint i8* %r71 to i64
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  %r74 = call i64 @emit(i64 %r73)
  %r75 = getelementptr [16 x i8], [16 x i8]* @.str.696, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = load i64, i64* %ptr_p
  %r78 = call i64 @_add(i64 %r76, i64 %r77)
  %r79 = getelementptr [8 x i8], [8 x i8]* @.str.697, i64 0, i64 0
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
  br label %L1016
L1018:
  %r90 = load i64, i64* %ptr_node
  %r91 = getelementptr [5 x i8], [5 x i8]* @.str.698, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_get(i64 %r90, i64 %r92)
  %r94 = call i64 @scan_for_vars(i64 %r93)
  %r95 = load i64, i64* %ptr_node
  %r96 = getelementptr [5 x i8], [5 x i8]* @.str.699, i64 0, i64 0
  %r97 = ptrtoint i8* %r96 to i64
  %r98 = call i64 @_get(i64 %r95, i64 %r97)
  %r99 = call i64 @compile_block(i64 %r98)
  %r100 = getelementptr [10 x i8], [10 x i8]* @.str.700, i64 0, i64 0
  %r101 = ptrtoint i8* %r100 to i64
  %r102 = call i64 @emit(i64 %r101)
  %r103 = getelementptr [2 x i8], [2 x i8]* @.str.701, i64 0, i64 0
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
  %ptr_ptr_thresh = alloca i64
  %ptr_arch = alloca i64
  %r1 = call i64 @signum_ex(i64 10)
  store i64 %r1, i64* %ptr_NL
  %r2 = getelementptr [29 x i8], [29 x i8]* @.str.702, i64 0, i64 0
  %r3 = ptrtoint i8* %r2 to i64
  %r4 = load i64, i64* %ptr_NL
  %r5 = call i64 @_add(i64 %r3, i64 %r4)
  store i64 %r5, i64* %ptr_s
  %r6 = getelementptr [11 x i8], [11 x i8]* @.str.703, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* %ptr_ptr_thresh
  %r8 = load i64, i64* %ptr_is_freestanding
  %r9 = icmp ne i64 %r8, 0
  br i1 %r9, label %L1019, label %L1021
L1019:
  %r10 = getelementptr [6 x i8], [6 x i8]* @.str.704, i64 0, i64 0
  %r11 = ptrtoint i8* %r10 to i64
  store i64 %r11, i64* %ptr_ptr_thresh
  br label %L1021
L1021:
  %r12 = getelementptr [20 x i8], [20 x i8]* @.str.705, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  store i64 %r13, i64* %ptr_arch
  %r14 = load i64, i64* %ptr_is_arm64
  %r15 = icmp ne i64 %r14, 0
  br i1 %r15, label %L1022, label %L1024
L1022:
  %r16 = getelementptr [22 x i8], [22 x i8]* @.str.706, i64 0, i64 0
  %r17 = ptrtoint i8* %r16 to i64
  store i64 %r17, i64* %ptr_arch
  br label %L1024
L1024:
  %r18 = load i64, i64* %ptr_s
  %r19 = getelementptr [18 x i8], [18 x i8]* @.str.707, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_add(i64 %r18, i64 %r20)
  %r22 = load i64, i64* %ptr_arch
  %r23 = call i64 @_add(i64 %r21, i64 %r22)
  %r24 = getelementptr [2 x i8], [2 x i8]* @.str.708, i64 0, i64 0
  %r25 = ptrtoint i8* %r24 to i64
  %r26 = call i64 @_add(i64 %r23, i64 %r25)
  %r27 = load i64, i64* %ptr_NL
  %r28 = call i64 @_add(i64 %r26, i64 %r27)
  store i64 %r28, i64* %ptr_s
  %r29 = load i64, i64* %ptr_is_freestanding
  %r30 = call i64 @_eq(i64 %r29, i64 0)
  %r31 = icmp ne i64 %r30, 0
  br i1 %r31, label %L1025, label %L1027
L1025:
  %r32 = load i64, i64* %ptr_s
  %r33 = getelementptr [30 x i8], [30 x i8]* @.str.709, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  %r35 = call i64 @_add(i64 %r32, i64 %r34)
  %r36 = load i64, i64* %ptr_NL
  %r37 = call i64 @_add(i64 %r35, i64 %r36)
  store i64 %r37, i64* %ptr_s
  %r38 = load i64, i64* %ptr_s
  %r39 = getelementptr [25 x i8], [25 x i8]* @.str.710, i64 0, i64 0
  %r40 = ptrtoint i8* %r39 to i64
  %r41 = call i64 @_add(i64 %r38, i64 %r40)
  %r42 = load i64, i64* %ptr_NL
  %r43 = call i64 @_add(i64 %r41, i64 %r42)
  store i64 %r43, i64* %ptr_s
  %r44 = load i64, i64* %ptr_s
  %r45 = getelementptr [25 x i8], [25 x i8]* @.str.711, i64 0, i64 0
  %r46 = ptrtoint i8* %r45 to i64
  %r47 = call i64 @_add(i64 %r44, i64 %r46)
  %r48 = load i64, i64* %ptr_NL
  %r49 = call i64 @_add(i64 %r47, i64 %r48)
  store i64 %r49, i64* %ptr_s
  %r50 = load i64, i64* %ptr_s
  %r51 = getelementptr [31 x i8], [31 x i8]* @.str.712, i64 0, i64 0
  %r52 = ptrtoint i8* %r51 to i64
  %r53 = call i64 @_add(i64 %r50, i64 %r52)
  %r54 = load i64, i64* %ptr_NL
  %r55 = call i64 @_add(i64 %r53, i64 %r54)
  store i64 %r55, i64* %ptr_s
  %r56 = load i64, i64* %ptr_s
  %r57 = getelementptr [23 x i8], [23 x i8]* @.str.713, i64 0, i64 0
  %r58 = ptrtoint i8* %r57 to i64
  %r59 = call i64 @_add(i64 %r56, i64 %r58)
  %r60 = load i64, i64* %ptr_NL
  %r61 = call i64 @_add(i64 %r59, i64 %r60)
  store i64 %r61, i64* %ptr_s
  %r62 = load i64, i64* %ptr_s
  %r63 = getelementptr [24 x i8], [24 x i8]* @.str.714, i64 0, i64 0
  %r64 = ptrtoint i8* %r63 to i64
  %r65 = call i64 @_add(i64 %r62, i64 %r64)
  %r66 = load i64, i64* %ptr_NL
  %r67 = call i64 @_add(i64 %r65, i64 %r66)
  store i64 %r67, i64* %ptr_s
  %r68 = load i64, i64* %ptr_s
  %r69 = getelementptr [29 x i8], [29 x i8]* @.str.715, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = call i64 @_add(i64 %r68, i64 %r70)
  %r72 = load i64, i64* %ptr_NL
  %r73 = call i64 @_add(i64 %r71, i64 %r72)
  store i64 %r73, i64* %ptr_s
  %r74 = load i64, i64* %ptr_s
  %r75 = getelementptr [34 x i8], [34 x i8]* @.str.716, i64 0, i64 0
  %r76 = ptrtoint i8* %r75 to i64
  %r77 = call i64 @_add(i64 %r74, i64 %r76)
  %r78 = load i64, i64* %ptr_NL
  %r79 = call i64 @_add(i64 %r77, i64 %r78)
  store i64 %r79, i64* %ptr_s
  %r80 = load i64, i64* %ptr_s
  %r81 = getelementptr [24 x i8], [24 x i8]* @.str.717, i64 0, i64 0
  %r82 = ptrtoint i8* %r81 to i64
  %r83 = call i64 @_add(i64 %r80, i64 %r82)
  %r84 = load i64, i64* %ptr_NL
  %r85 = call i64 @_add(i64 %r83, i64 %r84)
  store i64 %r85, i64* %ptr_s
  %r86 = load i64, i64* %ptr_s
  %r87 = getelementptr [39 x i8], [39 x i8]* @.str.718, i64 0, i64 0
  %r88 = ptrtoint i8* %r87 to i64
  %r89 = call i64 @_add(i64 %r86, i64 %r88)
  %r90 = load i64, i64* %ptr_NL
  %r91 = call i64 @_add(i64 %r89, i64 %r90)
  store i64 %r91, i64* %ptr_s
  %r92 = load i64, i64* %ptr_s
  %r93 = getelementptr [40 x i8], [40 x i8]* @.str.719, i64 0, i64 0
  %r94 = ptrtoint i8* %r93 to i64
  %r95 = call i64 @_add(i64 %r92, i64 %r94)
  %r96 = load i64, i64* %ptr_NL
  %r97 = call i64 @_add(i64 %r95, i64 %r96)
  store i64 %r97, i64* %ptr_s
  %r98 = load i64, i64* %ptr_s
  %r99 = getelementptr [25 x i8], [25 x i8]* @.str.720, i64 0, i64 0
  %r100 = ptrtoint i8* %r99 to i64
  %r101 = call i64 @_add(i64 %r98, i64 %r100)
  %r102 = load i64, i64* %ptr_NL
  %r103 = call i64 @_add(i64 %r101, i64 %r102)
  store i64 %r103, i64* %ptr_s
  %r104 = load i64, i64* %ptr_s
  %r105 = getelementptr [25 x i8], [25 x i8]* @.str.721, i64 0, i64 0
  %r106 = ptrtoint i8* %r105 to i64
  %r107 = call i64 @_add(i64 %r104, i64 %r106)
  %r108 = load i64, i64* %ptr_NL
  %r109 = call i64 @_add(i64 %r107, i64 %r108)
  store i64 %r109, i64* %ptr_s
  %r110 = load i64, i64* %ptr_s
  %r111 = getelementptr [25 x i8], [25 x i8]* @.str.722, i64 0, i64 0
  %r112 = ptrtoint i8* %r111 to i64
  %r113 = call i64 @_add(i64 %r110, i64 %r112)
  %r114 = load i64, i64* %ptr_NL
  %r115 = call i64 @_add(i64 %r113, i64 %r114)
  store i64 %r115, i64* %ptr_s
  %r116 = load i64, i64* %ptr_s
  %r117 = getelementptr [30 x i8], [30 x i8]* @.str.723, i64 0, i64 0
  %r118 = ptrtoint i8* %r117 to i64
  %r119 = call i64 @_add(i64 %r116, i64 %r118)
  %r120 = load i64, i64* %ptr_NL
  %r121 = call i64 @_add(i64 %r119, i64 %r120)
  store i64 %r121, i64* %ptr_s
  br label %L1027
L1027:
  %r122 = load i64, i64* %ptr_s
  %r123 = getelementptr [40 x i8], [40 x i8]* @.str.724, i64 0, i64 0
  %r124 = ptrtoint i8* %r123 to i64
  %r125 = call i64 @_add(i64 %r122, i64 %r124)
  %r126 = load i64, i64* %ptr_NL
  %r127 = call i64 @_add(i64 %r125, i64 %r126)
  store i64 %r127, i64* %ptr_s
  %r128 = load i64, i64* %ptr_s
  %r129 = getelementptr [40 x i8], [40 x i8]* @.str.725, i64 0, i64 0
  %r130 = ptrtoint i8* %r129 to i64
  %r131 = call i64 @_add(i64 %r128, i64 %r130)
  %r132 = load i64, i64* %ptr_NL
  %r133 = call i64 @_add(i64 %r131, i64 %r132)
  store i64 %r133, i64* %ptr_s
  %r134 = load i64, i64* %ptr_s
  %r135 = getelementptr [32 x i8], [32 x i8]* @.str.726, i64 0, i64 0
  %r136 = ptrtoint i8* %r135 to i64
  %r137 = call i64 @_add(i64 %r134, i64 %r136)
  %r138 = load i64, i64* %ptr_NL
  %r139 = call i64 @_add(i64 %r137, i64 %r138)
  store i64 %r139, i64* %ptr_s
  %r140 = load i64, i64* %ptr_s
  %r141 = getelementptr [73 x i8], [73 x i8]* @.str.727, i64 0, i64 0
  %r142 = ptrtoint i8* %r141 to i64
  %r143 = call i64 @_add(i64 %r140, i64 %r142)
  %r144 = load i64, i64* %ptr_NL
  %r145 = call i64 @_add(i64 %r143, i64 %r144)
  store i64 %r145, i64* %ptr_s
  %r146 = load i64, i64* %ptr_s
  %r147 = getelementptr [72 x i8], [72 x i8]* @.str.728, i64 0, i64 0
  %r148 = ptrtoint i8* %r147 to i64
  %r149 = call i64 @_add(i64 %r146, i64 %r148)
  %r150 = load i64, i64* %ptr_NL
  %r151 = call i64 @_add(i64 %r149, i64 %r150)
  store i64 %r151, i64* %ptr_s
  %r152 = load i64, i64* %ptr_s
  %r153 = getelementptr [71 x i8], [71 x i8]* @.str.729, i64 0, i64 0
  %r154 = ptrtoint i8* %r153 to i64
  %r155 = call i64 @_add(i64 %r152, i64 %r154)
  %r156 = load i64, i64* %ptr_NL
  %r157 = call i64 @_add(i64 %r155, i64 %r156)
  store i64 %r157, i64* %ptr_s
  %r158 = load i64, i64* %ptr_s
  %r159 = getelementptr [72 x i8], [72 x i8]* @.str.730, i64 0, i64 0
  %r160 = ptrtoint i8* %r159 to i64
  %r161 = call i64 @_add(i64 %r158, i64 %r160)
  %r162 = load i64, i64* %ptr_NL
  %r163 = call i64 @_add(i64 %r161, i64 %r162)
  store i64 %r163, i64* %ptr_s
  %r164 = load i64, i64* %ptr_s
  %r165 = getelementptr [67 x i8], [67 x i8]* @.str.731, i64 0, i64 0
  %r166 = ptrtoint i8* %r165 to i64
  %r167 = call i64 @_add(i64 %r164, i64 %r166)
  %r168 = load i64, i64* %ptr_NL
  %r169 = call i64 @_add(i64 %r167, i64 %r168)
  store i64 %r169, i64* %ptr_s
  %r170 = load i64, i64* %ptr_s
  %r171 = getelementptr [67 x i8], [67 x i8]* @.str.732, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_add(i64 %r170, i64 %r172)
  %r174 = load i64, i64* %ptr_NL
  %r175 = call i64 @_add(i64 %r173, i64 %r174)
  store i64 %r175, i64* %ptr_s
  %r176 = load i64, i64* %ptr_s
  %r177 = getelementptr [73 x i8], [73 x i8]* @.str.733, i64 0, i64 0
  %r178 = ptrtoint i8* %r177 to i64
  %r179 = call i64 @_add(i64 %r176, i64 %r178)
  %r180 = load i64, i64* %ptr_NL
  %r181 = call i64 @_add(i64 %r179, i64 %r180)
  store i64 %r181, i64* %ptr_s
  %r182 = load i64, i64* %ptr_s
  %r183 = getelementptr [72 x i8], [72 x i8]* @.str.734, i64 0, i64 0
  %r184 = ptrtoint i8* %r183 to i64
  %r185 = call i64 @_add(i64 %r182, i64 %r184)
  %r186 = load i64, i64* %ptr_NL
  %r187 = call i64 @_add(i64 %r185, i64 %r186)
  store i64 %r187, i64* %ptr_s
  %r188 = load i64, i64* %ptr_s
  %r189 = getelementptr [40 x i8], [40 x i8]* @.str.735, i64 0, i64 0
  %r190 = ptrtoint i8* %r189 to i64
  %r191 = call i64 @_add(i64 %r188, i64 %r190)
  %r192 = load i64, i64* %ptr_NL
  %r193 = call i64 @_add(i64 %r191, i64 %r192)
  store i64 %r193, i64* %ptr_s
  %r194 = load i64, i64* %ptr_s
  %r195 = getelementptr [36 x i8], [36 x i8]* @.str.736, i64 0, i64 0
  %r196 = ptrtoint i8* %r195 to i64
  %r197 = call i64 @_add(i64 %r194, i64 %r196)
  %r198 = load i64, i64* %ptr_NL
  %r199 = call i64 @_add(i64 %r197, i64 %r198)
  store i64 %r199, i64* %ptr_s
  %r200 = load i64, i64* %ptr_s
  %r201 = getelementptr [68 x i8], [68 x i8]* @.str.737, i64 0, i64 0
  %r202 = ptrtoint i8* %r201 to i64
  %r203 = call i64 @_add(i64 %r200, i64 %r202)
  %r204 = load i64, i64* %ptr_NL
  %r205 = call i64 @_add(i64 %r203, i64 %r204)
  store i64 %r205, i64* %ptr_s
  %r206 = load i64, i64* %ptr_s
  %r207 = getelementptr [71 x i8], [71 x i8]* @.str.738, i64 0, i64 0
  %r208 = ptrtoint i8* %r207 to i64
  %r209 = call i64 @_add(i64 %r206, i64 %r208)
  %r210 = load i64, i64* %ptr_NL
  %r211 = call i64 @_add(i64 %r209, i64 %r210)
  store i64 %r211, i64* %ptr_s
  %r212 = load i64, i64* %ptr_s
  %r213 = getelementptr [69 x i8], [69 x i8]* @.str.739, i64 0, i64 0
  %r214 = ptrtoint i8* %r213 to i64
  %r215 = call i64 @_add(i64 %r212, i64 %r214)
  %r216 = load i64, i64* %ptr_NL
  %r217 = call i64 @_add(i64 %r215, i64 %r216)
  store i64 %r217, i64* %ptr_s
  %r218 = load i64, i64* %ptr_s
  %r219 = getelementptr [39 x i8], [39 x i8]* @.str.740, i64 0, i64 0
  %r220 = ptrtoint i8* %r219 to i64
  %r221 = call i64 @_add(i64 %r218, i64 %r220)
  %r222 = load i64, i64* %ptr_NL
  %r223 = call i64 @_add(i64 %r221, i64 %r222)
  store i64 %r223, i64* %ptr_s
  %r224 = load i64, i64* %ptr_s
  %r225 = getelementptr [31 x i8], [31 x i8]* @.str.741, i64 0, i64 0
  %r226 = ptrtoint i8* %r225 to i64
  %r227 = call i64 @_add(i64 %r224, i64 %r226)
  %r228 = load i64, i64* %ptr_NL
  %r229 = call i64 @_add(i64 %r227, i64 %r228)
  store i64 %r229, i64* %ptr_s
  %r230 = load i64, i64* %ptr_s
  %r231 = getelementptr [31 x i8], [31 x i8]* @.str.742, i64 0, i64 0
  %r232 = ptrtoint i8* %r231 to i64
  %r233 = call i64 @_add(i64 %r230, i64 %r232)
  %r234 = load i64, i64* %ptr_NL
  %r235 = call i64 @_add(i64 %r233, i64 %r234)
  store i64 %r235, i64* %ptr_s
  %r236 = load i64, i64* %ptr_s
  %r237 = getelementptr [34 x i8], [34 x i8]* @.str.743, i64 0, i64 0
  %r238 = ptrtoint i8* %r237 to i64
  %r239 = call i64 @_add(i64 %r236, i64 %r238)
  %r240 = load i64, i64* %ptr_NL
  %r241 = call i64 @_add(i64 %r239, i64 %r240)
  store i64 %r241, i64* %ptr_s
  %r242 = load i64, i64* %ptr_s
  %r243 = getelementptr [34 x i8], [34 x i8]* @.str.744, i64 0, i64 0
  %r244 = ptrtoint i8* %r243 to i64
  %r245 = call i64 @_add(i64 %r242, i64 %r244)
  %r246 = load i64, i64* %ptr_NL
  %r247 = call i64 @_add(i64 %r245, i64 %r246)
  store i64 %r247, i64* %ptr_s
  %r248 = load i64, i64* %ptr_s
  %r249 = getelementptr [25 x i8], [25 x i8]* @.str.745, i64 0, i64 0
  %r250 = ptrtoint i8* %r249 to i64
  %r251 = call i64 @_add(i64 %r248, i64 %r250)
  %r252 = load i64, i64* %ptr_NL
  %r253 = call i64 @_add(i64 %r251, i64 %r252)
  store i64 %r253, i64* %ptr_s
  %r254 = load i64, i64* %ptr_s
  %r255 = getelementptr [24 x i8], [24 x i8]* @.str.746, i64 0, i64 0
  %r256 = ptrtoint i8* %r255 to i64
  %r257 = call i64 @_add(i64 %r254, i64 %r256)
  %r258 = load i64, i64* %ptr_NL
  %r259 = call i64 @_add(i64 %r257, i64 %r258)
  store i64 %r259, i64* %ptr_s
  %r260 = load i64, i64* %ptr_s
  %r261 = getelementptr [36 x i8], [36 x i8]* @.str.747, i64 0, i64 0
  %r262 = ptrtoint i8* %r261 to i64
  %r263 = call i64 @_add(i64 %r260, i64 %r262)
  %r264 = load i64, i64* %ptr_NL
  %r265 = call i64 @_add(i64 %r263, i64 %r264)
  store i64 %r265, i64* %ptr_s
  %r266 = load i64, i64* %ptr_s
  %r267 = getelementptr [34 x i8], [34 x i8]* @.str.748, i64 0, i64 0
  %r268 = ptrtoint i8* %r267 to i64
  %r269 = call i64 @_add(i64 %r266, i64 %r268)
  %r270 = load i64, i64* %ptr_NL
  %r271 = call i64 @_add(i64 %r269, i64 %r270)
  store i64 %r271, i64* %ptr_s
  %r272 = load i64, i64* %ptr_s
  %r273 = getelementptr [38 x i8], [38 x i8]* @.str.749, i64 0, i64 0
  %r274 = ptrtoint i8* %r273 to i64
  %r275 = call i64 @_add(i64 %r272, i64 %r274)
  %r276 = load i64, i64* %ptr_NL
  %r277 = call i64 @_add(i64 %r275, i64 %r276)
  store i64 %r277, i64* %ptr_s
  %r278 = load i64, i64* %ptr_s
  %r279 = getelementptr [38 x i8], [38 x i8]* @.str.750, i64 0, i64 0
  %r280 = ptrtoint i8* %r279 to i64
  %r281 = call i64 @_add(i64 %r278, i64 %r280)
  %r282 = load i64, i64* %ptr_NL
  %r283 = call i64 @_add(i64 %r281, i64 %r282)
  store i64 %r283, i64* %ptr_s
  %r284 = load i64, i64* %ptr_s
  %r285 = getelementptr [15 x i8], [15 x i8]* @.str.751, i64 0, i64 0
  %r286 = ptrtoint i8* %r285 to i64
  %r287 = call i64 @_add(i64 %r284, i64 %r286)
  %r288 = load i64, i64* %ptr_NL
  %r289 = call i64 @_add(i64 %r287, i64 %r288)
  store i64 %r289, i64* %ptr_s
  %r290 = load i64, i64* %ptr_s
  %r291 = getelementptr [2 x i8], [2 x i8]* @.str.752, i64 0, i64 0
  %r292 = ptrtoint i8* %r291 to i64
  %r293 = call i64 @_add(i64 %r290, i64 %r292)
  %r294 = load i64, i64* %ptr_NL
  %r295 = call i64 @_add(i64 %r293, i64 %r294)
  store i64 %r295, i64* %ptr_s
  %r296 = load i64, i64* %ptr_s
  %r297 = getelementptr [34 x i8], [34 x i8]* @.str.753, i64 0, i64 0
  %r298 = ptrtoint i8* %r297 to i64
  %r299 = call i64 @_add(i64 %r296, i64 %r298)
  %r300 = load i64, i64* %ptr_NL
  %r301 = call i64 @_add(i64 %r299, i64 %r300)
  store i64 %r301, i64* %ptr_s
  %r302 = load i64, i64* %ptr_s
  %r303 = getelementptr [32 x i8], [32 x i8]* @.str.754, i64 0, i64 0
  %r304 = ptrtoint i8* %r303 to i64
  %r305 = call i64 @_add(i64 %r302, i64 %r304)
  %r306 = load i64, i64* %ptr_ptr_thresh
  %r307 = call i64 @_add(i64 %r305, i64 %r306)
  %r308 = load i64, i64* %ptr_NL
  %r309 = call i64 @_add(i64 %r307, i64 %r308)
  store i64 %r309, i64* %ptr_s
  %r310 = load i64, i64* %ptr_s
  %r311 = getelementptr [46 x i8], [46 x i8]* @.str.755, i64 0, i64 0
  %r312 = ptrtoint i8* %r311 to i64
  %r313 = call i64 @_add(i64 %r310, i64 %r312)
  %r314 = load i64, i64* %ptr_NL
  %r315 = call i64 @_add(i64 %r313, i64 %r314)
  store i64 %r315, i64* %ptr_s
  %r316 = load i64, i64* %ptr_s
  %r317 = getelementptr [21 x i8], [21 x i8]* @.str.756, i64 0, i64 0
  %r318 = ptrtoint i8* %r317 to i64
  %r319 = call i64 @_add(i64 %r316, i64 %r318)
  %r320 = load i64, i64* %ptr_NL
  %r321 = call i64 @_add(i64 %r319, i64 %r320)
  store i64 %r321, i64* %ptr_s
  %r322 = load i64, i64* %ptr_s
  %r323 = getelementptr [8 x i8], [8 x i8]* @.str.757, i64 0, i64 0
  %r324 = ptrtoint i8* %r323 to i64
  %r325 = call i64 @_add(i64 %r322, i64 %r324)
  %r326 = load i64, i64* %ptr_NL
  %r327 = call i64 @_add(i64 %r325, i64 %r326)
  store i64 %r327, i64* %ptr_s
  %r328 = load i64, i64* %ptr_s
  %r329 = getelementptr [34 x i8], [34 x i8]* @.str.758, i64 0, i64 0
  %r330 = ptrtoint i8* %r329 to i64
  %r331 = call i64 @_add(i64 %r328, i64 %r330)
  %r332 = load i64, i64* %ptr_NL
  %r333 = call i64 @_add(i64 %r331, i64 %r332)
  store i64 %r333, i64* %ptr_s
  %r334 = load i64, i64* %ptr_s
  %r335 = getelementptr [34 x i8], [34 x i8]* @.str.759, i64 0, i64 0
  %r336 = ptrtoint i8* %r335 to i64
  %r337 = call i64 @_add(i64 %r334, i64 %r336)
  %r338 = load i64, i64* %ptr_NL
  %r339 = call i64 @_add(i64 %r337, i64 %r338)
  store i64 %r339, i64* %ptr_s
  %r340 = load i64, i64* %ptr_s
  %r341 = getelementptr [33 x i8], [33 x i8]* @.str.760, i64 0, i64 0
  %r342 = ptrtoint i8* %r341 to i64
  %r343 = call i64 @_add(i64 %r340, i64 %r342)
  %r344 = load i64, i64* %ptr_NL
  %r345 = call i64 @_add(i64 %r343, i64 %r344)
  store i64 %r345, i64* %ptr_s
  %r346 = load i64, i64* %ptr_s
  %r347 = getelementptr [43 x i8], [43 x i8]* @.str.761, i64 0, i64 0
  %r348 = ptrtoint i8* %r347 to i64
  %r349 = call i64 @_add(i64 %r346, i64 %r348)
  %r350 = load i64, i64* %ptr_NL
  %r351 = call i64 @_add(i64 %r349, i64 %r350)
  store i64 %r351, i64* %ptr_s
  %r352 = load i64, i64* %ptr_s
  %r353 = getelementptr [6 x i8], [6 x i8]* @.str.762, i64 0, i64 0
  %r354 = ptrtoint i8* %r353 to i64
  %r355 = call i64 @_add(i64 %r352, i64 %r354)
  %r356 = load i64, i64* %ptr_NL
  %r357 = call i64 @_add(i64 %r355, i64 %r356)
  store i64 %r357, i64* %ptr_s
  %r358 = load i64, i64* %ptr_s
  %r359 = getelementptr [24 x i8], [24 x i8]* @.str.763, i64 0, i64 0
  %r360 = ptrtoint i8* %r359 to i64
  %r361 = call i64 @_add(i64 %r358, i64 %r360)
  %r362 = load i64, i64* %ptr_NL
  %r363 = call i64 @_add(i64 %r361, i64 %r362)
  store i64 %r363, i64* %ptr_s
  %r364 = load i64, i64* %ptr_s
  %r365 = getelementptr [45 x i8], [45 x i8]* @.str.764, i64 0, i64 0
  %r366 = ptrtoint i8* %r365 to i64
  %r367 = call i64 @_add(i64 %r364, i64 %r366)
  %r368 = load i64, i64* %ptr_NL
  %r369 = call i64 @_add(i64 %r367, i64 %r368)
  store i64 %r369, i64* %ptr_s
  %r370 = load i64, i64* %ptr_s
  %r371 = getelementptr [25 x i8], [25 x i8]* @.str.765, i64 0, i64 0
  %r372 = ptrtoint i8* %r371 to i64
  %r373 = call i64 @_add(i64 %r370, i64 %r372)
  %r374 = load i64, i64* %ptr_NL
  %r375 = call i64 @_add(i64 %r373, i64 %r374)
  store i64 %r375, i64* %ptr_s
  %r376 = load i64, i64* %ptr_s
  %r377 = getelementptr [35 x i8], [35 x i8]* @.str.766, i64 0, i64 0
  %r378 = ptrtoint i8* %r377 to i64
  %r379 = call i64 @_add(i64 %r376, i64 %r378)
  %r380 = load i64, i64* %ptr_NL
  %r381 = call i64 @_add(i64 %r379, i64 %r380)
  store i64 %r381, i64* %ptr_s
  %r382 = load i64, i64* %ptr_s
  %r383 = getelementptr [16 x i8], [16 x i8]* @.str.767, i64 0, i64 0
  %r384 = ptrtoint i8* %r383 to i64
  %r385 = call i64 @_add(i64 %r382, i64 %r384)
  %r386 = load i64, i64* %ptr_NL
  %r387 = call i64 @_add(i64 %r385, i64 %r386)
  store i64 %r387, i64* %ptr_s
  %r388 = load i64, i64* %ptr_s
  %r389 = getelementptr [6 x i8], [6 x i8]* @.str.768, i64 0, i64 0
  %r390 = ptrtoint i8* %r389 to i64
  %r391 = call i64 @_add(i64 %r388, i64 %r390)
  %r392 = load i64, i64* %ptr_NL
  %r393 = call i64 @_add(i64 %r391, i64 %r392)
  store i64 %r393, i64* %ptr_s
  %r394 = load i64, i64* %ptr_s
  %r395 = getelementptr [33 x i8], [33 x i8]* @.str.769, i64 0, i64 0
  %r396 = ptrtoint i8* %r395 to i64
  %r397 = call i64 @_add(i64 %r394, i64 %r396)
  %r398 = load i64, i64* %ptr_NL
  %r399 = call i64 @_add(i64 %r397, i64 %r398)
  store i64 %r399, i64* %ptr_s
  %r400 = load i64, i64* %ptr_s
  %r401 = getelementptr [29 x i8], [29 x i8]* @.str.770, i64 0, i64 0
  %r402 = ptrtoint i8* %r401 to i64
  %r403 = call i64 @_add(i64 %r400, i64 %r402)
  %r404 = load i64, i64* %ptr_NL
  %r405 = call i64 @_add(i64 %r403, i64 %r404)
  store i64 %r405, i64* %ptr_s
  %r406 = load i64, i64* %ptr_s
  %r407 = getelementptr [55 x i8], [55 x i8]* @.str.771, i64 0, i64 0
  %r408 = ptrtoint i8* %r407 to i64
  %r409 = call i64 @_add(i64 %r406, i64 %r408)
  %r410 = load i64, i64* %ptr_NL
  %r411 = call i64 @_add(i64 %r409, i64 %r410)
  store i64 %r411, i64* %ptr_s
  %r412 = load i64, i64* %ptr_s
  %r413 = getelementptr [17 x i8], [17 x i8]* @.str.772, i64 0, i64 0
  %r414 = ptrtoint i8* %r413 to i64
  %r415 = call i64 @_add(i64 %r412, i64 %r414)
  %r416 = load i64, i64* %ptr_NL
  %r417 = call i64 @_add(i64 %r415, i64 %r416)
  store i64 %r417, i64* %ptr_s
  %r418 = load i64, i64* %ptr_s
  %r419 = getelementptr [6 x i8], [6 x i8]* @.str.773, i64 0, i64 0
  %r420 = ptrtoint i8* %r419 to i64
  %r421 = call i64 @_add(i64 %r418, i64 %r420)
  %r422 = load i64, i64* %ptr_NL
  %r423 = call i64 @_add(i64 %r421, i64 %r422)
  store i64 %r423, i64* %ptr_s
  %r424 = load i64, i64* %ptr_s
  %r425 = getelementptr [60 x i8], [60 x i8]* @.str.774, i64 0, i64 0
  %r426 = ptrtoint i8* %r425 to i64
  %r427 = call i64 @_add(i64 %r424, i64 %r426)
  %r428 = load i64, i64* %ptr_NL
  %r429 = call i64 @_add(i64 %r427, i64 %r428)
  store i64 %r429, i64* %ptr_s
  %r430 = load i64, i64* %ptr_s
  %r431 = getelementptr [53 x i8], [53 x i8]* @.str.775, i64 0, i64 0
  %r432 = ptrtoint i8* %r431 to i64
  %r433 = call i64 @_add(i64 %r430, i64 %r432)
  %r434 = load i64, i64* %ptr_NL
  %r435 = call i64 @_add(i64 %r433, i64 %r434)
  store i64 %r435, i64* %ptr_s
  %r436 = load i64, i64* %ptr_s
  %r437 = getelementptr [28 x i8], [28 x i8]* @.str.776, i64 0, i64 0
  %r438 = ptrtoint i8* %r437 to i64
  %r439 = call i64 @_add(i64 %r436, i64 %r438)
  %r440 = load i64, i64* %ptr_NL
  %r441 = call i64 @_add(i64 %r439, i64 %r440)
  store i64 %r441, i64* %ptr_s
  %r442 = load i64, i64* %ptr_s
  %r443 = getelementptr [27 x i8], [27 x i8]* @.str.777, i64 0, i64 0
  %r444 = ptrtoint i8* %r443 to i64
  %r445 = call i64 @_add(i64 %r442, i64 %r444)
  %r446 = load i64, i64* %ptr_NL
  %r447 = call i64 @_add(i64 %r445, i64 %r446)
  store i64 %r447, i64* %ptr_s
  %r448 = load i64, i64* %ptr_s
  %r449 = getelementptr [30 x i8], [30 x i8]* @.str.778, i64 0, i64 0
  %r450 = ptrtoint i8* %r449 to i64
  %r451 = call i64 @_add(i64 %r448, i64 %r450)
  %r452 = load i64, i64* %ptr_NL
  %r453 = call i64 @_add(i64 %r451, i64 %r452)
  store i64 %r453, i64* %ptr_s
  %r454 = load i64, i64* %ptr_s
  %r455 = getelementptr [47 x i8], [47 x i8]* @.str.779, i64 0, i64 0
  %r456 = ptrtoint i8* %r455 to i64
  %r457 = call i64 @_add(i64 %r454, i64 %r456)
  %r458 = load i64, i64* %ptr_NL
  %r459 = call i64 @_add(i64 %r457, i64 %r458)
  store i64 %r459, i64* %ptr_s
  %r460 = load i64, i64* %ptr_s
  %r461 = getelementptr [26 x i8], [26 x i8]* @.str.780, i64 0, i64 0
  %r462 = ptrtoint i8* %r461 to i64
  %r463 = call i64 @_add(i64 %r460, i64 %r462)
  %r464 = load i64, i64* %ptr_NL
  %r465 = call i64 @_add(i64 %r463, i64 %r464)
  store i64 %r465, i64* %ptr_s
  %r466 = load i64, i64* %ptr_s
  %r467 = getelementptr [33 x i8], [33 x i8]* @.str.781, i64 0, i64 0
  %r468 = ptrtoint i8* %r467 to i64
  %r469 = call i64 @_add(i64 %r466, i64 %r468)
  %r470 = load i64, i64* %ptr_NL
  %r471 = call i64 @_add(i64 %r469, i64 %r470)
  store i64 %r471, i64* %ptr_s
  %r472 = load i64, i64* %ptr_s
  %r473 = getelementptr [30 x i8], [30 x i8]* @.str.782, i64 0, i64 0
  %r474 = ptrtoint i8* %r473 to i64
  %r475 = call i64 @_add(i64 %r472, i64 %r474)
  %r476 = load i64, i64* %ptr_NL
  %r477 = call i64 @_add(i64 %r475, i64 %r476)
  store i64 %r477, i64* %ptr_s
  %r478 = load i64, i64* %ptr_s
  %r479 = getelementptr [35 x i8], [35 x i8]* @.str.783, i64 0, i64 0
  %r480 = ptrtoint i8* %r479 to i64
  %r481 = call i64 @_add(i64 %r478, i64 %r480)
  %r482 = load i64, i64* %ptr_NL
  %r483 = call i64 @_add(i64 %r481, i64 %r482)
  store i64 %r483, i64* %ptr_s
  %r484 = load i64, i64* %ptr_s
  %r485 = getelementptr [40 x i8], [40 x i8]* @.str.784, i64 0, i64 0
  %r486 = ptrtoint i8* %r485 to i64
  %r487 = call i64 @_add(i64 %r484, i64 %r486)
  %r488 = load i64, i64* %ptr_NL
  %r489 = call i64 @_add(i64 %r487, i64 %r488)
  store i64 %r489, i64* %ptr_s
  %r490 = load i64, i64* %ptr_s
  %r491 = getelementptr [6 x i8], [6 x i8]* @.str.785, i64 0, i64 0
  %r492 = ptrtoint i8* %r491 to i64
  %r493 = call i64 @_add(i64 %r490, i64 %r492)
  %r494 = load i64, i64* %ptr_NL
  %r495 = call i64 @_add(i64 %r493, i64 %r494)
  store i64 %r495, i64* %ptr_s
  %r496 = load i64, i64* %ptr_s
  %r497 = getelementptr [36 x i8], [36 x i8]* @.str.786, i64 0, i64 0
  %r498 = ptrtoint i8* %r497 to i64
  %r499 = call i64 @_add(i64 %r496, i64 %r498)
  %r500 = load i64, i64* %ptr_NL
  %r501 = call i64 @_add(i64 %r499, i64 %r500)
  store i64 %r501, i64* %ptr_s
  %r502 = load i64, i64* %ptr_s
  %r503 = getelementptr [45 x i8], [45 x i8]* @.str.787, i64 0, i64 0
  %r504 = ptrtoint i8* %r503 to i64
  %r505 = call i64 @_add(i64 %r502, i64 %r504)
  %r506 = load i64, i64* %ptr_NL
  %r507 = call i64 @_add(i64 %r505, i64 %r506)
  store i64 %r507, i64* %ptr_s
  %r508 = load i64, i64* %ptr_s
  %r509 = getelementptr [9 x i8], [9 x i8]* @.str.788, i64 0, i64 0
  %r510 = ptrtoint i8* %r509 to i64
  %r511 = call i64 @_add(i64 %r508, i64 %r510)
  %r512 = load i64, i64* %ptr_NL
  %r513 = call i64 @_add(i64 %r511, i64 %r512)
  store i64 %r513, i64* %ptr_s
  %r514 = load i64, i64* %ptr_s
  %r515 = getelementptr [56 x i8], [56 x i8]* @.str.789, i64 0, i64 0
  %r516 = ptrtoint i8* %r515 to i64
  %r517 = call i64 @_add(i64 %r514, i64 %r516)
  %r518 = load i64, i64* %ptr_NL
  %r519 = call i64 @_add(i64 %r517, i64 %r518)
  store i64 %r519, i64* %ptr_s
  %r520 = load i64, i64* %ptr_s
  %r521 = getelementptr [29 x i8], [29 x i8]* @.str.790, i64 0, i64 0
  %r522 = ptrtoint i8* %r521 to i64
  %r523 = call i64 @_add(i64 %r520, i64 %r522)
  %r524 = load i64, i64* %ptr_NL
  %r525 = call i64 @_add(i64 %r523, i64 %r524)
  store i64 %r525, i64* %ptr_s
  %r526 = load i64, i64* %ptr_s
  %r527 = getelementptr [17 x i8], [17 x i8]* @.str.791, i64 0, i64 0
  %r528 = ptrtoint i8* %r527 to i64
  %r529 = call i64 @_add(i64 %r526, i64 %r528)
  %r530 = load i64, i64* %ptr_NL
  %r531 = call i64 @_add(i64 %r529, i64 %r530)
  store i64 %r531, i64* %ptr_s
  %r532 = load i64, i64* %ptr_s
  %r533 = getelementptr [6 x i8], [6 x i8]* @.str.792, i64 0, i64 0
  %r534 = ptrtoint i8* %r533 to i64
  %r535 = call i64 @_add(i64 %r532, i64 %r534)
  %r536 = load i64, i64* %ptr_NL
  %r537 = call i64 @_add(i64 %r535, i64 %r536)
  store i64 %r537, i64* %ptr_s
  %r538 = load i64, i64* %ptr_s
  %r539 = getelementptr [72 x i8], [72 x i8]* @.str.793, i64 0, i64 0
  %r540 = ptrtoint i8* %r539 to i64
  %r541 = call i64 @_add(i64 %r538, i64 %r540)
  %r542 = load i64, i64* %ptr_NL
  %r543 = call i64 @_add(i64 %r541, i64 %r542)
  store i64 %r543, i64* %ptr_s
  %r544 = load i64, i64* %ptr_s
  %r545 = getelementptr [50 x i8], [50 x i8]* @.str.794, i64 0, i64 0
  %r546 = ptrtoint i8* %r545 to i64
  %r547 = call i64 @_add(i64 %r544, i64 %r546)
  %r548 = load i64, i64* %ptr_NL
  %r549 = call i64 @_add(i64 %r547, i64 %r548)
  store i64 %r549, i64* %ptr_s
  %r550 = load i64, i64* %ptr_s
  %r551 = getelementptr [29 x i8], [29 x i8]* @.str.795, i64 0, i64 0
  %r552 = ptrtoint i8* %r551 to i64
  %r553 = call i64 @_add(i64 %r550, i64 %r552)
  %r554 = load i64, i64* %ptr_NL
  %r555 = call i64 @_add(i64 %r553, i64 %r554)
  store i64 %r555, i64* %ptr_s
  %r556 = load i64, i64* %ptr_s
  %r557 = getelementptr [58 x i8], [58 x i8]* @.str.796, i64 0, i64 0
  %r558 = ptrtoint i8* %r557 to i64
  %r559 = call i64 @_add(i64 %r556, i64 %r558)
  %r560 = load i64, i64* %ptr_NL
  %r561 = call i64 @_add(i64 %r559, i64 %r560)
  store i64 %r561, i64* %ptr_s
  %r562 = load i64, i64* %ptr_s
  %r563 = getelementptr [42 x i8], [42 x i8]* @.str.797, i64 0, i64 0
  %r564 = ptrtoint i8* %r563 to i64
  %r565 = call i64 @_add(i64 %r562, i64 %r564)
  %r566 = load i64, i64* %ptr_NL
  %r567 = call i64 @_add(i64 %r565, i64 %r566)
  store i64 %r567, i64* %ptr_s
  %r568 = load i64, i64* %ptr_s
  %r569 = getelementptr [19 x i8], [19 x i8]* @.str.798, i64 0, i64 0
  %r570 = ptrtoint i8* %r569 to i64
  %r571 = call i64 @_add(i64 %r568, i64 %r570)
  %r572 = load i64, i64* %ptr_NL
  %r573 = call i64 @_add(i64 %r571, i64 %r572)
  store i64 %r573, i64* %ptr_s
  %r574 = load i64, i64* %ptr_s
  %r575 = getelementptr [2 x i8], [2 x i8]* @.str.799, i64 0, i64 0
  %r576 = ptrtoint i8* %r575 to i64
  %r577 = call i64 @_add(i64 %r574, i64 %r576)
  %r578 = load i64, i64* %ptr_NL
  %r579 = call i64 @_add(i64 %r577, i64 %r578)
  store i64 %r579, i64* %ptr_s
  %r580 = load i64, i64* %ptr_s
  %r581 = getelementptr [35 x i8], [35 x i8]* @.str.800, i64 0, i64 0
  %r582 = ptrtoint i8* %r581 to i64
  %r583 = call i64 @_add(i64 %r580, i64 %r582)
  %r584 = load i64, i64* %ptr_NL
  %r585 = call i64 @_add(i64 %r583, i64 %r584)
  store i64 %r585, i64* %ptr_s
  %r586 = load i64, i64* %ptr_s
  %r587 = getelementptr [32 x i8], [32 x i8]* @.str.801, i64 0, i64 0
  %r588 = ptrtoint i8* %r587 to i64
  %r589 = call i64 @_add(i64 %r586, i64 %r588)
  %r590 = load i64, i64* %ptr_ptr_thresh
  %r591 = call i64 @_add(i64 %r589, i64 %r590)
  %r592 = load i64, i64* %ptr_NL
  %r593 = call i64 @_add(i64 %r591, i64 %r592)
  store i64 %r593, i64* %ptr_s
  %r594 = load i64, i64* %ptr_s
  %r595 = getelementptr [32 x i8], [32 x i8]* @.str.802, i64 0, i64 0
  %r596 = ptrtoint i8* %r595 to i64
  %r597 = call i64 @_add(i64 %r594, i64 %r596)
  %r598 = load i64, i64* %ptr_ptr_thresh
  %r599 = call i64 @_add(i64 %r597, i64 %r598)
  %r600 = load i64, i64* %ptr_NL
  %r601 = call i64 @_add(i64 %r599, i64 %r600)
  store i64 %r601, i64* %ptr_s
  %r602 = load i64, i64* %ptr_s
  %r603 = getelementptr [42 x i8], [42 x i8]* @.str.803, i64 0, i64 0
  %r604 = ptrtoint i8* %r603 to i64
  %r605 = call i64 @_add(i64 %r602, i64 %r604)
  %r606 = load i64, i64* %ptr_NL
  %r607 = call i64 @_add(i64 %r605, i64 %r606)
  store i64 %r607, i64* %ptr_s
  %r608 = load i64, i64* %ptr_s
  %r609 = getelementptr [40 x i8], [40 x i8]* @.str.804, i64 0, i64 0
  %r610 = ptrtoint i8* %r609 to i64
  %r611 = call i64 @_add(i64 %r608, i64 %r610)
  %r612 = load i64, i64* %ptr_NL
  %r613 = call i64 @_add(i64 %r611, i64 %r612)
  store i64 %r613, i64* %ptr_s
  %r614 = load i64, i64* %ptr_s
  %r615 = getelementptr [55 x i8], [55 x i8]* @.str.805, i64 0, i64 0
  %r616 = ptrtoint i8* %r615 to i64
  %r617 = call i64 @_add(i64 %r614, i64 %r616)
  %r618 = load i64, i64* %ptr_NL
  %r619 = call i64 @_add(i64 %r617, i64 %r618)
  store i64 %r619, i64* %ptr_s
  %r620 = load i64, i64* %ptr_s
  %r621 = getelementptr [12 x i8], [12 x i8]* @.str.806, i64 0, i64 0
  %r622 = ptrtoint i8* %r621 to i64
  %r623 = call i64 @_add(i64 %r620, i64 %r622)
  %r624 = load i64, i64* %ptr_NL
  %r625 = call i64 @_add(i64 %r623, i64 %r624)
  store i64 %r625, i64* %ptr_s
  %r626 = load i64, i64* %ptr_s
  %r627 = getelementptr [34 x i8], [34 x i8]* @.str.807, i64 0, i64 0
  %r628 = ptrtoint i8* %r627 to i64
  %r629 = call i64 @_add(i64 %r626, i64 %r628)
  %r630 = load i64, i64* %ptr_NL
  %r631 = call i64 @_add(i64 %r629, i64 %r630)
  store i64 %r631, i64* %ptr_s
  %r632 = load i64, i64* %ptr_s
  %r633 = getelementptr [32 x i8], [32 x i8]* @.str.808, i64 0, i64 0
  %r634 = ptrtoint i8* %r633 to i64
  %r635 = call i64 @_add(i64 %r632, i64 %r634)
  %r636 = load i64, i64* %ptr_NL
  %r637 = call i64 @_add(i64 %r635, i64 %r636)
  store i64 %r637, i64* %ptr_s
  %r638 = load i64, i64* %ptr_s
  %r639 = getelementptr [35 x i8], [35 x i8]* @.str.809, i64 0, i64 0
  %r640 = ptrtoint i8* %r639 to i64
  %r641 = call i64 @_add(i64 %r638, i64 %r640)
  %r642 = load i64, i64* %ptr_NL
  %r643 = call i64 @_add(i64 %r641, i64 %r642)
  store i64 %r643, i64* %ptr_s
  %r644 = load i64, i64* %ptr_s
  %r645 = getelementptr [51 x i8], [51 x i8]* @.str.810, i64 0, i64 0
  %r646 = ptrtoint i8* %r645 to i64
  %r647 = call i64 @_add(i64 %r644, i64 %r646)
  %r648 = load i64, i64* %ptr_NL
  %r649 = call i64 @_add(i64 %r647, i64 %r648)
  store i64 %r649, i64* %ptr_s
  %r650 = load i64, i64* %ptr_s
  %r651 = getelementptr [11 x i8], [11 x i8]* @.str.811, i64 0, i64 0
  %r652 = ptrtoint i8* %r651 to i64
  %r653 = call i64 @_add(i64 %r650, i64 %r652)
  %r654 = load i64, i64* %ptr_NL
  %r655 = call i64 @_add(i64 %r653, i64 %r654)
  store i64 %r655, i64* %ptr_s
  %r656 = load i64, i64* %ptr_s
  %r657 = getelementptr [44 x i8], [44 x i8]* @.str.812, i64 0, i64 0
  %r658 = ptrtoint i8* %r657 to i64
  %r659 = call i64 @_add(i64 %r656, i64 %r658)
  %r660 = load i64, i64* %ptr_NL
  %r661 = call i64 @_add(i64 %r659, i64 %r660)
  store i64 %r661, i64* %ptr_s
  %r662 = load i64, i64* %ptr_s
  %r663 = getelementptr [8 x i8], [8 x i8]* @.str.813, i64 0, i64 0
  %r664 = ptrtoint i8* %r663 to i64
  %r665 = call i64 @_add(i64 %r662, i64 %r664)
  %r666 = load i64, i64* %ptr_NL
  %r667 = call i64 @_add(i64 %r665, i64 %r666)
  store i64 %r667, i64* %ptr_s
  %r668 = load i64, i64* %ptr_s
  %r669 = getelementptr [36 x i8], [36 x i8]* @.str.814, i64 0, i64 0
  %r670 = ptrtoint i8* %r669 to i64
  %r671 = call i64 @_add(i64 %r668, i64 %r670)
  %r672 = load i64, i64* %ptr_NL
  %r673 = call i64 @_add(i64 %r671, i64 %r672)
  store i64 %r673, i64* %ptr_s
  %r674 = load i64, i64* %ptr_s
  %r675 = getelementptr [36 x i8], [36 x i8]* @.str.815, i64 0, i64 0
  %r676 = ptrtoint i8* %r675 to i64
  %r677 = call i64 @_add(i64 %r674, i64 %r676)
  %r678 = load i64, i64* %ptr_NL
  %r679 = call i64 @_add(i64 %r677, i64 %r678)
  store i64 %r679, i64* %ptr_s
  %r680 = load i64, i64* %ptr_s
  %r681 = getelementptr [50 x i8], [50 x i8]* @.str.816, i64 0, i64 0
  %r682 = ptrtoint i8* %r681 to i64
  %r683 = call i64 @_add(i64 %r680, i64 %r682)
  %r684 = load i64, i64* %ptr_NL
  %r685 = call i64 @_add(i64 %r683, i64 %r684)
  store i64 %r685, i64* %ptr_s
  %r686 = load i64, i64* %ptr_s
  %r687 = getelementptr [19 x i8], [19 x i8]* @.str.817, i64 0, i64 0
  %r688 = ptrtoint i8* %r687 to i64
  %r689 = call i64 @_add(i64 %r686, i64 %r688)
  %r690 = load i64, i64* %ptr_NL
  %r691 = call i64 @_add(i64 %r689, i64 %r690)
  store i64 %r691, i64* %ptr_s
  %r692 = load i64, i64* %ptr_s
  %r693 = getelementptr [9 x i8], [9 x i8]* @.str.818, i64 0, i64 0
  %r694 = ptrtoint i8* %r693 to i64
  %r695 = call i64 @_add(i64 %r692, i64 %r694)
  %r696 = load i64, i64* %ptr_NL
  %r697 = call i64 @_add(i64 %r695, i64 %r696)
  store i64 %r697, i64* %ptr_s
  %r698 = load i64, i64* %ptr_s
  %r699 = getelementptr [36 x i8], [36 x i8]* @.str.819, i64 0, i64 0
  %r700 = ptrtoint i8* %r699 to i64
  %r701 = call i64 @_add(i64 %r698, i64 %r700)
  %r702 = load i64, i64* %ptr_NL
  %r703 = call i64 @_add(i64 %r701, i64 %r702)
  store i64 %r703, i64* %ptr_s
  %r704 = load i64, i64* %ptr_s
  %r705 = getelementptr [47 x i8], [47 x i8]* @.str.820, i64 0, i64 0
  %r706 = ptrtoint i8* %r705 to i64
  %r707 = call i64 @_add(i64 %r704, i64 %r706)
  %r708 = load i64, i64* %ptr_NL
  %r709 = call i64 @_add(i64 %r707, i64 %r708)
  store i64 %r709, i64* %ptr_s
  %r710 = load i64, i64* %ptr_s
  %r711 = getelementptr [47 x i8], [47 x i8]* @.str.821, i64 0, i64 0
  %r712 = ptrtoint i8* %r711 to i64
  %r713 = call i64 @_add(i64 %r710, i64 %r712)
  %r714 = load i64, i64* %ptr_NL
  %r715 = call i64 @_add(i64 %r713, i64 %r714)
  store i64 %r715, i64* %ptr_s
  %r716 = load i64, i64* %ptr_s
  %r717 = getelementptr [20 x i8], [20 x i8]* @.str.822, i64 0, i64 0
  %r718 = ptrtoint i8* %r717 to i64
  %r719 = call i64 @_add(i64 %r716, i64 %r718)
  %r720 = load i64, i64* %ptr_NL
  %r721 = call i64 @_add(i64 %r719, i64 %r720)
  store i64 %r721, i64* %ptr_s
  %r722 = load i64, i64* %ptr_s
  %r723 = getelementptr [5 x i8], [5 x i8]* @.str.823, i64 0, i64 0
  %r724 = ptrtoint i8* %r723 to i64
  %r725 = call i64 @_add(i64 %r722, i64 %r724)
  %r726 = load i64, i64* %ptr_NL
  %r727 = call i64 @_add(i64 %r725, i64 %r726)
  store i64 %r727, i64* %ptr_s
  %r728 = load i64, i64* %ptr_s
  %r729 = getelementptr [28 x i8], [28 x i8]* @.str.824, i64 0, i64 0
  %r730 = ptrtoint i8* %r729 to i64
  %r731 = call i64 @_add(i64 %r728, i64 %r730)
  %r732 = load i64, i64* %ptr_NL
  %r733 = call i64 @_add(i64 %r731, i64 %r732)
  store i64 %r733, i64* %ptr_s
  %r734 = load i64, i64* %ptr_s
  %r735 = getelementptr [19 x i8], [19 x i8]* @.str.825, i64 0, i64 0
  %r736 = ptrtoint i8* %r735 to i64
  %r737 = call i64 @_add(i64 %r734, i64 %r736)
  %r738 = load i64, i64* %ptr_NL
  %r739 = call i64 @_add(i64 %r737, i64 %r738)
  store i64 %r739, i64* %ptr_s
  %r740 = load i64, i64* %ptr_s
  %r741 = getelementptr [2 x i8], [2 x i8]* @.str.826, i64 0, i64 0
  %r742 = ptrtoint i8* %r741 to i64
  %r743 = call i64 @_add(i64 %r740, i64 %r742)
  %r744 = load i64, i64* %ptr_NL
  %r745 = call i64 @_add(i64 %r743, i64 %r744)
  store i64 %r745, i64* %ptr_s
  %r746 = load i64, i64* %ptr_s
  %r747 = getelementptr [47 x i8], [47 x i8]* @.str.827, i64 0, i64 0
  %r748 = ptrtoint i8* %r747 to i64
  %r749 = call i64 @_add(i64 %r746, i64 %r748)
  %r750 = load i64, i64* %ptr_NL
  %r751 = call i64 @_add(i64 %r749, i64 %r750)
  store i64 %r751, i64* %ptr_s
  %r752 = load i64, i64* %ptr_s
  %r753 = getelementptr [35 x i8], [35 x i8]* @.str.828, i64 0, i64 0
  %r754 = ptrtoint i8* %r753 to i64
  %r755 = call i64 @_add(i64 %r752, i64 %r754)
  %r756 = load i64, i64* %ptr_NL
  %r757 = call i64 @_add(i64 %r755, i64 %r756)
  store i64 %r757, i64* %ptr_s
  %r758 = load i64, i64* %ptr_s
  %r759 = getelementptr [49 x i8], [49 x i8]* @.str.829, i64 0, i64 0
  %r760 = ptrtoint i8* %r759 to i64
  %r761 = call i64 @_add(i64 %r758, i64 %r760)
  %r762 = load i64, i64* %ptr_NL
  %r763 = call i64 @_add(i64 %r761, i64 %r762)
  store i64 %r763, i64* %ptr_s
  %r764 = load i64, i64* %ptr_s
  %r765 = getelementptr [33 x i8], [33 x i8]* @.str.830, i64 0, i64 0
  %r766 = ptrtoint i8* %r765 to i64
  %r767 = call i64 @_add(i64 %r764, i64 %r766)
  %r768 = load i64, i64* %ptr_NL
  %r769 = call i64 @_add(i64 %r767, i64 %r768)
  store i64 %r769, i64* %ptr_s
  %r770 = load i64, i64* %ptr_s
  %r771 = getelementptr [50 x i8], [50 x i8]* @.str.831, i64 0, i64 0
  %r772 = ptrtoint i8* %r771 to i64
  %r773 = call i64 @_add(i64 %r770, i64 %r772)
  %r774 = load i64, i64* %ptr_NL
  %r775 = call i64 @_add(i64 %r773, i64 %r774)
  store i64 %r775, i64* %ptr_s
  %r776 = load i64, i64* %ptr_s
  %r777 = getelementptr [35 x i8], [35 x i8]* @.str.832, i64 0, i64 0
  %r778 = ptrtoint i8* %r777 to i64
  %r779 = call i64 @_add(i64 %r776, i64 %r778)
  %r780 = load i64, i64* %ptr_NL
  %r781 = call i64 @_add(i64 %r779, i64 %r780)
  store i64 %r781, i64* %ptr_s
  %r782 = load i64, i64* %ptr_s
  %r783 = getelementptr [41 x i8], [41 x i8]* @.str.833, i64 0, i64 0
  %r784 = ptrtoint i8* %r783 to i64
  %r785 = call i64 @_add(i64 %r782, i64 %r784)
  %r786 = load i64, i64* %ptr_NL
  %r787 = call i64 @_add(i64 %r785, i64 %r786)
  store i64 %r787, i64* %ptr_s
  %r788 = load i64, i64* %ptr_s
  %r789 = getelementptr [17 x i8], [17 x i8]* @.str.834, i64 0, i64 0
  %r790 = ptrtoint i8* %r789 to i64
  %r791 = call i64 @_add(i64 %r788, i64 %r790)
  %r792 = load i64, i64* %ptr_NL
  %r793 = call i64 @_add(i64 %r791, i64 %r792)
  store i64 %r793, i64* %ptr_s
  %r794 = load i64, i64* %ptr_s
  %r795 = getelementptr [6 x i8], [6 x i8]* @.str.835, i64 0, i64 0
  %r796 = ptrtoint i8* %r795 to i64
  %r797 = call i64 @_add(i64 %r794, i64 %r796)
  %r798 = load i64, i64* %ptr_NL
  %r799 = call i64 @_add(i64 %r797, i64 %r798)
  store i64 %r799, i64* %ptr_s
  %r800 = load i64, i64* %ptr_s
  %r801 = getelementptr [45 x i8], [45 x i8]* @.str.836, i64 0, i64 0
  %r802 = ptrtoint i8* %r801 to i64
  %r803 = call i64 @_add(i64 %r800, i64 %r802)
  %r804 = load i64, i64* %ptr_NL
  %r805 = call i64 @_add(i64 %r803, i64 %r804)
  store i64 %r805, i64* %ptr_s
  %r806 = load i64, i64* %ptr_s
  %r807 = getelementptr [32 x i8], [32 x i8]* @.str.837, i64 0, i64 0
  %r808 = ptrtoint i8* %r807 to i64
  %r809 = call i64 @_add(i64 %r806, i64 %r808)
  %r810 = load i64, i64* %ptr_NL
  %r811 = call i64 @_add(i64 %r809, i64 %r810)
  store i64 %r811, i64* %ptr_s
  %r812 = load i64, i64* %ptr_s
  %r813 = getelementptr [40 x i8], [40 x i8]* @.str.838, i64 0, i64 0
  %r814 = ptrtoint i8* %r813 to i64
  %r815 = call i64 @_add(i64 %r812, i64 %r814)
  %r816 = load i64, i64* %ptr_NL
  %r817 = call i64 @_add(i64 %r815, i64 %r816)
  store i64 %r817, i64* %ptr_s
  %r818 = load i64, i64* %ptr_s
  %r819 = getelementptr [6 x i8], [6 x i8]* @.str.839, i64 0, i64 0
  %r820 = ptrtoint i8* %r819 to i64
  %r821 = call i64 @_add(i64 %r818, i64 %r820)
  %r822 = load i64, i64* %ptr_NL
  %r823 = call i64 @_add(i64 %r821, i64 %r822)
  store i64 %r823, i64* %ptr_s
  %r824 = load i64, i64* %ptr_s
  %r825 = getelementptr [52 x i8], [52 x i8]* @.str.840, i64 0, i64 0
  %r826 = ptrtoint i8* %r825 to i64
  %r827 = call i64 @_add(i64 %r824, i64 %r826)
  %r828 = load i64, i64* %ptr_NL
  %r829 = call i64 @_add(i64 %r827, i64 %r828)
  store i64 %r829, i64* %ptr_s
  %r830 = load i64, i64* %ptr_s
  %r831 = getelementptr [30 x i8], [30 x i8]* @.str.841, i64 0, i64 0
  %r832 = ptrtoint i8* %r831 to i64
  %r833 = call i64 @_add(i64 %r830, i64 %r832)
  %r834 = load i64, i64* %ptr_NL
  %r835 = call i64 @_add(i64 %r833, i64 %r834)
  store i64 %r835, i64* %ptr_s
  %r836 = load i64, i64* %ptr_s
  %r837 = getelementptr [44 x i8], [44 x i8]* @.str.842, i64 0, i64 0
  %r838 = ptrtoint i8* %r837 to i64
  %r839 = call i64 @_add(i64 %r836, i64 %r838)
  %r840 = load i64, i64* %ptr_NL
  %r841 = call i64 @_add(i64 %r839, i64 %r840)
  store i64 %r841, i64* %ptr_s
  %r842 = load i64, i64* %ptr_s
  %r843 = getelementptr [26 x i8], [26 x i8]* @.str.843, i64 0, i64 0
  %r844 = ptrtoint i8* %r843 to i64
  %r845 = call i64 @_add(i64 %r842, i64 %r844)
  %r846 = load i64, i64* %ptr_NL
  %r847 = call i64 @_add(i64 %r845, i64 %r846)
  store i64 %r847, i64* %ptr_s
  %r848 = load i64, i64* %ptr_s
  %r849 = getelementptr [17 x i8], [17 x i8]* @.str.844, i64 0, i64 0
  %r850 = ptrtoint i8* %r849 to i64
  %r851 = call i64 @_add(i64 %r848, i64 %r850)
  %r852 = load i64, i64* %ptr_NL
  %r853 = call i64 @_add(i64 %r851, i64 %r852)
  store i64 %r853, i64* %ptr_s
  %r854 = load i64, i64* %ptr_s
  %r855 = getelementptr [6 x i8], [6 x i8]* @.str.845, i64 0, i64 0
  %r856 = ptrtoint i8* %r855 to i64
  %r857 = call i64 @_add(i64 %r854, i64 %r856)
  %r858 = load i64, i64* %ptr_NL
  %r859 = call i64 @_add(i64 %r857, i64 %r858)
  store i64 %r859, i64* %ptr_s
  %r860 = load i64, i64* %ptr_s
  %r861 = getelementptr [11 x i8], [11 x i8]* @.str.846, i64 0, i64 0
  %r862 = ptrtoint i8* %r861 to i64
  %r863 = call i64 @_add(i64 %r860, i64 %r862)
  %r864 = load i64, i64* %ptr_NL
  %r865 = call i64 @_add(i64 %r863, i64 %r864)
  store i64 %r865, i64* %ptr_s
  %r866 = load i64, i64* %ptr_s
  %r867 = getelementptr [2 x i8], [2 x i8]* @.str.847, i64 0, i64 0
  %r868 = ptrtoint i8* %r867 to i64
  %r869 = call i64 @_add(i64 %r866, i64 %r868)
  %r870 = load i64, i64* %ptr_NL
  %r871 = call i64 @_add(i64 %r869, i64 %r870)
  store i64 %r871, i64* %ptr_s
  %r872 = load i64, i64* %ptr_s
  %r873 = getelementptr [48 x i8], [48 x i8]* @.str.848, i64 0, i64 0
  %r874 = ptrtoint i8* %r873 to i64
  %r875 = call i64 @_add(i64 %r872, i64 %r874)
  %r876 = load i64, i64* %ptr_NL
  %r877 = call i64 @_add(i64 %r875, i64 %r876)
  store i64 %r877, i64* %ptr_s
  %r878 = load i64, i64* %ptr_s
  %r879 = getelementptr [32 x i8], [32 x i8]* @.str.849, i64 0, i64 0
  %r880 = ptrtoint i8* %r879 to i64
  %r881 = call i64 @_add(i64 %r878, i64 %r880)
  %r882 = load i64, i64* %ptr_ptr_thresh
  %r883 = call i64 @_add(i64 %r881, i64 %r882)
  %r884 = load i64, i64* %ptr_NL
  %r885 = call i64 @_add(i64 %r883, i64 %r884)
  store i64 %r885, i64* %ptr_s
  %r886 = load i64, i64* %ptr_s
  %r887 = getelementptr [52 x i8], [52 x i8]* @.str.850, i64 0, i64 0
  %r888 = ptrtoint i8* %r887 to i64
  %r889 = call i64 @_add(i64 %r886, i64 %r888)
  %r890 = load i64, i64* %ptr_NL
  %r891 = call i64 @_add(i64 %r889, i64 %r890)
  store i64 %r891, i64* %ptr_s
  %r892 = load i64, i64* %ptr_s
  %r893 = getelementptr [12 x i8], [12 x i8]* @.str.851, i64 0, i64 0
  %r894 = ptrtoint i8* %r893 to i64
  %r895 = call i64 @_add(i64 %r892, i64 %r894)
  %r896 = load i64, i64* %ptr_NL
  %r897 = call i64 @_add(i64 %r895, i64 %r896)
  store i64 %r897, i64* %ptr_s
  %r898 = load i64, i64* %ptr_s
  %r899 = getelementptr [34 x i8], [34 x i8]* @.str.852, i64 0, i64 0
  %r900 = ptrtoint i8* %r899 to i64
  %r901 = call i64 @_add(i64 %r898, i64 %r900)
  %r902 = load i64, i64* %ptr_NL
  %r903 = call i64 @_add(i64 %r901, i64 %r902)
  store i64 %r903, i64* %ptr_s
  %r904 = load i64, i64* %ptr_s
  %r905 = getelementptr [28 x i8], [28 x i8]* @.str.853, i64 0, i64 0
  %r906 = ptrtoint i8* %r905 to i64
  %r907 = call i64 @_add(i64 %r904, i64 %r906)
  %r908 = load i64, i64* %ptr_NL
  %r909 = call i64 @_add(i64 %r907, i64 %r908)
  store i64 %r909, i64* %ptr_s
  %r910 = load i64, i64* %ptr_s
  %r911 = getelementptr [33 x i8], [33 x i8]* @.str.854, i64 0, i64 0
  %r912 = ptrtoint i8* %r911 to i64
  %r913 = call i64 @_add(i64 %r910, i64 %r912)
  %r914 = load i64, i64* %ptr_NL
  %r915 = call i64 @_add(i64 %r913, i64 %r914)
  store i64 %r915, i64* %ptr_s
  %r916 = load i64, i64* %ptr_s
  %r917 = getelementptr [48 x i8], [48 x i8]* @.str.855, i64 0, i64 0
  %r918 = ptrtoint i8* %r917 to i64
  %r919 = call i64 @_add(i64 %r916, i64 %r918)
  %r920 = load i64, i64* %ptr_NL
  %r921 = call i64 @_add(i64 %r919, i64 %r920)
  store i64 %r921, i64* %ptr_s
  %r922 = load i64, i64* %ptr_s
  %r923 = getelementptr [7 x i8], [7 x i8]* @.str.856, i64 0, i64 0
  %r924 = ptrtoint i8* %r923 to i64
  %r925 = call i64 @_add(i64 %r922, i64 %r924)
  %r926 = load i64, i64* %ptr_NL
  %r927 = call i64 @_add(i64 %r925, i64 %r926)
  store i64 %r927, i64* %ptr_s
  %r928 = load i64, i64* %ptr_s
  %r929 = getelementptr [45 x i8], [45 x i8]* @.str.857, i64 0, i64 0
  %r930 = ptrtoint i8* %r929 to i64
  %r931 = call i64 @_add(i64 %r928, i64 %r930)
  %r932 = load i64, i64* %ptr_NL
  %r933 = call i64 @_add(i64 %r931, i64 %r932)
  store i64 %r933, i64* %ptr_s
  %r934 = load i64, i64* %ptr_s
  %r935 = getelementptr [12 x i8], [12 x i8]* @.str.858, i64 0, i64 0
  %r936 = ptrtoint i8* %r935 to i64
  %r937 = call i64 @_add(i64 %r934, i64 %r936)
  %r938 = load i64, i64* %ptr_NL
  %r939 = call i64 @_add(i64 %r937, i64 %r938)
  store i64 %r939, i64* %ptr_s
  %r940 = load i64, i64* %ptr_s
  %r941 = getelementptr [10 x i8], [10 x i8]* @.str.859, i64 0, i64 0
  %r942 = ptrtoint i8* %r941 to i64
  %r943 = call i64 @_add(i64 %r940, i64 %r942)
  %r944 = load i64, i64* %ptr_NL
  %r945 = call i64 @_add(i64 %r943, i64 %r944)
  store i64 %r945, i64* %ptr_s
  %r946 = load i64, i64* %ptr_s
  %r947 = getelementptr [44 x i8], [44 x i8]* @.str.860, i64 0, i64 0
  %r948 = ptrtoint i8* %r947 to i64
  %r949 = call i64 @_add(i64 %r946, i64 %r948)
  %r950 = load i64, i64* %ptr_NL
  %r951 = call i64 @_add(i64 %r949, i64 %r950)
  store i64 %r951, i64* %ptr_s
  %r952 = load i64, i64* %ptr_s
  %r953 = getelementptr [12 x i8], [12 x i8]* @.str.861, i64 0, i64 0
  %r954 = ptrtoint i8* %r953 to i64
  %r955 = call i64 @_add(i64 %r952, i64 %r954)
  %r956 = load i64, i64* %ptr_NL
  %r957 = call i64 @_add(i64 %r955, i64 %r956)
  store i64 %r957, i64* %ptr_s
  %r958 = load i64, i64* %ptr_s
  %r959 = getelementptr [2 x i8], [2 x i8]* @.str.862, i64 0, i64 0
  %r960 = ptrtoint i8* %r959 to i64
  %r961 = call i64 @_add(i64 %r958, i64 %r960)
  %r962 = load i64, i64* %ptr_NL
  %r963 = call i64 @_add(i64 %r961, i64 %r962)
  store i64 %r963, i64* %ptr_s
  %r964 = load i64, i64* %ptr_s
  %r965 = getelementptr [34 x i8], [34 x i8]* @.str.863, i64 0, i64 0
  %r966 = ptrtoint i8* %r965 to i64
  %r967 = call i64 @_add(i64 %r964, i64 %r966)
  %r968 = load i64, i64* %ptr_NL
  %r969 = call i64 @_add(i64 %r967, i64 %r968)
  store i64 %r969, i64* %ptr_s
  %r970 = load i64, i64* %ptr_s
  %r971 = getelementptr [32 x i8], [32 x i8]* @.str.864, i64 0, i64 0
  %r972 = ptrtoint i8* %r971 to i64
  %r973 = call i64 @_add(i64 %r970, i64 %r972)
  %r974 = load i64, i64* %ptr_ptr_thresh
  %r975 = call i64 @_add(i64 %r973, i64 %r974)
  %r976 = load i64, i64* %ptr_NL
  %r977 = call i64 @_add(i64 %r975, i64 %r976)
  store i64 %r977, i64* %ptr_s
  %r978 = load i64, i64* %ptr_s
  %r979 = getelementptr [32 x i8], [32 x i8]* @.str.865, i64 0, i64 0
  %r980 = ptrtoint i8* %r979 to i64
  %r981 = call i64 @_add(i64 %r978, i64 %r980)
  %r982 = load i64, i64* %ptr_ptr_thresh
  %r983 = call i64 @_add(i64 %r981, i64 %r982)
  %r984 = load i64, i64* %ptr_NL
  %r985 = call i64 @_add(i64 %r983, i64 %r984)
  store i64 %r985, i64* %ptr_s
  %r986 = load i64, i64* %ptr_s
  %r987 = getelementptr [42 x i8], [42 x i8]* @.str.866, i64 0, i64 0
  %r988 = ptrtoint i8* %r987 to i64
  %r989 = call i64 @_add(i64 %r986, i64 %r988)
  %r990 = load i64, i64* %ptr_NL
  %r991 = call i64 @_add(i64 %r989, i64 %r990)
  store i64 %r991, i64* %ptr_s
  %r992 = load i64, i64* %ptr_s
  %r993 = getelementptr [53 x i8], [53 x i8]* @.str.867, i64 0, i64 0
  %r994 = ptrtoint i8* %r993 to i64
  %r995 = call i64 @_add(i64 %r992, i64 %r994)
  %r996 = load i64, i64* %ptr_NL
  %r997 = call i64 @_add(i64 %r995, i64 %r996)
  store i64 %r997, i64* %ptr_s
  %r998 = load i64, i64* %ptr_s
  %r999 = getelementptr [12 x i8], [12 x i8]* @.str.868, i64 0, i64 0
  %r1000 = ptrtoint i8* %r999 to i64
  %r1001 = call i64 @_add(i64 %r998, i64 %r1000)
  %r1002 = load i64, i64* %ptr_NL
  %r1003 = call i64 @_add(i64 %r1001, i64 %r1002)
  store i64 %r1003, i64* %ptr_s
  %r1004 = load i64, i64* %ptr_s
  %r1005 = getelementptr [30 x i8], [30 x i8]* @.str.869, i64 0, i64 0
  %r1006 = ptrtoint i8* %r1005 to i64
  %r1007 = call i64 @_add(i64 %r1004, i64 %r1006)
  %r1008 = load i64, i64* %ptr_NL
  %r1009 = call i64 @_add(i64 %r1007, i64 %r1008)
  store i64 %r1009, i64* %ptr_s
  %r1010 = load i64, i64* %ptr_s
  %r1011 = getelementptr [30 x i8], [30 x i8]* @.str.870, i64 0, i64 0
  %r1012 = ptrtoint i8* %r1011 to i64
  %r1013 = call i64 @_add(i64 %r1010, i64 %r1012)
  %r1014 = load i64, i64* %ptr_NL
  %r1015 = call i64 @_add(i64 %r1013, i64 %r1014)
  store i64 %r1015, i64* %ptr_s
  %r1016 = load i64, i64* %ptr_s
  %r1017 = getelementptr [37 x i8], [37 x i8]* @.str.871, i64 0, i64 0
  %r1018 = ptrtoint i8* %r1017 to i64
  %r1019 = call i64 @_add(i64 %r1016, i64 %r1018)
  %r1020 = load i64, i64* %ptr_NL
  %r1021 = call i64 @_add(i64 %r1019, i64 %r1020)
  store i64 %r1021, i64* %ptr_s
  %r1022 = load i64, i64* %ptr_s
  %r1023 = getelementptr [50 x i8], [50 x i8]* @.str.872, i64 0, i64 0
  %r1024 = ptrtoint i8* %r1023 to i64
  %r1025 = call i64 @_add(i64 %r1022, i64 %r1024)
  %r1026 = load i64, i64* %ptr_NL
  %r1027 = call i64 @_add(i64 %r1025, i64 %r1026)
  store i64 %r1027, i64* %ptr_s
  %r1028 = load i64, i64* %ptr_s
  %r1029 = getelementptr [9 x i8], [9 x i8]* @.str.873, i64 0, i64 0
  %r1030 = ptrtoint i8* %r1029 to i64
  %r1031 = call i64 @_add(i64 %r1028, i64 %r1030)
  %r1032 = load i64, i64* %ptr_NL
  %r1033 = call i64 @_add(i64 %r1031, i64 %r1032)
  store i64 %r1033, i64* %ptr_s
  %r1034 = load i64, i64* %ptr_s
  %r1035 = getelementptr [31 x i8], [31 x i8]* @.str.874, i64 0, i64 0
  %r1036 = ptrtoint i8* %r1035 to i64
  %r1037 = call i64 @_add(i64 %r1034, i64 %r1036)
  %r1038 = load i64, i64* %ptr_NL
  %r1039 = call i64 @_add(i64 %r1037, i64 %r1038)
  store i64 %r1039, i64* %ptr_s
  %r1040 = load i64, i64* %ptr_s
  %r1041 = getelementptr [31 x i8], [31 x i8]* @.str.875, i64 0, i64 0
  %r1042 = ptrtoint i8* %r1041 to i64
  %r1043 = call i64 @_add(i64 %r1040, i64 %r1042)
  %r1044 = load i64, i64* %ptr_NL
  %r1045 = call i64 @_add(i64 %r1043, i64 %r1044)
  store i64 %r1045, i64* %ptr_s
  %r1046 = load i64, i64* %ptr_s
  %r1047 = getelementptr [44 x i8], [44 x i8]* @.str.876, i64 0, i64 0
  %r1048 = ptrtoint i8* %r1047 to i64
  %r1049 = call i64 @_add(i64 %r1046, i64 %r1048)
  %r1050 = load i64, i64* %ptr_NL
  %r1051 = call i64 @_add(i64 %r1049, i64 %r1050)
  store i64 %r1051, i64* %ptr_s
  %r1052 = load i64, i64* %ptr_s
  %r1053 = getelementptr [30 x i8], [30 x i8]* @.str.877, i64 0, i64 0
  %r1054 = ptrtoint i8* %r1053 to i64
  %r1055 = call i64 @_add(i64 %r1052, i64 %r1054)
  %r1056 = load i64, i64* %ptr_NL
  %r1057 = call i64 @_add(i64 %r1055, i64 %r1056)
  store i64 %r1057, i64* %ptr_s
  %r1058 = load i64, i64* %ptr_s
  %r1059 = getelementptr [34 x i8], [34 x i8]* @.str.878, i64 0, i64 0
  %r1060 = ptrtoint i8* %r1059 to i64
  %r1061 = call i64 @_add(i64 %r1058, i64 %r1060)
  %r1062 = load i64, i64* %ptr_NL
  %r1063 = call i64 @_add(i64 %r1061, i64 %r1062)
  store i64 %r1063, i64* %ptr_s
  %r1064 = load i64, i64* %ptr_s
  %r1065 = getelementptr [19 x i8], [19 x i8]* @.str.879, i64 0, i64 0
  %r1066 = ptrtoint i8* %r1065 to i64
  %r1067 = call i64 @_add(i64 %r1064, i64 %r1066)
  %r1068 = load i64, i64* %ptr_NL
  %r1069 = call i64 @_add(i64 %r1067, i64 %r1068)
  store i64 %r1069, i64* %ptr_s
  %r1070 = load i64, i64* %ptr_s
  %r1071 = getelementptr [9 x i8], [9 x i8]* @.str.880, i64 0, i64 0
  %r1072 = ptrtoint i8* %r1071 to i64
  %r1073 = call i64 @_add(i64 %r1070, i64 %r1072)
  %r1074 = load i64, i64* %ptr_NL
  %r1075 = call i64 @_add(i64 %r1073, i64 %r1074)
  store i64 %r1075, i64* %ptr_s
  %r1076 = load i64, i64* %ptr_s
  %r1077 = getelementptr [33 x i8], [33 x i8]* @.str.881, i64 0, i64 0
  %r1078 = ptrtoint i8* %r1077 to i64
  %r1079 = call i64 @_add(i64 %r1076, i64 %r1078)
  %r1080 = load i64, i64* %ptr_NL
  %r1081 = call i64 @_add(i64 %r1079, i64 %r1080)
  store i64 %r1081, i64* %ptr_s
  %r1082 = load i64, i64* %ptr_s
  %r1083 = getelementptr [38 x i8], [38 x i8]* @.str.882, i64 0, i64 0
  %r1084 = ptrtoint i8* %r1083 to i64
  %r1085 = call i64 @_add(i64 %r1082, i64 %r1084)
  %r1086 = load i64, i64* %ptr_NL
  %r1087 = call i64 @_add(i64 %r1085, i64 %r1086)
  store i64 %r1087, i64* %ptr_s
  %r1088 = load i64, i64* %ptr_s
  %r1089 = getelementptr [19 x i8], [19 x i8]* @.str.883, i64 0, i64 0
  %r1090 = ptrtoint i8* %r1089 to i64
  %r1091 = call i64 @_add(i64 %r1088, i64 %r1090)
  %r1092 = load i64, i64* %ptr_NL
  %r1093 = call i64 @_add(i64 %r1091, i64 %r1092)
  store i64 %r1093, i64* %ptr_s
  %r1094 = load i64, i64* %ptr_s
  %r1095 = getelementptr [2 x i8], [2 x i8]* @.str.884, i64 0, i64 0
  %r1096 = ptrtoint i8* %r1095 to i64
  %r1097 = call i64 @_add(i64 %r1094, i64 %r1096)
  %r1098 = load i64, i64* %ptr_NL
  %r1099 = call i64 @_add(i64 %r1097, i64 %r1098)
  store i64 %r1099, i64* %ptr_s
  %r1100 = load i64, i64* %ptr_s
  %r1101 = getelementptr [26 x i8], [26 x i8]* @.str.885, i64 0, i64 0
  %r1102 = ptrtoint i8* %r1101 to i64
  %r1103 = call i64 @_add(i64 %r1100, i64 %r1102)
  %r1104 = load i64, i64* %ptr_NL
  %r1105 = call i64 @_add(i64 %r1103, i64 %r1104)
  store i64 %r1105, i64* %ptr_s
  %r1106 = load i64, i64* %ptr_s
  %r1107 = getelementptr [34 x i8], [34 x i8]* @.str.886, i64 0, i64 0
  %r1108 = ptrtoint i8* %r1107 to i64
  %r1109 = call i64 @_add(i64 %r1106, i64 %r1108)
  %r1110 = load i64, i64* %ptr_NL
  %r1111 = call i64 @_add(i64 %r1109, i64 %r1110)
  store i64 %r1111, i64* %ptr_s
  %r1112 = load i64, i64* %ptr_s
  %r1113 = getelementptr [35 x i8], [35 x i8]* @.str.887, i64 0, i64 0
  %r1114 = ptrtoint i8* %r1113 to i64
  %r1115 = call i64 @_add(i64 %r1112, i64 %r1114)
  %r1116 = load i64, i64* %ptr_NL
  %r1117 = call i64 @_add(i64 %r1115, i64 %r1116)
  store i64 %r1117, i64* %ptr_s
  %r1118 = load i64, i64* %ptr_s
  %r1119 = getelementptr [25 x i8], [25 x i8]* @.str.888, i64 0, i64 0
  %r1120 = ptrtoint i8* %r1119 to i64
  %r1121 = call i64 @_add(i64 %r1118, i64 %r1120)
  %r1122 = load i64, i64* %ptr_NL
  %r1123 = call i64 @_add(i64 %r1121, i64 %r1122)
  store i64 %r1123, i64* %ptr_s
  %r1124 = load i64, i64* %ptr_s
  %r1125 = getelementptr [45 x i8], [45 x i8]* @.str.889, i64 0, i64 0
  %r1126 = ptrtoint i8* %r1125 to i64
  %r1127 = call i64 @_add(i64 %r1124, i64 %r1126)
  %r1128 = load i64, i64* %ptr_NL
  %r1129 = call i64 @_add(i64 %r1127, i64 %r1128)
  store i64 %r1129, i64* %ptr_s
  %r1130 = load i64, i64* %ptr_s
  %r1131 = getelementptr [25 x i8], [25 x i8]* @.str.890, i64 0, i64 0
  %r1132 = ptrtoint i8* %r1131 to i64
  %r1133 = call i64 @_add(i64 %r1130, i64 %r1132)
  %r1134 = load i64, i64* %ptr_NL
  %r1135 = call i64 @_add(i64 %r1133, i64 %r1134)
  store i64 %r1135, i64* %ptr_s
  %r1136 = load i64, i64* %ptr_s
  %r1137 = getelementptr [46 x i8], [46 x i8]* @.str.891, i64 0, i64 0
  %r1138 = ptrtoint i8* %r1137 to i64
  %r1139 = call i64 @_add(i64 %r1136, i64 %r1138)
  %r1140 = load i64, i64* %ptr_NL
  %r1141 = call i64 @_add(i64 %r1139, i64 %r1140)
  store i64 %r1141, i64* %ptr_s
  %r1142 = load i64, i64* %ptr_s
  %r1143 = getelementptr [26 x i8], [26 x i8]* @.str.892, i64 0, i64 0
  %r1144 = ptrtoint i8* %r1143 to i64
  %r1145 = call i64 @_add(i64 %r1142, i64 %r1144)
  %r1146 = load i64, i64* %ptr_NL
  %r1147 = call i64 @_add(i64 %r1145, i64 %r1146)
  store i64 %r1147, i64* %ptr_s
  %r1148 = load i64, i64* %ptr_s
  %r1149 = getelementptr [15 x i8], [15 x i8]* @.str.893, i64 0, i64 0
  %r1150 = ptrtoint i8* %r1149 to i64
  %r1151 = call i64 @_add(i64 %r1148, i64 %r1150)
  %r1152 = load i64, i64* %ptr_NL
  %r1153 = call i64 @_add(i64 %r1151, i64 %r1152)
  store i64 %r1153, i64* %ptr_s
  %r1154 = load i64, i64* %ptr_s
  %r1155 = getelementptr [2 x i8], [2 x i8]* @.str.894, i64 0, i64 0
  %r1156 = ptrtoint i8* %r1155 to i64
  %r1157 = call i64 @_add(i64 %r1154, i64 %r1156)
  %r1158 = load i64, i64* %ptr_NL
  %r1159 = call i64 @_add(i64 %r1157, i64 %r1158)
  store i64 %r1159, i64* %ptr_s
  %r1160 = load i64, i64* %ptr_s
  %r1161 = getelementptr [50 x i8], [50 x i8]* @.str.895, i64 0, i64 0
  %r1162 = ptrtoint i8* %r1161 to i64
  %r1163 = call i64 @_add(i64 %r1160, i64 %r1162)
  %r1164 = load i64, i64* %ptr_NL
  %r1165 = call i64 @_add(i64 %r1163, i64 %r1164)
  store i64 %r1165, i64* %ptr_s
  %r1166 = load i64, i64* %ptr_s
  %r1167 = getelementptr [33 x i8], [33 x i8]* @.str.896, i64 0, i64 0
  %r1168 = ptrtoint i8* %r1167 to i64
  %r1169 = call i64 @_add(i64 %r1166, i64 %r1168)
  %r1170 = load i64, i64* %ptr_NL
  %r1171 = call i64 @_add(i64 %r1169, i64 %r1170)
  store i64 %r1171, i64* %ptr_s
  %r1172 = load i64, i64* %ptr_s
  %r1173 = getelementptr [50 x i8], [50 x i8]* @.str.897, i64 0, i64 0
  %r1174 = ptrtoint i8* %r1173 to i64
  %r1175 = call i64 @_add(i64 %r1172, i64 %r1174)
  %r1176 = load i64, i64* %ptr_NL
  %r1177 = call i64 @_add(i64 %r1175, i64 %r1176)
  store i64 %r1177, i64* %ptr_s
  %r1178 = load i64, i64* %ptr_s
  %r1179 = getelementptr [35 x i8], [35 x i8]* @.str.898, i64 0, i64 0
  %r1180 = ptrtoint i8* %r1179 to i64
  %r1181 = call i64 @_add(i64 %r1178, i64 %r1180)
  %r1182 = load i64, i64* %ptr_NL
  %r1183 = call i64 @_add(i64 %r1181, i64 %r1182)
  store i64 %r1183, i64* %ptr_s
  %r1184 = load i64, i64* %ptr_s
  %r1185 = getelementptr [41 x i8], [41 x i8]* @.str.899, i64 0, i64 0
  %r1186 = ptrtoint i8* %r1185 to i64
  %r1187 = call i64 @_add(i64 %r1184, i64 %r1186)
  %r1188 = load i64, i64* %ptr_NL
  %r1189 = call i64 @_add(i64 %r1187, i64 %r1188)
  store i64 %r1189, i64* %ptr_s
  %r1190 = load i64, i64* %ptr_s
  %r1191 = getelementptr [54 x i8], [54 x i8]* @.str.900, i64 0, i64 0
  %r1192 = ptrtoint i8* %r1191 to i64
  %r1193 = call i64 @_add(i64 %r1190, i64 %r1192)
  %r1194 = load i64, i64* %ptr_NL
  %r1195 = call i64 @_add(i64 %r1193, i64 %r1194)
  store i64 %r1195, i64* %ptr_s
  %r1196 = load i64, i64* %ptr_s
  %r1197 = getelementptr [27 x i8], [27 x i8]* @.str.901, i64 0, i64 0
  %r1198 = ptrtoint i8* %r1197 to i64
  %r1199 = call i64 @_add(i64 %r1196, i64 %r1198)
  %r1200 = load i64, i64* %ptr_NL
  %r1201 = call i64 @_add(i64 %r1199, i64 %r1200)
  store i64 %r1201, i64* %ptr_s
  %r1202 = load i64, i64* %ptr_s
  %r1203 = getelementptr [12 x i8], [12 x i8]* @.str.902, i64 0, i64 0
  %r1204 = ptrtoint i8* %r1203 to i64
  %r1205 = call i64 @_add(i64 %r1202, i64 %r1204)
  %r1206 = load i64, i64* %ptr_NL
  %r1207 = call i64 @_add(i64 %r1205, i64 %r1206)
  store i64 %r1207, i64* %ptr_s
  %r1208 = load i64, i64* %ptr_s
  %r1209 = getelementptr [2 x i8], [2 x i8]* @.str.903, i64 0, i64 0
  %r1210 = ptrtoint i8* %r1209 to i64
  %r1211 = call i64 @_add(i64 %r1208, i64 %r1210)
  %r1212 = load i64, i64* %ptr_NL
  %r1213 = call i64 @_add(i64 %r1211, i64 %r1212)
  store i64 %r1213, i64* %ptr_s
  %r1214 = load i64, i64* %ptr_s
  %r1215 = getelementptr [41 x i8], [41 x i8]* @.str.904, i64 0, i64 0
  %r1216 = ptrtoint i8* %r1215 to i64
  %r1217 = call i64 @_add(i64 %r1214, i64 %r1216)
  %r1218 = load i64, i64* %ptr_NL
  %r1219 = call i64 @_add(i64 %r1217, i64 %r1218)
  store i64 %r1219, i64* %ptr_s
  %r1220 = load i64, i64* %ptr_s
  %r1221 = getelementptr [33 x i8], [33 x i8]* @.str.905, i64 0, i64 0
  %r1222 = ptrtoint i8* %r1221 to i64
  %r1223 = call i64 @_add(i64 %r1220, i64 %r1222)
  %r1224 = load i64, i64* %ptr_NL
  %r1225 = call i64 @_add(i64 %r1223, i64 %r1224)
  store i64 %r1225, i64* %ptr_s
  %r1226 = load i64, i64* %ptr_s
  %r1227 = getelementptr [49 x i8], [49 x i8]* @.str.906, i64 0, i64 0
  %r1228 = ptrtoint i8* %r1227 to i64
  %r1229 = call i64 @_add(i64 %r1226, i64 %r1228)
  %r1230 = load i64, i64* %ptr_NL
  %r1231 = call i64 @_add(i64 %r1229, i64 %r1230)
  store i64 %r1231, i64* %ptr_s
  %r1232 = load i64, i64* %ptr_s
  %r1233 = getelementptr [33 x i8], [33 x i8]* @.str.907, i64 0, i64 0
  %r1234 = ptrtoint i8* %r1233 to i64
  %r1235 = call i64 @_add(i64 %r1232, i64 %r1234)
  %r1236 = load i64, i64* %ptr_NL
  %r1237 = call i64 @_add(i64 %r1235, i64 %r1236)
  store i64 %r1237, i64* %ptr_s
  %r1238 = load i64, i64* %ptr_s
  %r1239 = getelementptr [29 x i8], [29 x i8]* @.str.908, i64 0, i64 0
  %r1240 = ptrtoint i8* %r1239 to i64
  %r1241 = call i64 @_add(i64 %r1238, i64 %r1240)
  %r1242 = load i64, i64* %ptr_NL
  %r1243 = call i64 @_add(i64 %r1241, i64 %r1242)
  store i64 %r1243, i64* %ptr_s
  %r1244 = load i64, i64* %ptr_s
  %r1245 = getelementptr [36 x i8], [36 x i8]* @.str.909, i64 0, i64 0
  %r1246 = ptrtoint i8* %r1245 to i64
  %r1247 = call i64 @_add(i64 %r1244, i64 %r1246)
  %r1248 = load i64, i64* %ptr_NL
  %r1249 = call i64 @_add(i64 %r1247, i64 %r1248)
  store i64 %r1249, i64* %ptr_s
  %r1250 = load i64, i64* %ptr_s
  %r1251 = getelementptr [50 x i8], [50 x i8]* @.str.910, i64 0, i64 0
  %r1252 = ptrtoint i8* %r1251 to i64
  %r1253 = call i64 @_add(i64 %r1250, i64 %r1252)
  %r1254 = load i64, i64* %ptr_NL
  %r1255 = call i64 @_add(i64 %r1253, i64 %r1254)
  store i64 %r1255, i64* %ptr_s
  %r1256 = load i64, i64* %ptr_s
  %r1257 = getelementptr [40 x i8], [40 x i8]* @.str.911, i64 0, i64 0
  %r1258 = ptrtoint i8* %r1257 to i64
  %r1259 = call i64 @_add(i64 %r1256, i64 %r1258)
  %r1260 = load i64, i64* %ptr_NL
  %r1261 = call i64 @_add(i64 %r1259, i64 %r1260)
  store i64 %r1261, i64* %ptr_s
  %r1262 = load i64, i64* %ptr_s
  %r1263 = getelementptr [35 x i8], [35 x i8]* @.str.912, i64 0, i64 0
  %r1264 = ptrtoint i8* %r1263 to i64
  %r1265 = call i64 @_add(i64 %r1262, i64 %r1264)
  %r1266 = load i64, i64* %ptr_NL
  %r1267 = call i64 @_add(i64 %r1265, i64 %r1266)
  store i64 %r1267, i64* %ptr_s
  %r1268 = load i64, i64* %ptr_s
  %r1269 = getelementptr [44 x i8], [44 x i8]* @.str.913, i64 0, i64 0
  %r1270 = ptrtoint i8* %r1269 to i64
  %r1271 = call i64 @_add(i64 %r1268, i64 %r1270)
  %r1272 = load i64, i64* %ptr_NL
  %r1273 = call i64 @_add(i64 %r1271, i64 %r1272)
  store i64 %r1273, i64* %ptr_s
  %r1274 = load i64, i64* %ptr_s
  %r1275 = getelementptr [61 x i8], [61 x i8]* @.str.914, i64 0, i64 0
  %r1276 = ptrtoint i8* %r1275 to i64
  %r1277 = call i64 @_add(i64 %r1274, i64 %r1276)
  %r1278 = load i64, i64* %ptr_NL
  %r1279 = call i64 @_add(i64 %r1277, i64 %r1278)
  store i64 %r1279, i64* %ptr_s
  %r1280 = load i64, i64* %ptr_s
  %r1281 = getelementptr [42 x i8], [42 x i8]* @.str.915, i64 0, i64 0
  %r1282 = ptrtoint i8* %r1281 to i64
  %r1283 = call i64 @_add(i64 %r1280, i64 %r1282)
  %r1284 = load i64, i64* %ptr_NL
  %r1285 = call i64 @_add(i64 %r1283, i64 %r1284)
  store i64 %r1285, i64* %ptr_s
  %r1286 = load i64, i64* %ptr_s
  %r1287 = getelementptr [37 x i8], [37 x i8]* @.str.916, i64 0, i64 0
  %r1288 = ptrtoint i8* %r1287 to i64
  %r1289 = call i64 @_add(i64 %r1286, i64 %r1288)
  %r1290 = load i64, i64* %ptr_NL
  %r1291 = call i64 @_add(i64 %r1289, i64 %r1290)
  store i64 %r1291, i64* %ptr_s
  %r1292 = load i64, i64* %ptr_s
  %r1293 = getelementptr [44 x i8], [44 x i8]* @.str.917, i64 0, i64 0
  %r1294 = ptrtoint i8* %r1293 to i64
  %r1295 = call i64 @_add(i64 %r1292, i64 %r1294)
  %r1296 = load i64, i64* %ptr_NL
  %r1297 = call i64 @_add(i64 %r1295, i64 %r1296)
  store i64 %r1297, i64* %ptr_s
  %r1298 = load i64, i64* %ptr_s
  %r1299 = getelementptr [53 x i8], [53 x i8]* @.str.918, i64 0, i64 0
  %r1300 = ptrtoint i8* %r1299 to i64
  %r1301 = call i64 @_add(i64 %r1298, i64 %r1300)
  %r1302 = load i64, i64* %ptr_NL
  %r1303 = call i64 @_add(i64 %r1301, i64 %r1302)
  store i64 %r1303, i64* %ptr_s
  %r1304 = load i64, i64* %ptr_s
  %r1305 = getelementptr [26 x i8], [26 x i8]* @.str.919, i64 0, i64 0
  %r1306 = ptrtoint i8* %r1305 to i64
  %r1307 = call i64 @_add(i64 %r1304, i64 %r1306)
  %r1308 = load i64, i64* %ptr_NL
  %r1309 = call i64 @_add(i64 %r1307, i64 %r1308)
  store i64 %r1309, i64* %ptr_s
  %r1310 = load i64, i64* %ptr_s
  %r1311 = getelementptr [12 x i8], [12 x i8]* @.str.920, i64 0, i64 0
  %r1312 = ptrtoint i8* %r1311 to i64
  %r1313 = call i64 @_add(i64 %r1310, i64 %r1312)
  %r1314 = load i64, i64* %ptr_NL
  %r1315 = call i64 @_add(i64 %r1313, i64 %r1314)
  store i64 %r1315, i64* %ptr_s
  %r1316 = load i64, i64* %ptr_s
  %r1317 = getelementptr [2 x i8], [2 x i8]* @.str.921, i64 0, i64 0
  %r1318 = ptrtoint i8* %r1317 to i64
  %r1319 = call i64 @_add(i64 %r1316, i64 %r1318)
  %r1320 = load i64, i64* %ptr_NL
  %r1321 = call i64 @_add(i64 %r1319, i64 %r1320)
  store i64 %r1321, i64* %ptr_s
  %r1322 = load i64, i64* %ptr_s
  %r1323 = getelementptr [25 x i8], [25 x i8]* @.str.922, i64 0, i64 0
  %r1324 = ptrtoint i8* %r1323 to i64
  %r1325 = call i64 @_add(i64 %r1322, i64 %r1324)
  %r1326 = load i64, i64* %ptr_NL
  %r1327 = call i64 @_add(i64 %r1325, i64 %r1326)
  store i64 %r1327, i64* %ptr_s
  %r1328 = load i64, i64* %ptr_s
  %r1329 = getelementptr [29 x i8], [29 x i8]* @.str.923, i64 0, i64 0
  %r1330 = ptrtoint i8* %r1329 to i64
  %r1331 = call i64 @_add(i64 %r1328, i64 %r1330)
  %r1332 = load i64, i64* %ptr_NL
  %r1333 = call i64 @_add(i64 %r1331, i64 %r1332)
  store i64 %r1333, i64* %ptr_s
  %r1334 = load i64, i64* %ptr_s
  %r1335 = getelementptr [33 x i8], [33 x i8]* @.str.924, i64 0, i64 0
  %r1336 = ptrtoint i8* %r1335 to i64
  %r1337 = call i64 @_add(i64 %r1334, i64 %r1336)
  %r1338 = load i64, i64* %ptr_NL
  %r1339 = call i64 @_add(i64 %r1337, i64 %r1338)
  store i64 %r1339, i64* %ptr_s
  %r1340 = load i64, i64* %ptr_s
  %r1341 = getelementptr [25 x i8], [25 x i8]* @.str.925, i64 0, i64 0
  %r1342 = ptrtoint i8* %r1341 to i64
  %r1343 = call i64 @_add(i64 %r1340, i64 %r1342)
  %r1344 = load i64, i64* %ptr_NL
  %r1345 = call i64 @_add(i64 %r1343, i64 %r1344)
  store i64 %r1345, i64* %ptr_s
  %r1346 = load i64, i64* %ptr_s
  %r1347 = getelementptr [13 x i8], [13 x i8]* @.str.926, i64 0, i64 0
  %r1348 = ptrtoint i8* %r1347 to i64
  %r1349 = call i64 @_add(i64 %r1346, i64 %r1348)
  %r1350 = load i64, i64* %ptr_NL
  %r1351 = call i64 @_add(i64 %r1349, i64 %r1350)
  store i64 %r1351, i64* %ptr_s
  %r1352 = load i64, i64* %ptr_s
  %r1353 = getelementptr [2 x i8], [2 x i8]* @.str.927, i64 0, i64 0
  %r1354 = ptrtoint i8* %r1353 to i64
  %r1355 = call i64 @_add(i64 %r1352, i64 %r1354)
  %r1356 = load i64, i64* %ptr_NL
  %r1357 = call i64 @_add(i64 %r1355, i64 %r1356)
  store i64 %r1357, i64* %ptr_s
  %r1358 = load i64, i64* %ptr_s
  %r1359 = getelementptr [47 x i8], [47 x i8]* @.str.928, i64 0, i64 0
  %r1360 = ptrtoint i8* %r1359 to i64
  %r1361 = call i64 @_add(i64 %r1358, i64 %r1360)
  %r1362 = load i64, i64* %ptr_NL
  %r1363 = call i64 @_add(i64 %r1361, i64 %r1362)
  store i64 %r1363, i64* %ptr_s
  %r1364 = load i64, i64* %ptr_s
  %r1365 = getelementptr [39 x i8], [39 x i8]* @.str.929, i64 0, i64 0
  %r1366 = ptrtoint i8* %r1365 to i64
  %r1367 = call i64 @_add(i64 %r1364, i64 %r1366)
  %r1368 = load i64, i64* %ptr_NL
  %r1369 = call i64 @_add(i64 %r1367, i64 %r1368)
  store i64 %r1369, i64* %ptr_s
  %r1370 = load i64, i64* %ptr_s
  %r1371 = getelementptr [39 x i8], [39 x i8]* @.str.930, i64 0, i64 0
  %r1372 = ptrtoint i8* %r1371 to i64
  %r1373 = call i64 @_add(i64 %r1370, i64 %r1372)
  %r1374 = load i64, i64* %ptr_NL
  %r1375 = call i64 @_add(i64 %r1373, i64 %r1374)
  store i64 %r1375, i64* %ptr_s
  %r1376 = load i64, i64* %ptr_s
  %r1377 = getelementptr [12 x i8], [12 x i8]* @.str.931, i64 0, i64 0
  %r1378 = ptrtoint i8* %r1377 to i64
  %r1379 = call i64 @_add(i64 %r1376, i64 %r1378)
  %r1380 = load i64, i64* %ptr_NL
  %r1381 = call i64 @_add(i64 %r1379, i64 %r1380)
  store i64 %r1381, i64* %ptr_s
  %r1382 = load i64, i64* %ptr_s
  %r1383 = getelementptr [2 x i8], [2 x i8]* @.str.932, i64 0, i64 0
  %r1384 = ptrtoint i8* %r1383 to i64
  %r1385 = call i64 @_add(i64 %r1382, i64 %r1384)
  %r1386 = load i64, i64* %ptr_NL
  %r1387 = call i64 @_add(i64 %r1385, i64 %r1386)
  store i64 %r1387, i64* %ptr_s
  %r1388 = load i64, i64* %ptr_s
  %r1389 = getelementptr [47 x i8], [47 x i8]* @.str.933, i64 0, i64 0
  %r1390 = ptrtoint i8* %r1389 to i64
  %r1391 = call i64 @_add(i64 %r1388, i64 %r1390)
  %r1392 = load i64, i64* %ptr_NL
  %r1393 = call i64 @_add(i64 %r1391, i64 %r1392)
  store i64 %r1393, i64* %ptr_s
  %r1394 = load i64, i64* %ptr_s
  %r1395 = getelementptr [35 x i8], [35 x i8]* @.str.934, i64 0, i64 0
  %r1396 = ptrtoint i8* %r1395 to i64
  %r1397 = call i64 @_add(i64 %r1394, i64 %r1396)
  %r1398 = load i64, i64* %ptr_NL
  %r1399 = call i64 @_add(i64 %r1397, i64 %r1398)
  store i64 %r1399, i64* %ptr_s
  %r1400 = load i64, i64* %ptr_s
  %r1401 = getelementptr [30 x i8], [30 x i8]* @.str.935, i64 0, i64 0
  %r1402 = ptrtoint i8* %r1401 to i64
  %r1403 = call i64 @_add(i64 %r1400, i64 %r1402)
  %r1404 = load i64, i64* %ptr_NL
  %r1405 = call i64 @_add(i64 %r1403, i64 %r1404)
  store i64 %r1405, i64* %ptr_s
  %r1406 = load i64, i64* %ptr_s
  %r1407 = getelementptr [33 x i8], [33 x i8]* @.str.936, i64 0, i64 0
  %r1408 = ptrtoint i8* %r1407 to i64
  %r1409 = call i64 @_add(i64 %r1406, i64 %r1408)
  %r1410 = load i64, i64* %ptr_NL
  %r1411 = call i64 @_add(i64 %r1409, i64 %r1410)
  store i64 %r1411, i64* %ptr_s
  %r1412 = load i64, i64* %ptr_s
  %r1413 = getelementptr [47 x i8], [47 x i8]* @.str.937, i64 0, i64 0
  %r1414 = ptrtoint i8* %r1413 to i64
  %r1415 = call i64 @_add(i64 %r1412, i64 %r1414)
  %r1416 = load i64, i64* %ptr_NL
  %r1417 = call i64 @_add(i64 %r1415, i64 %r1416)
  store i64 %r1417, i64* %ptr_s
  %r1418 = load i64, i64* %ptr_s
  %r1419 = getelementptr [9 x i8], [9 x i8]* @.str.938, i64 0, i64 0
  %r1420 = ptrtoint i8* %r1419 to i64
  %r1421 = call i64 @_add(i64 %r1418, i64 %r1420)
  %r1422 = load i64, i64* %ptr_NL
  %r1423 = call i64 @_add(i64 %r1421, i64 %r1422)
  store i64 %r1423, i64* %ptr_s
  %r1424 = load i64, i64* %ptr_s
  %r1425 = getelementptr [50 x i8], [50 x i8]* @.str.939, i64 0, i64 0
  %r1426 = ptrtoint i8* %r1425 to i64
  %r1427 = call i64 @_add(i64 %r1424, i64 %r1426)
  %r1428 = load i64, i64* %ptr_NL
  %r1429 = call i64 @_add(i64 %r1427, i64 %r1428)
  store i64 %r1429, i64* %ptr_s
  %r1430 = load i64, i64* %ptr_s
  %r1431 = getelementptr [12 x i8], [12 x i8]* @.str.940, i64 0, i64 0
  %r1432 = ptrtoint i8* %r1431 to i64
  %r1433 = call i64 @_add(i64 %r1430, i64 %r1432)
  %r1434 = load i64, i64* %ptr_NL
  %r1435 = call i64 @_add(i64 %r1433, i64 %r1434)
  store i64 %r1435, i64* %ptr_s
  %r1436 = load i64, i64* %ptr_s
  %r1437 = getelementptr [8 x i8], [8 x i8]* @.str.941, i64 0, i64 0
  %r1438 = ptrtoint i8* %r1437 to i64
  %r1439 = call i64 @_add(i64 %r1436, i64 %r1438)
  %r1440 = load i64, i64* %ptr_NL
  %r1441 = call i64 @_add(i64 %r1439, i64 %r1440)
  store i64 %r1441, i64* %ptr_s
  %r1442 = load i64, i64* %ptr_s
  %r1443 = getelementptr [49 x i8], [49 x i8]* @.str.942, i64 0, i64 0
  %r1444 = ptrtoint i8* %r1443 to i64
  %r1445 = call i64 @_add(i64 %r1442, i64 %r1444)
  %r1446 = load i64, i64* %ptr_NL
  %r1447 = call i64 @_add(i64 %r1445, i64 %r1446)
  store i64 %r1447, i64* %ptr_s
  %r1448 = load i64, i64* %ptr_s
  %r1449 = getelementptr [12 x i8], [12 x i8]* @.str.943, i64 0, i64 0
  %r1450 = ptrtoint i8* %r1449 to i64
  %r1451 = call i64 @_add(i64 %r1448, i64 %r1450)
  %r1452 = load i64, i64* %ptr_NL
  %r1453 = call i64 @_add(i64 %r1451, i64 %r1452)
  store i64 %r1453, i64* %ptr_s
  %r1454 = load i64, i64* %ptr_s
  %r1455 = getelementptr [2 x i8], [2 x i8]* @.str.944, i64 0, i64 0
  %r1456 = ptrtoint i8* %r1455 to i64
  %r1457 = call i64 @_add(i64 %r1454, i64 %r1456)
  %r1458 = load i64, i64* %ptr_NL
  %r1459 = call i64 @_add(i64 %r1457, i64 %r1458)
  store i64 %r1459, i64* %ptr_s
  %r1460 = load i64, i64* %ptr_s
  %r1461 = getelementptr [41 x i8], [41 x i8]* @.str.945, i64 0, i64 0
  %r1462 = ptrtoint i8* %r1461 to i64
  %r1463 = call i64 @_add(i64 %r1460, i64 %r1462)
  %r1464 = load i64, i64* %ptr_NL
  %r1465 = call i64 @_add(i64 %r1463, i64 %r1464)
  store i64 %r1465, i64* %ptr_s
  %r1466 = load i64, i64* %ptr_s
  %r1467 = getelementptr [33 x i8], [33 x i8]* @.str.946, i64 0, i64 0
  %r1468 = ptrtoint i8* %r1467 to i64
  %r1469 = call i64 @_add(i64 %r1466, i64 %r1468)
  %r1470 = load i64, i64* %ptr_NL
  %r1471 = call i64 @_add(i64 %r1469, i64 %r1470)
  store i64 %r1471, i64* %ptr_s
  %r1472 = load i64, i64* %ptr_s
  %r1473 = getelementptr [49 x i8], [49 x i8]* @.str.947, i64 0, i64 0
  %r1474 = ptrtoint i8* %r1473 to i64
  %r1475 = call i64 @_add(i64 %r1472, i64 %r1474)
  %r1476 = load i64, i64* %ptr_NL
  %r1477 = call i64 @_add(i64 %r1475, i64 %r1476)
  store i64 %r1477, i64* %ptr_s
  %r1478 = load i64, i64* %ptr_s
  %r1479 = getelementptr [33 x i8], [33 x i8]* @.str.948, i64 0, i64 0
  %r1480 = ptrtoint i8* %r1479 to i64
  %r1481 = call i64 @_add(i64 %r1478, i64 %r1480)
  %r1482 = load i64, i64* %ptr_NL
  %r1483 = call i64 @_add(i64 %r1481, i64 %r1482)
  store i64 %r1483, i64* %ptr_s
  %r1484 = load i64, i64* %ptr_s
  %r1485 = getelementptr [50 x i8], [50 x i8]* @.str.949, i64 0, i64 0
  %r1486 = ptrtoint i8* %r1485 to i64
  %r1487 = call i64 @_add(i64 %r1484, i64 %r1486)
  %r1488 = load i64, i64* %ptr_NL
  %r1489 = call i64 @_add(i64 %r1487, i64 %r1488)
  store i64 %r1489, i64* %ptr_s
  %r1490 = load i64, i64* %ptr_s
  %r1491 = getelementptr [35 x i8], [35 x i8]* @.str.950, i64 0, i64 0
  %r1492 = ptrtoint i8* %r1491 to i64
  %r1493 = call i64 @_add(i64 %r1490, i64 %r1492)
  %r1494 = load i64, i64* %ptr_NL
  %r1495 = call i64 @_add(i64 %r1493, i64 %r1494)
  store i64 %r1495, i64* %ptr_s
  %r1496 = load i64, i64* %ptr_s
  %r1497 = getelementptr [41 x i8], [41 x i8]* @.str.951, i64 0, i64 0
  %r1498 = ptrtoint i8* %r1497 to i64
  %r1499 = call i64 @_add(i64 %r1496, i64 %r1498)
  %r1500 = load i64, i64* %ptr_NL
  %r1501 = call i64 @_add(i64 %r1499, i64 %r1500)
  store i64 %r1501, i64* %ptr_s
  %r1502 = load i64, i64* %ptr_s
  %r1503 = getelementptr [36 x i8], [36 x i8]* @.str.952, i64 0, i64 0
  %r1504 = ptrtoint i8* %r1503 to i64
  %r1505 = call i64 @_add(i64 %r1502, i64 %r1504)
  %r1506 = load i64, i64* %ptr_NL
  %r1507 = call i64 @_add(i64 %r1505, i64 %r1506)
  store i64 %r1507, i64* %ptr_s
  %r1508 = load i64, i64* %ptr_s
  %r1509 = getelementptr [29 x i8], [29 x i8]* @.str.953, i64 0, i64 0
  %r1510 = ptrtoint i8* %r1509 to i64
  %r1511 = call i64 @_add(i64 %r1508, i64 %r1510)
  %r1512 = load i64, i64* %ptr_NL
  %r1513 = call i64 @_add(i64 %r1511, i64 %r1512)
  store i64 %r1513, i64* %ptr_s
  %r1514 = load i64, i64* %ptr_s
  %r1515 = getelementptr [17 x i8], [17 x i8]* @.str.954, i64 0, i64 0
  %r1516 = ptrtoint i8* %r1515 to i64
  %r1517 = call i64 @_add(i64 %r1514, i64 %r1516)
  %r1518 = load i64, i64* %ptr_NL
  %r1519 = call i64 @_add(i64 %r1517, i64 %r1518)
  store i64 %r1519, i64* %ptr_s
  %r1520 = load i64, i64* %ptr_s
  %r1521 = getelementptr [6 x i8], [6 x i8]* @.str.955, i64 0, i64 0
  %r1522 = ptrtoint i8* %r1521 to i64
  %r1523 = call i64 @_add(i64 %r1520, i64 %r1522)
  %r1524 = load i64, i64* %ptr_NL
  %r1525 = call i64 @_add(i64 %r1523, i64 %r1524)
  store i64 %r1525, i64* %ptr_s
  %r1526 = load i64, i64* %ptr_s
  %r1527 = getelementptr [52 x i8], [52 x i8]* @.str.956, i64 0, i64 0
  %r1528 = ptrtoint i8* %r1527 to i64
  %r1529 = call i64 @_add(i64 %r1526, i64 %r1528)
  %r1530 = load i64, i64* %ptr_NL
  %r1531 = call i64 @_add(i64 %r1529, i64 %r1530)
  store i64 %r1531, i64* %ptr_s
  %r1532 = load i64, i64* %ptr_s
  %r1533 = getelementptr [29 x i8], [29 x i8]* @.str.957, i64 0, i64 0
  %r1534 = ptrtoint i8* %r1533 to i64
  %r1535 = call i64 @_add(i64 %r1532, i64 %r1534)
  %r1536 = load i64, i64* %ptr_NL
  %r1537 = call i64 @_add(i64 %r1535, i64 %r1536)
  store i64 %r1537, i64* %ptr_s
  %r1538 = load i64, i64* %ptr_s
  %r1539 = getelementptr [50 x i8], [50 x i8]* @.str.958, i64 0, i64 0
  %r1540 = ptrtoint i8* %r1539 to i64
  %r1541 = call i64 @_add(i64 %r1538, i64 %r1540)
  %r1542 = load i64, i64* %ptr_NL
  %r1543 = call i64 @_add(i64 %r1541, i64 %r1542)
  store i64 %r1543, i64* %ptr_s
  %r1544 = load i64, i64* %ptr_s
  %r1545 = getelementptr [11 x i8], [11 x i8]* @.str.959, i64 0, i64 0
  %r1546 = ptrtoint i8* %r1545 to i64
  %r1547 = call i64 @_add(i64 %r1544, i64 %r1546)
  %r1548 = load i64, i64* %ptr_NL
  %r1549 = call i64 @_add(i64 %r1547, i64 %r1548)
  store i64 %r1549, i64* %ptr_s
  %r1550 = load i64, i64* %ptr_s
  %r1551 = getelementptr [54 x i8], [54 x i8]* @.str.960, i64 0, i64 0
  %r1552 = ptrtoint i8* %r1551 to i64
  %r1553 = call i64 @_add(i64 %r1550, i64 %r1552)
  %r1554 = load i64, i64* %ptr_NL
  %r1555 = call i64 @_add(i64 %r1553, i64 %r1554)
  store i64 %r1555, i64* %ptr_s
  %r1556 = load i64, i64* %ptr_s
  %r1557 = getelementptr [34 x i8], [34 x i8]* @.str.961, i64 0, i64 0
  %r1558 = ptrtoint i8* %r1557 to i64
  %r1559 = call i64 @_add(i64 %r1556, i64 %r1558)
  %r1560 = load i64, i64* %ptr_NL
  %r1561 = call i64 @_add(i64 %r1559, i64 %r1560)
  store i64 %r1561, i64* %ptr_s
  %r1562 = load i64, i64* %ptr_s
  %r1563 = getelementptr [38 x i8], [38 x i8]* @.str.962, i64 0, i64 0
  %r1564 = ptrtoint i8* %r1563 to i64
  %r1565 = call i64 @_add(i64 %r1562, i64 %r1564)
  %r1566 = load i64, i64* %ptr_NL
  %r1567 = call i64 @_add(i64 %r1565, i64 %r1566)
  store i64 %r1567, i64* %ptr_s
  %r1568 = load i64, i64* %ptr_s
  %r1569 = getelementptr [50 x i8], [50 x i8]* @.str.963, i64 0, i64 0
  %r1570 = ptrtoint i8* %r1569 to i64
  %r1571 = call i64 @_add(i64 %r1568, i64 %r1570)
  %r1572 = load i64, i64* %ptr_NL
  %r1573 = call i64 @_add(i64 %r1571, i64 %r1572)
  store i64 %r1573, i64* %ptr_s
  %r1574 = load i64, i64* %ptr_s
  %r1575 = getelementptr [31 x i8], [31 x i8]* @.str.964, i64 0, i64 0
  %r1576 = ptrtoint i8* %r1575 to i64
  %r1577 = call i64 @_add(i64 %r1574, i64 %r1576)
  %r1578 = load i64, i64* %ptr_NL
  %r1579 = call i64 @_add(i64 %r1577, i64 %r1578)
  store i64 %r1579, i64* %ptr_s
  %r1580 = load i64, i64* %ptr_s
  %r1581 = getelementptr [42 x i8], [42 x i8]* @.str.965, i64 0, i64 0
  %r1582 = ptrtoint i8* %r1581 to i64
  %r1583 = call i64 @_add(i64 %r1580, i64 %r1582)
  %r1584 = load i64, i64* %ptr_NL
  %r1585 = call i64 @_add(i64 %r1583, i64 %r1584)
  store i64 %r1585, i64* %ptr_s
  %r1586 = load i64, i64* %ptr_s
  %r1587 = getelementptr [6 x i8], [6 x i8]* @.str.966, i64 0, i64 0
  %r1588 = ptrtoint i8* %r1587 to i64
  %r1589 = call i64 @_add(i64 %r1586, i64 %r1588)
  %r1590 = load i64, i64* %ptr_NL
  %r1591 = call i64 @_add(i64 %r1589, i64 %r1590)
  store i64 %r1591, i64* %ptr_s
  %r1592 = load i64, i64* %ptr_s
  %r1593 = getelementptr [26 x i8], [26 x i8]* @.str.967, i64 0, i64 0
  %r1594 = ptrtoint i8* %r1593 to i64
  %r1595 = call i64 @_add(i64 %r1592, i64 %r1594)
  %r1596 = load i64, i64* %ptr_NL
  %r1597 = call i64 @_add(i64 %r1595, i64 %r1596)
  store i64 %r1597, i64* %ptr_s
  %r1598 = load i64, i64* %ptr_s
  %r1599 = getelementptr [17 x i8], [17 x i8]* @.str.968, i64 0, i64 0
  %r1600 = ptrtoint i8* %r1599 to i64
  %r1601 = call i64 @_add(i64 %r1598, i64 %r1600)
  %r1602 = load i64, i64* %ptr_NL
  %r1603 = call i64 @_add(i64 %r1601, i64 %r1602)
  store i64 %r1603, i64* %ptr_s
  %r1604 = load i64, i64* %ptr_s
  %r1605 = getelementptr [7 x i8], [7 x i8]* @.str.969, i64 0, i64 0
  %r1606 = ptrtoint i8* %r1605 to i64
  %r1607 = call i64 @_add(i64 %r1604, i64 %r1606)
  %r1608 = load i64, i64* %ptr_NL
  %r1609 = call i64 @_add(i64 %r1607, i64 %r1608)
  store i64 %r1609, i64* %ptr_s
  %r1610 = load i64, i64* %ptr_s
  %r1611 = getelementptr [25 x i8], [25 x i8]* @.str.970, i64 0, i64 0
  %r1612 = ptrtoint i8* %r1611 to i64
  %r1613 = call i64 @_add(i64 %r1610, i64 %r1612)
  %r1614 = load i64, i64* %ptr_NL
  %r1615 = call i64 @_add(i64 %r1613, i64 %r1614)
  store i64 %r1615, i64* %ptr_s
  %r1616 = load i64, i64* %ptr_s
  %r1617 = getelementptr [58 x i8], [58 x i8]* @.str.971, i64 0, i64 0
  %r1618 = ptrtoint i8* %r1617 to i64
  %r1619 = call i64 @_add(i64 %r1616, i64 %r1618)
  %r1620 = load i64, i64* %ptr_NL
  %r1621 = call i64 @_add(i64 %r1619, i64 %r1620)
  store i64 %r1621, i64* %ptr_s
  %r1622 = load i64, i64* %ptr_s
  %r1623 = getelementptr [32 x i8], [32 x i8]* @.str.972, i64 0, i64 0
  %r1624 = ptrtoint i8* %r1623 to i64
  %r1625 = call i64 @_add(i64 %r1622, i64 %r1624)
  %r1626 = load i64, i64* %ptr_NL
  %r1627 = call i64 @_add(i64 %r1625, i64 %r1626)
  store i64 %r1627, i64* %ptr_s
  %r1628 = load i64, i64* %ptr_s
  %r1629 = getelementptr [15 x i8], [15 x i8]* @.str.973, i64 0, i64 0
  %r1630 = ptrtoint i8* %r1629 to i64
  %r1631 = call i64 @_add(i64 %r1628, i64 %r1630)
  %r1632 = load i64, i64* %ptr_NL
  %r1633 = call i64 @_add(i64 %r1631, i64 %r1632)
  store i64 %r1633, i64* %ptr_s
  %r1634 = load i64, i64* %ptr_s
  %r1635 = getelementptr [11 x i8], [11 x i8]* @.str.974, i64 0, i64 0
  %r1636 = ptrtoint i8* %r1635 to i64
  %r1637 = call i64 @_add(i64 %r1634, i64 %r1636)
  %r1638 = load i64, i64* %ptr_NL
  %r1639 = call i64 @_add(i64 %r1637, i64 %r1638)
  store i64 %r1639, i64* %ptr_s
  %r1640 = load i64, i64* %ptr_s
  %r1641 = getelementptr [12 x i8], [12 x i8]* @.str.975, i64 0, i64 0
  %r1642 = ptrtoint i8* %r1641 to i64
  %r1643 = call i64 @_add(i64 %r1640, i64 %r1642)
  %r1644 = load i64, i64* %ptr_NL
  %r1645 = call i64 @_add(i64 %r1643, i64 %r1644)
  store i64 %r1645, i64* %ptr_s
  %r1646 = load i64, i64* %ptr_s
  %r1647 = getelementptr [2 x i8], [2 x i8]* @.str.976, i64 0, i64 0
  %r1648 = ptrtoint i8* %r1647 to i64
  %r1649 = call i64 @_add(i64 %r1646, i64 %r1648)
  %r1650 = load i64, i64* %ptr_NL
  %r1651 = call i64 @_add(i64 %r1649, i64 %r1650)
  store i64 %r1651, i64* %ptr_s
  %r1652 = load i64, i64* %ptr_s
  %r1653 = getelementptr [39 x i8], [39 x i8]* @.str.977, i64 0, i64 0
  %r1654 = ptrtoint i8* %r1653 to i64
  %r1655 = call i64 @_add(i64 %r1652, i64 %r1654)
  %r1656 = load i64, i64* %ptr_NL
  %r1657 = call i64 @_add(i64 %r1655, i64 %r1656)
  store i64 %r1657, i64* %ptr_s
  %r1658 = load i64, i64* %ptr_s
  %r1659 = getelementptr [33 x i8], [33 x i8]* @.str.978, i64 0, i64 0
  %r1660 = ptrtoint i8* %r1659 to i64
  %r1661 = call i64 @_add(i64 %r1658, i64 %r1660)
  %r1662 = load i64, i64* %ptr_NL
  %r1663 = call i64 @_add(i64 %r1661, i64 %r1662)
  store i64 %r1663, i64* %ptr_s
  %r1664 = load i64, i64* %ptr_s
  %r1665 = getelementptr [43 x i8], [43 x i8]* @.str.979, i64 0, i64 0
  %r1666 = ptrtoint i8* %r1665 to i64
  %r1667 = call i64 @_add(i64 %r1664, i64 %r1666)
  %r1668 = load i64, i64* %ptr_NL
  %r1669 = call i64 @_add(i64 %r1667, i64 %r1668)
  store i64 %r1669, i64* %ptr_s
  %r1670 = load i64, i64* %ptr_s
  %r1671 = getelementptr [7 x i8], [7 x i8]* @.str.980, i64 0, i64 0
  %r1672 = ptrtoint i8* %r1671 to i64
  %r1673 = call i64 @_add(i64 %r1670, i64 %r1672)
  %r1674 = load i64, i64* %ptr_NL
  %r1675 = call i64 @_add(i64 %r1673, i64 %r1674)
  store i64 %r1675, i64* %ptr_s
  %r1676 = load i64, i64* %ptr_s
  %r1677 = getelementptr [35 x i8], [35 x i8]* @.str.981, i64 0, i64 0
  %r1678 = ptrtoint i8* %r1677 to i64
  %r1679 = call i64 @_add(i64 %r1676, i64 %r1678)
  %r1680 = load i64, i64* %ptr_NL
  %r1681 = call i64 @_add(i64 %r1679, i64 %r1680)
  store i64 %r1681, i64* %ptr_s
  %r1682 = load i64, i64* %ptr_s
  %r1683 = getelementptr [28 x i8], [28 x i8]* @.str.982, i64 0, i64 0
  %r1684 = ptrtoint i8* %r1683 to i64
  %r1685 = call i64 @_add(i64 %r1682, i64 %r1684)
  %r1686 = load i64, i64* %ptr_NL
  %r1687 = call i64 @_add(i64 %r1685, i64 %r1686)
  store i64 %r1687, i64* %ptr_s
  %r1688 = load i64, i64* %ptr_s
  %r1689 = getelementptr [32 x i8], [32 x i8]* @.str.983, i64 0, i64 0
  %r1690 = ptrtoint i8* %r1689 to i64
  %r1691 = call i64 @_add(i64 %r1688, i64 %r1690)
  %r1692 = load i64, i64* %ptr_NL
  %r1693 = call i64 @_add(i64 %r1691, i64 %r1692)
  store i64 %r1693, i64* %ptr_s
  %r1694 = load i64, i64* %ptr_s
  %r1695 = getelementptr [51 x i8], [51 x i8]* @.str.984, i64 0, i64 0
  %r1696 = ptrtoint i8* %r1695 to i64
  %r1697 = call i64 @_add(i64 %r1694, i64 %r1696)
  %r1698 = load i64, i64* %ptr_NL
  %r1699 = call i64 @_add(i64 %r1697, i64 %r1698)
  store i64 %r1699, i64* %ptr_s
  %r1700 = load i64, i64* %ptr_s
  %r1701 = getelementptr [11 x i8], [11 x i8]* @.str.985, i64 0, i64 0
  %r1702 = ptrtoint i8* %r1701 to i64
  %r1703 = call i64 @_add(i64 %r1700, i64 %r1702)
  %r1704 = load i64, i64* %ptr_NL
  %r1705 = call i64 @_add(i64 %r1703, i64 %r1704)
  store i64 %r1705, i64* %ptr_s
  %r1706 = load i64, i64* %ptr_s
  %r1707 = getelementptr [31 x i8], [31 x i8]* @.str.986, i64 0, i64 0
  %r1708 = ptrtoint i8* %r1707 to i64
  %r1709 = call i64 @_add(i64 %r1706, i64 %r1708)
  %r1710 = load i64, i64* %ptr_NL
  %r1711 = call i64 @_add(i64 %r1709, i64 %r1710)
  store i64 %r1711, i64* %ptr_s
  %r1712 = load i64, i64* %ptr_s
  %r1713 = getelementptr [46 x i8], [46 x i8]* @.str.987, i64 0, i64 0
  %r1714 = ptrtoint i8* %r1713 to i64
  %r1715 = call i64 @_add(i64 %r1712, i64 %r1714)
  %r1716 = load i64, i64* %ptr_NL
  %r1717 = call i64 @_add(i64 %r1715, i64 %r1716)
  store i64 %r1717, i64* %ptr_s
  %r1718 = load i64, i64* %ptr_s
  %r1719 = getelementptr [8 x i8], [8 x i8]* @.str.988, i64 0, i64 0
  %r1720 = ptrtoint i8* %r1719 to i64
  %r1721 = call i64 @_add(i64 %r1718, i64 %r1720)
  %r1722 = load i64, i64* %ptr_NL
  %r1723 = call i64 @_add(i64 %r1721, i64 %r1722)
  store i64 %r1723, i64* %ptr_s
  %r1724 = load i64, i64* %ptr_s
  %r1725 = getelementptr [39 x i8], [39 x i8]* @.str.989, i64 0, i64 0
  %r1726 = ptrtoint i8* %r1725 to i64
  %r1727 = call i64 @_add(i64 %r1724, i64 %r1726)
  %r1728 = load i64, i64* %ptr_NL
  %r1729 = call i64 @_add(i64 %r1727, i64 %r1728)
  store i64 %r1729, i64* %ptr_s
  %r1730 = load i64, i64* %ptr_s
  %r1731 = getelementptr [56 x i8], [56 x i8]* @.str.990, i64 0, i64 0
  %r1732 = ptrtoint i8* %r1731 to i64
  %r1733 = call i64 @_add(i64 %r1730, i64 %r1732)
  %r1734 = load i64, i64* %ptr_NL
  %r1735 = call i64 @_add(i64 %r1733, i64 %r1734)
  store i64 %r1735, i64* %ptr_s
  %r1736 = load i64, i64* %ptr_s
  %r1737 = getelementptr [33 x i8], [33 x i8]* @.str.991, i64 0, i64 0
  %r1738 = ptrtoint i8* %r1737 to i64
  %r1739 = call i64 @_add(i64 %r1736, i64 %r1738)
  %r1740 = load i64, i64* %ptr_NL
  %r1741 = call i64 @_add(i64 %r1739, i64 %r1740)
  store i64 %r1741, i64* %ptr_s
  %r1742 = load i64, i64* %ptr_s
  %r1743 = getelementptr [37 x i8], [37 x i8]* @.str.992, i64 0, i64 0
  %r1744 = ptrtoint i8* %r1743 to i64
  %r1745 = call i64 @_add(i64 %r1742, i64 %r1744)
  %r1746 = load i64, i64* %ptr_NL
  %r1747 = call i64 @_add(i64 %r1745, i64 %r1746)
  store i64 %r1747, i64* %ptr_s
  %r1748 = load i64, i64* %ptr_s
  %r1749 = getelementptr [42 x i8], [42 x i8]* @.str.993, i64 0, i64 0
  %r1750 = ptrtoint i8* %r1749 to i64
  %r1751 = call i64 @_add(i64 %r1748, i64 %r1750)
  %r1752 = load i64, i64* %ptr_NL
  %r1753 = call i64 @_add(i64 %r1751, i64 %r1752)
  store i64 %r1753, i64* %ptr_s
  %r1754 = load i64, i64* %ptr_s
  %r1755 = getelementptr [31 x i8], [31 x i8]* @.str.994, i64 0, i64 0
  %r1756 = ptrtoint i8* %r1755 to i64
  %r1757 = call i64 @_add(i64 %r1754, i64 %r1756)
  %r1758 = load i64, i64* %ptr_NL
  %r1759 = call i64 @_add(i64 %r1757, i64 %r1758)
  store i64 %r1759, i64* %ptr_s
  %r1760 = load i64, i64* %ptr_s
  %r1761 = getelementptr [48 x i8], [48 x i8]* @.str.995, i64 0, i64 0
  %r1762 = ptrtoint i8* %r1761 to i64
  %r1763 = call i64 @_add(i64 %r1760, i64 %r1762)
  %r1764 = load i64, i64* %ptr_NL
  %r1765 = call i64 @_add(i64 %r1763, i64 %r1764)
  store i64 %r1765, i64* %ptr_s
  %r1766 = load i64, i64* %ptr_s
  %r1767 = getelementptr [24 x i8], [24 x i8]* @.str.996, i64 0, i64 0
  %r1768 = ptrtoint i8* %r1767 to i64
  %r1769 = call i64 @_add(i64 %r1766, i64 %r1768)
  %r1770 = load i64, i64* %ptr_NL
  %r1771 = call i64 @_add(i64 %r1769, i64 %r1770)
  store i64 %r1771, i64* %ptr_s
  %r1772 = load i64, i64* %ptr_s
  %r1773 = getelementptr [42 x i8], [42 x i8]* @.str.997, i64 0, i64 0
  %r1774 = ptrtoint i8* %r1773 to i64
  %r1775 = call i64 @_add(i64 %r1772, i64 %r1774)
  %r1776 = load i64, i64* %ptr_NL
  %r1777 = call i64 @_add(i64 %r1775, i64 %r1776)
  store i64 %r1777, i64* %ptr_s
  %r1778 = load i64, i64* %ptr_s
  %r1779 = getelementptr [19 x i8], [19 x i8]* @.str.998, i64 0, i64 0
  %r1780 = ptrtoint i8* %r1779 to i64
  %r1781 = call i64 @_add(i64 %r1778, i64 %r1780)
  %r1782 = load i64, i64* %ptr_NL
  %r1783 = call i64 @_add(i64 %r1781, i64 %r1782)
  store i64 %r1783, i64* %ptr_s
  %r1784 = load i64, i64* %ptr_s
  %r1785 = getelementptr [8 x i8], [8 x i8]* @.str.999, i64 0, i64 0
  %r1786 = ptrtoint i8* %r1785 to i64
  %r1787 = call i64 @_add(i64 %r1784, i64 %r1786)
  %r1788 = load i64, i64* %ptr_NL
  %r1789 = call i64 @_add(i64 %r1787, i64 %r1788)
  store i64 %r1789, i64* %ptr_s
  %r1790 = load i64, i64* %ptr_s
  %r1791 = getelementptr [52 x i8], [52 x i8]* @.str.1000, i64 0, i64 0
  %r1792 = ptrtoint i8* %r1791 to i64
  %r1793 = call i64 @_add(i64 %r1790, i64 %r1792)
  %r1794 = load i64, i64* %ptr_NL
  %r1795 = call i64 @_add(i64 %r1793, i64 %r1794)
  store i64 %r1795, i64* %ptr_s
  %r1796 = load i64, i64* %ptr_s
  %r1797 = getelementptr [19 x i8], [19 x i8]* @.str.1001, i64 0, i64 0
  %r1798 = ptrtoint i8* %r1797 to i64
  %r1799 = call i64 @_add(i64 %r1796, i64 %r1798)
  %r1800 = load i64, i64* %ptr_NL
  %r1801 = call i64 @_add(i64 %r1799, i64 %r1800)
  store i64 %r1801, i64* %ptr_s
  %r1802 = load i64, i64* %ptr_s
  %r1803 = getelementptr [9 x i8], [9 x i8]* @.str.1002, i64 0, i64 0
  %r1804 = ptrtoint i8* %r1803 to i64
  %r1805 = call i64 @_add(i64 %r1802, i64 %r1804)
  %r1806 = load i64, i64* %ptr_NL
  %r1807 = call i64 @_add(i64 %r1805, i64 %r1806)
  store i64 %r1807, i64* %ptr_s
  %r1808 = load i64, i64* %ptr_s
  %r1809 = getelementptr [37 x i8], [37 x i8]* @.str.1003, i64 0, i64 0
  %r1810 = ptrtoint i8* %r1809 to i64
  %r1811 = call i64 @_add(i64 %r1808, i64 %r1810)
  %r1812 = load i64, i64* %ptr_NL
  %r1813 = call i64 @_add(i64 %r1811, i64 %r1812)
  store i64 %r1813, i64* %ptr_s
  %r1814 = load i64, i64* %ptr_s
  %r1815 = getelementptr [52 x i8], [52 x i8]* @.str.1004, i64 0, i64 0
  %r1816 = ptrtoint i8* %r1815 to i64
  %r1817 = call i64 @_add(i64 %r1814, i64 %r1816)
  %r1818 = load i64, i64* %ptr_NL
  %r1819 = call i64 @_add(i64 %r1817, i64 %r1818)
  store i64 %r1819, i64* %ptr_s
  %r1820 = load i64, i64* %ptr_s
  %r1821 = getelementptr [35 x i8], [35 x i8]* @.str.1005, i64 0, i64 0
  %r1822 = ptrtoint i8* %r1821 to i64
  %r1823 = call i64 @_add(i64 %r1820, i64 %r1822)
  %r1824 = load i64, i64* %ptr_NL
  %r1825 = call i64 @_add(i64 %r1823, i64 %r1824)
  store i64 %r1825, i64* %ptr_s
  %r1826 = load i64, i64* %ptr_s
  %r1827 = getelementptr [36 x i8], [36 x i8]* @.str.1006, i64 0, i64 0
  %r1828 = ptrtoint i8* %r1827 to i64
  %r1829 = call i64 @_add(i64 %r1826, i64 %r1828)
  %r1830 = load i64, i64* %ptr_NL
  %r1831 = call i64 @_add(i64 %r1829, i64 %r1830)
  store i64 %r1831, i64* %ptr_s
  %r1832 = load i64, i64* %ptr_s
  %r1833 = getelementptr [49 x i8], [49 x i8]* @.str.1007, i64 0, i64 0
  %r1834 = ptrtoint i8* %r1833 to i64
  %r1835 = call i64 @_add(i64 %r1832, i64 %r1834)
  %r1836 = load i64, i64* %ptr_NL
  %r1837 = call i64 @_add(i64 %r1835, i64 %r1836)
  store i64 %r1837, i64* %ptr_s
  %r1838 = load i64, i64* %ptr_s
  %r1839 = getelementptr [30 x i8], [30 x i8]* @.str.1008, i64 0, i64 0
  %r1840 = ptrtoint i8* %r1839 to i64
  %r1841 = call i64 @_add(i64 %r1838, i64 %r1840)
  %r1842 = load i64, i64* %ptr_NL
  %r1843 = call i64 @_add(i64 %r1841, i64 %r1842)
  store i64 %r1843, i64* %ptr_s
  %r1844 = load i64, i64* %ptr_s
  %r1845 = getelementptr [15 x i8], [15 x i8]* @.str.1009, i64 0, i64 0
  %r1846 = ptrtoint i8* %r1845 to i64
  %r1847 = call i64 @_add(i64 %r1844, i64 %r1846)
  %r1848 = load i64, i64* %ptr_NL
  %r1849 = call i64 @_add(i64 %r1847, i64 %r1848)
  store i64 %r1849, i64* %ptr_s
  %r1850 = load i64, i64* %ptr_s
  %r1851 = getelementptr [15 x i8], [15 x i8]* @.str.1010, i64 0, i64 0
  %r1852 = ptrtoint i8* %r1851 to i64
  %r1853 = call i64 @_add(i64 %r1850, i64 %r1852)
  %r1854 = load i64, i64* %ptr_NL
  %r1855 = call i64 @_add(i64 %r1853, i64 %r1854)
  store i64 %r1855, i64* %ptr_s
  %r1856 = load i64, i64* %ptr_s
  %r1857 = getelementptr [2 x i8], [2 x i8]* @.str.1011, i64 0, i64 0
  %r1858 = ptrtoint i8* %r1857 to i64
  %r1859 = call i64 @_add(i64 %r1856, i64 %r1858)
  %r1860 = load i64, i64* %ptr_NL
  %r1861 = call i64 @_add(i64 %r1859, i64 %r1860)
  store i64 %r1861, i64* %ptr_s
  %r1862 = load i64, i64* %ptr_is_freestanding
  %r1863 = call i64 @_eq(i64 %r1862, i64 0)
  %r1864 = icmp ne i64 %r1863, 0
  br i1 %r1864, label %L1028, label %L1030
L1028:
  %r1865 = load i64, i64* %ptr_s
  %r1866 = getelementptr [34 x i8], [34 x i8]* @.str.1012, i64 0, i64 0
  %r1867 = ptrtoint i8* %r1866 to i64
  %r1868 = call i64 @_add(i64 %r1865, i64 %r1867)
  %r1869 = load i64, i64* %ptr_NL
  %r1870 = call i64 @_add(i64 %r1868, i64 %r1869)
  store i64 %r1870, i64* %ptr_s
  %r1871 = load i64, i64* %ptr_s
  %r1872 = getelementptr [37 x i8], [37 x i8]* @.str.1013, i64 0, i64 0
  %r1873 = ptrtoint i8* %r1872 to i64
  %r1874 = call i64 @_add(i64 %r1871, i64 %r1873)
  %r1875 = load i64, i64* %ptr_NL
  %r1876 = call i64 @_add(i64 %r1874, i64 %r1875)
  store i64 %r1876, i64* %ptr_s
  %r1877 = load i64, i64* %ptr_s
  %r1878 = getelementptr [34 x i8], [34 x i8]* @.str.1014, i64 0, i64 0
  %r1879 = ptrtoint i8* %r1878 to i64
  %r1880 = call i64 @_add(i64 %r1877, i64 %r1879)
  %r1881 = load i64, i64* %ptr_NL
  %r1882 = call i64 @_add(i64 %r1880, i64 %r1881)
  store i64 %r1882, i64* %ptr_s
  %r1883 = load i64, i64* %ptr_s
  %r1884 = getelementptr [39 x i8], [39 x i8]* @.str.1015, i64 0, i64 0
  %r1885 = ptrtoint i8* %r1884 to i64
  %r1886 = call i64 @_add(i64 %r1883, i64 %r1885)
  %r1887 = load i64, i64* %ptr_NL
  %r1888 = call i64 @_add(i64 %r1886, i64 %r1887)
  store i64 %r1888, i64* %ptr_s
  %r1889 = load i64, i64* %ptr_s
  %r1890 = getelementptr [39 x i8], [39 x i8]* @.str.1016, i64 0, i64 0
  %r1891 = ptrtoint i8* %r1890 to i64
  %r1892 = call i64 @_add(i64 %r1889, i64 %r1891)
  %r1893 = load i64, i64* %ptr_NL
  %r1894 = call i64 @_add(i64 %r1892, i64 %r1893)
  store i64 %r1894, i64* %ptr_s
  %r1895 = load i64, i64* %ptr_s
  %r1896 = getelementptr [5 x i8], [5 x i8]* @.str.1017, i64 0, i64 0
  %r1897 = ptrtoint i8* %r1896 to i64
  %r1898 = call i64 @_add(i64 %r1895, i64 %r1897)
  %r1899 = load i64, i64* %ptr_NL
  %r1900 = call i64 @_add(i64 %r1898, i64 %r1899)
  store i64 %r1900, i64* %ptr_s
  %r1901 = load i64, i64* %ptr_s
  %r1902 = getelementptr [33 x i8], [33 x i8]* @.str.1018, i64 0, i64 0
  %r1903 = ptrtoint i8* %r1902 to i64
  %r1904 = call i64 @_add(i64 %r1901, i64 %r1903)
  %r1905 = load i64, i64* %ptr_NL
  %r1906 = call i64 @_add(i64 %r1904, i64 %r1905)
  store i64 %r1906, i64* %ptr_s
  %r1907 = load i64, i64* %ptr_s
  %r1908 = getelementptr [36 x i8], [36 x i8]* @.str.1019, i64 0, i64 0
  %r1909 = ptrtoint i8* %r1908 to i64
  %r1910 = call i64 @_add(i64 %r1907, i64 %r1909)
  %r1911 = load i64, i64* %ptr_NL
  %r1912 = call i64 @_add(i64 %r1910, i64 %r1911)
  store i64 %r1912, i64* %ptr_s
  %r1913 = load i64, i64* %ptr_s
  %r1914 = getelementptr [25 x i8], [25 x i8]* @.str.1020, i64 0, i64 0
  %r1915 = ptrtoint i8* %r1914 to i64
  %r1916 = call i64 @_add(i64 %r1913, i64 %r1915)
  %r1917 = load i64, i64* %ptr_NL
  %r1918 = call i64 @_add(i64 %r1916, i64 %r1917)
  store i64 %r1918, i64* %ptr_s
  %r1919 = load i64, i64* %ptr_s
  %r1920 = getelementptr [15 x i8], [15 x i8]* @.str.1021, i64 0, i64 0
  %r1921 = ptrtoint i8* %r1920 to i64
  %r1922 = call i64 @_add(i64 %r1919, i64 %r1921)
  %r1923 = load i64, i64* %ptr_NL
  %r1924 = call i64 @_add(i64 %r1922, i64 %r1923)
  store i64 %r1924, i64* %ptr_s
  %r1925 = load i64, i64* %ptr_s
  %r1926 = getelementptr [4 x i8], [4 x i8]* @.str.1022, i64 0, i64 0
  %r1927 = ptrtoint i8* %r1926 to i64
  %r1928 = call i64 @_add(i64 %r1925, i64 %r1927)
  %r1929 = load i64, i64* %ptr_NL
  %r1930 = call i64 @_add(i64 %r1928, i64 %r1929)
  store i64 %r1930, i64* %ptr_s
  %r1931 = load i64, i64* %ptr_s
  %r1932 = getelementptr [39 x i8], [39 x i8]* @.str.1023, i64 0, i64 0
  %r1933 = ptrtoint i8* %r1932 to i64
  %r1934 = call i64 @_add(i64 %r1931, i64 %r1933)
  %r1935 = load i64, i64* %ptr_NL
  %r1936 = call i64 @_add(i64 %r1934, i64 %r1935)
  store i64 %r1936, i64* %ptr_s
  %r1937 = load i64, i64* %ptr_s
  %r1938 = getelementptr [49 x i8], [49 x i8]* @.str.1024, i64 0, i64 0
  %r1939 = ptrtoint i8* %r1938 to i64
  %r1940 = call i64 @_add(i64 %r1937, i64 %r1939)
  %r1941 = load i64, i64* %ptr_NL
  %r1942 = call i64 @_add(i64 %r1940, i64 %r1941)
  store i64 %r1942, i64* %ptr_s
  %r1943 = load i64, i64* %ptr_s
  %r1944 = getelementptr [29 x i8], [29 x i8]* @.str.1025, i64 0, i64 0
  %r1945 = ptrtoint i8* %r1944 to i64
  %r1946 = call i64 @_add(i64 %r1943, i64 %r1945)
  %r1947 = load i64, i64* %ptr_NL
  %r1948 = call i64 @_add(i64 %r1946, i64 %r1947)
  store i64 %r1948, i64* %ptr_s
  %r1949 = load i64, i64* %ptr_s
  %r1950 = getelementptr [34 x i8], [34 x i8]* @.str.1026, i64 0, i64 0
  %r1951 = ptrtoint i8* %r1950 to i64
  %r1952 = call i64 @_add(i64 %r1949, i64 %r1951)
  %r1953 = load i64, i64* %ptr_NL
  %r1954 = call i64 @_add(i64 %r1952, i64 %r1953)
  store i64 %r1954, i64* %ptr_s
  %r1955 = load i64, i64* %ptr_s
  %r1956 = getelementptr [15 x i8], [15 x i8]* @.str.1027, i64 0, i64 0
  %r1957 = ptrtoint i8* %r1956 to i64
  %r1958 = call i64 @_add(i64 %r1955, i64 %r1957)
  %r1959 = load i64, i64* %ptr_NL
  %r1960 = call i64 @_add(i64 %r1958, i64 %r1959)
  store i64 %r1960, i64* %ptr_s
  %r1961 = load i64, i64* %ptr_s
  %r1962 = getelementptr [2 x i8], [2 x i8]* @.str.1028, i64 0, i64 0
  %r1963 = ptrtoint i8* %r1962 to i64
  %r1964 = call i64 @_add(i64 %r1961, i64 %r1963)
  %r1965 = load i64, i64* %ptr_NL
  %r1966 = call i64 @_add(i64 %r1964, i64 %r1965)
  store i64 %r1966, i64* %ptr_s
  %r1967 = load i64, i64* %ptr_s
  %r1968 = getelementptr [36 x i8], [36 x i8]* @.str.1029, i64 0, i64 0
  %r1969 = ptrtoint i8* %r1968 to i64
  %r1970 = call i64 @_add(i64 %r1967, i64 %r1969)
  %r1971 = load i64, i64* %ptr_NL
  %r1972 = call i64 @_add(i64 %r1970, i64 %r1971)
  store i64 %r1972, i64* %ptr_s
  %r1973 = load i64, i64* %ptr_s
  %r1974 = getelementptr [38 x i8], [38 x i8]* @.str.1030, i64 0, i64 0
  %r1975 = ptrtoint i8* %r1974 to i64
  %r1976 = call i64 @_add(i64 %r1973, i64 %r1975)
  %r1977 = load i64, i64* %ptr_NL
  %r1978 = call i64 @_add(i64 %r1976, i64 %r1977)
  store i64 %r1978, i64* %ptr_s
  %r1979 = load i64, i64* %ptr_s
  %r1980 = getelementptr [67 x i8], [67 x i8]* @.str.1031, i64 0, i64 0
  %r1981 = ptrtoint i8* %r1980 to i64
  %r1982 = call i64 @_add(i64 %r1979, i64 %r1981)
  %r1983 = load i64, i64* %ptr_NL
  %r1984 = call i64 @_add(i64 %r1982, i64 %r1983)
  store i64 %r1984, i64* %ptr_s
  %r1985 = load i64, i64* %ptr_s
  %r1986 = getelementptr [45 x i8], [45 x i8]* @.str.1032, i64 0, i64 0
  %r1987 = ptrtoint i8* %r1986 to i64
  %r1988 = call i64 @_add(i64 %r1985, i64 %r1987)
  %r1989 = load i64, i64* %ptr_NL
  %r1990 = call i64 @_add(i64 %r1988, i64 %r1989)
  store i64 %r1990, i64* %ptr_s
  %r1991 = load i64, i64* %ptr_s
  %r1992 = getelementptr [34 x i8], [34 x i8]* @.str.1033, i64 0, i64 0
  %r1993 = ptrtoint i8* %r1992 to i64
  %r1994 = call i64 @_add(i64 %r1991, i64 %r1993)
  %r1995 = load i64, i64* %ptr_NL
  %r1996 = call i64 @_add(i64 %r1994, i64 %r1995)
  store i64 %r1996, i64* %ptr_s
  %r1997 = load i64, i64* %ptr_s
  %r1998 = getelementptr [33 x i8], [33 x i8]* @.str.1034, i64 0, i64 0
  %r1999 = ptrtoint i8* %r1998 to i64
  %r2000 = call i64 @_add(i64 %r1997, i64 %r1999)
  %r2001 = load i64, i64* %ptr_NL
  %r2002 = call i64 @_add(i64 %r2000, i64 %r2001)
  store i64 %r2002, i64* %ptr_s
  %r2003 = load i64, i64* %ptr_s
  %r2004 = getelementptr [40 x i8], [40 x i8]* @.str.1035, i64 0, i64 0
  %r2005 = ptrtoint i8* %r2004 to i64
  %r2006 = call i64 @_add(i64 %r2003, i64 %r2005)
  %r2007 = load i64, i64* %ptr_NL
  %r2008 = call i64 @_add(i64 %r2006, i64 %r2007)
  store i64 %r2008, i64* %ptr_s
  %r2009 = load i64, i64* %ptr_s
  %r2010 = getelementptr [6 x i8], [6 x i8]* @.str.1036, i64 0, i64 0
  %r2011 = ptrtoint i8* %r2010 to i64
  %r2012 = call i64 @_add(i64 %r2009, i64 %r2011)
  %r2013 = load i64, i64* %ptr_NL
  %r2014 = call i64 @_add(i64 %r2012, i64 %r2013)
  store i64 %r2014, i64* %ptr_s
  %r2015 = load i64, i64* %ptr_s
  %r2016 = getelementptr [40 x i8], [40 x i8]* @.str.1037, i64 0, i64 0
  %r2017 = ptrtoint i8* %r2016 to i64
  %r2018 = call i64 @_add(i64 %r2015, i64 %r2017)
  %r2019 = load i64, i64* %ptr_NL
  %r2020 = call i64 @_add(i64 %r2018, i64 %r2019)
  store i64 %r2020, i64* %ptr_s
  %r2021 = load i64, i64* %ptr_s
  %r2022 = getelementptr [33 x i8], [33 x i8]* @.str.1038, i64 0, i64 0
  %r2023 = ptrtoint i8* %r2022 to i64
  %r2024 = call i64 @_add(i64 %r2021, i64 %r2023)
  %r2025 = load i64, i64* %ptr_NL
  %r2026 = call i64 @_add(i64 %r2024, i64 %r2025)
  store i64 %r2026, i64* %ptr_s
  %r2027 = load i64, i64* %ptr_s
  %r2028 = getelementptr [40 x i8], [40 x i8]* @.str.1039, i64 0, i64 0
  %r2029 = ptrtoint i8* %r2028 to i64
  %r2030 = call i64 @_add(i64 %r2027, i64 %r2029)
  %r2031 = load i64, i64* %ptr_NL
  %r2032 = call i64 @_add(i64 %r2030, i64 %r2031)
  store i64 %r2032, i64* %ptr_s
  %r2033 = load i64, i64* %ptr_s
  %r2034 = getelementptr [30 x i8], [30 x i8]* @.str.1040, i64 0, i64 0
  %r2035 = ptrtoint i8* %r2034 to i64
  %r2036 = call i64 @_add(i64 %r2033, i64 %r2035)
  %r2037 = load i64, i64* %ptr_NL
  %r2038 = call i64 @_add(i64 %r2036, i64 %r2037)
  store i64 %r2038, i64* %ptr_s
  %r2039 = load i64, i64* %ptr_s
  %r2040 = getelementptr [41 x i8], [41 x i8]* @.str.1041, i64 0, i64 0
  %r2041 = ptrtoint i8* %r2040 to i64
  %r2042 = call i64 @_add(i64 %r2039, i64 %r2041)
  %r2043 = load i64, i64* %ptr_NL
  %r2044 = call i64 @_add(i64 %r2042, i64 %r2043)
  store i64 %r2044, i64* %ptr_s
  %r2045 = load i64, i64* %ptr_s
  %r2046 = getelementptr [38 x i8], [38 x i8]* @.str.1042, i64 0, i64 0
  %r2047 = ptrtoint i8* %r2046 to i64
  %r2048 = call i64 @_add(i64 %r2045, i64 %r2047)
  %r2049 = load i64, i64* %ptr_NL
  %r2050 = call i64 @_add(i64 %r2048, i64 %r2049)
  store i64 %r2050, i64* %ptr_s
  %r2051 = load i64, i64* %ptr_s
  %r2052 = getelementptr [57 x i8], [57 x i8]* @.str.1043, i64 0, i64 0
  %r2053 = ptrtoint i8* %r2052 to i64
  %r2054 = call i64 @_add(i64 %r2051, i64 %r2053)
  %r2055 = load i64, i64* %ptr_NL
  %r2056 = call i64 @_add(i64 %r2054, i64 %r2055)
  store i64 %r2056, i64* %ptr_s
  %r2057 = load i64, i64* %ptr_s
  %r2058 = getelementptr [51 x i8], [51 x i8]* @.str.1044, i64 0, i64 0
  %r2059 = ptrtoint i8* %r2058 to i64
  %r2060 = call i64 @_add(i64 %r2057, i64 %r2059)
  %r2061 = load i64, i64* %ptr_NL
  %r2062 = call i64 @_add(i64 %r2060, i64 %r2061)
  store i64 %r2062, i64* %ptr_s
  %r2063 = load i64, i64* %ptr_s
  %r2064 = getelementptr [24 x i8], [24 x i8]* @.str.1045, i64 0, i64 0
  %r2065 = ptrtoint i8* %r2064 to i64
  %r2066 = call i64 @_add(i64 %r2063, i64 %r2065)
  %r2067 = load i64, i64* %ptr_NL
  %r2068 = call i64 @_add(i64 %r2066, i64 %r2067)
  store i64 %r2068, i64* %ptr_s
  %r2069 = load i64, i64* %ptr_s
  %r2070 = getelementptr [27 x i8], [27 x i8]* @.str.1046, i64 0, i64 0
  %r2071 = ptrtoint i8* %r2070 to i64
  %r2072 = call i64 @_add(i64 %r2069, i64 %r2071)
  %r2073 = load i64, i64* %ptr_NL
  %r2074 = call i64 @_add(i64 %r2072, i64 %r2073)
  store i64 %r2074, i64* %ptr_s
  %r2075 = load i64, i64* %ptr_s
  %r2076 = getelementptr [15 x i8], [15 x i8]* @.str.1047, i64 0, i64 0
  %r2077 = ptrtoint i8* %r2076 to i64
  %r2078 = call i64 @_add(i64 %r2075, i64 %r2077)
  %r2079 = load i64, i64* %ptr_NL
  %r2080 = call i64 @_add(i64 %r2078, i64 %r2079)
  store i64 %r2080, i64* %ptr_s
  %r2081 = load i64, i64* %ptr_s
  %r2082 = getelementptr [5 x i8], [5 x i8]* @.str.1048, i64 0, i64 0
  %r2083 = ptrtoint i8* %r2082 to i64
  %r2084 = call i64 @_add(i64 %r2081, i64 %r2083)
  %r2085 = load i64, i64* %ptr_NL
  %r2086 = call i64 @_add(i64 %r2084, i64 %r2085)
  store i64 %r2086, i64* %ptr_s
  %r2087 = load i64, i64* %ptr_s
  %r2088 = getelementptr [12 x i8], [12 x i8]* @.str.1049, i64 0, i64 0
  %r2089 = ptrtoint i8* %r2088 to i64
  %r2090 = call i64 @_add(i64 %r2087, i64 %r2089)
  %r2091 = load i64, i64* %ptr_NL
  %r2092 = call i64 @_add(i64 %r2090, i64 %r2091)
  store i64 %r2092, i64* %ptr_s
  %r2093 = load i64, i64* %ptr_s
  %r2094 = getelementptr [2 x i8], [2 x i8]* @.str.1050, i64 0, i64 0
  %r2095 = ptrtoint i8* %r2094 to i64
  %r2096 = call i64 @_add(i64 %r2093, i64 %r2095)
  %r2097 = load i64, i64* %ptr_NL
  %r2098 = call i64 @_add(i64 %r2096, i64 %r2097)
  store i64 %r2098, i64* %ptr_s
  %r2099 = load i64, i64* %ptr_s
  %r2100 = getelementptr [52 x i8], [52 x i8]* @.str.1051, i64 0, i64 0
  %r2101 = ptrtoint i8* %r2100 to i64
  %r2102 = call i64 @_add(i64 %r2099, i64 %r2101)
  %r2103 = load i64, i64* %ptr_NL
  %r2104 = call i64 @_add(i64 %r2102, i64 %r2103)
  store i64 %r2104, i64* %ptr_s
  %r2105 = load i64, i64* %ptr_s
  %r2106 = getelementptr [38 x i8], [38 x i8]* @.str.1052, i64 0, i64 0
  %r2107 = ptrtoint i8* %r2106 to i64
  %r2108 = call i64 @_add(i64 %r2105, i64 %r2107)
  %r2109 = load i64, i64* %ptr_NL
  %r2110 = call i64 @_add(i64 %r2108, i64 %r2109)
  store i64 %r2110, i64* %ptr_s
  %r2111 = load i64, i64* %ptr_s
  %r2112 = getelementptr [44 x i8], [44 x i8]* @.str.1053, i64 0, i64 0
  %r2113 = ptrtoint i8* %r2112 to i64
  %r2114 = call i64 @_add(i64 %r2111, i64 %r2113)
  %r2115 = load i64, i64* %ptr_NL
  %r2116 = call i64 @_add(i64 %r2114, i64 %r2115)
  store i64 %r2116, i64* %ptr_s
  %r2117 = load i64, i64* %ptr_s
  %r2118 = getelementptr [67 x i8], [67 x i8]* @.str.1054, i64 0, i64 0
  %r2119 = ptrtoint i8* %r2118 to i64
  %r2120 = call i64 @_add(i64 %r2117, i64 %r2119)
  %r2121 = load i64, i64* %ptr_NL
  %r2122 = call i64 @_add(i64 %r2120, i64 %r2121)
  store i64 %r2122, i64* %ptr_s
  %r2123 = load i64, i64* %ptr_s
  %r2124 = getelementptr [45 x i8], [45 x i8]* @.str.1055, i64 0, i64 0
  %r2125 = ptrtoint i8* %r2124 to i64
  %r2126 = call i64 @_add(i64 %r2123, i64 %r2125)
  %r2127 = load i64, i64* %ptr_NL
  %r2128 = call i64 @_add(i64 %r2126, i64 %r2127)
  store i64 %r2128, i64* %ptr_s
  %r2129 = load i64, i64* %ptr_s
  %r2130 = getelementptr [40 x i8], [40 x i8]* @.str.1056, i64 0, i64 0
  %r2131 = ptrtoint i8* %r2130 to i64
  %r2132 = call i64 @_add(i64 %r2129, i64 %r2131)
  %r2133 = load i64, i64* %ptr_NL
  %r2134 = call i64 @_add(i64 %r2132, i64 %r2133)
  store i64 %r2134, i64* %ptr_s
  %r2135 = load i64, i64* %ptr_s
  %r2136 = getelementptr [58 x i8], [58 x i8]* @.str.1057, i64 0, i64 0
  %r2137 = ptrtoint i8* %r2136 to i64
  %r2138 = call i64 @_add(i64 %r2135, i64 %r2137)
  %r2139 = load i64, i64* %ptr_NL
  %r2140 = call i64 @_add(i64 %r2138, i64 %r2139)
  store i64 %r2140, i64* %ptr_s
  %r2141 = load i64, i64* %ptr_s
  %r2142 = getelementptr [27 x i8], [27 x i8]* @.str.1058, i64 0, i64 0
  %r2143 = ptrtoint i8* %r2142 to i64
  %r2144 = call i64 @_add(i64 %r2141, i64 %r2143)
  %r2145 = load i64, i64* %ptr_NL
  %r2146 = call i64 @_add(i64 %r2144, i64 %r2145)
  store i64 %r2146, i64* %ptr_s
  %r2147 = load i64, i64* %ptr_s
  %r2148 = getelementptr [12 x i8], [12 x i8]* @.str.1059, i64 0, i64 0
  %r2149 = ptrtoint i8* %r2148 to i64
  %r2150 = call i64 @_add(i64 %r2147, i64 %r2149)
  %r2151 = load i64, i64* %ptr_NL
  %r2152 = call i64 @_add(i64 %r2150, i64 %r2151)
  store i64 %r2152, i64* %ptr_s
  %r2153 = load i64, i64* %ptr_s
  %r2154 = getelementptr [2 x i8], [2 x i8]* @.str.1060, i64 0, i64 0
  %r2155 = ptrtoint i8* %r2154 to i64
  %r2156 = call i64 @_add(i64 %r2153, i64 %r2155)
  %r2157 = load i64, i64* %ptr_NL
  %r2158 = call i64 @_add(i64 %r2156, i64 %r2157)
  store i64 %r2158, i64* %ptr_s
  %r2159 = load i64, i64* %ptr_s
  %r2160 = getelementptr [34 x i8], [34 x i8]* @.str.1061, i64 0, i64 0
  %r2161 = ptrtoint i8* %r2160 to i64
  %r2162 = call i64 @_add(i64 %r2159, i64 %r2161)
  %r2163 = load i64, i64* %ptr_NL
  %r2164 = call i64 @_add(i64 %r2162, i64 %r2163)
  store i64 %r2164, i64* %ptr_s
  %r2165 = load i64, i64* %ptr_s
  %r2166 = getelementptr [7 x i8], [7 x i8]* @.str.1062, i64 0, i64 0
  %r2167 = ptrtoint i8* %r2166 to i64
  %r2168 = call i64 @_add(i64 %r2165, i64 %r2167)
  %r2169 = load i64, i64* %ptr_NL
  %r2170 = call i64 @_add(i64 %r2168, i64 %r2169)
  store i64 %r2170, i64* %ptr_s
  %r2171 = load i64, i64* %ptr_s
  %r2172 = getelementptr [32 x i8], [32 x i8]* @.str.1063, i64 0, i64 0
  %r2173 = ptrtoint i8* %r2172 to i64
  %r2174 = call i64 @_add(i64 %r2171, i64 %r2173)
  %r2175 = load i64, i64* %ptr_ptr_thresh
  %r2176 = call i64 @_add(i64 %r2174, i64 %r2175)
  %r2177 = load i64, i64* %ptr_NL
  %r2178 = call i64 @_add(i64 %r2176, i64 %r2177)
  store i64 %r2178, i64* %ptr_s
  %r2179 = load i64, i64* %ptr_s
  %r2180 = getelementptr [52 x i8], [52 x i8]* @.str.1064, i64 0, i64 0
  %r2181 = ptrtoint i8* %r2180 to i64
  %r2182 = call i64 @_add(i64 %r2179, i64 %r2181)
  %r2183 = load i64, i64* %ptr_NL
  %r2184 = call i64 @_add(i64 %r2182, i64 %r2183)
  store i64 %r2184, i64* %ptr_s
  %r2185 = load i64, i64* %ptr_s
  %r2186 = getelementptr [11 x i8], [11 x i8]* @.str.1065, i64 0, i64 0
  %r2187 = ptrtoint i8* %r2186 to i64
  %r2188 = call i64 @_add(i64 %r2185, i64 %r2187)
  %r2189 = load i64, i64* %ptr_NL
  %r2190 = call i64 @_add(i64 %r2188, i64 %r2189)
  store i64 %r2190, i64* %ptr_s
  %r2191 = load i64, i64* %ptr_s
  %r2192 = getelementptr [35 x i8], [35 x i8]* @.str.1066, i64 0, i64 0
  %r2193 = ptrtoint i8* %r2192 to i64
  %r2194 = call i64 @_add(i64 %r2191, i64 %r2193)
  %r2195 = load i64, i64* %ptr_NL
  %r2196 = call i64 @_add(i64 %r2194, i64 %r2195)
  store i64 %r2196, i64* %ptr_s
  %r2197 = load i64, i64* %ptr_s
  %r2198 = getelementptr [28 x i8], [28 x i8]* @.str.1067, i64 0, i64 0
  %r2199 = ptrtoint i8* %r2198 to i64
  %r2200 = call i64 @_add(i64 %r2197, i64 %r2199)
  %r2201 = load i64, i64* %ptr_NL
  %r2202 = call i64 @_add(i64 %r2200, i64 %r2201)
  store i64 %r2202, i64* %ptr_s
  %r2203 = load i64, i64* %ptr_s
  %r2204 = getelementptr [32 x i8], [32 x i8]* @.str.1068, i64 0, i64 0
  %r2205 = ptrtoint i8* %r2204 to i64
  %r2206 = call i64 @_add(i64 %r2203, i64 %r2205)
  %r2207 = load i64, i64* %ptr_NL
  %r2208 = call i64 @_add(i64 %r2206, i64 %r2207)
  store i64 %r2208, i64* %ptr_s
  %r2209 = load i64, i64* %ptr_s
  %r2210 = getelementptr [54 x i8], [54 x i8]* @.str.1069, i64 0, i64 0
  %r2211 = ptrtoint i8* %r2210 to i64
  %r2212 = call i64 @_add(i64 %r2209, i64 %r2211)
  %r2213 = load i64, i64* %ptr_NL
  %r2214 = call i64 @_add(i64 %r2212, i64 %r2213)
  store i64 %r2214, i64* %ptr_s
  %r2215 = load i64, i64* %ptr_s
  %r2216 = getelementptr [12 x i8], [12 x i8]* @.str.1070, i64 0, i64 0
  %r2217 = ptrtoint i8* %r2216 to i64
  %r2218 = call i64 @_add(i64 %r2215, i64 %r2217)
  %r2219 = load i64, i64* %ptr_NL
  %r2220 = call i64 @_add(i64 %r2218, i64 %r2219)
  store i64 %r2220, i64* %ptr_s
  %r2221 = load i64, i64* %ptr_s
  %r2222 = getelementptr [70 x i8], [70 x i8]* @.str.1071, i64 0, i64 0
  %r2223 = ptrtoint i8* %r2222 to i64
  %r2224 = call i64 @_add(i64 %r2221, i64 %r2223)
  %r2225 = load i64, i64* %ptr_NL
  %r2226 = call i64 @_add(i64 %r2224, i64 %r2225)
  store i64 %r2226, i64* %ptr_s
  %r2227 = load i64, i64* %ptr_s
  %r2228 = getelementptr [67 x i8], [67 x i8]* @.str.1072, i64 0, i64 0
  %r2229 = ptrtoint i8* %r2228 to i64
  %r2230 = call i64 @_add(i64 %r2227, i64 %r2229)
  %r2231 = load i64, i64* %ptr_NL
  %r2232 = call i64 @_add(i64 %r2230, i64 %r2231)
  store i64 %r2232, i64* %ptr_s
  %r2233 = load i64, i64* %ptr_s
  %r2234 = getelementptr [51 x i8], [51 x i8]* @.str.1073, i64 0, i64 0
  %r2235 = ptrtoint i8* %r2234 to i64
  %r2236 = call i64 @_add(i64 %r2233, i64 %r2235)
  %r2237 = load i64, i64* %ptr_NL
  %r2238 = call i64 @_add(i64 %r2236, i64 %r2237)
  store i64 %r2238, i64* %ptr_s
  %r2239 = load i64, i64* %ptr_s
  %r2240 = getelementptr [29 x i8], [29 x i8]* @.str.1074, i64 0, i64 0
  %r2241 = ptrtoint i8* %r2240 to i64
  %r2242 = call i64 @_add(i64 %r2239, i64 %r2241)
  %r2243 = load i64, i64* %ptr_NL
  %r2244 = call i64 @_add(i64 %r2242, i64 %r2243)
  store i64 %r2244, i64* %ptr_s
  %r2245 = load i64, i64* %ptr_s
  %r2246 = getelementptr [37 x i8], [37 x i8]* @.str.1075, i64 0, i64 0
  %r2247 = ptrtoint i8* %r2246 to i64
  %r2248 = call i64 @_add(i64 %r2245, i64 %r2247)
  %r2249 = load i64, i64* %ptr_NL
  %r2250 = call i64 @_add(i64 %r2248, i64 %r2249)
  store i64 %r2250, i64* %ptr_s
  %r2251 = load i64, i64* %ptr_s
  %r2252 = getelementptr [51 x i8], [51 x i8]* @.str.1076, i64 0, i64 0
  %r2253 = ptrtoint i8* %r2252 to i64
  %r2254 = call i64 @_add(i64 %r2251, i64 %r2253)
  %r2255 = load i64, i64* %ptr_NL
  %r2256 = call i64 @_add(i64 %r2254, i64 %r2255)
  store i64 %r2256, i64* %ptr_s
  %r2257 = load i64, i64* %ptr_s
  %r2258 = getelementptr [33 x i8], [33 x i8]* @.str.1077, i64 0, i64 0
  %r2259 = ptrtoint i8* %r2258 to i64
  %r2260 = call i64 @_add(i64 %r2257, i64 %r2259)
  %r2261 = load i64, i64* %ptr_NL
  %r2262 = call i64 @_add(i64 %r2260, i64 %r2261)
  store i64 %r2262, i64* %ptr_s
  %r2263 = load i64, i64* %ptr_s
  %r2264 = getelementptr [34 x i8], [34 x i8]* @.str.1078, i64 0, i64 0
  %r2265 = ptrtoint i8* %r2264 to i64
  %r2266 = call i64 @_add(i64 %r2263, i64 %r2265)
  %r2267 = load i64, i64* %ptr_NL
  %r2268 = call i64 @_add(i64 %r2266, i64 %r2267)
  store i64 %r2268, i64* %ptr_s
  %r2269 = load i64, i64* %ptr_s
  %r2270 = getelementptr [50 x i8], [50 x i8]* @.str.1079, i64 0, i64 0
  %r2271 = ptrtoint i8* %r2270 to i64
  %r2272 = call i64 @_add(i64 %r2269, i64 %r2271)
  %r2273 = load i64, i64* %ptr_NL
  %r2274 = call i64 @_add(i64 %r2272, i64 %r2273)
  store i64 %r2274, i64* %ptr_s
  %r2275 = load i64, i64* %ptr_s
  %r2276 = getelementptr [12 x i8], [12 x i8]* @.str.1080, i64 0, i64 0
  %r2277 = ptrtoint i8* %r2276 to i64
  %r2278 = call i64 @_add(i64 %r2275, i64 %r2277)
  %r2279 = load i64, i64* %ptr_NL
  %r2280 = call i64 @_add(i64 %r2278, i64 %r2279)
  store i64 %r2280, i64* %ptr_s
  %r2281 = load i64, i64* %ptr_s
  %r2282 = getelementptr [52 x i8], [52 x i8]* @.str.1081, i64 0, i64 0
  %r2283 = ptrtoint i8* %r2282 to i64
  %r2284 = call i64 @_add(i64 %r2281, i64 %r2283)
  %r2285 = load i64, i64* %ptr_NL
  %r2286 = call i64 @_add(i64 %r2284, i64 %r2285)
  store i64 %r2286, i64* %ptr_s
  %r2287 = load i64, i64* %ptr_s
  %r2288 = getelementptr [35 x i8], [35 x i8]* @.str.1082, i64 0, i64 0
  %r2289 = ptrtoint i8* %r2288 to i64
  %r2290 = call i64 @_add(i64 %r2287, i64 %r2289)
  %r2291 = load i64, i64* %ptr_NL
  %r2292 = call i64 @_add(i64 %r2290, i64 %r2291)
  store i64 %r2292, i64* %ptr_s
  %r2293 = load i64, i64* %ptr_s
  %r2294 = getelementptr [41 x i8], [41 x i8]* @.str.1083, i64 0, i64 0
  %r2295 = ptrtoint i8* %r2294 to i64
  %r2296 = call i64 @_add(i64 %r2293, i64 %r2295)
  %r2297 = load i64, i64* %ptr_NL
  %r2298 = call i64 @_add(i64 %r2296, i64 %r2297)
  store i64 %r2298, i64* %ptr_s
  %r2299 = load i64, i64* %ptr_s
  %r2300 = getelementptr [17 x i8], [17 x i8]* @.str.1084, i64 0, i64 0
  %r2301 = ptrtoint i8* %r2300 to i64
  %r2302 = call i64 @_add(i64 %r2299, i64 %r2301)
  %r2303 = load i64, i64* %ptr_NL
  %r2304 = call i64 @_add(i64 %r2302, i64 %r2303)
  store i64 %r2304, i64* %ptr_s
  %r2305 = load i64, i64* %ptr_s
  %r2306 = getelementptr [6 x i8], [6 x i8]* @.str.1085, i64 0, i64 0
  %r2307 = ptrtoint i8* %r2306 to i64
  %r2308 = call i64 @_add(i64 %r2305, i64 %r2307)
  %r2309 = load i64, i64* %ptr_NL
  %r2310 = call i64 @_add(i64 %r2308, i64 %r2309)
  store i64 %r2310, i64* %ptr_s
  %r2311 = load i64, i64* %ptr_s
  %r2312 = getelementptr [58 x i8], [58 x i8]* @.str.1086, i64 0, i64 0
  %r2313 = ptrtoint i8* %r2312 to i64
  %r2314 = call i64 @_add(i64 %r2311, i64 %r2313)
  %r2315 = load i64, i64* %ptr_NL
  %r2316 = call i64 @_add(i64 %r2314, i64 %r2315)
  store i64 %r2316, i64* %ptr_s
  %r2317 = load i64, i64* %ptr_s
  %r2318 = getelementptr [32 x i8], [32 x i8]* @.str.1087, i64 0, i64 0
  %r2319 = ptrtoint i8* %r2318 to i64
  %r2320 = call i64 @_add(i64 %r2317, i64 %r2319)
  %r2321 = load i64, i64* %ptr_NL
  %r2322 = call i64 @_add(i64 %r2320, i64 %r2321)
  store i64 %r2322, i64* %ptr_s
  %r2323 = load i64, i64* %ptr_s
  %r2324 = getelementptr [40 x i8], [40 x i8]* @.str.1088, i64 0, i64 0
  %r2325 = ptrtoint i8* %r2324 to i64
  %r2326 = call i64 @_add(i64 %r2323, i64 %r2325)
  %r2327 = load i64, i64* %ptr_NL
  %r2328 = call i64 @_add(i64 %r2326, i64 %r2327)
  store i64 %r2328, i64* %ptr_s
  %r2329 = load i64, i64* %ptr_s
  %r2330 = getelementptr [6 x i8], [6 x i8]* @.str.1089, i64 0, i64 0
  %r2331 = ptrtoint i8* %r2330 to i64
  %r2332 = call i64 @_add(i64 %r2329, i64 %r2331)
  %r2333 = load i64, i64* %ptr_NL
  %r2334 = call i64 @_add(i64 %r2332, i64 %r2333)
  store i64 %r2334, i64* %ptr_s
  %r2335 = load i64, i64* %ptr_s
  %r2336 = getelementptr [33 x i8], [33 x i8]* @.str.1090, i64 0, i64 0
  %r2337 = ptrtoint i8* %r2336 to i64
  %r2338 = call i64 @_add(i64 %r2335, i64 %r2337)
  %r2339 = load i64, i64* %ptr_NL
  %r2340 = call i64 @_add(i64 %r2338, i64 %r2339)
  store i64 %r2340, i64* %ptr_s
  %r2341 = load i64, i64* %ptr_s
  %r2342 = getelementptr [51 x i8], [51 x i8]* @.str.1091, i64 0, i64 0
  %r2343 = ptrtoint i8* %r2342 to i64
  %r2344 = call i64 @_add(i64 %r2341, i64 %r2343)
  %r2345 = load i64, i64* %ptr_NL
  %r2346 = call i64 @_add(i64 %r2344, i64 %r2345)
  store i64 %r2346, i64* %ptr_s
  %r2347 = load i64, i64* %ptr_s
  %r2348 = getelementptr [7 x i8], [7 x i8]* @.str.1092, i64 0, i64 0
  %r2349 = ptrtoint i8* %r2348 to i64
  %r2350 = call i64 @_add(i64 %r2347, i64 %r2349)
  %r2351 = load i64, i64* %ptr_NL
  %r2352 = call i64 @_add(i64 %r2350, i64 %r2351)
  store i64 %r2352, i64* %ptr_s
  %r2353 = load i64, i64* %ptr_s
  %r2354 = getelementptr [70 x i8], [70 x i8]* @.str.1093, i64 0, i64 0
  %r2355 = ptrtoint i8* %r2354 to i64
  %r2356 = call i64 @_add(i64 %r2353, i64 %r2355)
  %r2357 = load i64, i64* %ptr_NL
  %r2358 = call i64 @_add(i64 %r2356, i64 %r2357)
  store i64 %r2358, i64* %ptr_s
  %r2359 = load i64, i64* %ptr_s
  %r2360 = getelementptr [67 x i8], [67 x i8]* @.str.1094, i64 0, i64 0
  %r2361 = ptrtoint i8* %r2360 to i64
  %r2362 = call i64 @_add(i64 %r2359, i64 %r2361)
  %r2363 = load i64, i64* %ptr_NL
  %r2364 = call i64 @_add(i64 %r2362, i64 %r2363)
  store i64 %r2364, i64* %ptr_s
  %r2365 = load i64, i64* %ptr_s
  %r2366 = getelementptr [51 x i8], [51 x i8]* @.str.1095, i64 0, i64 0
  %r2367 = ptrtoint i8* %r2366 to i64
  %r2368 = call i64 @_add(i64 %r2365, i64 %r2367)
  %r2369 = load i64, i64* %ptr_NL
  %r2370 = call i64 @_add(i64 %r2368, i64 %r2369)
  store i64 %r2370, i64* %ptr_s
  %r2371 = load i64, i64* %ptr_s
  %r2372 = getelementptr [29 x i8], [29 x i8]* @.str.1096, i64 0, i64 0
  %r2373 = ptrtoint i8* %r2372 to i64
  %r2374 = call i64 @_add(i64 %r2371, i64 %r2373)
  %r2375 = load i64, i64* %ptr_NL
  %r2376 = call i64 @_add(i64 %r2374, i64 %r2375)
  store i64 %r2376, i64* %ptr_s
  %r2377 = load i64, i64* %ptr_s
  %r2378 = getelementptr [22 x i8], [22 x i8]* @.str.1097, i64 0, i64 0
  %r2379 = ptrtoint i8* %r2378 to i64
  %r2380 = call i64 @_add(i64 %r2377, i64 %r2379)
  %r2381 = load i64, i64* %ptr_NL
  %r2382 = call i64 @_add(i64 %r2380, i64 %r2381)
  store i64 %r2382, i64* %ptr_s
  %r2383 = load i64, i64* %ptr_s
  %r2384 = getelementptr [11 x i8], [11 x i8]* @.str.1098, i64 0, i64 0
  %r2385 = ptrtoint i8* %r2384 to i64
  %r2386 = call i64 @_add(i64 %r2383, i64 %r2385)
  %r2387 = load i64, i64* %ptr_NL
  %r2388 = call i64 @_add(i64 %r2386, i64 %r2387)
  store i64 %r2388, i64* %ptr_s
  %r2389 = load i64, i64* %ptr_s
  %r2390 = getelementptr [52 x i8], [52 x i8]* @.str.1099, i64 0, i64 0
  %r2391 = ptrtoint i8* %r2390 to i64
  %r2392 = call i64 @_add(i64 %r2389, i64 %r2391)
  %r2393 = load i64, i64* %ptr_NL
  %r2394 = call i64 @_add(i64 %r2392, i64 %r2393)
  store i64 %r2394, i64* %ptr_s
  %r2395 = load i64, i64* %ptr_s
  %r2396 = getelementptr [28 x i8], [28 x i8]* @.str.1100, i64 0, i64 0
  %r2397 = ptrtoint i8* %r2396 to i64
  %r2398 = call i64 @_add(i64 %r2395, i64 %r2397)
  %r2399 = load i64, i64* %ptr_NL
  %r2400 = call i64 @_add(i64 %r2398, i64 %r2399)
  store i64 %r2400, i64* %ptr_s
  %r2401 = load i64, i64* %ptr_s
  %r2402 = getelementptr [32 x i8], [32 x i8]* @.str.1101, i64 0, i64 0
  %r2403 = ptrtoint i8* %r2402 to i64
  %r2404 = call i64 @_add(i64 %r2401, i64 %r2403)
  %r2405 = load i64, i64* %ptr_ptr_thresh
  %r2406 = call i64 @_add(i64 %r2404, i64 %r2405)
  %r2407 = load i64, i64* %ptr_NL
  %r2408 = call i64 @_add(i64 %r2406, i64 %r2407)
  store i64 %r2408, i64* %ptr_s
  %r2409 = load i64, i64* %ptr_s
  %r2410 = getelementptr [52 x i8], [52 x i8]* @.str.1102, i64 0, i64 0
  %r2411 = ptrtoint i8* %r2410 to i64
  %r2412 = call i64 @_add(i64 %r2409, i64 %r2411)
  %r2413 = load i64, i64* %ptr_NL
  %r2414 = call i64 @_add(i64 %r2412, i64 %r2413)
  store i64 %r2414, i64* %ptr_s
  %r2415 = load i64, i64* %ptr_s
  %r2416 = getelementptr [13 x i8], [13 x i8]* @.str.1103, i64 0, i64 0
  %r2417 = ptrtoint i8* %r2416 to i64
  %r2418 = call i64 @_add(i64 %r2415, i64 %r2417)
  %r2419 = load i64, i64* %ptr_NL
  %r2420 = call i64 @_add(i64 %r2418, i64 %r2419)
  store i64 %r2420, i64* %ptr_s
  %r2421 = load i64, i64* %ptr_s
  %r2422 = getelementptr [36 x i8], [36 x i8]* @.str.1104, i64 0, i64 0
  %r2423 = ptrtoint i8* %r2422 to i64
  %r2424 = call i64 @_add(i64 %r2421, i64 %r2423)
  %r2425 = load i64, i64* %ptr_NL
  %r2426 = call i64 @_add(i64 %r2424, i64 %r2425)
  store i64 %r2426, i64* %ptr_s
  %r2427 = load i64, i64* %ptr_s
  %r2428 = getelementptr [34 x i8], [34 x i8]* @.str.1105, i64 0, i64 0
  %r2429 = ptrtoint i8* %r2428 to i64
  %r2430 = call i64 @_add(i64 %r2427, i64 %r2429)
  %r2431 = load i64, i64* %ptr_NL
  %r2432 = call i64 @_add(i64 %r2430, i64 %r2431)
  store i64 %r2432, i64* %ptr_s
  %r2433 = load i64, i64* %ptr_s
  %r2434 = getelementptr [38 x i8], [38 x i8]* @.str.1106, i64 0, i64 0
  %r2435 = ptrtoint i8* %r2434 to i64
  %r2436 = call i64 @_add(i64 %r2433, i64 %r2435)
  %r2437 = load i64, i64* %ptr_NL
  %r2438 = call i64 @_add(i64 %r2436, i64 %r2437)
  store i64 %r2438, i64* %ptr_s
  %r2439 = load i64, i64* %ptr_s
  %r2440 = getelementptr [55 x i8], [55 x i8]* @.str.1107, i64 0, i64 0
  %r2441 = ptrtoint i8* %r2440 to i64
  %r2442 = call i64 @_add(i64 %r2439, i64 %r2441)
  %r2443 = load i64, i64* %ptr_NL
  %r2444 = call i64 @_add(i64 %r2442, i64 %r2443)
  store i64 %r2444, i64* %ptr_s
  %r2445 = load i64, i64* %ptr_s
  %r2446 = getelementptr [10 x i8], [10 x i8]* @.str.1108, i64 0, i64 0
  %r2447 = ptrtoint i8* %r2446 to i64
  %r2448 = call i64 @_add(i64 %r2445, i64 %r2447)
  %r2449 = load i64, i64* %ptr_NL
  %r2450 = call i64 @_add(i64 %r2448, i64 %r2449)
  store i64 %r2450, i64* %ptr_s
  %r2451 = load i64, i64* %ptr_s
  %r2452 = getelementptr [30 x i8], [30 x i8]* @.str.1109, i64 0, i64 0
  %r2453 = ptrtoint i8* %r2452 to i64
  %r2454 = call i64 @_add(i64 %r2451, i64 %r2453)
  %r2455 = load i64, i64* %ptr_NL
  %r2456 = call i64 @_add(i64 %r2454, i64 %r2455)
  store i64 %r2456, i64* %ptr_s
  %r2457 = load i64, i64* %ptr_s
  %r2458 = getelementptr [21 x i8], [21 x i8]* @.str.1110, i64 0, i64 0
  %r2459 = ptrtoint i8* %r2458 to i64
  %r2460 = call i64 @_add(i64 %r2457, i64 %r2459)
  %r2461 = load i64, i64* %ptr_NL
  %r2462 = call i64 @_add(i64 %r2460, i64 %r2461)
  store i64 %r2462, i64* %ptr_s
  %r2463 = load i64, i64* %ptr_s
  %r2464 = getelementptr [11 x i8], [11 x i8]* @.str.1111, i64 0, i64 0
  %r2465 = ptrtoint i8* %r2464 to i64
  %r2466 = call i64 @_add(i64 %r2463, i64 %r2465)
  %r2467 = load i64, i64* %ptr_NL
  %r2468 = call i64 @_add(i64 %r2466, i64 %r2467)
  store i64 %r2468, i64* %ptr_s
  %r2469 = load i64, i64* %ptr_s
  %r2470 = getelementptr [70 x i8], [70 x i8]* @.str.1112, i64 0, i64 0
  %r2471 = ptrtoint i8* %r2470 to i64
  %r2472 = call i64 @_add(i64 %r2469, i64 %r2471)
  %r2473 = load i64, i64* %ptr_NL
  %r2474 = call i64 @_add(i64 %r2472, i64 %r2473)
  store i64 %r2474, i64* %ptr_s
  %r2475 = load i64, i64* %ptr_s
  %r2476 = getelementptr [35 x i8], [35 x i8]* @.str.1113, i64 0, i64 0
  %r2477 = ptrtoint i8* %r2476 to i64
  %r2478 = call i64 @_add(i64 %r2475, i64 %r2477)
  %r2479 = load i64, i64* %ptr_NL
  %r2480 = call i64 @_add(i64 %r2478, i64 %r2479)
  store i64 %r2480, i64* %ptr_s
  %r2481 = load i64, i64* %ptr_s
  %r2482 = getelementptr [54 x i8], [54 x i8]* @.str.1114, i64 0, i64 0
  %r2483 = ptrtoint i8* %r2482 to i64
  %r2484 = call i64 @_add(i64 %r2481, i64 %r2483)
  %r2485 = load i64, i64* %ptr_NL
  %r2486 = call i64 @_add(i64 %r2484, i64 %r2485)
  store i64 %r2486, i64* %ptr_s
  %r2487 = load i64, i64* %ptr_s
  %r2488 = getelementptr [29 x i8], [29 x i8]* @.str.1115, i64 0, i64 0
  %r2489 = ptrtoint i8* %r2488 to i64
  %r2490 = call i64 @_add(i64 %r2487, i64 %r2489)
  %r2491 = load i64, i64* %ptr_NL
  %r2492 = call i64 @_add(i64 %r2490, i64 %r2491)
  store i64 %r2492, i64* %ptr_s
  %r2493 = load i64, i64* %ptr_s
  %r2494 = getelementptr [21 x i8], [21 x i8]* @.str.1116, i64 0, i64 0
  %r2495 = ptrtoint i8* %r2494 to i64
  %r2496 = call i64 @_add(i64 %r2493, i64 %r2495)
  %r2497 = load i64, i64* %ptr_NL
  %r2498 = call i64 @_add(i64 %r2496, i64 %r2497)
  store i64 %r2498, i64* %ptr_s
  %r2499 = load i64, i64* %ptr_s
  %r2500 = getelementptr [7 x i8], [7 x i8]* @.str.1117, i64 0, i64 0
  %r2501 = ptrtoint i8* %r2500 to i64
  %r2502 = call i64 @_add(i64 %r2499, i64 %r2501)
  %r2503 = load i64, i64* %ptr_NL
  %r2504 = call i64 @_add(i64 %r2502, i64 %r2503)
  store i64 %r2504, i64* %ptr_s
  %r2505 = load i64, i64* %ptr_s
  %r2506 = getelementptr [69 x i8], [69 x i8]* @.str.1118, i64 0, i64 0
  %r2507 = ptrtoint i8* %r2506 to i64
  %r2508 = call i64 @_add(i64 %r2505, i64 %r2507)
  %r2509 = load i64, i64* %ptr_NL
  %r2510 = call i64 @_add(i64 %r2508, i64 %r2509)
  store i64 %r2510, i64* %ptr_s
  %r2511 = load i64, i64* %ptr_s
  %r2512 = getelementptr [48 x i8], [48 x i8]* @.str.1119, i64 0, i64 0
  %r2513 = ptrtoint i8* %r2512 to i64
  %r2514 = call i64 @_add(i64 %r2511, i64 %r2513)
  %r2515 = load i64, i64* %ptr_NL
  %r2516 = call i64 @_add(i64 %r2514, i64 %r2515)
  store i64 %r2516, i64* %ptr_s
  %r2517 = load i64, i64* %ptr_s
  %r2518 = getelementptr [29 x i8], [29 x i8]* @.str.1120, i64 0, i64 0
  %r2519 = ptrtoint i8* %r2518 to i64
  %r2520 = call i64 @_add(i64 %r2517, i64 %r2519)
  %r2521 = load i64, i64* %ptr_NL
  %r2522 = call i64 @_add(i64 %r2520, i64 %r2521)
  store i64 %r2522, i64* %ptr_s
  %r2523 = load i64, i64* %ptr_s
  %r2524 = getelementptr [21 x i8], [21 x i8]* @.str.1121, i64 0, i64 0
  %r2525 = ptrtoint i8* %r2524 to i64
  %r2526 = call i64 @_add(i64 %r2523, i64 %r2525)
  %r2527 = load i64, i64* %ptr_NL
  %r2528 = call i64 @_add(i64 %r2526, i64 %r2527)
  store i64 %r2528, i64* %ptr_s
  %r2529 = load i64, i64* %ptr_s
  %r2530 = getelementptr [10 x i8], [10 x i8]* @.str.1122, i64 0, i64 0
  %r2531 = ptrtoint i8* %r2530 to i64
  %r2532 = call i64 @_add(i64 %r2529, i64 %r2531)
  %r2533 = load i64, i64* %ptr_NL
  %r2534 = call i64 @_add(i64 %r2532, i64 %r2533)
  store i64 %r2534, i64* %ptr_s
  %r2535 = load i64, i64* %ptr_s
  %r2536 = getelementptr [26 x i8], [26 x i8]* @.str.1123, i64 0, i64 0
  %r2537 = ptrtoint i8* %r2536 to i64
  %r2538 = call i64 @_add(i64 %r2535, i64 %r2537)
  %r2539 = load i64, i64* %ptr_NL
  %r2540 = call i64 @_add(i64 %r2538, i64 %r2539)
  store i64 %r2540, i64* %ptr_s
  %r2541 = load i64, i64* %ptr_s
  %r2542 = getelementptr [17 x i8], [17 x i8]* @.str.1124, i64 0, i64 0
  %r2543 = ptrtoint i8* %r2542 to i64
  %r2544 = call i64 @_add(i64 %r2541, i64 %r2543)
  %r2545 = load i64, i64* %ptr_NL
  %r2546 = call i64 @_add(i64 %r2544, i64 %r2545)
  store i64 %r2546, i64* %ptr_s
  %r2547 = load i64, i64* %ptr_s
  %r2548 = getelementptr [6 x i8], [6 x i8]* @.str.1125, i64 0, i64 0
  %r2549 = ptrtoint i8* %r2548 to i64
  %r2550 = call i64 @_add(i64 %r2547, i64 %r2549)
  %r2551 = load i64, i64* %ptr_NL
  %r2552 = call i64 @_add(i64 %r2550, i64 %r2551)
  store i64 %r2552, i64* %ptr_s
  %r2553 = load i64, i64* %ptr_s
  %r2554 = getelementptr [70 x i8], [70 x i8]* @.str.1126, i64 0, i64 0
  %r2555 = ptrtoint i8* %r2554 to i64
  %r2556 = call i64 @_add(i64 %r2553, i64 %r2555)
  %r2557 = load i64, i64* %ptr_NL
  %r2558 = call i64 @_add(i64 %r2556, i64 %r2557)
  store i64 %r2558, i64* %ptr_s
  %r2559 = load i64, i64* %ptr_s
  %r2560 = getelementptr [67 x i8], [67 x i8]* @.str.1127, i64 0, i64 0
  %r2561 = ptrtoint i8* %r2560 to i64
  %r2562 = call i64 @_add(i64 %r2559, i64 %r2561)
  %r2563 = load i64, i64* %ptr_NL
  %r2564 = call i64 @_add(i64 %r2562, i64 %r2563)
  store i64 %r2564, i64* %ptr_s
  %r2565 = load i64, i64* %ptr_s
  %r2566 = getelementptr [51 x i8], [51 x i8]* @.str.1128, i64 0, i64 0
  %r2567 = ptrtoint i8* %r2566 to i64
  %r2568 = call i64 @_add(i64 %r2565, i64 %r2567)
  %r2569 = load i64, i64* %ptr_NL
  %r2570 = call i64 @_add(i64 %r2568, i64 %r2569)
  store i64 %r2570, i64* %ptr_s
  %r2571 = load i64, i64* %ptr_s
  %r2572 = getelementptr [29 x i8], [29 x i8]* @.str.1129, i64 0, i64 0
  %r2573 = ptrtoint i8* %r2572 to i64
  %r2574 = call i64 @_add(i64 %r2571, i64 %r2573)
  %r2575 = load i64, i64* %ptr_NL
  %r2576 = call i64 @_add(i64 %r2574, i64 %r2575)
  store i64 %r2576, i64* %ptr_s
  %r2577 = load i64, i64* %ptr_s
  %r2578 = getelementptr [12 x i8], [12 x i8]* @.str.1130, i64 0, i64 0
  %r2579 = ptrtoint i8* %r2578 to i64
  %r2580 = call i64 @_add(i64 %r2577, i64 %r2579)
  %r2581 = load i64, i64* %ptr_NL
  %r2582 = call i64 @_add(i64 %r2580, i64 %r2581)
  store i64 %r2582, i64* %ptr_s
  %r2583 = load i64, i64* %ptr_s
  %r2584 = getelementptr [11 x i8], [11 x i8]* @.str.1131, i64 0, i64 0
  %r2585 = ptrtoint i8* %r2584 to i64
  %r2586 = call i64 @_add(i64 %r2583, i64 %r2585)
  %r2587 = load i64, i64* %ptr_NL
  %r2588 = call i64 @_add(i64 %r2586, i64 %r2587)
  store i64 %r2588, i64* %ptr_s
  %r2589 = load i64, i64* %ptr_s
  %r2590 = getelementptr [71 x i8], [71 x i8]* @.str.1132, i64 0, i64 0
  %r2591 = ptrtoint i8* %r2590 to i64
  %r2592 = call i64 @_add(i64 %r2589, i64 %r2591)
  %r2593 = load i64, i64* %ptr_NL
  %r2594 = call i64 @_add(i64 %r2592, i64 %r2593)
  store i64 %r2594, i64* %ptr_s
  %r2595 = load i64, i64* %ptr_s
  %r2596 = getelementptr [54 x i8], [54 x i8]* @.str.1133, i64 0, i64 0
  %r2597 = ptrtoint i8* %r2596 to i64
  %r2598 = call i64 @_add(i64 %r2595, i64 %r2597)
  %r2599 = load i64, i64* %ptr_NL
  %r2600 = call i64 @_add(i64 %r2598, i64 %r2599)
  store i64 %r2600, i64* %ptr_s
  %r2601 = load i64, i64* %ptr_s
  %r2602 = getelementptr [29 x i8], [29 x i8]* @.str.1134, i64 0, i64 0
  %r2603 = ptrtoint i8* %r2602 to i64
  %r2604 = call i64 @_add(i64 %r2601, i64 %r2603)
  %r2605 = load i64, i64* %ptr_NL
  %r2606 = call i64 @_add(i64 %r2604, i64 %r2605)
  store i64 %r2606, i64* %ptr_s
  %r2607 = load i64, i64* %ptr_s
  %r2608 = getelementptr [12 x i8], [12 x i8]* @.str.1135, i64 0, i64 0
  %r2609 = ptrtoint i8* %r2608 to i64
  %r2610 = call i64 @_add(i64 %r2607, i64 %r2609)
  %r2611 = load i64, i64* %ptr_NL
  %r2612 = call i64 @_add(i64 %r2610, i64 %r2611)
  store i64 %r2612, i64* %ptr_s
  %r2613 = load i64, i64* %ptr_s
  %r2614 = getelementptr [11 x i8], [11 x i8]* @.str.1136, i64 0, i64 0
  %r2615 = ptrtoint i8* %r2614 to i64
  %r2616 = call i64 @_add(i64 %r2613, i64 %r2615)
  %r2617 = load i64, i64* %ptr_NL
  %r2618 = call i64 @_add(i64 %r2616, i64 %r2617)
  store i64 %r2618, i64* %ptr_s
  %r2619 = load i64, i64* %ptr_s
  %r2620 = getelementptr [71 x i8], [71 x i8]* @.str.1137, i64 0, i64 0
  %r2621 = ptrtoint i8* %r2620 to i64
  %r2622 = call i64 @_add(i64 %r2619, i64 %r2621)
  %r2623 = load i64, i64* %ptr_NL
  %r2624 = call i64 @_add(i64 %r2622, i64 %r2623)
  store i64 %r2624, i64* %ptr_s
  %r2625 = load i64, i64* %ptr_s
  %r2626 = getelementptr [36 x i8], [36 x i8]* @.str.1138, i64 0, i64 0
  %r2627 = ptrtoint i8* %r2626 to i64
  %r2628 = call i64 @_add(i64 %r2625, i64 %r2627)
  %r2629 = load i64, i64* %ptr_NL
  %r2630 = call i64 @_add(i64 %r2628, i64 %r2629)
  store i64 %r2630, i64* %ptr_s
  %r2631 = load i64, i64* %ptr_s
  %r2632 = getelementptr [56 x i8], [56 x i8]* @.str.1139, i64 0, i64 0
  %r2633 = ptrtoint i8* %r2632 to i64
  %r2634 = call i64 @_add(i64 %r2631, i64 %r2633)
  %r2635 = load i64, i64* %ptr_NL
  %r2636 = call i64 @_add(i64 %r2634, i64 %r2635)
  store i64 %r2636, i64* %ptr_s
  %r2637 = load i64, i64* %ptr_s
  %r2638 = getelementptr [29 x i8], [29 x i8]* @.str.1140, i64 0, i64 0
  %r2639 = ptrtoint i8* %r2638 to i64
  %r2640 = call i64 @_add(i64 %r2637, i64 %r2639)
  %r2641 = load i64, i64* %ptr_NL
  %r2642 = call i64 @_add(i64 %r2640, i64 %r2641)
  store i64 %r2642, i64* %ptr_s
  %r2643 = load i64, i64* %ptr_s
  %r2644 = getelementptr [12 x i8], [12 x i8]* @.str.1141, i64 0, i64 0
  %r2645 = ptrtoint i8* %r2644 to i64
  %r2646 = call i64 @_add(i64 %r2643, i64 %r2645)
  %r2647 = load i64, i64* %ptr_NL
  %r2648 = call i64 @_add(i64 %r2646, i64 %r2647)
  store i64 %r2648, i64* %ptr_s
  %r2649 = load i64, i64* %ptr_s
  %r2650 = getelementptr [2 x i8], [2 x i8]* @.str.1142, i64 0, i64 0
  %r2651 = ptrtoint i8* %r2650 to i64
  %r2652 = call i64 @_add(i64 %r2649, i64 %r2651)
  %r2653 = load i64, i64* %ptr_NL
  %r2654 = call i64 @_add(i64 %r2652, i64 %r2653)
  store i64 %r2654, i64* %ptr_s
  br label %L1030
L1030:
  %r2655 = load i64, i64* %ptr_s
  %r2656 = getelementptr [30 x i8], [30 x i8]* @.str.1143, i64 0, i64 0
  %r2657 = ptrtoint i8* %r2656 to i64
  %r2658 = call i64 @_add(i64 %r2655, i64 %r2657)
  %r2659 = load i64, i64* %ptr_NL
  %r2660 = call i64 @_add(i64 %r2658, i64 %r2659)
  store i64 %r2660, i64* %ptr_s
  %r2661 = load i64, i64* %ptr_s
  %r2662 = getelementptr [34 x i8], [34 x i8]* @.str.1144, i64 0, i64 0
  %r2663 = ptrtoint i8* %r2662 to i64
  %r2664 = call i64 @_add(i64 %r2661, i64 %r2663)
  %r2665 = load i64, i64* %ptr_NL
  %r2666 = call i64 @_add(i64 %r2664, i64 %r2665)
  store i64 %r2666, i64* %ptr_s
  %r2667 = load i64, i64* %ptr_s
  %r2668 = getelementptr [25 x i8], [25 x i8]* @.str.1145, i64 0, i64 0
  %r2669 = ptrtoint i8* %r2668 to i64
  %r2670 = call i64 @_add(i64 %r2667, i64 %r2669)
  %r2671 = load i64, i64* %ptr_NL
  %r2672 = call i64 @_add(i64 %r2670, i64 %r2671)
  store i64 %r2672, i64* %ptr_s
  %r2673 = load i64, i64* %ptr_s
  %r2674 = getelementptr [27 x i8], [27 x i8]* @.str.1146, i64 0, i64 0
  %r2675 = ptrtoint i8* %r2674 to i64
  %r2676 = call i64 @_add(i64 %r2673, i64 %r2675)
  %r2677 = load i64, i64* %ptr_NL
  %r2678 = call i64 @_add(i64 %r2676, i64 %r2677)
  store i64 %r2678, i64* %ptr_s
  %r2679 = load i64, i64* %ptr_s
  %r2680 = getelementptr [15 x i8], [15 x i8]* @.str.1147, i64 0, i64 0
  %r2681 = ptrtoint i8* %r2680 to i64
  %r2682 = call i64 @_add(i64 %r2679, i64 %r2681)
  %r2683 = load i64, i64* %ptr_NL
  %r2684 = call i64 @_add(i64 %r2682, i64 %r2683)
  store i64 %r2684, i64* %ptr_s
  %r2685 = load i64, i64* %ptr_s
  %r2686 = getelementptr [2 x i8], [2 x i8]* @.str.1148, i64 0, i64 0
  %r2687 = ptrtoint i8* %r2686 to i64
  %r2688 = call i64 @_add(i64 %r2685, i64 %r2687)
  %r2689 = load i64, i64* %ptr_NL
  %r2690 = call i64 @_add(i64 %r2688, i64 %r2689)
  store i64 %r2690, i64* %ptr_s
  %r2691 = load i64, i64* %ptr_s
  %r2692 = getelementptr [51 x i8], [51 x i8]* @.str.1149, i64 0, i64 0
  %r2693 = ptrtoint i8* %r2692 to i64
  %r2694 = call i64 @_add(i64 %r2691, i64 %r2693)
  %r2695 = load i64, i64* %ptr_NL
  %r2696 = call i64 @_add(i64 %r2694, i64 %r2695)
  store i64 %r2696, i64* %ptr_s
  %r2697 = load i64, i64* %ptr_s
  %r2698 = getelementptr [34 x i8], [34 x i8]* @.str.1150, i64 0, i64 0
  %r2699 = ptrtoint i8* %r2698 to i64
  %r2700 = call i64 @_add(i64 %r2697, i64 %r2699)
  %r2701 = load i64, i64* %ptr_NL
  %r2702 = call i64 @_add(i64 %r2700, i64 %r2701)
  store i64 %r2702, i64* %ptr_s
  %r2703 = load i64, i64* %ptr_s
  %r2704 = getelementptr [37 x i8], [37 x i8]* @.str.1151, i64 0, i64 0
  %r2705 = ptrtoint i8* %r2704 to i64
  %r2706 = call i64 @_add(i64 %r2703, i64 %r2705)
  %r2707 = load i64, i64* %ptr_NL
  %r2708 = call i64 @_add(i64 %r2706, i64 %r2707)
  store i64 %r2708, i64* %ptr_s
  %r2709 = load i64, i64* %ptr_s
  %r2710 = getelementptr [39 x i8], [39 x i8]* @.str.1152, i64 0, i64 0
  %r2711 = ptrtoint i8* %r2710 to i64
  %r2712 = call i64 @_add(i64 %r2709, i64 %r2711)
  %r2713 = load i64, i64* %ptr_NL
  %r2714 = call i64 @_add(i64 %r2712, i64 %r2713)
  store i64 %r2714, i64* %ptr_s
  %r2715 = load i64, i64* %ptr_s
  %r2716 = getelementptr [39 x i8], [39 x i8]* @.str.1153, i64 0, i64 0
  %r2717 = ptrtoint i8* %r2716 to i64
  %r2718 = call i64 @_add(i64 %r2715, i64 %r2717)
  %r2719 = load i64, i64* %ptr_NL
  %r2720 = call i64 @_add(i64 %r2718, i64 %r2719)
  store i64 %r2720, i64* %ptr_s
  %r2721 = load i64, i64* %ptr_s
  %r2722 = getelementptr [5 x i8], [5 x i8]* @.str.1154, i64 0, i64 0
  %r2723 = ptrtoint i8* %r2722 to i64
  %r2724 = call i64 @_add(i64 %r2721, i64 %r2723)
  %r2725 = load i64, i64* %ptr_NL
  %r2726 = call i64 @_add(i64 %r2724, i64 %r2725)
  store i64 %r2726, i64* %ptr_s
  %r2727 = load i64, i64* %ptr_s
  %r2728 = getelementptr [33 x i8], [33 x i8]* @.str.1155, i64 0, i64 0
  %r2729 = ptrtoint i8* %r2728 to i64
  %r2730 = call i64 @_add(i64 %r2727, i64 %r2729)
  %r2731 = load i64, i64* %ptr_NL
  %r2732 = call i64 @_add(i64 %r2730, i64 %r2731)
  store i64 %r2732, i64* %ptr_s
  %r2733 = load i64, i64* %ptr_s
  %r2734 = getelementptr [36 x i8], [36 x i8]* @.str.1156, i64 0, i64 0
  %r2735 = ptrtoint i8* %r2734 to i64
  %r2736 = call i64 @_add(i64 %r2733, i64 %r2735)
  %r2737 = load i64, i64* %ptr_NL
  %r2738 = call i64 @_add(i64 %r2736, i64 %r2737)
  store i64 %r2738, i64* %ptr_s
  %r2739 = load i64, i64* %ptr_s
  %r2740 = getelementptr [25 x i8], [25 x i8]* @.str.1157, i64 0, i64 0
  %r2741 = ptrtoint i8* %r2740 to i64
  %r2742 = call i64 @_add(i64 %r2739, i64 %r2741)
  %r2743 = load i64, i64* %ptr_NL
  %r2744 = call i64 @_add(i64 %r2742, i64 %r2743)
  store i64 %r2744, i64* %ptr_s
  %r2745 = load i64, i64* %ptr_s
  %r2746 = getelementptr [15 x i8], [15 x i8]* @.str.1158, i64 0, i64 0
  %r2747 = ptrtoint i8* %r2746 to i64
  %r2748 = call i64 @_add(i64 %r2745, i64 %r2747)
  %r2749 = load i64, i64* %ptr_NL
  %r2750 = call i64 @_add(i64 %r2748, i64 %r2749)
  store i64 %r2750, i64* %ptr_s
  %r2751 = load i64, i64* %ptr_s
  %r2752 = getelementptr [4 x i8], [4 x i8]* @.str.1159, i64 0, i64 0
  %r2753 = ptrtoint i8* %r2752 to i64
  %r2754 = call i64 @_add(i64 %r2751, i64 %r2753)
  %r2755 = load i64, i64* %ptr_NL
  %r2756 = call i64 @_add(i64 %r2754, i64 %r2755)
  store i64 %r2756, i64* %ptr_s
  %r2757 = load i64, i64* %ptr_s
  %r2758 = getelementptr [31 x i8], [31 x i8]* @.str.1160, i64 0, i64 0
  %r2759 = ptrtoint i8* %r2758 to i64
  %r2760 = call i64 @_add(i64 %r2757, i64 %r2759)
  %r2761 = load i64, i64* %ptr_NL
  %r2762 = call i64 @_add(i64 %r2760, i64 %r2761)
  store i64 %r2762, i64* %ptr_s
  %r2763 = load i64, i64* %ptr_s
  %r2764 = getelementptr [37 x i8], [37 x i8]* @.str.1161, i64 0, i64 0
  %r2765 = ptrtoint i8* %r2764 to i64
  %r2766 = call i64 @_add(i64 %r2763, i64 %r2765)
  %r2767 = load i64, i64* %ptr_NL
  %r2768 = call i64 @_add(i64 %r2766, i64 %r2767)
  store i64 %r2768, i64* %ptr_s
  %r2769 = load i64, i64* %ptr_s
  %r2770 = getelementptr [53 x i8], [53 x i8]* @.str.1162, i64 0, i64 0
  %r2771 = ptrtoint i8* %r2770 to i64
  %r2772 = call i64 @_add(i64 %r2769, i64 %r2771)
  %r2773 = load i64, i64* %ptr_NL
  %r2774 = call i64 @_add(i64 %r2772, i64 %r2773)
  store i64 %r2774, i64* %ptr_s
  %r2775 = load i64, i64* %ptr_s
  %r2776 = getelementptr [52 x i8], [52 x i8]* @.str.1163, i64 0, i64 0
  %r2777 = ptrtoint i8* %r2776 to i64
  %r2778 = call i64 @_add(i64 %r2775, i64 %r2777)
  %r2779 = load i64, i64* %ptr_NL
  %r2780 = call i64 @_add(i64 %r2778, i64 %r2779)
  store i64 %r2780, i64* %ptr_s
  %r2781 = load i64, i64* %ptr_s
  %r2782 = getelementptr [35 x i8], [35 x i8]* @.str.1164, i64 0, i64 0
  %r2783 = ptrtoint i8* %r2782 to i64
  %r2784 = call i64 @_add(i64 %r2781, i64 %r2783)
  %r2785 = load i64, i64* %ptr_NL
  %r2786 = call i64 @_add(i64 %r2784, i64 %r2785)
  store i64 %r2786, i64* %ptr_s
  %r2787 = load i64, i64* %ptr_s
  %r2788 = getelementptr [42 x i8], [42 x i8]* @.str.1165, i64 0, i64 0
  %r2789 = ptrtoint i8* %r2788 to i64
  %r2790 = call i64 @_add(i64 %r2787, i64 %r2789)
  %r2791 = load i64, i64* %ptr_NL
  %r2792 = call i64 @_add(i64 %r2790, i64 %r2791)
  store i64 %r2792, i64* %ptr_s
  %r2793 = load i64, i64* %ptr_s
  %r2794 = getelementptr [40 x i8], [40 x i8]* @.str.1166, i64 0, i64 0
  %r2795 = ptrtoint i8* %r2794 to i64
  %r2796 = call i64 @_add(i64 %r2793, i64 %r2795)
  %r2797 = load i64, i64* %ptr_NL
  %r2798 = call i64 @_add(i64 %r2796, i64 %r2797)
  store i64 %r2798, i64* %ptr_s
  %r2799 = load i64, i64* %ptr_s
  %r2800 = getelementptr [64 x i8], [64 x i8]* @.str.1167, i64 0, i64 0
  %r2801 = ptrtoint i8* %r2800 to i64
  %r2802 = call i64 @_add(i64 %r2799, i64 %r2801)
  %r2803 = load i64, i64* %ptr_NL
  %r2804 = call i64 @_add(i64 %r2802, i64 %r2803)
  store i64 %r2804, i64* %ptr_s
  %r2805 = load i64, i64* %ptr_s
  %r2806 = getelementptr [57 x i8], [57 x i8]* @.str.1168, i64 0, i64 0
  %r2807 = ptrtoint i8* %r2806 to i64
  %r2808 = call i64 @_add(i64 %r2805, i64 %r2807)
  %r2809 = load i64, i64* %ptr_NL
  %r2810 = call i64 @_add(i64 %r2808, i64 %r2809)
  store i64 %r2810, i64* %ptr_s
  %r2811 = load i64, i64* %ptr_s
  %r2812 = getelementptr [24 x i8], [24 x i8]* @.str.1169, i64 0, i64 0
  %r2813 = ptrtoint i8* %r2812 to i64
  %r2814 = call i64 @_add(i64 %r2811, i64 %r2813)
  %r2815 = load i64, i64* %ptr_NL
  %r2816 = call i64 @_add(i64 %r2814, i64 %r2815)
  store i64 %r2816, i64* %ptr_s
  %r2817 = load i64, i64* %ptr_s
  %r2818 = getelementptr [16 x i8], [16 x i8]* @.str.1170, i64 0, i64 0
  %r2819 = ptrtoint i8* %r2818 to i64
  %r2820 = call i64 @_add(i64 %r2817, i64 %r2819)
  %r2821 = load i64, i64* %ptr_NL
  %r2822 = call i64 @_add(i64 %r2820, i64 %r2821)
  store i64 %r2822, i64* %ptr_s
  %r2823 = load i64, i64* %ptr_s
  %r2824 = getelementptr [2 x i8], [2 x i8]* @.str.1171, i64 0, i64 0
  %r2825 = ptrtoint i8* %r2824 to i64
  %r2826 = call i64 @_add(i64 %r2823, i64 %r2825)
  %r2827 = load i64, i64* %ptr_NL
  %r2828 = call i64 @_add(i64 %r2826, i64 %r2827)
  store i64 %r2828, i64* %ptr_s
  %r2829 = load i64, i64* %ptr_s
  %r2830 = getelementptr [34 x i8], [34 x i8]* @.str.1172, i64 0, i64 0
  %r2831 = ptrtoint i8* %r2830 to i64
  %r2832 = call i64 @_add(i64 %r2829, i64 %r2831)
  %r2833 = load i64, i64* %ptr_NL
  %r2834 = call i64 @_add(i64 %r2832, i64 %r2833)
  store i64 %r2834, i64* %ptr_s
  %r2835 = load i64, i64* %ptr_s
  %r2836 = getelementptr [33 x i8], [33 x i8]* @.str.1173, i64 0, i64 0
  %r2837 = ptrtoint i8* %r2836 to i64
  %r2838 = call i64 @_add(i64 %r2835, i64 %r2837)
  %r2839 = load i64, i64* %ptr_NL
  %r2840 = call i64 @_add(i64 %r2838, i64 %r2839)
  store i64 %r2840, i64* %ptr_s
  %r2841 = load i64, i64* %ptr_s
  %r2842 = getelementptr [34 x i8], [34 x i8]* @.str.1174, i64 0, i64 0
  %r2843 = ptrtoint i8* %r2842 to i64
  %r2844 = call i64 @_add(i64 %r2841, i64 %r2843)
  %r2845 = load i64, i64* %ptr_NL
  %r2846 = call i64 @_add(i64 %r2844, i64 %r2845)
  store i64 %r2846, i64* %ptr_s
  %r2847 = load i64, i64* %ptr_s
  %r2848 = getelementptr [28 x i8], [28 x i8]* @.str.1175, i64 0, i64 0
  %r2849 = ptrtoint i8* %r2848 to i64
  %r2850 = call i64 @_add(i64 %r2847, i64 %r2849)
  %r2851 = load i64, i64* %ptr_NL
  %r2852 = call i64 @_add(i64 %r2850, i64 %r2851)
  store i64 %r2852, i64* %ptr_s
  %r2853 = load i64, i64* %ptr_s
  %r2854 = getelementptr [24 x i8], [24 x i8]* @.str.1176, i64 0, i64 0
  %r2855 = ptrtoint i8* %r2854 to i64
  %r2856 = call i64 @_add(i64 %r2853, i64 %r2855)
  %r2857 = load i64, i64* %ptr_NL
  %r2858 = call i64 @_add(i64 %r2856, i64 %r2857)
  store i64 %r2858, i64* %ptr_s
  %r2859 = load i64, i64* %ptr_s
  %r2860 = getelementptr [44 x i8], [44 x i8]* @.str.1177, i64 0, i64 0
  %r2861 = ptrtoint i8* %r2860 to i64
  %r2862 = call i64 @_add(i64 %r2859, i64 %r2861)
  %r2863 = load i64, i64* %ptr_NL
  %r2864 = call i64 @_add(i64 %r2862, i64 %r2863)
  store i64 %r2864, i64* %ptr_s
  %r2865 = load i64, i64* %ptr_s
  %r2866 = getelementptr [24 x i8], [24 x i8]* @.str.1178, i64 0, i64 0
  %r2867 = ptrtoint i8* %r2866 to i64
  %r2868 = call i64 @_add(i64 %r2865, i64 %r2867)
  %r2869 = load i64, i64* %ptr_NL
  %r2870 = call i64 @_add(i64 %r2868, i64 %r2869)
  store i64 %r2870, i64* %ptr_s
  %r2871 = load i64, i64* %ptr_s
  %r2872 = getelementptr [15 x i8], [15 x i8]* @.str.1179, i64 0, i64 0
  %r2873 = ptrtoint i8* %r2872 to i64
  %r2874 = call i64 @_add(i64 %r2871, i64 %r2873)
  %r2875 = load i64, i64* %ptr_NL
  %r2876 = call i64 @_add(i64 %r2874, i64 %r2875)
  store i64 %r2876, i64* %ptr_s
  %r2877 = load i64, i64* %ptr_s
  %r2878 = getelementptr [2 x i8], [2 x i8]* @.str.1180, i64 0, i64 0
  %r2879 = ptrtoint i8* %r2878 to i64
  %r2880 = call i64 @_add(i64 %r2877, i64 %r2879)
  %r2881 = load i64, i64* %ptr_NL
  %r2882 = call i64 @_add(i64 %r2880, i64 %r2881)
  store i64 %r2882, i64* %ptr_s
  %r2883 = load i64, i64* %ptr_s
  %r2884 = getelementptr [32 x i8], [32 x i8]* @.str.1181, i64 0, i64 0
  %r2885 = ptrtoint i8* %r2884 to i64
  %r2886 = call i64 @_add(i64 %r2883, i64 %r2885)
  %r2887 = load i64, i64* %ptr_NL
  %r2888 = call i64 @_add(i64 %r2886, i64 %r2887)
  store i64 %r2888, i64* %ptr_s
  %r2889 = load i64, i64* %ptr_s
  %r2890 = getelementptr [33 x i8], [33 x i8]* @.str.1182, i64 0, i64 0
  %r2891 = ptrtoint i8* %r2890 to i64
  %r2892 = call i64 @_add(i64 %r2889, i64 %r2891)
  %r2893 = load i64, i64* %ptr_NL
  %r2894 = call i64 @_add(i64 %r2892, i64 %r2893)
  store i64 %r2894, i64* %ptr_s
  %r2895 = load i64, i64* %ptr_s
  %r2896 = getelementptr [47 x i8], [47 x i8]* @.str.1183, i64 0, i64 0
  %r2897 = ptrtoint i8* %r2896 to i64
  %r2898 = call i64 @_add(i64 %r2895, i64 %r2897)
  %r2899 = load i64, i64* %ptr_NL
  %r2900 = call i64 @_add(i64 %r2898, i64 %r2899)
  store i64 %r2900, i64* %ptr_s
  %r2901 = load i64, i64* %ptr_s
  %r2902 = getelementptr [10 x i8], [10 x i8]* @.str.1184, i64 0, i64 0
  %r2903 = ptrtoint i8* %r2902 to i64
  %r2904 = call i64 @_add(i64 %r2901, i64 %r2903)
  %r2905 = load i64, i64* %ptr_NL
  %r2906 = call i64 @_add(i64 %r2904, i64 %r2905)
  store i64 %r2906, i64* %ptr_s
  %r2907 = load i64, i64* %ptr_s
  %r2908 = getelementptr [12 x i8], [12 x i8]* @.str.1185, i64 0, i64 0
  %r2909 = ptrtoint i8* %r2908 to i64
  %r2910 = call i64 @_add(i64 %r2907, i64 %r2909)
  %r2911 = load i64, i64* %ptr_NL
  %r2912 = call i64 @_add(i64 %r2910, i64 %r2911)
  store i64 %r2912, i64* %ptr_s
  %r2913 = load i64, i64* %ptr_s
  %r2914 = getelementptr [6 x i8], [6 x i8]* @.str.1186, i64 0, i64 0
  %r2915 = ptrtoint i8* %r2914 to i64
  %r2916 = call i64 @_add(i64 %r2913, i64 %r2915)
  %r2917 = load i64, i64* %ptr_NL
  %r2918 = call i64 @_add(i64 %r2916, i64 %r2917)
  store i64 %r2918, i64* %ptr_s
  %r2919 = load i64, i64* %ptr_s
  %r2920 = getelementptr [35 x i8], [35 x i8]* @.str.1187, i64 0, i64 0
  %r2921 = ptrtoint i8* %r2920 to i64
  %r2922 = call i64 @_add(i64 %r2919, i64 %r2921)
  %r2923 = load i64, i64* %ptr_NL
  %r2924 = call i64 @_add(i64 %r2922, i64 %r2923)
  store i64 %r2924, i64* %ptr_s
  %r2925 = load i64, i64* %ptr_s
  %r2926 = getelementptr [29 x i8], [29 x i8]* @.str.1188, i64 0, i64 0
  %r2927 = ptrtoint i8* %r2926 to i64
  %r2928 = call i64 @_add(i64 %r2925, i64 %r2927)
  %r2929 = load i64, i64* %ptr_NL
  %r2930 = call i64 @_add(i64 %r2928, i64 %r2929)
  store i64 %r2930, i64* %ptr_s
  %r2931 = load i64, i64* %ptr_s
  %r2932 = getelementptr [33 x i8], [33 x i8]* @.str.1189, i64 0, i64 0
  %r2933 = ptrtoint i8* %r2932 to i64
  %r2934 = call i64 @_add(i64 %r2931, i64 %r2933)
  %r2935 = load i64, i64* %ptr_NL
  %r2936 = call i64 @_add(i64 %r2934, i64 %r2935)
  store i64 %r2936, i64* %ptr_s
  %r2937 = load i64, i64* %ptr_s
  %r2938 = getelementptr [32 x i8], [32 x i8]* @.str.1190, i64 0, i64 0
  %r2939 = ptrtoint i8* %r2938 to i64
  %r2940 = call i64 @_add(i64 %r2937, i64 %r2939)
  %r2941 = load i64, i64* %ptr_NL
  %r2942 = call i64 @_add(i64 %r2940, i64 %r2941)
  store i64 %r2942, i64* %ptr_s
  %r2943 = load i64, i64* %ptr_s
  %r2944 = getelementptr [36 x i8], [36 x i8]* @.str.1191, i64 0, i64 0
  %r2945 = ptrtoint i8* %r2944 to i64
  %r2946 = call i64 @_add(i64 %r2943, i64 %r2945)
  %r2947 = load i64, i64* %ptr_NL
  %r2948 = call i64 @_add(i64 %r2946, i64 %r2947)
  store i64 %r2948, i64* %ptr_s
  %r2949 = load i64, i64* %ptr_s
  %r2950 = getelementptr [48 x i8], [48 x i8]* @.str.1192, i64 0, i64 0
  %r2951 = ptrtoint i8* %r2950 to i64
  %r2952 = call i64 @_add(i64 %r2949, i64 %r2951)
  %r2953 = load i64, i64* %ptr_NL
  %r2954 = call i64 @_add(i64 %r2952, i64 %r2953)
  store i64 %r2954, i64* %ptr_s
  %r2955 = load i64, i64* %ptr_s
  %r2956 = getelementptr [9 x i8], [9 x i8]* @.str.1193, i64 0, i64 0
  %r2957 = ptrtoint i8* %r2956 to i64
  %r2958 = call i64 @_add(i64 %r2955, i64 %r2957)
  %r2959 = load i64, i64* %ptr_NL
  %r2960 = call i64 @_add(i64 %r2958, i64 %r2959)
  store i64 %r2960, i64* %ptr_s
  %r2961 = load i64, i64* %ptr_s
  %r2962 = getelementptr [37 x i8], [37 x i8]* @.str.1194, i64 0, i64 0
  %r2963 = ptrtoint i8* %r2962 to i64
  %r2964 = call i64 @_add(i64 %r2961, i64 %r2963)
  %r2965 = load i64, i64* %ptr_NL
  %r2966 = call i64 @_add(i64 %r2964, i64 %r2965)
  store i64 %r2966, i64* %ptr_s
  %r2967 = load i64, i64* %ptr_s
  %r2968 = getelementptr [51 x i8], [51 x i8]* @.str.1195, i64 0, i64 0
  %r2969 = ptrtoint i8* %r2968 to i64
  %r2970 = call i64 @_add(i64 %r2967, i64 %r2969)
  %r2971 = load i64, i64* %ptr_NL
  %r2972 = call i64 @_add(i64 %r2970, i64 %r2971)
  store i64 %r2972, i64* %ptr_s
  %r2973 = load i64, i64* %ptr_s
  %r2974 = getelementptr [33 x i8], [33 x i8]* @.str.1196, i64 0, i64 0
  %r2975 = ptrtoint i8* %r2974 to i64
  %r2976 = call i64 @_add(i64 %r2973, i64 %r2975)
  %r2977 = load i64, i64* %ptr_NL
  %r2978 = call i64 @_add(i64 %r2976, i64 %r2977)
  store i64 %r2978, i64* %ptr_s
  %r2979 = load i64, i64* %ptr_s
  %r2980 = getelementptr [15 x i8], [15 x i8]* @.str.1197, i64 0, i64 0
  %r2981 = ptrtoint i8* %r2980 to i64
  %r2982 = call i64 @_add(i64 %r2979, i64 %r2981)
  %r2983 = load i64, i64* %ptr_NL
  %r2984 = call i64 @_add(i64 %r2982, i64 %r2983)
  store i64 %r2984, i64* %ptr_s
  %r2985 = load i64, i64* %ptr_s
  %r2986 = getelementptr [9 x i8], [9 x i8]* @.str.1198, i64 0, i64 0
  %r2987 = ptrtoint i8* %r2986 to i64
  %r2988 = call i64 @_add(i64 %r2985, i64 %r2987)
  %r2989 = load i64, i64* %ptr_NL
  %r2990 = call i64 @_add(i64 %r2988, i64 %r2989)
  store i64 %r2990, i64* %ptr_s
  %r2991 = load i64, i64* %ptr_s
  %r2992 = getelementptr [38 x i8], [38 x i8]* @.str.1199, i64 0, i64 0
  %r2993 = ptrtoint i8* %r2992 to i64
  %r2994 = call i64 @_add(i64 %r2991, i64 %r2993)
  %r2995 = load i64, i64* %ptr_NL
  %r2996 = call i64 @_add(i64 %r2994, i64 %r2995)
  store i64 %r2996, i64* %ptr_s
  %r2997 = load i64, i64* %ptr_s
  %r2998 = getelementptr [40 x i8], [40 x i8]* @.str.1200, i64 0, i64 0
  %r2999 = ptrtoint i8* %r2998 to i64
  %r3000 = call i64 @_add(i64 %r2997, i64 %r2999)
  %r3001 = load i64, i64* %ptr_NL
  %r3002 = call i64 @_add(i64 %r3000, i64 %r3001)
  store i64 %r3002, i64* %ptr_s
  %r3003 = load i64, i64* %ptr_s
  %r3004 = getelementptr [15 x i8], [15 x i8]* @.str.1201, i64 0, i64 0
  %r3005 = ptrtoint i8* %r3004 to i64
  %r3006 = call i64 @_add(i64 %r3003, i64 %r3005)
  %r3007 = load i64, i64* %ptr_NL
  %r3008 = call i64 @_add(i64 %r3006, i64 %r3007)
  store i64 %r3008, i64* %ptr_s
  %r3009 = load i64, i64* %ptr_s
  %r3010 = getelementptr [2 x i8], [2 x i8]* @.str.1202, i64 0, i64 0
  %r3011 = ptrtoint i8* %r3010 to i64
  %r3012 = call i64 @_add(i64 %r3009, i64 %r3011)
  %r3013 = load i64, i64* %ptr_NL
  %r3014 = call i64 @_add(i64 %r3012, i64 %r3013)
  store i64 %r3014, i64* %ptr_s
  %r3015 = load i64, i64* %ptr_is_freestanding
  %r3016 = call i64 @_eq(i64 %r3015, i64 0)
  %r3017 = icmp ne i64 %r3016, 0
  br i1 %r3017, label %L1031, label %L1033
L1031:
  %r3018 = load i64, i64* %ptr_s
  %r3019 = getelementptr [22 x i8], [22 x i8]* @.str.1203, i64 0, i64 0
  %r3020 = ptrtoint i8* %r3019 to i64
  %r3021 = call i64 @_add(i64 %r3018, i64 %r3020)
  %r3022 = load i64, i64* %ptr_NL
  %r3023 = call i64 @_add(i64 %r3021, i64 %r3022)
  store i64 %r3023, i64* %ptr_s
  %r3024 = load i64, i64* %ptr_s
  %r3025 = getelementptr [36 x i8], [36 x i8]* @.str.1204, i64 0, i64 0
  %r3026 = ptrtoint i8* %r3025 to i64
  %r3027 = call i64 @_add(i64 %r3024, i64 %r3026)
  %r3028 = load i64, i64* %ptr_NL
  %r3029 = call i64 @_add(i64 %r3027, i64 %r3028)
  store i64 %r3029, i64* %ptr_s
  %r3030 = load i64, i64* %ptr_s
  %r3031 = getelementptr [34 x i8], [34 x i8]* @.str.1205, i64 0, i64 0
  %r3032 = ptrtoint i8* %r3031 to i64
  %r3033 = call i64 @_add(i64 %r3030, i64 %r3032)
  %r3034 = load i64, i64* %ptr_NL
  %r3035 = call i64 @_add(i64 %r3033, i64 %r3034)
  store i64 %r3035, i64* %ptr_s
  %r3036 = load i64, i64* %ptr_s
  %r3037 = getelementptr [17 x i8], [17 x i8]* @.str.1206, i64 0, i64 0
  %r3038 = ptrtoint i8* %r3037 to i64
  %r3039 = call i64 @_add(i64 %r3036, i64 %r3038)
  %r3040 = load i64, i64* %ptr_NL
  %r3041 = call i64 @_add(i64 %r3039, i64 %r3040)
  store i64 %r3041, i64* %ptr_s
  %r3042 = load i64, i64* %ptr_s
  %r3043 = getelementptr [6 x i8], [6 x i8]* @.str.1207, i64 0, i64 0
  %r3044 = ptrtoint i8* %r3043 to i64
  %r3045 = call i64 @_add(i64 %r3042, i64 %r3044)
  %r3046 = load i64, i64* %ptr_NL
  %r3047 = call i64 @_add(i64 %r3045, i64 %r3046)
  store i64 %r3047, i64* %ptr_s
  %r3048 = load i64, i64* %ptr_s
  %r3049 = getelementptr [45 x i8], [45 x i8]* @.str.1208, i64 0, i64 0
  %r3050 = ptrtoint i8* %r3049 to i64
  %r3051 = call i64 @_add(i64 %r3048, i64 %r3050)
  %r3052 = load i64, i64* %ptr_NL
  %r3053 = call i64 @_add(i64 %r3051, i64 %r3052)
  store i64 %r3053, i64* %ptr_s
  %r3054 = load i64, i64* %ptr_s
  %r3055 = getelementptr [27 x i8], [27 x i8]* @.str.1209, i64 0, i64 0
  %r3056 = ptrtoint i8* %r3055 to i64
  %r3057 = call i64 @_add(i64 %r3054, i64 %r3056)
  %r3058 = load i64, i64* %ptr_NL
  %r3059 = call i64 @_add(i64 %r3057, i64 %r3058)
  store i64 %r3059, i64* %ptr_s
  %r3060 = load i64, i64* %ptr_s
  %r3061 = getelementptr [31 x i8], [31 x i8]* @.str.1210, i64 0, i64 0
  %r3062 = ptrtoint i8* %r3061 to i64
  %r3063 = call i64 @_add(i64 %r3060, i64 %r3062)
  %r3064 = load i64, i64* %ptr_NL
  %r3065 = call i64 @_add(i64 %r3063, i64 %r3064)
  store i64 %r3065, i64* %ptr_s
  %r3066 = load i64, i64* %ptr_s
  %r3067 = getelementptr [30 x i8], [30 x i8]* @.str.1211, i64 0, i64 0
  %r3068 = ptrtoint i8* %r3067 to i64
  %r3069 = call i64 @_add(i64 %r3066, i64 %r3068)
  %r3070 = load i64, i64* %ptr_NL
  %r3071 = call i64 @_add(i64 %r3069, i64 %r3070)
  store i64 %r3071, i64* %ptr_s
  %r3072 = load i64, i64* %ptr_s
  %r3073 = getelementptr [32 x i8], [32 x i8]* @.str.1212, i64 0, i64 0
  %r3074 = ptrtoint i8* %r3073 to i64
  %r3075 = call i64 @_add(i64 %r3072, i64 %r3074)
  %r3076 = load i64, i64* %ptr_NL
  %r3077 = call i64 @_add(i64 %r3075, i64 %r3076)
  store i64 %r3077, i64* %ptr_s
  %r3078 = load i64, i64* %ptr_s
  %r3079 = getelementptr [40 x i8], [40 x i8]* @.str.1213, i64 0, i64 0
  %r3080 = ptrtoint i8* %r3079 to i64
  %r3081 = call i64 @_add(i64 %r3078, i64 %r3080)
  %r3082 = load i64, i64* %ptr_NL
  %r3083 = call i64 @_add(i64 %r3081, i64 %r3082)
  store i64 %r3083, i64* %ptr_s
  %r3084 = load i64, i64* %ptr_s
  %r3085 = getelementptr [6 x i8], [6 x i8]* @.str.1214, i64 0, i64 0
  %r3086 = ptrtoint i8* %r3085 to i64
  %r3087 = call i64 @_add(i64 %r3084, i64 %r3086)
  %r3088 = load i64, i64* %ptr_NL
  %r3089 = call i64 @_add(i64 %r3087, i64 %r3088)
  store i64 %r3089, i64* %ptr_s
  %r3090 = load i64, i64* %ptr_s
  %r3091 = getelementptr [29 x i8], [29 x i8]* @.str.1215, i64 0, i64 0
  %r3092 = ptrtoint i8* %r3091 to i64
  %r3093 = call i64 @_add(i64 %r3090, i64 %r3092)
  %r3094 = load i64, i64* %ptr_NL
  %r3095 = call i64 @_add(i64 %r3093, i64 %r3094)
  store i64 %r3095, i64* %ptr_s
  %r3096 = load i64, i64* %ptr_s
  %r3097 = getelementptr [45 x i8], [45 x i8]* @.str.1216, i64 0, i64 0
  %r3098 = ptrtoint i8* %r3097 to i64
  %r3099 = call i64 @_add(i64 %r3096, i64 %r3098)
  %r3100 = load i64, i64* %ptr_NL
  %r3101 = call i64 @_add(i64 %r3099, i64 %r3100)
  store i64 %r3101, i64* %ptr_s
  %r3102 = load i64, i64* %ptr_s
  %r3103 = getelementptr [28 x i8], [28 x i8]* @.str.1217, i64 0, i64 0
  %r3104 = ptrtoint i8* %r3103 to i64
  %r3105 = call i64 @_add(i64 %r3102, i64 %r3104)
  %r3106 = load i64, i64* %ptr_NL
  %r3107 = call i64 @_add(i64 %r3105, i64 %r3106)
  store i64 %r3107, i64* %ptr_s
  %r3108 = load i64, i64* %ptr_s
  %r3109 = getelementptr [26 x i8], [26 x i8]* @.str.1218, i64 0, i64 0
  %r3110 = ptrtoint i8* %r3109 to i64
  %r3111 = call i64 @_add(i64 %r3108, i64 %r3110)
  %r3112 = load i64, i64* %ptr_NL
  %r3113 = call i64 @_add(i64 %r3111, i64 %r3112)
  store i64 %r3113, i64* %ptr_s
  %r3114 = load i64, i64* %ptr_s
  %r3115 = getelementptr [38 x i8], [38 x i8]* @.str.1219, i64 0, i64 0
  %r3116 = ptrtoint i8* %r3115 to i64
  %r3117 = call i64 @_add(i64 %r3114, i64 %r3116)
  %r3118 = load i64, i64* %ptr_NL
  %r3119 = call i64 @_add(i64 %r3117, i64 %r3118)
  store i64 %r3119, i64* %ptr_s
  %r3120 = load i64, i64* %ptr_s
  %r3121 = getelementptr [41 x i8], [41 x i8]* @.str.1220, i64 0, i64 0
  %r3122 = ptrtoint i8* %r3121 to i64
  %r3123 = call i64 @_add(i64 %r3120, i64 %r3122)
  %r3124 = load i64, i64* %ptr_NL
  %r3125 = call i64 @_add(i64 %r3123, i64 %r3124)
  store i64 %r3125, i64* %ptr_s
  %r3126 = load i64, i64* %ptr_s
  %r3127 = getelementptr [6 x i8], [6 x i8]* @.str.1221, i64 0, i64 0
  %r3128 = ptrtoint i8* %r3127 to i64
  %r3129 = call i64 @_add(i64 %r3126, i64 %r3128)
  %r3130 = load i64, i64* %ptr_NL
  %r3131 = call i64 @_add(i64 %r3129, i64 %r3130)
  store i64 %r3131, i64* %ptr_s
  %r3132 = load i64, i64* %ptr_s
  %r3133 = getelementptr [50 x i8], [50 x i8]* @.str.1222, i64 0, i64 0
  %r3134 = ptrtoint i8* %r3133 to i64
  %r3135 = call i64 @_add(i64 %r3132, i64 %r3134)
  %r3136 = load i64, i64* %ptr_NL
  %r3137 = call i64 @_add(i64 %r3135, i64 %r3136)
  store i64 %r3137, i64* %ptr_s
  %r3138 = load i64, i64* %ptr_s
  %r3139 = getelementptr [29 x i8], [29 x i8]* @.str.1223, i64 0, i64 0
  %r3140 = ptrtoint i8* %r3139 to i64
  %r3141 = call i64 @_add(i64 %r3138, i64 %r3140)
  %r3142 = load i64, i64* %ptr_NL
  %r3143 = call i64 @_add(i64 %r3141, i64 %r3142)
  store i64 %r3143, i64* %ptr_s
  %r3144 = load i64, i64* %ptr_s
  %r3145 = getelementptr [15 x i8], [15 x i8]* @.str.1224, i64 0, i64 0
  %r3146 = ptrtoint i8* %r3145 to i64
  %r3147 = call i64 @_add(i64 %r3144, i64 %r3146)
  %r3148 = load i64, i64* %ptr_NL
  %r3149 = call i64 @_add(i64 %r3147, i64 %r3148)
  store i64 %r3149, i64* %ptr_s
  %r3150 = load i64, i64* %ptr_s
  %r3151 = getelementptr [2 x i8], [2 x i8]* @.str.1225, i64 0, i64 0
  %r3152 = ptrtoint i8* %r3151 to i64
  %r3153 = call i64 @_add(i64 %r3150, i64 %r3152)
  %r3154 = load i64, i64* %ptr_NL
  %r3155 = call i64 @_add(i64 %r3153, i64 %r3154)
  store i64 %r3155, i64* %ptr_s
  %r3156 = load i64, i64* %ptr_s
  %r3157 = getelementptr [33 x i8], [33 x i8]* @.str.1226, i64 0, i64 0
  %r3158 = ptrtoint i8* %r3157 to i64
  %r3159 = call i64 @_add(i64 %r3156, i64 %r3158)
  %r3160 = load i64, i64* %ptr_NL
  %r3161 = call i64 @_add(i64 %r3159, i64 %r3160)
  store i64 %r3161, i64* %ptr_s
  %r3162 = load i64, i64* %ptr_s
  %r3163 = getelementptr [32 x i8], [32 x i8]* @.str.1227, i64 0, i64 0
  %r3164 = ptrtoint i8* %r3163 to i64
  %r3165 = call i64 @_add(i64 %r3162, i64 %r3164)
  %r3166 = load i64, i64* %ptr_NL
  %r3167 = call i64 @_add(i64 %r3165, i64 %r3166)
  store i64 %r3167, i64* %ptr_s
  %r3168 = load i64, i64* %ptr_s
  %r3169 = getelementptr [34 x i8], [34 x i8]* @.str.1228, i64 0, i64 0
  %r3170 = ptrtoint i8* %r3169 to i64
  %r3171 = call i64 @_add(i64 %r3168, i64 %r3170)
  %r3172 = load i64, i64* %ptr_NL
  %r3173 = call i64 @_add(i64 %r3171, i64 %r3172)
  store i64 %r3173, i64* %ptr_s
  %r3174 = load i64, i64* %ptr_s
  %r3175 = getelementptr [30 x i8], [30 x i8]* @.str.1229, i64 0, i64 0
  %r3176 = ptrtoint i8* %r3175 to i64
  %r3177 = call i64 @_add(i64 %r3174, i64 %r3176)
  %r3178 = load i64, i64* %ptr_NL
  %r3179 = call i64 @_add(i64 %r3177, i64 %r3178)
  store i64 %r3179, i64* %ptr_s
  %r3180 = load i64, i64* %ptr_s
  %r3181 = getelementptr [15 x i8], [15 x i8]* @.str.1230, i64 0, i64 0
  %r3182 = ptrtoint i8* %r3181 to i64
  %r3183 = call i64 @_add(i64 %r3180, i64 %r3182)
  %r3184 = load i64, i64* %ptr_NL
  %r3185 = call i64 @_add(i64 %r3183, i64 %r3184)
  store i64 %r3185, i64* %ptr_s
  %r3186 = load i64, i64* %ptr_s
  %r3187 = getelementptr [2 x i8], [2 x i8]* @.str.1231, i64 0, i64 0
  %r3188 = ptrtoint i8* %r3187 to i64
  %r3189 = call i64 @_add(i64 %r3186, i64 %r3188)
  %r3190 = load i64, i64* %ptr_NL
  %r3191 = call i64 @_add(i64 %r3189, i64 %r3190)
  store i64 %r3191, i64* %ptr_s
  %r3192 = load i64, i64* %ptr_s
  %r3193 = getelementptr [31 x i8], [31 x i8]* @.str.1232, i64 0, i64 0
  %r3194 = ptrtoint i8* %r3193 to i64
  %r3195 = call i64 @_add(i64 %r3192, i64 %r3194)
  %r3196 = load i64, i64* %ptr_NL
  %r3197 = call i64 @_add(i64 %r3195, i64 %r3196)
  store i64 %r3197, i64* %ptr_s
  %r3198 = load i64, i64* %ptr_s
  %r3199 = getelementptr [26 x i8], [26 x i8]* @.str.1233, i64 0, i64 0
  %r3200 = ptrtoint i8* %r3199 to i64
  %r3201 = call i64 @_add(i64 %r3198, i64 %r3200)
  %r3202 = load i64, i64* %ptr_NL
  %r3203 = call i64 @_add(i64 %r3201, i64 %r3202)
  store i64 %r3203, i64* %ptr_s
  %r3204 = load i64, i64* %ptr_s
  %r3205 = getelementptr [31 x i8], [31 x i8]* @.str.1234, i64 0, i64 0
  %r3206 = ptrtoint i8* %r3205 to i64
  %r3207 = call i64 @_add(i64 %r3204, i64 %r3206)
  %r3208 = load i64, i64* %ptr_NL
  %r3209 = call i64 @_add(i64 %r3207, i64 %r3208)
  store i64 %r3209, i64* %ptr_s
  %r3210 = load i64, i64* %ptr_s
  %r3211 = getelementptr [30 x i8], [30 x i8]* @.str.1235, i64 0, i64 0
  %r3212 = ptrtoint i8* %r3211 to i64
  %r3213 = call i64 @_add(i64 %r3210, i64 %r3212)
  %r3214 = load i64, i64* %ptr_NL
  %r3215 = call i64 @_add(i64 %r3213, i64 %r3214)
  store i64 %r3215, i64* %ptr_s
  %r3216 = load i64, i64* %ptr_s
  %r3217 = getelementptr [12 x i8], [12 x i8]* @.str.1236, i64 0, i64 0
  %r3218 = ptrtoint i8* %r3217 to i64
  %r3219 = call i64 @_add(i64 %r3216, i64 %r3218)
  %r3220 = load i64, i64* %ptr_NL
  %r3221 = call i64 @_add(i64 %r3219, i64 %r3220)
  store i64 %r3221, i64* %ptr_s
  %r3222 = load i64, i64* %ptr_s
  %r3223 = getelementptr [2 x i8], [2 x i8]* @.str.1237, i64 0, i64 0
  %r3224 = ptrtoint i8* %r3223 to i64
  %r3225 = call i64 @_add(i64 %r3222, i64 %r3224)
  %r3226 = load i64, i64* %ptr_NL
  %r3227 = call i64 @_add(i64 %r3225, i64 %r3226)
  store i64 %r3227, i64* %ptr_s
  %r3228 = load i64, i64* %ptr_s
  %r3229 = getelementptr [32 x i8], [32 x i8]* @.str.1238, i64 0, i64 0
  %r3230 = ptrtoint i8* %r3229 to i64
  %r3231 = call i64 @_add(i64 %r3228, i64 %r3230)
  %r3232 = load i64, i64* %ptr_NL
  %r3233 = call i64 @_add(i64 %r3231, i64 %r3232)
  store i64 %r3233, i64* %ptr_s
  %r3234 = load i64, i64* %ptr_s
  %r3235 = getelementptr [34 x i8], [34 x i8]* @.str.1239, i64 0, i64 0
  %r3236 = ptrtoint i8* %r3235 to i64
  %r3237 = call i64 @_add(i64 %r3234, i64 %r3236)
  %r3238 = load i64, i64* %ptr_NL
  %r3239 = call i64 @_add(i64 %r3237, i64 %r3238)
  store i64 %r3239, i64* %ptr_s
  %r3240 = load i64, i64* %ptr_s
  %r3241 = getelementptr [17 x i8], [17 x i8]* @.str.1240, i64 0, i64 0
  %r3242 = ptrtoint i8* %r3241 to i64
  %r3243 = call i64 @_add(i64 %r3240, i64 %r3242)
  %r3244 = load i64, i64* %ptr_NL
  %r3245 = call i64 @_add(i64 %r3243, i64 %r3244)
  store i64 %r3245, i64* %ptr_s
  %r3246 = load i64, i64* %ptr_s
  %r3247 = getelementptr [6 x i8], [6 x i8]* @.str.1241, i64 0, i64 0
  %r3248 = ptrtoint i8* %r3247 to i64
  %r3249 = call i64 @_add(i64 %r3246, i64 %r3248)
  %r3250 = load i64, i64* %ptr_NL
  %r3251 = call i64 @_add(i64 %r3249, i64 %r3250)
  store i64 %r3251, i64* %ptr_s
  %r3252 = load i64, i64* %ptr_s
  %r3253 = getelementptr [45 x i8], [45 x i8]* @.str.1242, i64 0, i64 0
  %r3254 = ptrtoint i8* %r3253 to i64
  %r3255 = call i64 @_add(i64 %r3252, i64 %r3254)
  %r3256 = load i64, i64* %ptr_NL
  %r3257 = call i64 @_add(i64 %r3255, i64 %r3256)
  store i64 %r3257, i64* %ptr_s
  %r3258 = load i64, i64* %ptr_s
  %r3259 = getelementptr [49 x i8], [49 x i8]* @.str.1243, i64 0, i64 0
  %r3260 = ptrtoint i8* %r3259 to i64
  %r3261 = call i64 @_add(i64 %r3258, i64 %r3260)
  %r3262 = load i64, i64* %ptr_NL
  %r3263 = call i64 @_add(i64 %r3261, i64 %r3262)
  store i64 %r3263, i64* %ptr_s
  %r3264 = load i64, i64* %ptr_s
  %r3265 = getelementptr [49 x i8], [49 x i8]* @.str.1244, i64 0, i64 0
  %r3266 = ptrtoint i8* %r3265 to i64
  %r3267 = call i64 @_add(i64 %r3264, i64 %r3266)
  %r3268 = load i64, i64* %ptr_NL
  %r3269 = call i64 @_add(i64 %r3267, i64 %r3268)
  store i64 %r3269, i64* %ptr_s
  %r3270 = load i64, i64* %ptr_s
  %r3271 = getelementptr [30 x i8], [30 x i8]* @.str.1245, i64 0, i64 0
  %r3272 = ptrtoint i8* %r3271 to i64
  %r3273 = call i64 @_add(i64 %r3270, i64 %r3272)
  %r3274 = load i64, i64* %ptr_NL
  %r3275 = call i64 @_add(i64 %r3273, i64 %r3274)
  store i64 %r3275, i64* %ptr_s
  %r3276 = load i64, i64* %ptr_s
  %r3277 = getelementptr [30 x i8], [30 x i8]* @.str.1246, i64 0, i64 0
  %r3278 = ptrtoint i8* %r3277 to i64
  %r3279 = call i64 @_add(i64 %r3276, i64 %r3278)
  %r3280 = load i64, i64* %ptr_NL
  %r3281 = call i64 @_add(i64 %r3279, i64 %r3280)
  store i64 %r3281, i64* %ptr_s
  %r3282 = load i64, i64* %ptr_s
  %r3283 = getelementptr [43 x i8], [43 x i8]* @.str.1247, i64 0, i64 0
  %r3284 = ptrtoint i8* %r3283 to i64
  %r3285 = call i64 @_add(i64 %r3282, i64 %r3284)
  %r3286 = load i64, i64* %ptr_NL
  %r3287 = call i64 @_add(i64 %r3285, i64 %r3286)
  store i64 %r3287, i64* %ptr_s
  %r3288 = load i64, i64* %ptr_s
  %r3289 = getelementptr [6 x i8], [6 x i8]* @.str.1248, i64 0, i64 0
  %r3290 = ptrtoint i8* %r3289 to i64
  %r3291 = call i64 @_add(i64 %r3288, i64 %r3290)
  %r3292 = load i64, i64* %ptr_NL
  %r3293 = call i64 @_add(i64 %r3291, i64 %r3292)
  store i64 %r3293, i64* %ptr_s
  %r3294 = load i64, i64* %ptr_s
  %r3295 = getelementptr [29 x i8], [29 x i8]* @.str.1249, i64 0, i64 0
  %r3296 = ptrtoint i8* %r3295 to i64
  %r3297 = call i64 @_add(i64 %r3294, i64 %r3296)
  %r3298 = load i64, i64* %ptr_NL
  %r3299 = call i64 @_add(i64 %r3297, i64 %r3298)
  store i64 %r3299, i64* %ptr_s
  %r3300 = load i64, i64* %ptr_s
  %r3301 = getelementptr [30 x i8], [30 x i8]* @.str.1250, i64 0, i64 0
  %r3302 = ptrtoint i8* %r3301 to i64
  %r3303 = call i64 @_add(i64 %r3300, i64 %r3302)
  %r3304 = load i64, i64* %ptr_NL
  %r3305 = call i64 @_add(i64 %r3303, i64 %r3304)
  store i64 %r3305, i64* %ptr_s
  %r3306 = load i64, i64* %ptr_s
  %r3307 = getelementptr [28 x i8], [28 x i8]* @.str.1251, i64 0, i64 0
  %r3308 = ptrtoint i8* %r3307 to i64
  %r3309 = call i64 @_add(i64 %r3306, i64 %r3308)
  %r3310 = load i64, i64* %ptr_NL
  %r3311 = call i64 @_add(i64 %r3309, i64 %r3310)
  store i64 %r3311, i64* %ptr_s
  %r3312 = load i64, i64* %ptr_s
  %r3313 = getelementptr [37 x i8], [37 x i8]* @.str.1252, i64 0, i64 0
  %r3314 = ptrtoint i8* %r3313 to i64
  %r3315 = call i64 @_add(i64 %r3312, i64 %r3314)
  %r3316 = load i64, i64* %ptr_NL
  %r3317 = call i64 @_add(i64 %r3315, i64 %r3316)
  store i64 %r3317, i64* %ptr_s
  %r3318 = load i64, i64* %ptr_s
  %r3319 = getelementptr [26 x i8], [26 x i8]* @.str.1253, i64 0, i64 0
  %r3320 = ptrtoint i8* %r3319 to i64
  %r3321 = call i64 @_add(i64 %r3318, i64 %r3320)
  %r3322 = load i64, i64* %ptr_NL
  %r3323 = call i64 @_add(i64 %r3321, i64 %r3322)
  store i64 %r3323, i64* %ptr_s
  %r3324 = load i64, i64* %ptr_s
  %r3325 = getelementptr [17 x i8], [17 x i8]* @.str.1254, i64 0, i64 0
  %r3326 = ptrtoint i8* %r3325 to i64
  %r3327 = call i64 @_add(i64 %r3324, i64 %r3326)
  %r3328 = load i64, i64* %ptr_NL
  %r3329 = call i64 @_add(i64 %r3327, i64 %r3328)
  store i64 %r3329, i64* %ptr_s
  %r3330 = load i64, i64* %ptr_s
  %r3331 = getelementptr [6 x i8], [6 x i8]* @.str.1255, i64 0, i64 0
  %r3332 = ptrtoint i8* %r3331 to i64
  %r3333 = call i64 @_add(i64 %r3330, i64 %r3332)
  %r3334 = load i64, i64* %ptr_NL
  %r3335 = call i64 @_add(i64 %r3333, i64 %r3334)
  store i64 %r3335, i64* %ptr_s
  %r3336 = load i64, i64* %ptr_s
  %r3337 = getelementptr [15 x i8], [15 x i8]* @.str.1256, i64 0, i64 0
  %r3338 = ptrtoint i8* %r3337 to i64
  %r3339 = call i64 @_add(i64 %r3336, i64 %r3338)
  %r3340 = load i64, i64* %ptr_NL
  %r3341 = call i64 @_add(i64 %r3339, i64 %r3340)
  store i64 %r3341, i64* %ptr_s
  %r3342 = load i64, i64* %ptr_s
  %r3343 = getelementptr [2 x i8], [2 x i8]* @.str.1257, i64 0, i64 0
  %r3344 = ptrtoint i8* %r3343 to i64
  %r3345 = call i64 @_add(i64 %r3342, i64 %r3344)
  %r3346 = load i64, i64* %ptr_NL
  %r3347 = call i64 @_add(i64 %r3345, i64 %r3346)
  store i64 %r3347, i64* %ptr_s
  %r3348 = load i64, i64* %ptr_s
  %r3349 = getelementptr [45 x i8], [45 x i8]* @.str.1258, i64 0, i64 0
  %r3350 = ptrtoint i8* %r3349 to i64
  %r3351 = call i64 @_add(i64 %r3348, i64 %r3350)
  %r3352 = load i64, i64* %ptr_NL
  %r3353 = call i64 @_add(i64 %r3351, i64 %r3352)
  store i64 %r3353, i64* %ptr_s
  %r3354 = load i64, i64* %ptr_s
  %r3355 = getelementptr [32 x i8], [32 x i8]* @.str.1259, i64 0, i64 0
  %r3356 = ptrtoint i8* %r3355 to i64
  %r3357 = call i64 @_add(i64 %r3354, i64 %r3356)
  %r3358 = load i64, i64* %ptr_NL
  %r3359 = call i64 @_add(i64 %r3357, i64 %r3358)
  store i64 %r3359, i64* %ptr_s
  %r3360 = load i64, i64* %ptr_s
  %r3361 = getelementptr [34 x i8], [34 x i8]* @.str.1260, i64 0, i64 0
  %r3362 = ptrtoint i8* %r3361 to i64
  %r3363 = call i64 @_add(i64 %r3360, i64 %r3362)
  %r3364 = load i64, i64* %ptr_NL
  %r3365 = call i64 @_add(i64 %r3363, i64 %r3364)
  store i64 %r3365, i64* %ptr_s
  %r3366 = load i64, i64* %ptr_s
  %r3367 = getelementptr [36 x i8], [36 x i8]* @.str.1261, i64 0, i64 0
  %r3368 = ptrtoint i8* %r3367 to i64
  %r3369 = call i64 @_add(i64 %r3366, i64 %r3368)
  %r3370 = load i64, i64* %ptr_NL
  %r3371 = call i64 @_add(i64 %r3369, i64 %r3370)
  store i64 %r3371, i64* %ptr_s
  %r3372 = load i64, i64* %ptr_s
  %r3373 = getelementptr [36 x i8], [36 x i8]* @.str.1262, i64 0, i64 0
  %r3374 = ptrtoint i8* %r3373 to i64
  %r3375 = call i64 @_add(i64 %r3372, i64 %r3374)
  %r3376 = load i64, i64* %ptr_NL
  %r3377 = call i64 @_add(i64 %r3375, i64 %r3376)
  store i64 %r3377, i64* %ptr_s
  %r3378 = load i64, i64* %ptr_s
  %r3379 = getelementptr [24 x i8], [24 x i8]* @.str.1263, i64 0, i64 0
  %r3380 = ptrtoint i8* %r3379 to i64
  %r3381 = call i64 @_add(i64 %r3378, i64 %r3380)
  %r3382 = load i64, i64* %ptr_NL
  %r3383 = call i64 @_add(i64 %r3381, i64 %r3382)
  store i64 %r3383, i64* %ptr_s
  %r3384 = load i64, i64* %ptr_s
  %r3385 = getelementptr [35 x i8], [35 x i8]* @.str.1264, i64 0, i64 0
  %r3386 = ptrtoint i8* %r3385 to i64
  %r3387 = call i64 @_add(i64 %r3384, i64 %r3386)
  %r3388 = load i64, i64* %ptr_NL
  %r3389 = call i64 @_add(i64 %r3387, i64 %r3388)
  store i64 %r3389, i64* %ptr_s
  %r3390 = load i64, i64* %ptr_s
  %r3391 = getelementptr [33 x i8], [33 x i8]* @.str.1265, i64 0, i64 0
  %r3392 = ptrtoint i8* %r3391 to i64
  %r3393 = call i64 @_add(i64 %r3390, i64 %r3392)
  %r3394 = load i64, i64* %ptr_NL
  %r3395 = call i64 @_add(i64 %r3393, i64 %r3394)
  store i64 %r3395, i64* %ptr_s
  %r3396 = load i64, i64* %ptr_s
  %r3397 = getelementptr [38 x i8], [38 x i8]* @.str.1266, i64 0, i64 0
  %r3398 = ptrtoint i8* %r3397 to i64
  %r3399 = call i64 @_add(i64 %r3396, i64 %r3398)
  %r3400 = load i64, i64* %ptr_NL
  %r3401 = call i64 @_add(i64 %r3399, i64 %r3400)
  store i64 %r3401, i64* %ptr_s
  %r3402 = load i64, i64* %ptr_s
  %r3403 = getelementptr [45 x i8], [45 x i8]* @.str.1267, i64 0, i64 0
  %r3404 = ptrtoint i8* %r3403 to i64
  %r3405 = call i64 @_add(i64 %r3402, i64 %r3404)
  %r3406 = load i64, i64* %ptr_NL
  %r3407 = call i64 @_add(i64 %r3405, i64 %r3406)
  store i64 %r3407, i64* %ptr_s
  %r3408 = load i64, i64* %ptr_s
  %r3409 = getelementptr [17 x i8], [17 x i8]* @.str.1268, i64 0, i64 0
  %r3410 = ptrtoint i8* %r3409 to i64
  %r3411 = call i64 @_add(i64 %r3408, i64 %r3410)
  %r3412 = load i64, i64* %ptr_NL
  %r3413 = call i64 @_add(i64 %r3411, i64 %r3412)
  store i64 %r3413, i64* %ptr_s
  %r3414 = load i64, i64* %ptr_s
  %r3415 = getelementptr [6 x i8], [6 x i8]* @.str.1269, i64 0, i64 0
  %r3416 = ptrtoint i8* %r3415 to i64
  %r3417 = call i64 @_add(i64 %r3414, i64 %r3416)
  %r3418 = load i64, i64* %ptr_NL
  %r3419 = call i64 @_add(i64 %r3417, i64 %r3418)
  store i64 %r3419, i64* %ptr_s
  %r3420 = load i64, i64* %ptr_s
  %r3421 = getelementptr [48 x i8], [48 x i8]* @.str.1270, i64 0, i64 0
  %r3422 = ptrtoint i8* %r3421 to i64
  %r3423 = call i64 @_add(i64 %r3420, i64 %r3422)
  %r3424 = load i64, i64* %ptr_NL
  %r3425 = call i64 @_add(i64 %r3423, i64 %r3424)
  store i64 %r3425, i64* %ptr_s
  %r3426 = load i64, i64* %ptr_s
  %r3427 = getelementptr [37 x i8], [37 x i8]* @.str.1271, i64 0, i64 0
  %r3428 = ptrtoint i8* %r3427 to i64
  %r3429 = call i64 @_add(i64 %r3426, i64 %r3428)
  %r3430 = load i64, i64* %ptr_NL
  %r3431 = call i64 @_add(i64 %r3429, i64 %r3430)
  store i64 %r3431, i64* %ptr_s
  %r3432 = load i64, i64* %ptr_s
  %r3433 = getelementptr [43 x i8], [43 x i8]* @.str.1272, i64 0, i64 0
  %r3434 = ptrtoint i8* %r3433 to i64
  %r3435 = call i64 @_add(i64 %r3432, i64 %r3434)
  %r3436 = load i64, i64* %ptr_NL
  %r3437 = call i64 @_add(i64 %r3435, i64 %r3436)
  store i64 %r3437, i64* %ptr_s
  %r3438 = load i64, i64* %ptr_s
  %r3439 = getelementptr [6 x i8], [6 x i8]* @.str.1273, i64 0, i64 0
  %r3440 = ptrtoint i8* %r3439 to i64
  %r3441 = call i64 @_add(i64 %r3438, i64 %r3440)
  %r3442 = load i64, i64* %ptr_NL
  %r3443 = call i64 @_add(i64 %r3441, i64 %r3442)
  store i64 %r3443, i64* %ptr_s
  %r3444 = load i64, i64* %ptr_s
  %r3445 = getelementptr [37 x i8], [37 x i8]* @.str.1274, i64 0, i64 0
  %r3446 = ptrtoint i8* %r3445 to i64
  %r3447 = call i64 @_add(i64 %r3444, i64 %r3446)
  %r3448 = load i64, i64* %ptr_NL
  %r3449 = call i64 @_add(i64 %r3447, i64 %r3448)
  store i64 %r3449, i64* %ptr_s
  %r3450 = load i64, i64* %ptr_s
  %r3451 = getelementptr [46 x i8], [46 x i8]* @.str.1275, i64 0, i64 0
  %r3452 = ptrtoint i8* %r3451 to i64
  %r3453 = call i64 @_add(i64 %r3450, i64 %r3452)
  %r3454 = load i64, i64* %ptr_NL
  %r3455 = call i64 @_add(i64 %r3453, i64 %r3454)
  store i64 %r3455, i64* %ptr_s
  %r3456 = load i64, i64* %ptr_s
  %r3457 = getelementptr [46 x i8], [46 x i8]* @.str.1276, i64 0, i64 0
  %r3458 = ptrtoint i8* %r3457 to i64
  %r3459 = call i64 @_add(i64 %r3456, i64 %r3458)
  %r3460 = load i64, i64* %ptr_NL
  %r3461 = call i64 @_add(i64 %r3459, i64 %r3460)
  store i64 %r3461, i64* %ptr_s
  %r3462 = load i64, i64* %ptr_s
  %r3463 = getelementptr [17 x i8], [17 x i8]* @.str.1277, i64 0, i64 0
  %r3464 = ptrtoint i8* %r3463 to i64
  %r3465 = call i64 @_add(i64 %r3462, i64 %r3464)
  %r3466 = load i64, i64* %ptr_NL
  %r3467 = call i64 @_add(i64 %r3465, i64 %r3466)
  store i64 %r3467, i64* %ptr_s
  %r3468 = load i64, i64* %ptr_s
  %r3469 = getelementptr [6 x i8], [6 x i8]* @.str.1278, i64 0, i64 0
  %r3470 = ptrtoint i8* %r3469 to i64
  %r3471 = call i64 @_add(i64 %r3468, i64 %r3470)
  %r3472 = load i64, i64* %ptr_NL
  %r3473 = call i64 @_add(i64 %r3471, i64 %r3472)
  store i64 %r3473, i64* %ptr_s
  %r3474 = load i64, i64* %ptr_s
  %r3475 = getelementptr [16 x i8], [16 x i8]* @.str.1279, i64 0, i64 0
  %r3476 = ptrtoint i8* %r3475 to i64
  %r3477 = call i64 @_add(i64 %r3474, i64 %r3476)
  %r3478 = load i64, i64* %ptr_NL
  %r3479 = call i64 @_add(i64 %r3477, i64 %r3478)
  store i64 %r3479, i64* %ptr_s
  %r3480 = load i64, i64* %ptr_s
  %r3481 = getelementptr [2 x i8], [2 x i8]* @.str.1280, i64 0, i64 0
  %r3482 = ptrtoint i8* %r3481 to i64
  %r3483 = call i64 @_add(i64 %r3480, i64 %r3482)
  %r3484 = load i64, i64* %ptr_NL
  %r3485 = call i64 @_add(i64 %r3483, i64 %r3484)
  store i64 %r3485, i64* %ptr_s
  br label %L1033
L1033:
  %r3486 = load i64, i64* %ptr_s
  %r3487 = getelementptr [50 x i8], [50 x i8]* @.str.1281, i64 0, i64 0
  %r3488 = ptrtoint i8* %r3487 to i64
  %r3489 = call i64 @_add(i64 %r3486, i64 %r3488)
  %r3490 = load i64, i64* %ptr_NL
  %r3491 = call i64 @_add(i64 %r3489, i64 %r3490)
  store i64 %r3491, i64* %ptr_s
  %r3492 = load i64, i64* %ptr_s
  %r3493 = getelementptr [38 x i8], [38 x i8]* @.str.1282, i64 0, i64 0
  %r3494 = ptrtoint i8* %r3493 to i64
  %r3495 = call i64 @_add(i64 %r3492, i64 %r3494)
  %r3496 = load i64, i64* %ptr_NL
  %r3497 = call i64 @_add(i64 %r3495, i64 %r3496)
  store i64 %r3497, i64* %ptr_s
  %r3498 = load i64, i64* %ptr_s
  %r3499 = getelementptr [49 x i8], [49 x i8]* @.str.1283, i64 0, i64 0
  %r3500 = ptrtoint i8* %r3499 to i64
  %r3501 = call i64 @_add(i64 %r3498, i64 %r3500)
  %r3502 = load i64, i64* %ptr_NL
  %r3503 = call i64 @_add(i64 %r3501, i64 %r3502)
  store i64 %r3503, i64* %ptr_s
  %r3504 = load i64, i64* %ptr_s
  %r3505 = getelementptr [7 x i8], [7 x i8]* @.str.1284, i64 0, i64 0
  %r3506 = ptrtoint i8* %r3505 to i64
  %r3507 = call i64 @_add(i64 %r3504, i64 %r3506)
  %r3508 = load i64, i64* %ptr_NL
  %r3509 = call i64 @_add(i64 %r3507, i64 %r3508)
  store i64 %r3509, i64* %ptr_s
  %r3510 = load i64, i64* %ptr_s
  %r3511 = getelementptr [42 x i8], [42 x i8]* @.str.1285, i64 0, i64 0
  %r3512 = ptrtoint i8* %r3511 to i64
  %r3513 = call i64 @_add(i64 %r3510, i64 %r3512)
  %r3514 = load i64, i64* %ptr_NL
  %r3515 = call i64 @_add(i64 %r3513, i64 %r3514)
  store i64 %r3515, i64* %ptr_s
  %r3516 = load i64, i64* %ptr_s
  %r3517 = getelementptr [51 x i8], [51 x i8]* @.str.1286, i64 0, i64 0
  %r3518 = ptrtoint i8* %r3517 to i64
  %r3519 = call i64 @_add(i64 %r3516, i64 %r3518)
  %r3520 = load i64, i64* %ptr_NL
  %r3521 = call i64 @_add(i64 %r3519, i64 %r3520)
  store i64 %r3521, i64* %ptr_s
  %r3522 = load i64, i64* %ptr_s
  %r3523 = getelementptr [33 x i8], [33 x i8]* @.str.1287, i64 0, i64 0
  %r3524 = ptrtoint i8* %r3523 to i64
  %r3525 = call i64 @_add(i64 %r3522, i64 %r3524)
  %r3526 = load i64, i64* %ptr_NL
  %r3527 = call i64 @_add(i64 %r3525, i64 %r3526)
  store i64 %r3527, i64* %ptr_s
  %r3528 = load i64, i64* %ptr_s
  %r3529 = getelementptr [34 x i8], [34 x i8]* @.str.1288, i64 0, i64 0
  %r3530 = ptrtoint i8* %r3529 to i64
  %r3531 = call i64 @_add(i64 %r3528, i64 %r3530)
  %r3532 = load i64, i64* %ptr_NL
  %r3533 = call i64 @_add(i64 %r3531, i64 %r3532)
  store i64 %r3533, i64* %ptr_s
  %r3534 = load i64, i64* %ptr_s
  %r3535 = getelementptr [49 x i8], [49 x i8]* @.str.1289, i64 0, i64 0
  %r3536 = ptrtoint i8* %r3535 to i64
  %r3537 = call i64 @_add(i64 %r3534, i64 %r3536)
  %r3538 = load i64, i64* %ptr_NL
  %r3539 = call i64 @_add(i64 %r3537, i64 %r3538)
  store i64 %r3539, i64* %ptr_s
  %r3540 = load i64, i64* %ptr_s
  %r3541 = getelementptr [11 x i8], [11 x i8]* @.str.1290, i64 0, i64 0
  %r3542 = ptrtoint i8* %r3541 to i64
  %r3543 = call i64 @_add(i64 %r3540, i64 %r3542)
  %r3544 = load i64, i64* %ptr_NL
  %r3545 = call i64 @_add(i64 %r3543, i64 %r3544)
  store i64 %r3545, i64* %ptr_s
  %r3546 = load i64, i64* %ptr_s
  %r3547 = getelementptr [33 x i8], [33 x i8]* @.str.1291, i64 0, i64 0
  %r3548 = ptrtoint i8* %r3547 to i64
  %r3549 = call i64 @_add(i64 %r3546, i64 %r3548)
  %r3550 = load i64, i64* %ptr_NL
  %r3551 = call i64 @_add(i64 %r3549, i64 %r3550)
  store i64 %r3551, i64* %ptr_s
  %r3552 = load i64, i64* %ptr_s
  %r3553 = getelementptr [36 x i8], [36 x i8]* @.str.1292, i64 0, i64 0
  %r3554 = ptrtoint i8* %r3553 to i64
  %r3555 = call i64 @_add(i64 %r3552, i64 %r3554)
  %r3556 = load i64, i64* %ptr_NL
  %r3557 = call i64 @_add(i64 %r3555, i64 %r3556)
  store i64 %r3557, i64* %ptr_s
  %r3558 = load i64, i64* %ptr_s
  %r3559 = getelementptr [25 x i8], [25 x i8]* @.str.1293, i64 0, i64 0
  %r3560 = ptrtoint i8* %r3559 to i64
  %r3561 = call i64 @_add(i64 %r3558, i64 %r3560)
  %r3562 = load i64, i64* %ptr_NL
  %r3563 = call i64 @_add(i64 %r3561, i64 %r3562)
  store i64 %r3563, i64* %ptr_s
  %r3564 = load i64, i64* %ptr_s
  %r3565 = getelementptr [15 x i8], [15 x i8]* @.str.1294, i64 0, i64 0
  %r3566 = ptrtoint i8* %r3565 to i64
  %r3567 = call i64 @_add(i64 %r3564, i64 %r3566)
  %r3568 = load i64, i64* %ptr_NL
  %r3569 = call i64 @_add(i64 %r3567, i64 %r3568)
  store i64 %r3569, i64* %ptr_s
  %r3570 = load i64, i64* %ptr_s
  %r3571 = getelementptr [6 x i8], [6 x i8]* @.str.1295, i64 0, i64 0
  %r3572 = ptrtoint i8* %r3571 to i64
  %r3573 = call i64 @_add(i64 %r3570, i64 %r3572)
  %r3574 = load i64, i64* %ptr_NL
  %r3575 = call i64 @_add(i64 %r3573, i64 %r3574)
  store i64 %r3575, i64* %ptr_s
  %r3576 = load i64, i64* %ptr_s
  %r3577 = getelementptr [52 x i8], [52 x i8]* @.str.1296, i64 0, i64 0
  %r3578 = ptrtoint i8* %r3577 to i64
  %r3579 = call i64 @_add(i64 %r3576, i64 %r3578)
  %r3580 = load i64, i64* %ptr_NL
  %r3581 = call i64 @_add(i64 %r3579, i64 %r3580)
  store i64 %r3581, i64* %ptr_s
  %r3582 = load i64, i64* %ptr_s
  %r3583 = getelementptr [35 x i8], [35 x i8]* @.str.1297, i64 0, i64 0
  %r3584 = ptrtoint i8* %r3583 to i64
  %r3585 = call i64 @_add(i64 %r3582, i64 %r3584)
  %r3586 = load i64, i64* %ptr_NL
  %r3587 = call i64 @_add(i64 %r3585, i64 %r3586)
  store i64 %r3587, i64* %ptr_s
  %r3588 = load i64, i64* %ptr_s
  %r3589 = getelementptr [41 x i8], [41 x i8]* @.str.1298, i64 0, i64 0
  %r3590 = ptrtoint i8* %r3589 to i64
  %r3591 = call i64 @_add(i64 %r3588, i64 %r3590)
  %r3592 = load i64, i64* %ptr_NL
  %r3593 = call i64 @_add(i64 %r3591, i64 %r3592)
  store i64 %r3593, i64* %ptr_s
  %r3594 = load i64, i64* %ptr_s
  %r3595 = getelementptr [35 x i8], [35 x i8]* @.str.1299, i64 0, i64 0
  %r3596 = ptrtoint i8* %r3595 to i64
  %r3597 = call i64 @_add(i64 %r3594, i64 %r3596)
  %r3598 = load i64, i64* %ptr_NL
  %r3599 = call i64 @_add(i64 %r3597, i64 %r3598)
  store i64 %r3599, i64* %ptr_s
  %r3600 = load i64, i64* %ptr_s
  %r3601 = getelementptr [40 x i8], [40 x i8]* @.str.1300, i64 0, i64 0
  %r3602 = ptrtoint i8* %r3601 to i64
  %r3603 = call i64 @_add(i64 %r3600, i64 %r3602)
  %r3604 = load i64, i64* %ptr_NL
  %r3605 = call i64 @_add(i64 %r3603, i64 %r3604)
  store i64 %r3605, i64* %ptr_s
  %r3606 = load i64, i64* %ptr_s
  %r3607 = getelementptr [27 x i8], [27 x i8]* @.str.1301, i64 0, i64 0
  %r3608 = ptrtoint i8* %r3607 to i64
  %r3609 = call i64 @_add(i64 %r3606, i64 %r3608)
  %r3610 = load i64, i64* %ptr_NL
  %r3611 = call i64 @_add(i64 %r3609, i64 %r3610)
  store i64 %r3611, i64* %ptr_s
  %r3612 = load i64, i64* %ptr_s
  %r3613 = getelementptr [17 x i8], [17 x i8]* @.str.1302, i64 0, i64 0
  %r3614 = ptrtoint i8* %r3613 to i64
  %r3615 = call i64 @_add(i64 %r3612, i64 %r3614)
  %r3616 = load i64, i64* %ptr_NL
  %r3617 = call i64 @_add(i64 %r3615, i64 %r3616)
  store i64 %r3617, i64* %ptr_s
  %r3618 = load i64, i64* %ptr_s
  %r3619 = getelementptr [6 x i8], [6 x i8]* @.str.1303, i64 0, i64 0
  %r3620 = ptrtoint i8* %r3619 to i64
  %r3621 = call i64 @_add(i64 %r3618, i64 %r3620)
  %r3622 = load i64, i64* %ptr_NL
  %r3623 = call i64 @_add(i64 %r3621, i64 %r3622)
  store i64 %r3623, i64* %ptr_s
  %r3624 = load i64, i64* %ptr_s
  %r3625 = getelementptr [49 x i8], [49 x i8]* @.str.1304, i64 0, i64 0
  %r3626 = ptrtoint i8* %r3625 to i64
  %r3627 = call i64 @_add(i64 %r3624, i64 %r3626)
  %r3628 = load i64, i64* %ptr_NL
  %r3629 = call i64 @_add(i64 %r3627, i64 %r3628)
  store i64 %r3629, i64* %ptr_s
  %r3630 = load i64, i64* %ptr_s
  %r3631 = getelementptr [63 x i8], [63 x i8]* @.str.1305, i64 0, i64 0
  %r3632 = ptrtoint i8* %r3631 to i64
  %r3633 = call i64 @_add(i64 %r3630, i64 %r3632)
  %r3634 = load i64, i64* %ptr_NL
  %r3635 = call i64 @_add(i64 %r3633, i64 %r3634)
  store i64 %r3635, i64* %ptr_s
  %r3636 = load i64, i64* %ptr_s
  %r3637 = getelementptr [32 x i8], [32 x i8]* @.str.1306, i64 0, i64 0
  %r3638 = ptrtoint i8* %r3637 to i64
  %r3639 = call i64 @_add(i64 %r3636, i64 %r3638)
  %r3640 = load i64, i64* %ptr_NL
  %r3641 = call i64 @_add(i64 %r3639, i64 %r3640)
  store i64 %r3641, i64* %ptr_s
  %r3642 = load i64, i64* %ptr_s
  %r3643 = getelementptr [40 x i8], [40 x i8]* @.str.1307, i64 0, i64 0
  %r3644 = ptrtoint i8* %r3643 to i64
  %r3645 = call i64 @_add(i64 %r3642, i64 %r3644)
  %r3646 = load i64, i64* %ptr_NL
  %r3647 = call i64 @_add(i64 %r3645, i64 %r3646)
  store i64 %r3647, i64* %ptr_s
  %r3648 = load i64, i64* %ptr_s
  %r3649 = getelementptr [6 x i8], [6 x i8]* @.str.1308, i64 0, i64 0
  %r3650 = ptrtoint i8* %r3649 to i64
  %r3651 = call i64 @_add(i64 %r3648, i64 %r3650)
  %r3652 = load i64, i64* %ptr_NL
  %r3653 = call i64 @_add(i64 %r3651, i64 %r3652)
  store i64 %r3653, i64* %ptr_s
  %r3654 = load i64, i64* %ptr_s
  %r3655 = getelementptr [52 x i8], [52 x i8]* @.str.1309, i64 0, i64 0
  %r3656 = ptrtoint i8* %r3655 to i64
  %r3657 = call i64 @_add(i64 %r3654, i64 %r3656)
  %r3658 = load i64, i64* %ptr_NL
  %r3659 = call i64 @_add(i64 %r3657, i64 %r3658)
  store i64 %r3659, i64* %ptr_s
  %r3660 = load i64, i64* %ptr_s
  %r3661 = getelementptr [31 x i8], [31 x i8]* @.str.1310, i64 0, i64 0
  %r3662 = ptrtoint i8* %r3661 to i64
  %r3663 = call i64 @_add(i64 %r3660, i64 %r3662)
  %r3664 = load i64, i64* %ptr_NL
  %r3665 = call i64 @_add(i64 %r3663, i64 %r3664)
  store i64 %r3665, i64* %ptr_s
  %r3666 = load i64, i64* %ptr_s
  %r3667 = getelementptr [43 x i8], [43 x i8]* @.str.1311, i64 0, i64 0
  %r3668 = ptrtoint i8* %r3667 to i64
  %r3669 = call i64 @_add(i64 %r3666, i64 %r3668)
  %r3670 = load i64, i64* %ptr_NL
  %r3671 = call i64 @_add(i64 %r3669, i64 %r3670)
  store i64 %r3671, i64* %ptr_s
  %r3672 = load i64, i64* %ptr_s
  %r3673 = getelementptr [58 x i8], [58 x i8]* @.str.1312, i64 0, i64 0
  %r3674 = ptrtoint i8* %r3673 to i64
  %r3675 = call i64 @_add(i64 %r3672, i64 %r3674)
  %r3676 = load i64, i64* %ptr_NL
  %r3677 = call i64 @_add(i64 %r3675, i64 %r3676)
  store i64 %r3677, i64* %ptr_s
  %r3678 = load i64, i64* %ptr_s
  %r3679 = getelementptr [30 x i8], [30 x i8]* @.str.1313, i64 0, i64 0
  %r3680 = ptrtoint i8* %r3679 to i64
  %r3681 = call i64 @_add(i64 %r3678, i64 %r3680)
  %r3682 = load i64, i64* %ptr_NL
  %r3683 = call i64 @_add(i64 %r3681, i64 %r3682)
  store i64 %r3683, i64* %ptr_s
  %r3684 = load i64, i64* %ptr_s
  %r3685 = getelementptr [39 x i8], [39 x i8]* @.str.1314, i64 0, i64 0
  %r3686 = ptrtoint i8* %r3685 to i64
  %r3687 = call i64 @_add(i64 %r3684, i64 %r3686)
  %r3688 = load i64, i64* %ptr_NL
  %r3689 = call i64 @_add(i64 %r3687, i64 %r3688)
  store i64 %r3689, i64* %ptr_s
  %r3690 = load i64, i64* %ptr_s
  %r3691 = getelementptr [54 x i8], [54 x i8]* @.str.1315, i64 0, i64 0
  %r3692 = ptrtoint i8* %r3691 to i64
  %r3693 = call i64 @_add(i64 %r3690, i64 %r3692)
  %r3694 = load i64, i64* %ptr_NL
  %r3695 = call i64 @_add(i64 %r3693, i64 %r3694)
  store i64 %r3695, i64* %ptr_s
  %r3696 = load i64, i64* %ptr_s
  %r3697 = getelementptr [11 x i8], [11 x i8]* @.str.1316, i64 0, i64 0
  %r3698 = ptrtoint i8* %r3697 to i64
  %r3699 = call i64 @_add(i64 %r3696, i64 %r3698)
  %r3700 = load i64, i64* %ptr_NL
  %r3701 = call i64 @_add(i64 %r3699, i64 %r3700)
  store i64 %r3701, i64* %ptr_s
  %r3702 = load i64, i64* %ptr_s
  %r3703 = getelementptr [59 x i8], [59 x i8]* @.str.1317, i64 0, i64 0
  %r3704 = ptrtoint i8* %r3703 to i64
  %r3705 = call i64 @_add(i64 %r3702, i64 %r3704)
  %r3706 = load i64, i64* %ptr_NL
  %r3707 = call i64 @_add(i64 %r3705, i64 %r3706)
  store i64 %r3707, i64* %ptr_s
  %r3708 = load i64, i64* %ptr_s
  %r3709 = getelementptr [18 x i8], [18 x i8]* @.str.1318, i64 0, i64 0
  %r3710 = ptrtoint i8* %r3709 to i64
  %r3711 = call i64 @_add(i64 %r3708, i64 %r3710)
  %r3712 = load i64, i64* %ptr_NL
  %r3713 = call i64 @_add(i64 %r3711, i64 %r3712)
  store i64 %r3713, i64* %ptr_s
  %r3714 = load i64, i64* %ptr_s
  %r3715 = getelementptr [12 x i8], [12 x i8]* @.str.1319, i64 0, i64 0
  %r3716 = ptrtoint i8* %r3715 to i64
  %r3717 = call i64 @_add(i64 %r3714, i64 %r3716)
  %r3718 = load i64, i64* %ptr_NL
  %r3719 = call i64 @_add(i64 %r3717, i64 %r3718)
  store i64 %r3719, i64* %ptr_s
  %r3720 = load i64, i64* %ptr_s
  %r3721 = getelementptr [18 x i8], [18 x i8]* @.str.1320, i64 0, i64 0
  %r3722 = ptrtoint i8* %r3721 to i64
  %r3723 = call i64 @_add(i64 %r3720, i64 %r3722)
  %r3724 = load i64, i64* %ptr_NL
  %r3725 = call i64 @_add(i64 %r3723, i64 %r3724)
  store i64 %r3725, i64* %ptr_s
  %r3726 = load i64, i64* %ptr_s
  %r3727 = getelementptr [7 x i8], [7 x i8]* @.str.1321, i64 0, i64 0
  %r3728 = ptrtoint i8* %r3727 to i64
  %r3729 = call i64 @_add(i64 %r3726, i64 %r3728)
  %r3730 = load i64, i64* %ptr_NL
  %r3731 = call i64 @_add(i64 %r3729, i64 %r3730)
  store i64 %r3731, i64* %ptr_s
  %r3732 = load i64, i64* %ptr_s
  %r3733 = getelementptr [75 x i8], [75 x i8]* @.str.1322, i64 0, i64 0
  %r3734 = ptrtoint i8* %r3733 to i64
  %r3735 = call i64 @_add(i64 %r3732, i64 %r3734)
  %r3736 = load i64, i64* %ptr_NL
  %r3737 = call i64 @_add(i64 %r3735, i64 %r3736)
  store i64 %r3737, i64* %ptr_s
  %r3738 = load i64, i64* %ptr_s
  %r3739 = getelementptr [26 x i8], [26 x i8]* @.str.1323, i64 0, i64 0
  %r3740 = ptrtoint i8* %r3739 to i64
  %r3741 = call i64 @_add(i64 %r3738, i64 %r3740)
  %r3742 = load i64, i64* %ptr_NL
  %r3743 = call i64 @_add(i64 %r3741, i64 %r3742)
  store i64 %r3743, i64* %ptr_s
  %r3744 = load i64, i64* %ptr_s
  %r3745 = getelementptr [17 x i8], [17 x i8]* @.str.1324, i64 0, i64 0
  %r3746 = ptrtoint i8* %r3745 to i64
  %r3747 = call i64 @_add(i64 %r3744, i64 %r3746)
  %r3748 = load i64, i64* %ptr_NL
  %r3749 = call i64 @_add(i64 %r3747, i64 %r3748)
  store i64 %r3749, i64* %ptr_s
  %r3750 = load i64, i64* %ptr_s
  %r3751 = getelementptr [6 x i8], [6 x i8]* @.str.1325, i64 0, i64 0
  %r3752 = ptrtoint i8* %r3751 to i64
  %r3753 = call i64 @_add(i64 %r3750, i64 %r3752)
  %r3754 = load i64, i64* %ptr_NL
  %r3755 = call i64 @_add(i64 %r3753, i64 %r3754)
  store i64 %r3755, i64* %ptr_s
  %r3756 = load i64, i64* %ptr_s
  %r3757 = getelementptr [20 x i8], [20 x i8]* @.str.1326, i64 0, i64 0
  %r3758 = ptrtoint i8* %r3757 to i64
  %r3759 = call i64 @_add(i64 %r3756, i64 %r3758)
  %r3760 = load i64, i64* %ptr_NL
  %r3761 = call i64 @_add(i64 %r3759, i64 %r3760)
  store i64 %r3761, i64* %ptr_s
  %r3762 = load i64, i64* %ptr_s
  %r3763 = getelementptr [2 x i8], [2 x i8]* @.str.1327, i64 0, i64 0
  %r3764 = ptrtoint i8* %r3763 to i64
  %r3765 = call i64 @_add(i64 %r3762, i64 %r3764)
  %r3766 = load i64, i64* %ptr_NL
  %r3767 = call i64 @_add(i64 %r3765, i64 %r3766)
  store i64 %r3767, i64* %ptr_s
  %r3768 = load i64, i64* %ptr_s
  %r3769 = getelementptr [90 x i8], [90 x i8]* @.str.1328, i64 0, i64 0
  %r3770 = ptrtoint i8* %r3769 to i64
  %r3771 = call i64 @_add(i64 %r3768, i64 %r3770)
  %r3772 = load i64, i64* %ptr_NL
  %r3773 = call i64 @_add(i64 %r3771, i64 %r3772)
  store i64 %r3773, i64* %ptr_s
  %r3774 = load i64, i64* %ptr_s
  %r3775 = getelementptr [184 x i8], [184 x i8]* @.str.1329, i64 0, i64 0
  %r3776 = ptrtoint i8* %r3775 to i64
  %r3777 = call i64 @_add(i64 %r3774, i64 %r3776)
  %r3778 = load i64, i64* %ptr_NL
  %r3779 = call i64 @_add(i64 %r3777, i64 %r3778)
  store i64 %r3779, i64* %ptr_s
  %r3780 = load i64, i64* %ptr_s
  %r3781 = getelementptr [15 x i8], [15 x i8]* @.str.1330, i64 0, i64 0
  %r3782 = ptrtoint i8* %r3781 to i64
  %r3783 = call i64 @_add(i64 %r3780, i64 %r3782)
  %r3784 = load i64, i64* %ptr_NL
  %r3785 = call i64 @_add(i64 %r3783, i64 %r3784)
  store i64 %r3785, i64* %ptr_s
  %r3786 = load i64, i64* %ptr_s
  %r3787 = getelementptr [2 x i8], [2 x i8]* @.str.1331, i64 0, i64 0
  %r3788 = ptrtoint i8* %r3787 to i64
  %r3789 = call i64 @_add(i64 %r3786, i64 %r3788)
  %r3790 = load i64, i64* %ptr_NL
  %r3791 = call i64 @_add(i64 %r3789, i64 %r3790)
  store i64 %r3791, i64* %ptr_s
  %r3792 = load i64, i64* %ptr_s
  %r3793 = getelementptr [31 x i8], [31 x i8]* @.str.1332, i64 0, i64 0
  %r3794 = ptrtoint i8* %r3793 to i64
  %r3795 = call i64 @_add(i64 %r3792, i64 %r3794)
  %r3796 = load i64, i64* %ptr_NL
  %r3797 = call i64 @_add(i64 %r3795, i64 %r3796)
  store i64 %r3797, i64* %ptr_s
  %r3798 = load i64, i64* %ptr_s
  %r3799 = getelementptr [22 x i8], [22 x i8]* @.str.1333, i64 0, i64 0
  %r3800 = ptrtoint i8* %r3799 to i64
  %r3801 = call i64 @_add(i64 %r3798, i64 %r3800)
  %r3802 = load i64, i64* %ptr_NL
  %r3803 = call i64 @_add(i64 %r3801, i64 %r3802)
  store i64 %r3803, i64* %ptr_s
  %r3804 = load i64, i64* %ptr_s
  %r3805 = getelementptr [6 x i8], [6 x i8]* @.str.1334, i64 0, i64 0
  %r3806 = ptrtoint i8* %r3805 to i64
  %r3807 = call i64 @_add(i64 %r3804, i64 %r3806)
  %r3808 = load i64, i64* %ptr_NL
  %r3809 = call i64 @_add(i64 %r3807, i64 %r3808)
  store i64 %r3809, i64* %ptr_s
  %r3810 = load i64, i64* %ptr_s
  %r3811 = getelementptr [46 x i8], [46 x i8]* @.str.1335, i64 0, i64 0
  %r3812 = ptrtoint i8* %r3811 to i64
  %r3813 = call i64 @_add(i64 %r3810, i64 %r3812)
  %r3814 = load i64, i64* %ptr_NL
  %r3815 = call i64 @_add(i64 %r3813, i64 %r3814)
  store i64 %r3815, i64* %ptr_s
  %r3816 = load i64, i64* %ptr_s
  %r3817 = getelementptr [44 x i8], [44 x i8]* @.str.1336, i64 0, i64 0
  %r3818 = ptrtoint i8* %r3817 to i64
  %r3819 = call i64 @_add(i64 %r3816, i64 %r3818)
  %r3820 = load i64, i64* %ptr_NL
  %r3821 = call i64 @_add(i64 %r3819, i64 %r3820)
  store i64 %r3821, i64* %ptr_s
  %r3822 = load i64, i64* %ptr_s
  %r3823 = getelementptr [25 x i8], [25 x i8]* @.str.1337, i64 0, i64 0
  %r3824 = ptrtoint i8* %r3823 to i64
  %r3825 = call i64 @_add(i64 %r3822, i64 %r3824)
  %r3826 = load i64, i64* %ptr_NL
  %r3827 = call i64 @_add(i64 %r3825, i64 %r3826)
  store i64 %r3827, i64* %ptr_s
  %r3828 = load i64, i64* %ptr_s
  %r3829 = getelementptr [30 x i8], [30 x i8]* @.str.1338, i64 0, i64 0
  %r3830 = ptrtoint i8* %r3829 to i64
  %r3831 = call i64 @_add(i64 %r3828, i64 %r3830)
  %r3832 = load i64, i64* %ptr_NL
  %r3833 = call i64 @_add(i64 %r3831, i64 %r3832)
  store i64 %r3833, i64* %ptr_s
  %r3834 = load i64, i64* %ptr_s
  %r3835 = getelementptr [23 x i8], [23 x i8]* @.str.1339, i64 0, i64 0
  %r3836 = ptrtoint i8* %r3835 to i64
  %r3837 = call i64 @_add(i64 %r3834, i64 %r3836)
  %r3838 = load i64, i64* %ptr_NL
  %r3839 = call i64 @_add(i64 %r3837, i64 %r3838)
  store i64 %r3839, i64* %ptr_s
  %r3840 = load i64, i64* %ptr_s
  %r3841 = getelementptr [43 x i8], [43 x i8]* @.str.1340, i64 0, i64 0
  %r3842 = ptrtoint i8* %r3841 to i64
  %r3843 = call i64 @_add(i64 %r3840, i64 %r3842)
  %r3844 = load i64, i64* %ptr_NL
  %r3845 = call i64 @_add(i64 %r3843, i64 %r3844)
  store i64 %r3845, i64* %ptr_s
  %r3846 = load i64, i64* %ptr_s
  %r3847 = getelementptr [17 x i8], [17 x i8]* @.str.1341, i64 0, i64 0
  %r3848 = ptrtoint i8* %r3847 to i64
  %r3849 = call i64 @_add(i64 %r3846, i64 %r3848)
  %r3850 = load i64, i64* %ptr_NL
  %r3851 = call i64 @_add(i64 %r3849, i64 %r3850)
  store i64 %r3851, i64* %ptr_s
  %r3852 = load i64, i64* %ptr_s
  %r3853 = getelementptr [2 x i8], [2 x i8]* @.str.1342, i64 0, i64 0
  %r3854 = ptrtoint i8* %r3853 to i64
  %r3855 = call i64 @_add(i64 %r3852, i64 %r3854)
  %r3856 = load i64, i64* %ptr_NL
  %r3857 = call i64 @_add(i64 %r3855, i64 %r3856)
  store i64 %r3857, i64* %ptr_s
  %r3858 = load i64, i64* %ptr_s
  %r3859 = getelementptr [39 x i8], [39 x i8]* @.str.1343, i64 0, i64 0
  %r3860 = ptrtoint i8* %r3859 to i64
  %r3861 = call i64 @_add(i64 %r3858, i64 %r3860)
  %r3862 = load i64, i64* %ptr_NL
  %r3863 = call i64 @_add(i64 %r3861, i64 %r3862)
  store i64 %r3863, i64* %ptr_s
  %r3864 = load i64, i64* %ptr_s
  %r3865 = getelementptr [22 x i8], [22 x i8]* @.str.1344, i64 0, i64 0
  %r3866 = ptrtoint i8* %r3865 to i64
  %r3867 = call i64 @_add(i64 %r3864, i64 %r3866)
  %r3868 = load i64, i64* %ptr_NL
  %r3869 = call i64 @_add(i64 %r3867, i64 %r3868)
  store i64 %r3869, i64* %ptr_s
  %r3870 = load i64, i64* %ptr_s
  %r3871 = getelementptr [6 x i8], [6 x i8]* @.str.1345, i64 0, i64 0
  %r3872 = ptrtoint i8* %r3871 to i64
  %r3873 = call i64 @_add(i64 %r3870, i64 %r3872)
  %r3874 = load i64, i64* %ptr_NL
  %r3875 = call i64 @_add(i64 %r3873, i64 %r3874)
  store i64 %r3875, i64* %ptr_s
  %r3876 = load i64, i64* %ptr_s
  %r3877 = getelementptr [46 x i8], [46 x i8]* @.str.1346, i64 0, i64 0
  %r3878 = ptrtoint i8* %r3877 to i64
  %r3879 = call i64 @_add(i64 %r3876, i64 %r3878)
  %r3880 = load i64, i64* %ptr_NL
  %r3881 = call i64 @_add(i64 %r3879, i64 %r3880)
  store i64 %r3881, i64* %ptr_s
  %r3882 = load i64, i64* %ptr_s
  %r3883 = getelementptr [42 x i8], [42 x i8]* @.str.1347, i64 0, i64 0
  %r3884 = ptrtoint i8* %r3883 to i64
  %r3885 = call i64 @_add(i64 %r3882, i64 %r3884)
  %r3886 = load i64, i64* %ptr_NL
  %r3887 = call i64 @_add(i64 %r3885, i64 %r3886)
  store i64 %r3887, i64* %ptr_s
  %r3888 = load i64, i64* %ptr_s
  %r3889 = getelementptr [42 x i8], [42 x i8]* @.str.1348, i64 0, i64 0
  %r3890 = ptrtoint i8* %r3889 to i64
  %r3891 = call i64 @_add(i64 %r3888, i64 %r3890)
  %r3892 = load i64, i64* %ptr_NL
  %r3893 = call i64 @_add(i64 %r3891, i64 %r3892)
  store i64 %r3893, i64* %ptr_s
  %r3894 = load i64, i64* %ptr_s
  %r3895 = getelementptr [25 x i8], [25 x i8]* @.str.1349, i64 0, i64 0
  %r3896 = ptrtoint i8* %r3895 to i64
  %r3897 = call i64 @_add(i64 %r3894, i64 %r3896)
  %r3898 = load i64, i64* %ptr_NL
  %r3899 = call i64 @_add(i64 %r3897, i64 %r3898)
  store i64 %r3899, i64* %ptr_s
  %r3900 = load i64, i64* %ptr_s
  %r3901 = getelementptr [25 x i8], [25 x i8]* @.str.1350, i64 0, i64 0
  %r3902 = ptrtoint i8* %r3901 to i64
  %r3903 = call i64 @_add(i64 %r3900, i64 %r3902)
  %r3904 = load i64, i64* %ptr_NL
  %r3905 = call i64 @_add(i64 %r3903, i64 %r3904)
  store i64 %r3905, i64* %ptr_s
  %r3906 = load i64, i64* %ptr_s
  %r3907 = getelementptr [32 x i8], [32 x i8]* @.str.1351, i64 0, i64 0
  %r3908 = ptrtoint i8* %r3907 to i64
  %r3909 = call i64 @_add(i64 %r3906, i64 %r3908)
  %r3910 = load i64, i64* %ptr_NL
  %r3911 = call i64 @_add(i64 %r3909, i64 %r3910)
  store i64 %r3911, i64* %ptr_s
  %r3912 = load i64, i64* %ptr_s
  %r3913 = getelementptr [31 x i8], [31 x i8]* @.str.1352, i64 0, i64 0
  %r3914 = ptrtoint i8* %r3913 to i64
  %r3915 = call i64 @_add(i64 %r3912, i64 %r3914)
  %r3916 = load i64, i64* %ptr_NL
  %r3917 = call i64 @_add(i64 %r3915, i64 %r3916)
  store i64 %r3917, i64* %ptr_s
  %r3918 = load i64, i64* %ptr_s
  %r3919 = getelementptr [34 x i8], [34 x i8]* @.str.1353, i64 0, i64 0
  %r3920 = ptrtoint i8* %r3919 to i64
  %r3921 = call i64 @_add(i64 %r3918, i64 %r3920)
  %r3922 = load i64, i64* %ptr_NL
  %r3923 = call i64 @_add(i64 %r3921, i64 %r3922)
  store i64 %r3923, i64* %ptr_s
  %r3924 = load i64, i64* %ptr_s
  %r3925 = getelementptr [23 x i8], [23 x i8]* @.str.1354, i64 0, i64 0
  %r3926 = ptrtoint i8* %r3925 to i64
  %r3927 = call i64 @_add(i64 %r3924, i64 %r3926)
  %r3928 = load i64, i64* %ptr_NL
  %r3929 = call i64 @_add(i64 %r3927, i64 %r3928)
  store i64 %r3929, i64* %ptr_s
  %r3930 = load i64, i64* %ptr_s
  %r3931 = getelementptr [40 x i8], [40 x i8]* @.str.1355, i64 0, i64 0
  %r3932 = ptrtoint i8* %r3931 to i64
  %r3933 = call i64 @_add(i64 %r3930, i64 %r3932)
  %r3934 = load i64, i64* %ptr_NL
  %r3935 = call i64 @_add(i64 %r3933, i64 %r3934)
  store i64 %r3935, i64* %ptr_s
  %r3936 = load i64, i64* %ptr_s
  %r3937 = getelementptr [6 x i8], [6 x i8]* @.str.1356, i64 0, i64 0
  %r3938 = ptrtoint i8* %r3937 to i64
  %r3939 = call i64 @_add(i64 %r3936, i64 %r3938)
  %r3940 = load i64, i64* %ptr_NL
  %r3941 = call i64 @_add(i64 %r3939, i64 %r3940)
  store i64 %r3941, i64* %ptr_s
  %r3942 = load i64, i64* %ptr_s
  %r3943 = getelementptr [27 x i8], [27 x i8]* @.str.1357, i64 0, i64 0
  %r3944 = ptrtoint i8* %r3943 to i64
  %r3945 = call i64 @_add(i64 %r3942, i64 %r3944)
  %r3946 = load i64, i64* %ptr_NL
  %r3947 = call i64 @_add(i64 %r3945, i64 %r3946)
  store i64 %r3947, i64* %ptr_s
  %r3948 = load i64, i64* %ptr_s
  %r3949 = getelementptr [27 x i8], [27 x i8]* @.str.1358, i64 0, i64 0
  %r3950 = ptrtoint i8* %r3949 to i64
  %r3951 = call i64 @_add(i64 %r3948, i64 %r3950)
  %r3952 = load i64, i64* %ptr_NL
  %r3953 = call i64 @_add(i64 %r3951, i64 %r3952)
  store i64 %r3953, i64* %ptr_s
  %r3954 = load i64, i64* %ptr_s
  %r3955 = getelementptr [27 x i8], [27 x i8]* @.str.1359, i64 0, i64 0
  %r3956 = ptrtoint i8* %r3955 to i64
  %r3957 = call i64 @_add(i64 %r3954, i64 %r3956)
  %r3958 = load i64, i64* %ptr_NL
  %r3959 = call i64 @_add(i64 %r3957, i64 %r3958)
  store i64 %r3959, i64* %ptr_s
  %r3960 = load i64, i64* %ptr_s
  %r3961 = getelementptr [16 x i8], [16 x i8]* @.str.1360, i64 0, i64 0
  %r3962 = ptrtoint i8* %r3961 to i64
  %r3963 = call i64 @_add(i64 %r3960, i64 %r3962)
  %r3964 = load i64, i64* %ptr_NL
  %r3965 = call i64 @_add(i64 %r3963, i64 %r3964)
  store i64 %r3965, i64* %ptr_s
  %r3966 = load i64, i64* %ptr_s
  %r3967 = getelementptr [2 x i8], [2 x i8]* @.str.1361, i64 0, i64 0
  %r3968 = ptrtoint i8* %r3967 to i64
  %r3969 = call i64 @_add(i64 %r3966, i64 %r3968)
  %r3970 = load i64, i64* %ptr_NL
  %r3971 = call i64 @_add(i64 %r3969, i64 %r3970)
  store i64 %r3971, i64* %ptr_s
  %r3972 = load i64, i64* %ptr_s
  %r3973 = getelementptr [42 x i8], [42 x i8]* @.str.1362, i64 0, i64 0
  %r3974 = ptrtoint i8* %r3973 to i64
  %r3975 = call i64 @_add(i64 %r3972, i64 %r3974)
  %r3976 = load i64, i64* %ptr_NL
  %r3977 = call i64 @_add(i64 %r3975, i64 %r3976)
  store i64 %r3977, i64* %ptr_s
  %r3978 = load i64, i64* %ptr_s
  %r3979 = getelementptr [22 x i8], [22 x i8]* @.str.1363, i64 0, i64 0
  %r3980 = ptrtoint i8* %r3979 to i64
  %r3981 = call i64 @_add(i64 %r3978, i64 %r3980)
  %r3982 = load i64, i64* %ptr_NL
  %r3983 = call i64 @_add(i64 %r3981, i64 %r3982)
  store i64 %r3983, i64* %ptr_s
  %r3984 = load i64, i64* %ptr_s
  %r3985 = getelementptr [6 x i8], [6 x i8]* @.str.1364, i64 0, i64 0
  %r3986 = ptrtoint i8* %r3985 to i64
  %r3987 = call i64 @_add(i64 %r3984, i64 %r3986)
  %r3988 = load i64, i64* %ptr_NL
  %r3989 = call i64 @_add(i64 %r3987, i64 %r3988)
  store i64 %r3989, i64* %ptr_s
  %r3990 = load i64, i64* %ptr_s
  %r3991 = getelementptr [46 x i8], [46 x i8]* @.str.1365, i64 0, i64 0
  %r3992 = ptrtoint i8* %r3991 to i64
  %r3993 = call i64 @_add(i64 %r3990, i64 %r3992)
  %r3994 = load i64, i64* %ptr_NL
  %r3995 = call i64 @_add(i64 %r3993, i64 %r3994)
  store i64 %r3995, i64* %ptr_s
  %r3996 = load i64, i64* %ptr_s
  %r3997 = getelementptr [43 x i8], [43 x i8]* @.str.1366, i64 0, i64 0
  %r3998 = ptrtoint i8* %r3997 to i64
  %r3999 = call i64 @_add(i64 %r3996, i64 %r3998)
  %r4000 = load i64, i64* %ptr_NL
  %r4001 = call i64 @_add(i64 %r3999, i64 %r4000)
  store i64 %r4001, i64* %ptr_s
  %r4002 = load i64, i64* %ptr_s
  %r4003 = getelementptr [44 x i8], [44 x i8]* @.str.1367, i64 0, i64 0
  %r4004 = ptrtoint i8* %r4003 to i64
  %r4005 = call i64 @_add(i64 %r4002, i64 %r4004)
  %r4006 = load i64, i64* %ptr_NL
  %r4007 = call i64 @_add(i64 %r4005, i64 %r4006)
  store i64 %r4007, i64* %ptr_s
  %r4008 = load i64, i64* %ptr_s
  %r4009 = getelementptr [24 x i8], [24 x i8]* @.str.1368, i64 0, i64 0
  %r4010 = ptrtoint i8* %r4009 to i64
  %r4011 = call i64 @_add(i64 %r4008, i64 %r4010)
  %r4012 = load i64, i64* %ptr_NL
  %r4013 = call i64 @_add(i64 %r4011, i64 %r4012)
  store i64 %r4013, i64* %ptr_s
  %r4014 = load i64, i64* %ptr_s
  %r4015 = getelementptr [23 x i8], [23 x i8]* @.str.1369, i64 0, i64 0
  %r4016 = ptrtoint i8* %r4015 to i64
  %r4017 = call i64 @_add(i64 %r4014, i64 %r4016)
  %r4018 = load i64, i64* %ptr_NL
  %r4019 = call i64 @_add(i64 %r4017, i64 %r4018)
  store i64 %r4019, i64* %ptr_s
  %r4020 = load i64, i64* %ptr_s
  %r4021 = getelementptr [30 x i8], [30 x i8]* @.str.1370, i64 0, i64 0
  %r4022 = ptrtoint i8* %r4021 to i64
  %r4023 = call i64 @_add(i64 %r4020, i64 %r4022)
  %r4024 = load i64, i64* %ptr_NL
  %r4025 = call i64 @_add(i64 %r4023, i64 %r4024)
  store i64 %r4025, i64* %ptr_s
  %r4026 = load i64, i64* %ptr_s
  %r4027 = getelementptr [23 x i8], [23 x i8]* @.str.1371, i64 0, i64 0
  %r4028 = ptrtoint i8* %r4027 to i64
  %r4029 = call i64 @_add(i64 %r4026, i64 %r4028)
  %r4030 = load i64, i64* %ptr_NL
  %r4031 = call i64 @_add(i64 %r4029, i64 %r4030)
  store i64 %r4031, i64* %ptr_s
  %r4032 = load i64, i64* %ptr_s
  %r4033 = getelementptr [43 x i8], [43 x i8]* @.str.1372, i64 0, i64 0
  %r4034 = ptrtoint i8* %r4033 to i64
  %r4035 = call i64 @_add(i64 %r4032, i64 %r4034)
  %r4036 = load i64, i64* %ptr_NL
  %r4037 = call i64 @_add(i64 %r4035, i64 %r4036)
  store i64 %r4037, i64* %ptr_s
  %r4038 = load i64, i64* %ptr_s
  %r4039 = getelementptr [20 x i8], [20 x i8]* @.str.1373, i64 0, i64 0
  %r4040 = ptrtoint i8* %r4039 to i64
  %r4041 = call i64 @_add(i64 %r4038, i64 %r4040)
  %r4042 = load i64, i64* %ptr_NL
  %r4043 = call i64 @_add(i64 %r4041, i64 %r4042)
  store i64 %r4043, i64* %ptr_s
  %r4044 = load i64, i64* %ptr_s
  %r4045 = getelementptr [2 x i8], [2 x i8]* @.str.1374, i64 0, i64 0
  %r4046 = ptrtoint i8* %r4045 to i64
  %r4047 = call i64 @_add(i64 %r4044, i64 %r4046)
  %r4048 = load i64, i64* %ptr_NL
  %r4049 = call i64 @_add(i64 %r4047, i64 %r4048)
  store i64 %r4049, i64* %ptr_s
  %r4050 = load i64, i64* %ptr_s
  %r4051 = getelementptr [51 x i8], [51 x i8]* @.str.1375, i64 0, i64 0
  %r4052 = ptrtoint i8* %r4051 to i64
  %r4053 = call i64 @_add(i64 %r4050, i64 %r4052)
  %r4054 = load i64, i64* %ptr_NL
  %r4055 = call i64 @_add(i64 %r4053, i64 %r4054)
  store i64 %r4055, i64* %ptr_s
  %r4056 = load i64, i64* %ptr_s
  %r4057 = getelementptr [22 x i8], [22 x i8]* @.str.1376, i64 0, i64 0
  %r4058 = ptrtoint i8* %r4057 to i64
  %r4059 = call i64 @_add(i64 %r4056, i64 %r4058)
  %r4060 = load i64, i64* %ptr_NL
  %r4061 = call i64 @_add(i64 %r4059, i64 %r4060)
  store i64 %r4061, i64* %ptr_s
  %r4062 = load i64, i64* %ptr_s
  %r4063 = getelementptr [6 x i8], [6 x i8]* @.str.1377, i64 0, i64 0
  %r4064 = ptrtoint i8* %r4063 to i64
  %r4065 = call i64 @_add(i64 %r4062, i64 %r4064)
  %r4066 = load i64, i64* %ptr_NL
  %r4067 = call i64 @_add(i64 %r4065, i64 %r4066)
  store i64 %r4067, i64* %ptr_s
  %r4068 = load i64, i64* %ptr_s
  %r4069 = getelementptr [46 x i8], [46 x i8]* @.str.1378, i64 0, i64 0
  %r4070 = ptrtoint i8* %r4069 to i64
  %r4071 = call i64 @_add(i64 %r4068, i64 %r4070)
  %r4072 = load i64, i64* %ptr_NL
  %r4073 = call i64 @_add(i64 %r4071, i64 %r4072)
  store i64 %r4073, i64* %ptr_s
  %r4074 = load i64, i64* %ptr_s
  %r4075 = getelementptr [29 x i8], [29 x i8]* @.str.1379, i64 0, i64 0
  %r4076 = ptrtoint i8* %r4075 to i64
  %r4077 = call i64 @_add(i64 %r4074, i64 %r4076)
  %r4078 = load i64, i64* %ptr_NL
  %r4079 = call i64 @_add(i64 %r4077, i64 %r4078)
  store i64 %r4079, i64* %ptr_s
  %r4080 = load i64, i64* %ptr_s
  %r4081 = getelementptr [39 x i8], [39 x i8]* @.str.1380, i64 0, i64 0
  %r4082 = ptrtoint i8* %r4081 to i64
  %r4083 = call i64 @_add(i64 %r4080, i64 %r4082)
  %r4084 = load i64, i64* %ptr_NL
  %r4085 = call i64 @_add(i64 %r4083, i64 %r4084)
  store i64 %r4085, i64* %ptr_s
  %r4086 = load i64, i64* %ptr_s
  %r4087 = getelementptr [6 x i8], [6 x i8]* @.str.1381, i64 0, i64 0
  %r4088 = ptrtoint i8* %r4087 to i64
  %r4089 = call i64 @_add(i64 %r4086, i64 %r4088)
  %r4090 = load i64, i64* %ptr_NL
  %r4091 = call i64 @_add(i64 %r4089, i64 %r4090)
  store i64 %r4091, i64* %ptr_s
  %r4092 = load i64, i64* %ptr_s
  %r4093 = getelementptr [43 x i8], [43 x i8]* @.str.1382, i64 0, i64 0
  %r4094 = ptrtoint i8* %r4093 to i64
  %r4095 = call i64 @_add(i64 %r4092, i64 %r4094)
  %r4096 = load i64, i64* %ptr_NL
  %r4097 = call i64 @_add(i64 %r4095, i64 %r4096)
  store i64 %r4097, i64* %ptr_s
  %r4098 = load i64, i64* %ptr_s
  %r4099 = getelementptr [44 x i8], [44 x i8]* @.str.1383, i64 0, i64 0
  %r4100 = ptrtoint i8* %r4099 to i64
  %r4101 = call i64 @_add(i64 %r4098, i64 %r4100)
  %r4102 = load i64, i64* %ptr_NL
  %r4103 = call i64 @_add(i64 %r4101, i64 %r4102)
  store i64 %r4103, i64* %ptr_s
  %r4104 = load i64, i64* %ptr_s
  %r4105 = getelementptr [24 x i8], [24 x i8]* @.str.1384, i64 0, i64 0
  %r4106 = ptrtoint i8* %r4105 to i64
  %r4107 = call i64 @_add(i64 %r4104, i64 %r4106)
  %r4108 = load i64, i64* %ptr_NL
  %r4109 = call i64 @_add(i64 %r4107, i64 %r4108)
  store i64 %r4109, i64* %ptr_s
  %r4110 = load i64, i64* %ptr_s
  %r4111 = getelementptr [23 x i8], [23 x i8]* @.str.1385, i64 0, i64 0
  %r4112 = ptrtoint i8* %r4111 to i64
  %r4113 = call i64 @_add(i64 %r4110, i64 %r4112)
  %r4114 = load i64, i64* %ptr_NL
  %r4115 = call i64 @_add(i64 %r4113, i64 %r4114)
  store i64 %r4115, i64* %ptr_s
  %r4116 = load i64, i64* %ptr_s
  %r4117 = getelementptr [23 x i8], [23 x i8]* @.str.1386, i64 0, i64 0
  %r4118 = ptrtoint i8* %r4117 to i64
  %r4119 = call i64 @_add(i64 %r4116, i64 %r4118)
  %r4120 = load i64, i64* %ptr_NL
  %r4121 = call i64 @_add(i64 %r4119, i64 %r4120)
  store i64 %r4121, i64* %ptr_s
  %r4122 = load i64, i64* %ptr_s
  %r4123 = getelementptr [17 x i8], [17 x i8]* @.str.1387, i64 0, i64 0
  %r4124 = ptrtoint i8* %r4123 to i64
  %r4125 = call i64 @_add(i64 %r4122, i64 %r4124)
  %r4126 = load i64, i64* %ptr_NL
  %r4127 = call i64 @_add(i64 %r4125, i64 %r4126)
  store i64 %r4127, i64* %ptr_s
  %r4128 = load i64, i64* %ptr_s
  %r4129 = getelementptr [20 x i8], [20 x i8]* @.str.1388, i64 0, i64 0
  %r4130 = ptrtoint i8* %r4129 to i64
  %r4131 = call i64 @_add(i64 %r4128, i64 %r4130)
  %r4132 = load i64, i64* %ptr_NL
  %r4133 = call i64 @_add(i64 %r4131, i64 %r4132)
  store i64 %r4133, i64* %ptr_s
  %r4134 = load i64, i64* %ptr_s
  %r4135 = getelementptr [2 x i8], [2 x i8]* @.str.1389, i64 0, i64 0
  %r4136 = ptrtoint i8* %r4135 to i64
  %r4137 = call i64 @_add(i64 %r4134, i64 %r4136)
  %r4138 = load i64, i64* %ptr_NL
  %r4139 = call i64 @_add(i64 %r4137, i64 %r4138)
  store i64 %r4139, i64* %ptr_s
  %r4140 = load i64, i64* %ptr_s
  %r4141 = getelementptr [42 x i8], [42 x i8]* @.str.1390, i64 0, i64 0
  %r4142 = ptrtoint i8* %r4141 to i64
  %r4143 = call i64 @_add(i64 %r4140, i64 %r4142)
  %r4144 = load i64, i64* %ptr_NL
  %r4145 = call i64 @_add(i64 %r4143, i64 %r4144)
  store i64 %r4145, i64* %ptr_s
  %r4146 = load i64, i64* %ptr_s
  %r4147 = getelementptr [37 x i8], [37 x i8]* @.str.1391, i64 0, i64 0
  %r4148 = ptrtoint i8* %r4147 to i64
  %r4149 = call i64 @_add(i64 %r4146, i64 %r4148)
  %r4150 = load i64, i64* %ptr_NL
  %r4151 = call i64 @_add(i64 %r4149, i64 %r4150)
  store i64 %r4151, i64* %ptr_s
  %r4152 = load i64, i64* %ptr_s
  %r4153 = getelementptr [49 x i8], [49 x i8]* @.str.1392, i64 0, i64 0
  %r4154 = ptrtoint i8* %r4153 to i64
  %r4155 = call i64 @_add(i64 %r4152, i64 %r4154)
  %r4156 = load i64, i64* %ptr_NL
  %r4157 = call i64 @_add(i64 %r4155, i64 %r4156)
  store i64 %r4157, i64* %ptr_s
  %r4158 = load i64, i64* %ptr_s
  %r4159 = getelementptr [41 x i8], [41 x i8]* @.str.1393, i64 0, i64 0
  %r4160 = ptrtoint i8* %r4159 to i64
  %r4161 = call i64 @_add(i64 %r4158, i64 %r4160)
  %r4162 = load i64, i64* %ptr_NL
  %r4163 = call i64 @_add(i64 %r4161, i64 %r4162)
  store i64 %r4163, i64* %ptr_s
  %r4164 = load i64, i64* %ptr_s
  %r4165 = getelementptr [16 x i8], [16 x i8]* @.str.1394, i64 0, i64 0
  %r4166 = ptrtoint i8* %r4165 to i64
  %r4167 = call i64 @_add(i64 %r4164, i64 %r4166)
  %r4168 = load i64, i64* %ptr_NL
  %r4169 = call i64 @_add(i64 %r4167, i64 %r4168)
  store i64 %r4169, i64* %ptr_s
  %r4170 = load i64, i64* %ptr_s
  %r4171 = getelementptr [2 x i8], [2 x i8]* @.str.1395, i64 0, i64 0
  %r4172 = ptrtoint i8* %r4171 to i64
  %r4173 = call i64 @_add(i64 %r4170, i64 %r4172)
  %r4174 = load i64, i64* %ptr_NL
  %r4175 = call i64 @_add(i64 %r4173, i64 %r4174)
  store i64 %r4175, i64* %ptr_s
  %r4176 = load i64, i64* %ptr_s
  ret i64 %r4176
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
  br label %L1034
L1034:
  %r2 = load i64, i64* %ptr_i
  %r3 = load i64, i64* %ptr_stmts
  %r4 = call i64 @mensura(i64 %r3)
  %r6 = icmp slt i64 %r2, %r4
  %r5 = zext i1 %r6 to i64
  %r7 = icmp ne i64 %r5, 0
  br i1 %r7, label %L1035, label %L1036
L1035:
  %r8 = load i64, i64* %ptr_stmts
  %r9 = load i64, i64* %ptr_i
  %r10 = call i64 @_get(i64 %r8, i64 %r9)
  store i64 %r10, i64* %ptr_s
  %r11 = load i64, i64* %ptr_s
  %r12 = getelementptr [5 x i8], [5 x i8]* @.str.1396, i64 0, i64 0
  %r13 = ptrtoint i8* %r12 to i64
  %r14 = call i64 @_get(i64 %r11, i64 %r13)
  %r15 = load i64, i64* @STMT_IMPORT
  %r16 = call i64 @_eq(i64 %r14, i64 %r15)
  %r17 = icmp ne i64 %r16, 0
  br i1 %r17, label %L1037, label %L1038
L1037:
  %r18 = load i64, i64* %ptr_s
  %r19 = getelementptr [4 x i8], [4 x i8]* @.str.1397, i64 0, i64 0
  %r20 = ptrtoint i8* %r19 to i64
  %r21 = call i64 @_get(i64 %r18, i64 %r20)
  %r22 = getelementptr [4 x i8], [4 x i8]* @.str.1398, i64 0, i64 0
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
  br i1 %r31, label %L1040, label %L1041
L1040:
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
  br label %L1043
L1043:
  %r37 = call i64 @peek()
  %r38 = getelementptr [5 x i8], [5 x i8]* @.str.1399, i64 0, i64 0
  %r39 = ptrtoint i8* %r38 to i64
  %r40 = call i64 @_get(i64 %r37, i64 %r39)
  %r42 = call i64 @_eq(i64 %r40, i64 0)
  %r41 = xor i64 %r42, 1
  %r43 = icmp ne i64 %r41, 0
  br i1 %r43, label %L1044, label %L1045
L1044:
  %r44 = call i64 @peek()
  %r45 = getelementptr [5 x i8], [5 x i8]* @.str.1400, i64 0, i64 0
  %r46 = ptrtoint i8* %r45 to i64
  %r47 = call i64 @_get(i64 %r44, i64 %r46)
  %r48 = call i64 @_eq(i64 %r47, i64 29)
  %r49 = icmp ne i64 %r48, 0
  br i1 %r49, label %L1046, label %L1047
L1046:
  %r50 = call i64 @advance()
  br label %L1048
L1047:
  %r51 = call i64 @parse_stmt()
  %r52 = load i64, i64* %ptr_imp_stmts
  call i64 @_append_poly(i64 %r52, i64 %r51)
  br label %L1048
L1048:
  br label %L1043
L1045:
  %r53 = load i64, i64* %ptr_imp_stmts
  %r54 = call i64 @expand_imports(i64 %r53)
  store i64 %r54, i64* %ptr_sub_exp
  store i64 0, i64* %ptr_j
  br label %L1049
L1049:
  %r55 = load i64, i64* %ptr_j
  %r56 = load i64, i64* %ptr_sub_exp
  %r57 = call i64 @mensura(i64 %r56)
  %r59 = icmp slt i64 %r55, %r57
  %r58 = zext i1 %r59 to i64
  %r60 = icmp ne i64 %r58, 0
  br i1 %r60, label %L1050, label %L1051
L1050:
  %r61 = load i64, i64* %ptr_sub_exp
  %r62 = load i64, i64* %ptr_j
  %r63 = call i64 @_get(i64 %r61, i64 %r62)
  %r64 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r64, i64 %r63)
  %r65 = load i64, i64* %ptr_j
  %r66 = call i64 @_add(i64 %r65, i64 1)
  store i64 %r66, i64* %ptr_j
  br label %L1049
L1051:
  %r67 = load i64, i64* %ptr_old_toks
  store i64 %r67, i64* @global_tokens
  %r68 = load i64, i64* %ptr_old_pos
  store i64 %r68, i64* @p_pos
  br label %L1042
L1041:
  %r69 = getelementptr [41 x i8], [41 x i8]* @.str.1401, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_path
  %r72 = call i64 @_add(i64 %r70, i64 %r71)
  call i64 @print_any(i64 %r72)
  br label %L1042
L1042:
  br label %L1039
L1038:
  %r73 = load i64, i64* %ptr_s
  %r74 = load i64, i64* %ptr_expanded
  call i64 @_append_poly(i64 %r74, i64 %r73)
  br label %L1039
L1039:
  %r75 = load i64, i64* %ptr_i
  %r76 = call i64 @_add(i64 %r75, i64 1)
  store i64 %r76, i64* %ptr_i
  br label %L1034
L1036:
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
  %r1 = getelementptr [61 x i8], [61 x i8]* @.str.1402, i64 0, i64 0
  %r2 = ptrtoint i8* %r1 to i64
  call i64 @print_any(i64 %r2)
  %r3 = call i64 @init_constants()
  %r4 = call i64 @_list_new()
  store i64 %r4, i64* @global_tokens
  store i64 0, i64* @p_pos
  store i64 0, i64* %ptr_is_freestanding
  store i64 0, i64* %ptr_is_arm64
  store i64 1, i64* %ptr_arg_idx
  %r5 = getelementptr [1 x i8], [1 x i8]* @.str.1403, i64 0, i64 0
  %r6 = ptrtoint i8* %r5 to i64
  store i64 %r6, i64* %ptr_arg
  %r7 = getelementptr [1 x i8], [1 x i8]* @.str.1404, i64 0, i64 0
  %r8 = ptrtoint i8* %r7 to i64
  store i64 %r8, i64* %ptr_filename
  store i64 1, i64* %ptr_valid
  br label %L1052
L1052:
  %r9 = icmp ne i64 1, 0
  br i1 %r9, label %L1053, label %L1054
L1053:
  %r10 = load i64, i64* %ptr_arg_idx
  %r11 = call i64 @_get_argv(i64 %r10)
  store i64 %r11, i64* %ptr_arg
  %r12 = load i64, i64* %ptr_arg
  %r13 = call i64 @mensura(i64 %r12)
  %r14 = call i64 @_eq(i64 %r13, i64 0)
  %r15 = icmp ne i64 %r14, 0
  br i1 %r15, label %L1055, label %L1057
L1055:
  br label %L1054
L1057:
  %r16 = load i64, i64* %ptr_arg
  %r17 = getelementptr [15 x i8], [15 x i8]* @.str.1405, i64 0, i64 0
  %r18 = ptrtoint i8* %r17 to i64
  %r19 = call i64 @_eq(i64 %r16, i64 %r18)
  %r20 = icmp ne i64 %r19, 0
  br i1 %r20, label %L1058, label %L1059
L1058:
  store i64 1, i64* %ptr_is_freestanding
  br label %L1060
L1059:
  %r21 = load i64, i64* %ptr_arg
  %r22 = getelementptr [8 x i8], [8 x i8]* @.str.1406, i64 0, i64 0
  %r23 = ptrtoint i8* %r22 to i64
  %r24 = call i64 @_eq(i64 %r21, i64 %r23)
  %r25 = icmp ne i64 %r24, 0
  br i1 %r25, label %L1061, label %L1062
L1061:
  store i64 1, i64* %ptr_is_arm64
  br label %L1063
L1062:
  %r26 = load i64, i64* %ptr_arg
  store i64 %r26, i64* %ptr_filename
  br label %L1063
L1063:
  br label %L1060
L1060:
  %r27 = load i64, i64* %ptr_arg_idx
  %r28 = call i64 @_add(i64 %r27, i64 1)
  store i64 %r28, i64* %ptr_arg_idx
  br label %L1052
L1054:
  %r29 = load i64, i64* %ptr_filename
  %r30 = call i64 @mensura(i64 %r29)
  %r31 = call i64 @_eq(i64 %r30, i64 0)
  %r32 = icmp ne i64 %r31, 0
  br i1 %r32, label %L1064, label %L1066
L1064:
  %r33 = getelementptr [52 x i8], [52 x i8]* @.str.1407, i64 0, i64 0
  %r34 = ptrtoint i8* %r33 to i64
  call i64 @print_any(i64 %r34)
  store i64 0, i64* %ptr_valid
  br label %L1066
L1066:
  %r35 = load i64, i64* %ptr_valid
  %r36 = icmp ne i64 %r35, 0
  br i1 %r36, label %L1067, label %L1069
L1067:
  %r37 = load i64, i64* %ptr_filename
  %r38 = call i64 @revelare(i64 %r37)
  store i64 %r38, i64* %ptr_src
  %r39 = load i64, i64* %ptr_src
  %r40 = call i64 @mensura(i64 %r39)
  %r41 = call i64 @_eq(i64 %r40, i64 0)
  %r42 = icmp ne i64 %r41, 0
  br i1 %r42, label %L1070, label %L1071
L1070:
  %r43 = getelementptr [25 x i8], [25 x i8]* @.str.1408, i64 0, i64 0
  %r44 = ptrtoint i8* %r43 to i64
  %r45 = load i64, i64* %ptr_filename
  %r46 = call i64 @_add(i64 %r44, i64 %r45)
  call i64 @print_any(i64 %r46)
  br label %L1072
L1071:
  %r47 = getelementptr [16 x i8], [16 x i8]* @.str.1409, i64 0, i64 0
  %r48 = ptrtoint i8* %r47 to i64
  call i64 @print_any(i64 %r48)
  %r49 = load i64, i64* %ptr_src
  %r50 = call i64 @lex_source(i64 %r49)
  store i64 %r50, i64* @global_tokens
  %r51 = load i64, i64* @global_tokens
  %r52 = call i64 @mensura(i64 %r51)
  store i64 %r52, i64* %ptr_token_count
  %r53 = getelementptr [19 x i8], [19 x i8]* @.str.1410, i64 0, i64 0
  %r54 = ptrtoint i8* %r53 to i64
  %r55 = load i64, i64* %ptr_token_count
  %r56 = call i64 @int_to_str(i64 %r55)
  %r57 = call i64 @_add(i64 %r54, i64 %r56)
  %r58 = getelementptr [9 x i8], [9 x i8]* @.str.1411, i64 0, i64 0
  %r59 = ptrtoint i8* %r58 to i64
  %r60 = call i64 @_add(i64 %r57, i64 %r59)
  call i64 @print_any(i64 %r60)
  store i64 0, i64* %ptr_k
  br label %L1073
L1073:
  %r61 = load i64, i64* %ptr_k
  %r62 = load i64, i64* %ptr_token_count
  %r64 = icmp slt i64 %r61, %r62
  %r63 = zext i1 %r64 to i64
  %r65 = icmp ne i64 %r63, 0
  br i1 %r65, label %L1074, label %L1075
L1074:
  %r66 = load i64, i64* @global_tokens
  %r67 = load i64, i64* %ptr_k
  %r68 = call i64 @_get(i64 %r66, i64 %r67)
  store i64 %r68, i64* %ptr_t
  %r69 = getelementptr [4 x i8], [4 x i8]* @.str.1412, i64 0, i64 0
  %r70 = ptrtoint i8* %r69 to i64
  %r71 = load i64, i64* %ptr_k
  %r72 = call i64 @int_to_str(i64 %r71)
  %r73 = call i64 @_add(i64 %r70, i64 %r72)
  %r74 = getelementptr [4 x i8], [4 x i8]* @.str.1413, i64 0, i64 0
  %r75 = ptrtoint i8* %r74 to i64
  %r76 = call i64 @_add(i64 %r73, i64 %r75)
  %r77 = load i64, i64* %ptr_t
  %r78 = getelementptr [5 x i8], [5 x i8]* @.str.1414, i64 0, i64 0
  %r79 = ptrtoint i8* %r78 to i64
  %r80 = call i64 @_get(i64 %r77, i64 %r79)
  %r81 = call i64 @_add(i64 %r76, i64 %r80)
  %r82 = getelementptr [3 x i8], [3 x i8]* @.str.1415, i64 0, i64 0
  %r83 = ptrtoint i8* %r82 to i64
  %r84 = call i64 @_add(i64 %r81, i64 %r83)
  %r85 = load i64, i64* %ptr_t
  %r86 = getelementptr [5 x i8], [5 x i8]* @.str.1416, i64 0, i64 0
  %r87 = ptrtoint i8* %r86 to i64
  %r88 = call i64 @_get(i64 %r85, i64 %r87)
  %r89 = call i64 @int_to_str(i64 %r88)
  %r90 = call i64 @_add(i64 %r84, i64 %r89)
  %r91 = getelementptr [2 x i8], [2 x i8]* @.str.1417, i64 0, i64 0
  %r92 = ptrtoint i8* %r91 to i64
  %r93 = call i64 @_add(i64 %r90, i64 %r92)
  call i64 @print_any(i64 %r93)
  %r94 = load i64, i64* %ptr_k
  %r95 = call i64 @_add(i64 %r94, i64 1)
  store i64 %r95, i64* %ptr_k
  br label %L1073
L1075:
  %r96 = getelementptr [17 x i8], [17 x i8]* @.str.1418, i64 0, i64 0
  %r97 = ptrtoint i8* %r96 to i64
  call i64 @print_any(i64 %r97)
  store i64 1, i64* @use_huge_lists
  %r98 = call i64 @_list_new()
  store i64 %r98, i64* %ptr_stmts
  store i64 0, i64* @use_huge_lists
  %r99 = call i64 @peek()
  store i64 %r99, i64* %ptr_pt
  br label %L1076
L1076:
  %r100 = load i64, i64* %ptr_pt
  %r101 = getelementptr [5 x i8], [5 x i8]* @.str.1419, i64 0, i64 0
  %r102 = ptrtoint i8* %r101 to i64
  %r103 = call i64 @_get(i64 %r100, i64 %r102)
  %r104 = load i64, i64* @TOK_EOF
  %r106 = call i64 @_eq(i64 %r103, i64 %r104)
  %r105 = xor i64 %r106, 1
  %r107 = icmp ne i64 %r105, 0
  br i1 %r107, label %L1077, label %L1078
L1077:
  %r108 = load i64, i64* @has_error
  %r109 = icmp ne i64 %r108, 0
  br i1 %r109, label %L1079, label %L1081
L1079:
  br label %L1078
L1081:
  %r110 = load i64, i64* %ptr_pt
  %r111 = getelementptr [5 x i8], [5 x i8]* @.str.1420, i64 0, i64 0
  %r112 = ptrtoint i8* %r111 to i64
  %r113 = call i64 @_get(i64 %r110, i64 %r112)
  %r114 = load i64, i64* @TOK_CARET
  %r115 = call i64 @_eq(i64 %r113, i64 %r114)
  %r116 = icmp ne i64 %r115, 0
  br i1 %r116, label %L1082, label %L1084
L1082:
  %r117 = call i64 @advance()
  br label %L1076
L1084:
  %r118 = call i64 @parse_stmt()
  %r119 = load i64, i64* %ptr_stmts
  call i64 @_append_poly(i64 %r119, i64 %r118)
  %r120 = call i64 @peek()
  store i64 %r120, i64* %ptr_pt
  br label %L1076
L1078:
  %r121 = load i64, i64* %ptr_stmts
  %r122 = call i64 @expand_imports(i64 %r121)
  store i64 %r122, i64* %ptr_flat_stmts
  %r123 = load i64, i64* @has_error
  %r124 = icmp ne i64 %r123, 0
  br i1 %r124, label %L1085, label %L1086
L1085:
  %r125 = getelementptr [24 x i8], [24 x i8]* @.str.1421, i64 0, i64 0
  %r126 = ptrtoint i8* %r125 to i64
  call i64 @print_any(i64 %r126)
  br label %L1087
L1086:
  %r127 = getelementptr [28 x i8], [28 x i8]* @.str.1422, i64 0, i64 0
  %r128 = ptrtoint i8* %r127 to i64
  call i64 @print_any(i64 %r128)
  %r129 = load i64, i64* %ptr_is_freestanding
  %r130 = load i64, i64* %ptr_is_arm64
  %r131 = call i64 @get_llvm_header(i64 %r129, i64 %r130)
  store i64 %r131, i64* %ptr_header
  %r132 = call i64 @_list_new()
  store i64 %r132, i64* %ptr_top_level
  store i64 0, i64* %ptr_i
  br label %L1088
L1088:
  %r133 = load i64, i64* %ptr_i
  %r134 = load i64, i64* %ptr_flat_stmts
  %r135 = call i64 @mensura(i64 %r134)
  %r137 = icmp slt i64 %r133, %r135
  %r136 = zext i1 %r137 to i64
  %r138 = icmp ne i64 %r136, 0
  br i1 %r138, label %L1089, label %L1090
L1089:
  %r139 = load i64, i64* %ptr_flat_stmts
  %r140 = load i64, i64* %ptr_i
  %r141 = call i64 @_get(i64 %r139, i64 %r140)
  store i64 %r141, i64* %ptr_s
  %r142 = load i64, i64* %ptr_s
  %r143 = getelementptr [5 x i8], [5 x i8]* @.str.1423, i64 0, i64 0
  %r144 = ptrtoint i8* %r143 to i64
  %r145 = call i64 @_get(i64 %r142, i64 %r144)
  %r146 = load i64, i64* @STMT_FUNC
  %r147 = call i64 @_eq(i64 %r145, i64 %r146)
  %r148 = icmp ne i64 %r147, 0
  br i1 %r148, label %L1091, label %L1092
L1091:
  %r149 = load i64, i64* %ptr_s
  %r150 = call i64 @compile_func(i64 %r149)
  br label %L1093
L1092:
  %r151 = load i64, i64* %ptr_s
  %r152 = getelementptr [5 x i8], [5 x i8]* @.str.1425, i64 0, i64 0
  %r153 = ptrtoint i8* %r152 to i64
  %r154 = call i64 @_get(i64 %r151, i64 %r153)
  %r155 = load i64, i64* @STMT_SHARED
  %r156 = call i64 @_eq(i64 %r154, i64 %r155)
  store i64 1, i64* @.sc.1424
  %r158 = icmp eq i64 %r156, 0
  br i1 %r158, label %L1094, label %L1095
L1094:
  %r159 = load i64, i64* %ptr_s
  %r160 = getelementptr [5 x i8], [5 x i8]* @.str.1426, i64 0, i64 0
  %r161 = ptrtoint i8* %r160 to i64
  %r162 = call i64 @_get(i64 %r159, i64 %r161)
  %r163 = load i64, i64* @STMT_CONST
  %r164 = call i64 @_eq(i64 %r162, i64 %r163)
  %r165 = icmp ne i64 %r164, 0
  %r166 = zext i1 %r165 to i64
  store i64 %r166, i64* @.sc.1424
  br label %L1095
L1095:
  %r157 = load i64, i64* @.sc.1424
  %r167 = icmp ne i64 %r157, 0
  br i1 %r167, label %L1096, label %L1097
L1096:
  %r168 = getelementptr [2 x i8], [2 x i8]* @.str.1427, i64 0, i64 0
  %r169 = ptrtoint i8* %r168 to i64
  %r170 = load i64, i64* %ptr_s
  %r171 = getelementptr [5 x i8], [5 x i8]* @.str.1428, i64 0, i64 0
  %r172 = ptrtoint i8* %r171 to i64
  %r173 = call i64 @_get(i64 %r170, i64 %r172)
  %r174 = call i64 @_add(i64 %r169, i64 %r173)
  store i64 %r174, i64* %ptr_g_name
  %r175 = load i64, i64* @out_data
  %r176 = load i64, i64* %ptr_g_name
  %r177 = call i64 @_add(i64 %r175, i64 %r176)
  %r178 = getelementptr [16 x i8], [16 x i8]* @.str.1429, i64 0, i64 0
  %r179 = ptrtoint i8* %r178 to i64
  %r180 = call i64 @_add(i64 %r177, i64 %r179)
  %r181 = call i64 @signum_ex(i64 10)
  %r182 = call i64 @_add(i64 %r180, i64 %r181)
  store i64 %r182, i64* @out_data
  %r183 = load i64, i64* %ptr_g_name
  %r184 = load i64, i64* %ptr_s
  %r185 = getelementptr [5 x i8], [5 x i8]* @.str.1430, i64 0, i64 0
  %r186 = ptrtoint i8* %r185 to i64
  %r187 = call i64 @_get(i64 %r184, i64 %r186)
  %r188 = load i64, i64* @global_map
  call i64 @_set(i64 %r188, i64 %r187, i64 %r183)
  %r189 = call i64 @_map_new()
  %r190 = getelementptr [5 x i8], [5 x i8]* @.str.1431, i64 0, i64 0
  %r191 = ptrtoint i8* %r190 to i64
  %r192 = load i64, i64* @STMT_ASSIGN
  call i64 @_map_set(i64 %r189, i64 %r191, i64 %r192)
  %r193 = getelementptr [5 x i8], [5 x i8]* @.str.1432, i64 0, i64 0
  %r194 = ptrtoint i8* %r193 to i64
  %r195 = load i64, i64* %ptr_s
  %r196 = getelementptr [5 x i8], [5 x i8]* @.str.1433, i64 0, i64 0
  %r197 = ptrtoint i8* %r196 to i64
  %r198 = call i64 @_get(i64 %r195, i64 %r197)
  call i64 @_map_set(i64 %r189, i64 %r194, i64 %r198)
  %r199 = getelementptr [4 x i8], [4 x i8]* @.str.1434, i64 0, i64 0
  %r200 = ptrtoint i8* %r199 to i64
  %r201 = load i64, i64* %ptr_s
  %r202 = getelementptr [4 x i8], [4 x i8]* @.str.1435, i64 0, i64 0
  %r203 = ptrtoint i8* %r202 to i64
  %r204 = call i64 @_get(i64 %r201, i64 %r203)
  call i64 @_map_set(i64 %r189, i64 %r200, i64 %r204)
  store i64 %r189, i64* %ptr_assign
  %r205 = load i64, i64* %ptr_assign
  %r206 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r206, i64 %r205)
  br label %L1098
L1097:
  %r207 = load i64, i64* %ptr_s
  %r208 = load i64, i64* %ptr_top_level
  call i64 @_append_poly(i64 %r208, i64 %r207)
  br label %L1098
L1098:
  br label %L1093
L1093:
  %r209 = load i64, i64* %ptr_i
  %r210 = call i64 @_add(i64 %r209, i64 1)
  store i64 %r210, i64* %ptr_i
  br label %L1088
L1090:
  %r211 = call i64 @signum_ex(i64 10)
  store i64 %r211, i64* %ptr_NL
  %r212 = load i64, i64* %ptr_is_freestanding
  %r213 = call i64 @_eq(i64 %r212, i64 0)
  %r214 = icmp ne i64 %r213, 0
  br i1 %r214, label %L1099, label %L1100
L1099:
  %r215 = getelementptr [42 x i8], [42 x i8]* @.str.1436, i64 0, i64 0
  %r216 = ptrtoint i8* %r215 to i64
  %r217 = call i64 @emit_raw(i64 %r216)
  %r218 = getelementptr [36 x i8], [36 x i8]* @.str.1437, i64 0, i64 0
  %r219 = ptrtoint i8* %r218 to i64
  %r220 = call i64 @emit_raw(i64 %r219)
  %r221 = getelementptr [38 x i8], [38 x i8]* @.str.1438, i64 0, i64 0
  %r222 = ptrtoint i8* %r221 to i64
  %r223 = call i64 @emit_raw(i64 %r222)
  %r224 = getelementptr [16 x i8], [16 x i8]* @.str.1439, i64 0, i64 0
  %r225 = ptrtoint i8* %r224 to i64
  %r226 = call i64 @add_global_string(i64 %r225)
  store i64 %r226, i64* %ptr_boot_msg
  %r227 = getelementptr [55 x i8], [55 x i8]* @.str.1440, i64 0, i64 0
  %r228 = ptrtoint i8* %r227 to i64
  %r229 = load i64, i64* %ptr_boot_msg
  %r230 = call i64 @_add(i64 %r228, i64 %r229)
  %r231 = getelementptr [15 x i8], [15 x i8]* @.str.1441, i64 0, i64 0
  %r232 = ptrtoint i8* %r231 to i64
  %r233 = call i64 @_add(i64 %r230, i64 %r232)
  %r234 = call i64 @emit_raw(i64 %r233)
  %r235 = getelementptr [52 x i8], [52 x i8]* @.str.1442, i64 0, i64 0
  %r236 = ptrtoint i8* %r235 to i64
  %r237 = call i64 @emit_raw(i64 %r236)
  %r238 = getelementptr [41 x i8], [41 x i8]* @.str.1443, i64 0, i64 0
  %r239 = ptrtoint i8* %r238 to i64
  %r240 = call i64 @emit_raw(i64 %r239)
  br label %L1101
L1100:
  %r241 = getelementptr [30 x i8], [30 x i8]* @.str.1444, i64 0, i64 0
  %r242 = ptrtoint i8* %r241 to i64
  %r243 = call i64 @emit_raw(i64 %r242)
  br label %L1101
L1101:
  store i64 0, i64* @reg_count
  %r244 = call i64 @_map_new()
  store i64 %r244, i64* @var_map
  %r245 = getelementptr [31 x i8], [31 x i8]* @.str.1445, i64 0, i64 0
  %r246 = ptrtoint i8* %r245 to i64
  %r247 = load i64, i64* %ptr_top_level
  %r248 = call i64 @mensura(i64 %r247)
  %r249 = call i64 @int_to_str(i64 %r248)
  %r250 = call i64 @_add(i64 %r246, i64 %r249)
  call i64 @print_any(i64 %r250)
  store i64 0, i64* %ptr_i
  br label %L1102
L1102:
  %r251 = load i64, i64* %ptr_i
  %r252 = load i64, i64* %ptr_top_level
  %r253 = call i64 @mensura(i64 %r252)
  %r255 = icmp slt i64 %r251, %r253
  %r254 = zext i1 %r255 to i64
  %r256 = icmp ne i64 %r254, 0
  br i1 %r256, label %L1103, label %L1104
L1103:
  %r257 = load i64, i64* %ptr_top_level
  %r258 = load i64, i64* %ptr_i
  %r259 = call i64 @_get(i64 %r257, i64 %r258)
  %r260 = call i64 @compile_stmt(i64 %r259)
  %r261 = load i64, i64* %ptr_i
  %r262 = call i64 @_add(i64 %r261, i64 1)
  store i64 %r262, i64* %ptr_i
  br label %L1102
L1104:
  %r263 = load i64, i64* %ptr_is_freestanding
  %r264 = call i64 @_eq(i64 %r263, i64 0)
  %r265 = icmp ne i64 %r264, 0
  br i1 %r265, label %L1105, label %L1106
L1105:
  %r266 = getelementptr [10 x i8], [10 x i8]* @.str.1446, i64 0, i64 0
  %r267 = ptrtoint i8* %r266 to i64
  %r268 = call i64 @emit(i64 %r267)
  %r269 = getelementptr [2 x i8], [2 x i8]* @.str.1447, i64 0, i64 0
  %r270 = ptrtoint i8* %r269 to i64
  %r271 = call i64 @emit_raw(i64 %r270)
  br label %L1107
L1106:
  %r272 = getelementptr [36 x i8], [36 x i8]* @.str.1448, i64 0, i64 0
  %r273 = ptrtoint i8* %r272 to i64
  %r274 = call i64 @emit(i64 %r273)
  %r275 = getelementptr [11 x i8], [11 x i8]* @.str.1449, i64 0, i64 0
  %r276 = ptrtoint i8* %r275 to i64
  %r277 = call i64 @emit(i64 %r276)
  %r278 = getelementptr [2 x i8], [2 x i8]* @.str.1450, i64 0, i64 0
  %r279 = ptrtoint i8* %r278 to i64
  %r280 = call i64 @emit_raw(i64 %r279)
  br label %L1107
L1107:
  %r281 = load i64, i64* %ptr_header
  %r282 = load i64, i64* @out_data
  %r283 = call i64 @_add(i64 %r281, i64 %r282)
  %r284 = load i64, i64* @out_code
  %r285 = call i64 @_add(i64 %r283, i64 %r284)
  store i64 %r285, i64* %ptr_final_ir
  %r286 = getelementptr [10 x i8], [10 x i8]* @.str.1451, i64 0, i64 0
  %r287 = ptrtoint i8* %r286 to i64
  %r288 = load i64, i64* %ptr_final_ir
  %r289 = call i64 @inscribo(i64 %r287, i64 %r288)
  %r290 = getelementptr [36 x i8], [36 x i8]* @.str.1452, i64 0, i64 0
  %r291 = ptrtoint i8* %r290 to i64
  call i64 @print_any(i64 %r291)
  br label %L1087
L1087:
  br label %L1072
L1072:
  br label %L1069
L1069:
  ret i64 0
}
define i32 @main(i32 %argc, i8** %argv) {
  store i32 %argc, i32* @__sys_argc
  store i8** %argv, i8*** @__sys_argv
  %boot_msg_ptr = getelementptr [22 x i8], [22 x i8]* @.str.1453, i64 0, i64 0
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
  %r4 = getelementptr [1 x i8], [1 x i8]* @.str.1454, i64 0, i64 0
  %r5 = ptrtoint i8* %r4 to i64
  store i64 %r5, i64* @asm_main
  %r6 = getelementptr [1 x i8], [1 x i8]* @.str.1455, i64 0, i64 0
  %r7 = ptrtoint i8* %r6 to i64
  store i64 %r7, i64* @asm_funcs
  store i64 0, i64* @in_func
  %r8 = call i64 @_list_new()
  store i64 %r8, i64* @local_vars
  store i64 0, i64* @stack_depth
  store i64 0, i64* @reg_count
  store i64 0, i64* @str_count
  store i64 0, i64* @label_count
  %r9 = getelementptr [1 x i8], [1 x i8]* @.str.1456, i64 0, i64 0
  %r10 = ptrtoint i8* %r9 to i64
  store i64 %r10, i64* @out_code
  %r11 = getelementptr [1 x i8], [1 x i8]* @.str.1457, i64 0, i64 0
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
