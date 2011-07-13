// =============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
//
// The BareMetal OS C library header.
//
// Version 2.0
//
// This allows for a C program to access OS functions available in BareMetal OS
// =============================================================================


void b_print_string(char *str);
void b_print_char(char chr);
void b_print_char_hex(char chr);
void b_print_newline(void);
void b_print_string_with_color(char *str, unsigned char clr);
void b_print_char_with_color(char chr, unsigned char clr);
void b_print_char_hex_with_color(char chr, unsigned char clr);


unsigned char b_input_get_key(void);
unsigned char b_input_wait_for_key(void);
unsigned long b_input_string(unsigned char *str, unsigned long nbr);


unsigned long b_string_length(unsigned char *str);
unsigned long b_string_find_char(unsigned char *str, unsigned char chr);
void b_os_string_copy(unsigned char *dst, unsigned char *src);
void b_int_to_string(unsigned long nbr, unsigned char *str);
unsigned long b_string_to_int(unsigned char *str);


void b_delay(unsigned long nbr);
unsigned long b_get_argc();
char* b_get_argv(unsigned char nbr);
unsigned long b_get_timercounter(void);


void b_debug_dump_mem(void *data, unsigned int size);


void b_serial_send(unsigned char chr);
unsigned char b_serial_recv(void);


void b_file_read(unsigned char *name, void *mem);
void b_file_write(void *data, unsigned char *name, unsigned int size);
void b_file_delete(unsigned char *name);


unsigned long b_smp_enqueue(void *ptr, unsigned long var);
unsigned long b_smp_dequeue(unsigned long *var);
void b_smp_run(unsigned long ptr);
unsigned long b_smp_queuelen(void);
void b_smp_wait(void);
void b_smp_lock(unsigned long ptr);
void b_smp_unlock(unsigned long ptr);
unsigned long b_smp_get_id(void);
unsigned long b_smp_numcores(void);


void b_speaker_tone(unsigned long nbr);
void b_speaker_off(void);
void b_speaker_beep(void);


void b_ethernet_tx(void *mem, void *dest, unsigned short type, unsigned short len);
void b_ethernet_tx_raw(void *mem, unsigned short len);
unsigned long b_ethernet_rx(void *mem);
unsigned long b_ethernet_avail();


// =============================================================================
// EOF
