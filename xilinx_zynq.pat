#include <std/string.pat>
#include <std/mem.pat>

union bootrom_union_0 {
    u32 user_defined_0;
    u32 fsbl_defined_0;
    u32 fsbl_execution_addr;
};

struct bootrom_img_details {
    u32 img_len;
    u32 reserved;
};

struct bootrom_pmufw_details {
    u32 pmufw_len;
    u32 pmufw_total_len;
};

union bootrom_union_1 {
    bootrom_img_details img_details;
    bootrom_pmufw_details pmufw_details;
};

union bootrom_union_2 {
    u32 start_of_exec;
    u32 fsbl_img_len;
};
    
union bootrom_union_zynq_0 {
    u32 user_defined_zynq_0[21];
    u32 fsbl_defined_zynq_0[21];
};

union bootrom_union_zynq_1 {
    u32 user_defined_zynq_1[8];
    u32 fsbl_defined_zynq_1[8];
};

struct bootrom_hdr {
  u32 interrupt_table[8];
  u32 width_detect;
  u32 img_id;
  u32 encryption_status;
  bootrom_union_0 anon_0;
  u32 src_offset;
  bootrom_union_1 anon_1;
  bootrom_union_2 anon_2;
  u32 total_img_len;
  u32 reserved;
  u32 checksum;
  /* The rest of the header is different for zynq and zynqmp*/
  bootrom_union_zynq_0 anon_3;
  u32 reg_init_zynq[512];
  bootrom_union_zynq_1 anon_4;
};

struct bootrom_img_hdr_table {
  u32 version;
  u32 hdrs_count;
  u32 part_hdr_off;     /* word offset to the partition header */
  u32 part_img_hdr_off; /* word offset to first image header */
  u32 auth_hdr_off;     /* word offset to header authentication */
  u32 pad[11];
};

       
struct be_chunk_string {
   u8 data[32];
};

struct bootrom_img_hdr {
  u32 next_img_off; /* 0 if last */
  u32 part_hdr_off;
  u32 part_count; /* always set to 0 */
  /* Name length is not really the length of the name.
   * According to the documentation it is the value of the
   * actual partition count, however the bootgen binary
   * always sets this field to 1. */
  u32 name_len;
  be_chunk_string name [[format_read("print_be_chunk_str"), transform("read_be_chunk_str")]];
  u8 pad[16];
};

struct bootrom_part_hdr {
  u32 pd_len;    /* encrypted partiton data length */
  u32 ed_len;    /* unecrypted data length */
  u32 total_len; /* total encrypted, padding,expansion, auth length */

  u32 dest_load_addr; /* RAM addr where the part will be loaded */
  u32 dest_exec_addr;
  u32 data_off;
  u32 attributes;
  u32 section_count;

  u32 checksum_off;
  u32 img_hdr_off;
  u32 cert_off;

  u32 reserved[4]; /* set to 0 */
  u32 checksum;
};

struct bootrom_part {
    bootrom_part_hdr part_hdr;
    u8 data[part_hdr.total_len * 4] @ part_hdr.data_off * 4;
};

struct bootrom_img {
    bootrom_img_hdr img_hdr;
    if (img_hdr.name_len == 1) {
        bootrom_part part @ img_hdr.part_hdr_off * 4;
    } else {
        bootrom_part part[img_hdr.name_len] @ img_hdr.part_hdr_off * 4;
    }
};

fn print_be_chunk_str(be_chunk_string inString) {
    str be_str;
    
    for (u32 i = 0, i < 32, i = i + 4) {
        std::print("{}", i);
        if (inString.data[i] == 0x0) {
            break;
        }
        
        u32 j = i + 3;
        while (j >= i) {
            if (inString.data[j] != 0) {
                std::print("{}, {}", j, inString.data[j]);
                be_str = be_str + char(inString.data[j]);
             }
             if (j == 0) break;
             j = j - 1;
        }
    }
    
    return be_str;
};

fn read_be_chunk_str(ref be_chunk_string inString) {
    be_chunk_string fixed_str;
    u32 fixed_str_size = 0;
    
    for (u32 i = 0, i < 4, i = i + 1) {
        if (inString.data[i] == 0x0) {
            break;
        }
        
        for (u32 j = i + 3, j >= i, j = j - 1) {
            if (inString.data[j] > 0) {
                fixed_str.data[fixed_str_size] = inString.data[j];
                fixed_str_size = fixed_str_size + 1;
             }
        }
    }
    
    fixed_str.data[fixed_str_size] = 0;
    return fixed_str;
};

fn read_img_hdr_name(str name) {
    char fixed_name[32];
    u32 fixed_name_size = 0;
    
    for (u32 i = 0, i < 16, i = i + 1) {
        if (name[i] == 0x0) {
            break;
        }
        
        for (u32 j = i + 3, j >= i, j = j - 1) {
            if (name[j] > 0) {
                // fixed_name[fixed_name_size] = name[j];
                fixed_name_size = fixed_name_size + 1;
             }
        }
    }
    
    // fixed_name[fixed_name_size] = 0;
    return fixed_name;
};

fn is_last_img_hdr(u32 img_hdr_addr) {
    u32 next_img_off @ img_hdr_addr;
    if (next_img_off == 0) {
        return 1;
    }
    return 0;
};

bool found_img_hdr_end = false;

fn keep_reading_img_headers() {
    if (found_img_hdr_end) return false;
    
    if (std::mem::read_unsigned($, 1) == 0) {
        found_img_hdr_end = true;
    }
    
    return true;
};

struct bootrom {
    bootrom_hdr hdr;
    bootrom_img_hdr_table img_hdr_table;
    bootrom_img img[while(keep_reading_img_headers())];
};

bootrom bootrom @ 0x0;