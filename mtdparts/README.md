# MTD partition layout for DPH-153 NOR flash

| mtd | name        | format      | start   | end     | bytes    | KB    |
|-----|-------------|-------------|---------|---------|----------|-------|
| 7   | fsboot      | blank       | 0       | 3FFFF   | 262144   | 256   |
| 1   | env         | raw         | 40000   | 7FFFF   | 262144   | 256   |
| 2   | kernel1     | zImage      | 80000   | 27FFFF  | 2097152  | 2048  |
| 3   | kernel2     | zImage      | 280000  | 47FFFF  | 2097152  | 2048  |
| 4   | config      | multi jffs2 | 480000  | 7FFFFF  | 3670016  | 3584  |
| 5   | fs1         | cramfs      | 800000  | 22FFFFF | 28311552 | 27648 |
| 6   | fs2         | cramfs      | 2300000 | 3DFFFFF | 28311552 | 27648 |
| 0   | u-boot      | ELF         | 3E00000 | 3E5FFFF | 393216   | 384   |
| 8   | oem_divert2 | blank       | 3E60000 | 3E7FFFF | 131072   | 128   |
| 9   | oem_data2   | blank       | 3EC0000 | 3EFFFFF | 262144   | 256   |
| 10  | oem_lib1    | blank       | 3F00000 | 3F3FFFF | 262144   | 256   |
| 11  | oem_lib2    | blank       | 3F40000 | 3F7FFFF | 262144   | 256   |
| N/A | resv        | blank       | 3F80000 | 3FBFFFF | 262144   | 256   |
| 12  | ipa_calib   | cramfs      | 3FC0000 | 3FFFFFF | 262144   | 256   |
