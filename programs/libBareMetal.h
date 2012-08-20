// =============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
//
// The BareMetal OS C/C++ library header.
//
// Version 2.0
//
// This allows for a C/C++ program to access OS functions available in BareMetal OS
// =============================================================================


void b_print_string(const char *str);
void b_print_char(char chr);
unsigned long b_input_string(unsigned char *str, unsigned long nbr);
unsigned char b_input_key(void);
void b_file_create(const char *name, unsigned long size);
void b_delay(unsigned long nbr);
void b_move_cursor(unsigned char col, unsigned char row);
void b_smp_reset(void);
unsigned long b_smp_get_id(void);
unsigned long b_smp_enqueue(void *ptr, unsigned long var);
unsigned long b_smp_dequeue(unsigned long *var);
void b_serial_send(unsigned char chr);
unsigned char b_serial_recv(void);
unsigned long b_smp_queuelen(void);
void b_smp_wait(unsigned long nbr);
void b_file_read(const unsigned char *name, void *mem);
void b_file_write(void *data, const unsigned char *name, unsigned int size);
void b_file_delete(const unsigned char *name);
// b_file_get_list
void b_smp_run(unsigned long ptr, unsigned long var);
void b_smp_lock(unsigned long ptr);
void b_smp_unlock(unsigned long ptr);
void b_ethernet_tx(void *mem, void *dest, unsigned short type, unsigned short len);
unsigned long b_ethernet_rx(void *mem);
unsigned long b_mem_allocate(unsigned long *mem, unsigned long nbr);
unsigned long b_mem_release(unsigned long *mem, unsigned long nbr);
unsigned long b_mem_get_free(void);
unsigned long b_smp_numcores(void);
unsigned long b_file_get_size(const char *name);
unsigned long b_ethernet_avail();
void b_ethernet_tx_raw(void *mem, unsigned short len);
void b_show_statusbar(void);
void b_hide_statusbar(void);
void b_screen_update(void);
void b_print_chars(const char *chrs, unsigned int len);
void b_print_chars_with_color(const char *chrs, unsigned int len, unsigned char clr);

// =============================================================================
// EOF
