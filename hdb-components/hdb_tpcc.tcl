proc check_oratpcc {} {
global instance system_user system_password count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp count_ware plsql directory partition hash_clusters tpcc_tt_compat num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists system_user ] } { set system_user "system" }
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists count_ware ] } { set count_ware "1" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists tpcc_def_tab ] } { set tpcc_def_tab "tpcctab" }
if {  ![ info exists tpcc_ol_tab ] } { set tpcc_ol_tab $tpcc_def_tab }
if {  ![ info exists tpcc_def_temp ] } { set tpcc_def_temp "temp" }
if {  ![ info exists count_ware ] } { set count_ware 1 }
if {  ![ info exists plsql ] } { set plsql 0 }
if {  ![ info exists directory ] } { set directory [ findtempdir ] }
if {  ![ info exists partition ] } { set partition "false" }
if {  ![ info exists hash_clusters ] } { set hash_clusters "false" }
if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
if {  ![ info exists num_threads ] } { set num_threads "1" }
if { $tpcc_tt_compat eq "true" } {
set install_message "Ready to create a $count_ware Warehouse TimesTen TPC-C schema\nin the existing database [string toupper $instance] under existing user [ string toupper $tpcc_user ]?" 
	} else {
set install_message "Ready to create a $count_ware Warehouse Oracle TPC-C schema\nin database [string toupper $instance] under user [ string toupper $tpcc_user ] in tablespace [ string toupper $tpcc_def_tab]?" 
	}
if {[ tk_messageBox -title "Create Schema" -icon question -message $install_message -type yesno ] == yes} { 
if { $num_threads eq 1 || $count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for schema creation: $message"
	return 1
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require Oratcl} ] { error "Failed to load Oratcl - Oracle OCI Library Error" }
proc CreateStoredProcs { lda timesten num_part } {
puts "CREATING TPCC STORED PROCEDURES"
set curn1 [ oraopen $lda ]
if { $timesten && $num_part != 0 } {
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
timestamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
stmt_str		VARCHAR2(512);
mywid			INTEGER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
integrity_viol			EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_viol,-1);
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM.value(low => 1, high => 100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM.value(low => 1, high => 100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM.value(low => 1, high => 100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM.value(low => 1, high => no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM.value(low => 1, high => 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

mywid := mod(no_w_id, 10);
IF ( mywid = 0 )
THEN
mywid := 10;
END IF;

stmt_str := 'INSERT INTO order_line_'||mywid||'(ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) VALUES (:o_id, :no_d_id, :no_w_id, :loop_counter, :no_ol_i_id, :no_ol_supply_w_id, :no_ol_quantity, :no_ol_amount, :no_ol_dist_info)';
--dbms_output.put_line(stmt_str);
EXECUTE IMMEDIATE stmt_str USING o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info;

END LOOP;

COMMIT;

EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol OR no_data_found
THEN
ROLLBACK;

END; }
} else {
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
timestamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
integrity_viol			EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_viol,-1);
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM.value(low => 1, high => 100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM.value(low => 1, high => 100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM.value(low => 1, high => 100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM.value(low => 1, high => no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM.value(low => 1, high => 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;

COMMIT;

EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol OR no_data_found
THEN
ROLLBACK;

END; }
}
if { $timesten } {
if { $num_part != 0 } { 
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
stmt_str		VARCHAR2(512);
mywid			INTEGER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id from (SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC) where rownum = 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;

mywid := mod(d_w_id, 10);
IF ( mywid = 0 )
THEN
mywid := 10;
END IF;

stmt_str := 'UPDATE order_line_'||mywid||' SET ol_delivery_d = :timestamp WHERE ol_o_id = :d_no_o_id AND ol_d_id = :d_d_id AND ol_w_id = :d_w_id';
EXECUTE IMMEDIATE stmt_str USING timestamp, d_no_o_id, d_d_id, d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END;
	}
} else {
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id from (SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC) where rownum = 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
  }
} else {
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
current_ROWID		UROWID;
--WHERE CURRENT OF CLAUSE IN SPECIFICATION GAVE VERY POOR PERFORMANCE
--USED ROWID AS GIVEN IN DOC CDOUG Tricks and Treats by Shahs Upadhye
CURSOR c_no IS
SELECT no_o_id,ROWID
FROM new_order
WHERE no_d_id = d_d_id AND no_w_id = d_w_id
ORDER BY no_o_id ASC;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
open c_no;
FETCH c_no INTO d_no_o_id,current_ROWID;
EXIT WHEN c_no%NOTFOUND;
DELETE FROM new_order WHERE rowid = current_ROWID;
close c_no;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
 }
set sql(3) { CREATE OR REPLACE PROCEDURE PAYMENT (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
p_c_id			IN OUT INTEGER,
byname			INTEGER,
p_h_amount		NUMBER,
p_c_last		IN OUT VARCHAR2,
p_w_street_1		OUT VARCHAR2,
p_w_street_2		OUT VARCHAR2,
p_w_city		OUT VARCHAR2,
p_w_state		OUT VARCHAR2,
p_w_zip			OUT VARCHAR2,
p_d_street_1		OUT VARCHAR2,
p_d_street_2		OUT VARCHAR2,
p_d_city		OUT VARCHAR2,
p_d_state		OUT VARCHAR2,
p_d_zip			OUT VARCHAR2,
p_c_first		OUT VARCHAR2,
p_c_middle		OUT VARCHAR2,
p_c_street_1		OUT VARCHAR2,
p_c_street_2		OUT VARCHAR2,
p_c_city		OUT VARCHAR2,
p_c_state		OUT VARCHAR2,
p_c_zip			OUT VARCHAR2,
p_c_phone		OUT VARCHAR2,
p_c_since		OUT DATE,
p_c_credit		IN OUT VARCHAR2,
p_c_credit_lim		OUT NUMBER,
p_c_discount		OUT NUMBER,
p_c_balance		IN OUT NUMBER,
p_c_data		OUT VARCHAR2,
timestamp		IN DATE )
IS
namecnt			INTEGER;
p_d_name		VARCHAR2(11);
p_w_name		VARCHAR2(11);
p_c_new_data		VARCHAR2(500);
h_data			VARCHAR2(30);
CURSOR c_byname IS
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. (namecnt/2)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
-- The following statement in the TPC-C specification appendix is incorrect
-- copied setting of h_data from later on in the procedure to here as well
h_data := ( p_w_name || ' ' || p_d_name );
p_c_new_data := (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' ||
TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || TO_CHAR(p_h_amount,'9999.99') || TO_CHAR(timestamp) || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
--setting of h_data is here in the TPC-C appendix
h_data := ( p_w_name|| ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, timestamp, p_h_amount, h_data);
COMMIT;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
set sql(4) { CREATE OR REPLACE PROCEDURE OSTAT (
os_w_id			INTEGER,
os_d_id			INTEGER,
os_c_id			IN OUT INTEGER,
byname			INTEGER,
os_c_last		IN OUT VARCHAR2,
os_c_first		OUT VARCHAR2,
os_c_middle		OUT VARCHAR2,
os_c_balance		OUT NUMBER,
os_o_id			OUT INTEGER,
os_entdate		OUT DATE,
os_o_carrier_id		OUT INTEGER )
IS
TYPE numbertable IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
os_ol_i_id numbertable;	
os_ol_supply_w_id numbertable;	
os_ol_quantity numbertable;	
TYPE amounttable IS TABLE OF NUMBER(6,2) INDEX BY BINARY_INTEGER;
os_ol_amount amounttable;
TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
os_ol_delivery_d datetable;
namecnt			INTEGER;
i			BINARY_INTEGER;
CURSOR c_name IS
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
CURSOR c_line IS
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
os_c_line c_line%ROWTYPE;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. (namecnt/2)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
-- The following statement in the TPC-C specification appendix is incorrect
-- as it does not include the where clause and does not restrict the 
-- results set giving an ORA-01422.
-- The statement has been modified in accordance with the
-- descriptive specification as follows:
-- The row in the ORDER table with matching O_W_ID (equals C_W_ID),
-- O_D_ID (equals C_D_ID), O_C_ID (equals C_ID), and with the largest
-- existing O_ID, is selected. This is the most recent order placed by that
-- customer. O_ID, O_ENTRY_D, and O_CARRIER_ID are retrieved.
BEGIN
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC)
WHERE ROWNUM = 1;
EXCEPTION
WHEN NO_DATA_FOUND THEN
dbms_output.put_line('No orders for customer');
END;
i := 0;
FOR os_c_line IN c_line
LOOP
os_ol_i_id(i) := os_c_line.ol_i_id;
os_ol_supply_w_id(i) := os_c_line.ol_supply_w_id;
os_ol_quantity(i) := os_c_line.ol_quantity;
os_ol_amount(i) := os_c_line.ol_amount;
os_ol_delivery_d(i) := os_c_line.ol_delivery_d;
i := i+1;
END LOOP;
EXCEPTION WHEN not_serializable OR deadlock OR snapshot_too_old THEN
ROLLBACK;
END; }
set sql(5) { CREATE OR REPLACE PROCEDURE SLEV (
st_w_id			INTEGER,
st_d_id			INTEGER,
threshold		INTEGER )
IS 
st_o_id			NUMBER;	
stock_count		INTEGER;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;

SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
COMMIT;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
for { set i 1 } { $i <= 5 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc TTPLSQLSettings { lda } {
set curn1 [ oraopen $lda ]
set sql(1) "alter session set PLSQL_OPTIMIZE_LEVEL = 2"
set sql(2) "alter session set PLSQL_CODE_TYPE = INTERPRETED"
set sql(3) "alter session set NLS_LENGTH_SEMANTICS = BYTE"
set sql(4) "alter session set PLSQL_CCFLAGS = ''"
set sql(5) "alter session set PLSCOPE_SETTINGS = 'IDENTIFIERS:NONE'"
for { set i 1 } { $i <= 5 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc GatherStatistics { lda tpcc_user timesten num_part } {
puts "GATHERING SCHEMA STATISTICS"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "call ttOptUpdateStats('WAREHOUSE',1)"
set sql(2) "call ttOptUpdateStats('DISTRICT',1)"
set sql(3) "call ttOptUpdateStats('ITEM',1)"
set sql(4) "call ttOptUpdateStats('STOCK',1)"
set sql(5) "call ttOptUpdateStats('CUSTOMER',1)"
set sql(6) "call ttOptUpdateStats('ORDERS',1)"
set sql(7) "call ttOptUpdateStats('NEW_ORDER',1)"
set sql(8) "call ttOptUpdateStats('HISTORY',1)"
for { set i 1 } { $i <= 8 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
if { $num_part eq 0 } {
set sql(9) "call ttOptUpdateStats('ORDER_LINE',1)"
set i 9
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
          }
	} else {
set sql(9a) "call ttOptUpdateStats('ORDER_LINE_1',1)"
set sql(9b) "call ttOptUpdateStats('ORDER_LINE_2',1)"
set sql(9c) "call ttOptUpdateStats('ORDER_LINE_3',1)"
set sql(9d) "call ttOptUpdateStats('ORDER_LINE_4',1)"
set sql(9e) "call ttOptUpdateStats('ORDER_LINE_5',1)"
set sql(9f) "call ttOptUpdateStats('ORDER_LINE_6',1)"
set sql(9g) "call ttOptUpdateStats('ORDER_LINE_7',1)"
set sql(9h) "call ttOptUpdateStats('ORDER_LINE_8',1)"
set sql(9i) "call ttOptUpdateStats('ORDER_LINE_9',1)"
set sql(9j) "call ttOptUpdateStats('ORDER_LINE_10',1)"
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
if {[ catch {orasql $curn1 $sql(9$idx)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
          }
        }
     }
   } else {
set sql(1) "BEGIN dbms_stats.gather_schema_stats('$tpcc_user'); END;"
if {[ catch {orasql $curn1 $sql(1)} message ] } {
puts "$message $sql(1)"
puts [ oramsg $curn1 all ]
	}
}
oraclose $curn1
return
}

proc CreateUser { lda tpcc_user tpcc_pass tpcc_def_tab tpcc_def_temp tpcc_ol_tab partition} {
puts "CREATING USER $tpcc_user"
set stmt_cnt 3
set curn1 [ oraopen $lda ]
set sql(1) "create user $tpcc_user identified by $tpcc_pass default tablespace $tpcc_def_tab temporary tablespace $tpcc_def_temp\n"
set sql(2) "grant connect,resource to $tpcc_user\n"
set sql(3) "alter user $tpcc_user quota unlimited on $tpcc_def_tab\n"
if { $partition eq "true" } {
if { $tpcc_def_tab != $tpcc_ol_tab } { 
set stmt_cnt 4
set sql(4) "alter user $tpcc_user quota unlimited on $tpcc_ol_tab\n"
	}
  }
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc CreateTables { lda num_part tpcc_ol_tab timesten hash_clusters count_ware } {
puts "CREATING TPCC TABLES"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "create table TPCC.CUSTOMER (C_ID TT_BIGINT, C_D_ID TT_INTEGER, C_W_ID TT_INTEGER, C_FIRST CHAR(16), C_MIDDLE CHAR(2), C_LAST CHAR(16), C_STREET_1 CHAR(20), C_STREET_2 CHAR(20), C_CITY CHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM BINARY_DOUBLE, C_DISCOUNT BINARY_DOUBLE, C_BALANCE BINARY_DOUBLE, C_YTD_PAYMENT BINARY_DOUBLE, C_PAYMENT_CNT TT_INTEGER, C_DELIVERY_CNT TT_INTEGER, C_DATA VARCHAR2(500))"
set sql(2) "create table TPCC.DISTRICT (D_ID TT_INTEGER, D_W_ID TT_INTEGER, D_YTD BINARY_DOUBLE, D_TAX BINARY_DOUBLE, D_NEXT_O_ID TT_BIGINT, D_NAME CHAR(10), D_STREET_1 CHAR(20), D_STREET_2 CHAR(20), D_CITY CHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9))"
set sql(3) "create table TPCC.HISTORY (H_C_ID TT_BIGINT, H_C_D_ID TT_INTEGER, H_C_W_ID TT_INTEGER, H_D_ID TT_INTEGER, H_W_ID TT_INTEGER, H_DATE DATE, H_AMOUNT BINARY_DOUBLE, H_DATA CHAR(24))"
set sql(4) "create table TPCC.ITEM (I_ID TT_BIGINT, I_IM_ID TT_BIGINT, I_NAME CHAR(24), I_PRICE BINARY_DOUBLE, I_DATA CHAR(50))"
set sql(5) "create table TPCC.NEW_ORDER (NO_W_ID TT_BIGINT, NO_D_ID TT_INTEGER, NO_O_ID TT_INTEGER)"
set sql(6) "create table TPCC.ORDERS (O_ID TT_BIGINT, O_W_ID TT_BIGINT, O_D_ID TT_INTEGER, O_C_ID TT_INTEGER, O_CARRIER_ID TT_INTEGER, O_OL_CNT TT_INTEGER, O_ALL_LOCAL TT_INTEGER, O_ENTRY_D DATE)"
if {$num_part eq 0} {
set sql(7) "create table TPCC.ORDER_LINE (OL_W_ID TT_BIGINT, OL_D_ID TT_INTEGER, OL_O_ID TT_INTEGER, OL_NUMBER TT_INTEGER, OL_I_ID TT_BIGINT, OL_DELIVERY_D DATE, OL_AMOUNT BINARY_DOUBLE, OL_SUPPLY_W_ID TT_INTEGER, OL_QUANTITY TT_INTEGER, OL_DIST_INFO CHAR(24))"
	} else {
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
set sql(7$idx) "create table TPCC.ORDER_LINE_$p (OL_W_ID TT_BIGINT, OL_D_ID TT_INTEGER, OL_O_ID TT_INTEGER, OL_NUMBER TT_INTEGER, OL_I_ID TT_BIGINT, OL_DELIVERY_D DATE, OL_AMOUNT BINARY_DOUBLE, OL_SUPPLY_W_ID TT_INTEGER, OL_QUANTITY TT_INTEGER, OL_DIST_INFO CHAR(24))"
		}
set idx k
set sql(7$idx) "create view ORDER_LINE AS ("
for { set p 1 } { $p <= 9 } { incr p } {
set sql(7$idx) "$sql(7$idx) SELECT * FROM ORDER_LINE_$p UNION ALL" 
		}
set p 10
set sql(7$idx) "$sql(7$idx) SELECT * FROM ORDER_LINE_$p )"
	}
set sql(8) "create table TPCC.STOCK (S_I_ID TT_BIGINT, S_W_ID TT_INTEGER, S_QUANTITY TT_INTEGER, S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD TT_BIGINT, S_ORDER_CNT TT_INTEGER, S_REMOTE_CNT TT_INTEGER, S_DATA CHAR(50))"
set sql(9) "create table TPCC.WAREHOUSE (W_ID TT_INTEGER, W_YTD BINARY_DOUBLE, W_TAX BINARY_DOUBLE, W_NAME CHAR(10), W_STREET_1 CHAR(20), W_STREET_2 CHAR(20), W_CITY CHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9))"
	} else {
if  { $hash_clusters } {
set blocksize 8000
while 1 { if { ![ expr {$count_ware % 100} ] } { break } else { incr $count_ware } } 
set ware_hkeys $count_ware
set dist_hkeys [ expr {$ware_hkeys * 10} ]
set cust_hkeys [ expr {$count_ware * 30000} ]
set cust_mult [ expr {$cust_hkeys / 3000} ]
set stock_hkeys [ expr {$count_ware * 100000} ]
set stock_mult $count_ware
set sqlclust(1) "CREATE CLUSTER CUSTCLUSTER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0)) SINGLE TABLE HASHKEYS $cust_hkeys hash is ((c_id * $cust_mult)+(c_w_id * 10) + c_d_id) size 650 INITRANS 4 PCTFREE 0"
set sqlclust(2) "CREATE CLUSTER DISTCLUSTER (D_W_ID NUMBER(4, 0), D_ID NUMBER(2, 0)) SINGLE TABLE HASHKEYS $dist_hkeys hash is ((d_w_id) * 10 + d_id) size $blocksize INITRANS 4 PCTFREE 0"
set sqlclust(3) "CREATE CLUSTER ITEMCLUSTER (I_ID NUMBER(6, 0)) SINGLE TABLE HASHKEYS 100000 hash is i_id size 120 INITRANS 4 PCTFREE 0"
set sqlclust(4) "CREATE CLUSTER WARECLUSTER (W_ID NUMBER(4, 0)) SINGLE TABLE HASHKEYS $ware_hkeys hash is w_id size $blocksize INITRANS 4 PCTFREE 0"
set sqlclust(5) "CREATE CLUSTER STOCKCLUSTER (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0)) SINGLE TABLE HASHKEYS $stock_hkeys hash is (s_i_id * $stock_mult + s_w_id) size 350 INITRANS 4 PCTFREE 0"
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500)) CLUSTER CUSTCLUSTER (C_ID, C_D_ID, C_W_ID)"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(4, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9)) CLUSTER DISTCLUSTER (D_W_ID, D_ID)"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50)) CLUSTER ITEMCLUSTER(I_ID)"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(4, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9)) CLUSTER WARECLUSTER(W_ID)"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50)) CLUSTER STOCKCLUSTER(S_I_ID, S_W_ID)"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER, CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 MAXTRANS 16 PCTFREE 10" 
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10 PARTITION BY HASH(OL_W_ID) PARTITIONS $num_part TABLESPACE $tpcc_ol_tab"
	} else {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(4, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9)) INITRANS 4 MAXTRANS 16 PCTFREE 99 PCTUSED 1"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(4, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9)) INITRANS 4 MAXTRANS 16 PCTFREE 99 PCTUSED 1"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER, CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE ) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 MAXTRANS 16 PCTFREE 10"
if {$num_part eq 0} {
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10"
	} else {
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10 PARTITION BY HASH(OL_W_ID) PARTITIONS $num_part TABLESPACE $tpcc_ol_tab"
	}
    }
}   
if { $hash_clusters } {
for { set j 1 } { $j <= 5 } { incr j } {
if {[ catch {orasql $curn1 $sqlclust($j)} message ] } {
puts "$message $sql($j)"
puts [ oramsg $curn1 all ]
			}
		}
	}
for { set i 1 } { $i <= 9 } { incr i } {
if { $i eq 7 && $timesten && $num_part eq 10 } {
set partidx [ list a b c d e f g h i j k ]
for { set p 1 } { $p <= 11 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
if {[ catch {orasql $curn1 $sql(7$idx)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
	}}} else {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
	}
oraclose $curn1
return
}

proc CreateIndexes { lda timesten num_part hash_clusters } {
puts "CREATING TPCC INDEXES"
set curn1 [ oraopen $lda ]
set stmt_cnt 9
if { $timesten } {
if { $num_part eq 0 } {
set stmt_cnt 10
set sql(1) "create unique index TPCC.WAREHOUSE_I1 on TPCC.WAREHOUSE (W_ID)"
set sql(2) "create unique index TPCC.STOCK_I1 on TPCC.STOCK (S_I_ID, S_W_ID)"
set sql(3) "create unique index TPCC.ORDER_LINE_I1 on TPCC.ORDER_LINE (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(4) "create unique index TPCC.ORDERS_I1 on TPCC.ORDERS (O_W_ID, O_D_ID, O_ID)"
set sql(5) "create unique index TPCC.ORDERS_I2 on TPCC.ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(6) "create unique index TPCC.NEW_ORDER_I1 on TPCC.NEW_ORDER (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(7) "create unique index TPCC.ITEM_I1 on TPCC.ITEM (I_ID)"
set sql(8) "create unique index TPCC.DISTRICT_I1 on TPCC.DISTRICT (D_W_ID, D_ID)"
set sql(9) "create unique index TPCC.CUSTOMER_I1 on TPCC.CUSTOMER (C_W_ID, C_D_ID, C_ID)"
set sql(10) "create unique index TPCC.CUSTOMER_I2 on TPCC.CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
	  } else {
set stmt_cnt 19
set sql(1) "create unique index TPCC.WAREHOUSE_I1 on TPCC.WAREHOUSE (W_ID)"
set sql(2) "create unique index TPCC.STOCK_I1 on TPCC.STOCK (S_I_ID, S_W_ID)"
set sql(3) "create unique index TPCC.ORDER_LINE_I1 on TPCC.ORDER_LINE_1 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(4) "create unique index TPCC.ORDER_LINE_I2 on TPCC.ORDER_LINE_2 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(5) "create unique index TPCC.ORDER_LINE_I3 on TPCC.ORDER_LINE_3 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(6) "create unique index TPCC.ORDER_LINE_I4 on TPCC.ORDER_LINE_4 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(7) "create unique index TPCC.ORDER_LINE_I5 on TPCC.ORDER_LINE_5 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(8) "create unique index TPCC.ORDER_LINE_I6 on TPCC.ORDER_LINE_6 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(9) "create unique index TPCC.ORDER_LINE_I7 on TPCC.ORDER_LINE_7 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(10) "create unique index TPCC.ORDER_LINE_I8 on TPCC.ORDER_LINE_8 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(11) "create unique index TPCC.ORDER_LINE_I9 on TPCC.ORDER_LINE_9 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(12) "create unique index TPCC.ORDER_LINE_I10 on TPCC.ORDER_LINE_10 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(13) "create unique index TPCC.ORDERS_I1 on TPCC.ORDERS (O_W_ID, O_D_ID, O_ID)"
set sql(14) "create unique index TPCC.ORDERS_I2 on TPCC.ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(15) "create unique index TPCC.NEW_ORDER_I1 on TPCC.NEW_ORDER (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(16) "create unique index TPCC.ITEM_I1 on TPCC.ITEM (I_ID)"
set sql(17) "create unique index TPCC.DISTRICT_I1 on TPCC.DISTRICT (D_W_ID, D_ID)"
set sql(18) "create unique index TPCC.CUSTOMER_I1 on TPCC.CUSTOMER (C_W_ID, C_D_ID, C_ID)"
set sql(19) "create unique index TPCC.CUSTOMER_I2 on TPCC.CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
	}
   } else {
if { $hash_clusters } {
set stmt_cnt 18
set sql(1) "alter session set sort_area_size=5000000"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I1 ON CUSTOMER (C_W_ID, C_D_ID, C_ID) INITRANS 4 PCTFREE 1"
set sql(3) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_LAST, C_D_ID, C_W_ID, C_FIRST) INITRANS 4 PCTFREE 1"
set sql(4) "CREATE UNIQUE INDEX DISTRICT_I1 ON DISTRICT (D_W_ID, D_ID) INITRANS 4 PCTFREE 5"
set sql(5) "CREATE UNIQUE INDEX ITEM_I1 ON ITEM (I_ID) INITRANS 4 PCTFREE 5"
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 PCTFREE 1"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 PCTFREE 25"
set sql(8) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK (S_I_ID, S_W_ID) INITRANS 4 PCTFREE 1"
set sql(9) "CREATE UNIQUE INDEX WAREHOUSE_I1 ON WAREHOUSE (W_ID) INITRANS 4 PCTFREE 1"
set sql(10) "ALTER TABLE WAREHOUSE DISABLE TABLE LOCK"
set sql(11) "ALTER TABLE DISTRICT DISABLE TABLE LOCK"
set sql(12) "ALTER TABLE CUSTOMER DISABLE TABLE LOCK"
set sql(13) "ALTER TABLE ITEM DISABLE TABLE LOCK"
set sql(14) "ALTER TABLE STOCK DISABLE TABLE LOCK"
set sql(15) "ALTER TABLE ORDERS DISABLE TABLE LOCK"
set sql(16) "ALTER TABLE NEW_ORDER DISABLE TABLE LOCK"
set sql(17) "ALTER TABLE ORDER_LINE DISABLE TABLE LOCK"
set sql(18) "ALTER TABLE HISTORY DISABLE TABLE LOCK"
	} else {
set sql(1) "alter session set sort_area_size=5000000"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I1 ON CUSTOMER ( C_W_ID, C_D_ID, C_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(3) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER ( C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(4) "CREATE UNIQUE INDEX DISTRICT_I1 ON DISTRICT ( D_W_ID, D_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(5) "CREATE UNIQUE INDEX ITEM_I1 ON ITEM (I_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(8) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK (S_I_ID, S_W_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(9) "CREATE UNIQUE INDEX WAREHOUSE_I1 ON WAREHOUSE (W_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
		}
	}
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc CreateDirectory { lda directory tpcc_user } {
set curn1 [ oraopen $lda ]
set sql(1) "CREATE OR REPLACE DIRECTORY tpcc_log AS '$directory'"
set sql(2) "GRANT READ,WRITE ON DIRECTORY tpcc_log TO $tpcc_user"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc ServerSidePackage { lda count_ware } {
set curn1 [ oraopen $lda ]
set sql(1) "CREATE OR REPLACE PACKAGE tpcc_server_side
AUTHID CURRENT_USER 
IS
  PROCEDURE LoadSchema(count_ware NUMBER);
  FUNCTION RandomNumber (p_min NUMBER, p_max NUMBER) RETURN NUMBER;
  FUNCTION NURand (p_const NUMBER, p_x NUMBER, p_y NUMBER, p_c NUMBER)
  RETURN NUMBER;
  FUNCTION Lastname (num NUMBER) RETURN VARCHAR;
  FUNCTION MakeAlphaString (p_x NUMBER, p_y NUMBER) RETURN VARCHAR;
  FUNCTION MakeZip RETURN VARCHAR;
  FUNCTION MakeNumberString RETURN VARCHAR;
END;"
if {[ catch {orasql $curn1 $sql(1)} message ] } {
puts "$message $sql(1)"
puts [ oramsg $curn1 all ]
}

set sql(2) "CREATE OR REPLACE PACKAGE BODY tpcc_server_side
IS
  c_maxitems CONSTANT NUMBER := 100000;
  c_customers_per_district CONSTANT NUMBER := 3000;
  c_districts_per_warehouse CONSTANT NUMBER := 10;
  c_orders_per_district CONSTANT NUMBER := 3000;

  trace_file UTL_FILE.FILE_TYPE;
  trace_directory VARCHAR2(30) := 'TPCC_LOG';

  TYPE namearray IS TABLE OF VARCHAR2(10)
    INDEX BY BINARY_INTEGER;
  namearr namearray;

  TYPE globarray IS TABLE OF CHAR
    INDEX BY BINARY_INTEGER;
  list globarray;

  TYPE numarray IS TABLE OF BINARY_INTEGER
    INDEX BY BINARY_INTEGER;

  TYPE address IS RECORD
  (
    street_1 VARCHAR2(20),
    street_2 VARCHAR2(20),
    city     VARCHAR2(20),
    state    CHAR(2),
    zip      CHAR(9)
  );

  PROCEDURE OpenTrace 
  (
    directory_name VARCHAR2,
    file_name VARCHAR2
  )
  IS
  BEGIN
    trace_file := utl_file.fopen (directory_name,file_name,'a');
  END;
 
  PROCEDURE WriteTrace (s VARCHAR2)
  IS
  BEGIN
    utl_file.put (trace_file,TO_CHAR (SYSDATE,'HH24:MI:SS '));
    utl_file.put_line (trace_file,s);
    utl_file.fflush (trace_file);
  END;

  PROCEDURE CloseTrace
  IS
  BEGIN
    utl_file.fclose (trace_file);
  END;

  FUNCTION RandomNumber (p_min NUMBER, p_max NUMBER) 
  RETURN NUMBER
  IS
  BEGIN
    RETURN TRUNC (ABS (dbms_random.value (p_min,p_max)));
  END;

  FUNCTION NURand (p_const NUMBER, p_x NUMBER, p_y NUMBER, p_c NUMBER)
  RETURN NUMBER
  IS
    l_rand_num NUMBER;
    l_ran1 NUMBER;
    l_ran2 NUMBER;
  BEGIN
    l_ran1 := RandomNumber (0,p_Const); 
    l_ran2 := RandomNumber (p_x,p_y);
    l_rand_num := MOD (l_ran1+l_ran2-BITAND(l_ran1,l_ran2)+p_c, p_y-p_x+1) + p_x;
    RETURN l_rand_num;
  END;

  FUNCTION Lastname (num NUMBER) RETURN VARCHAR
  IS
    name VARCHAR2(20);
  BEGIN
    name := namearr (TRUNC (MOD ((num / 100),10)))||
    namearr (TRUNC (MOD ((num / 10),10)))||
    namearr (TRUNC (MOD ((num / 1),10)));
  
    RETURN name; 
  END;


  FUNCTION MakeAlphaString (p_x NUMBER, p_y NUMBER)
  RETURN VARCHAR
  IS
    l_len NUMBER := RandomNumber (p_x,p_y);
    l_string VARCHAR2(4000) := '';
    l_ch CHAR;
  BEGIN
    FOR i IN 0..l_len - 1 LOOP
      l_ch := list (TRUNC (ABS (dbms_random.value (0,list.COUNT -1))));  
      l_string := l_string || l_ch; 
    END LOOP;
    RETURN l_string;
  END;

  FUNCTION MakeZip 
  RETURN VARCHAR
  IS 
    l_zip VARCHAR2(10) := '000011111';
    l_ranz NUMBER := RandomNumber (0,9999);
    l_len NUMBER := LENGTH (TO_CHAR (l_ranz));
  BEGIN
    l_zip := TO_CHAR (l_ranz) || SUBSTR (l_zip,l_len + 1,9);
    return l_zip;
  END;

  FUNCTION  MakeAddress RETURN address
  IS 
    add address;
  BEGIN
    add.street_1 := MakeAlphaString (10,20);
    add.street_2 := MakeAlphaString (10,20);
    add.city     := MakeAlphaString (10,20);
    add.state    := MakeAlphaString (2,2);
    add.zip      := MakeZip;
    return add;
  END;

  FUNCTION MakeNumberString
  RETURN VARCHAR
  IS
    l_zeroed VARCHAR2(8);
    l_a NUMBER;
    l_b NUMBER;
    l_lena NUMBER;
    l_lenb NUMBER;
    l_c_pa VARCHAR2(8);
    l_c_pb VARCHAR2(8);
  BEGIN
    l_zeroed := '00000000';
    l_a := RandomNumber (0,99999999);
    l_b := RandomNumber (0,99999999);
    l_lena := LENGTH (TO_CHAR (l_a)); 
    l_lenb := LENGTH (TO_CHAR (l_b)); 
    l_c_pa := TO_CHAR (l_a)||SUBSTR (l_zeroed,l_lena + 1);
    l_c_pb := TO_CHAR (l_b)||SUBSTR (l_zeroed,l_lenb + 1);
    RETURN l_c_pa||l_c_pb;
  END;

  PROCEDURE Customer 
  (
    p_d_id NUMBER,
    p_w_id NUMBER,
    p_customers_per_district NUMBER
  )
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_cust PLS_INTEGER := 1;
    l_nrnd NUMBER;
    l_c_add address;

    TYPE l_c_id_aat IS TABLE OF NUMBER(5) INDEX BY PLS_INTEGER;
    TYPE l_c_d_id_aat IS TABLE OF NUMBER(2) INDEX BY PLS_INTEGER;
    TYPE l_c_w_id_aat IS TABLE OF NUMBER(4) INDEX BY PLS_INTEGER;
    TYPE l_c_first_aat IS TABLE OF VARCHAR(16) INDEX BY PLS_INTEGER;
    TYPE l_c_middle_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_last_aat IS TABLE OF VARCHAR2(16) INDEX BY PLS_INTEGER;
    TYPE l_c_street_1_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_street_2_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_city_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_state_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_zip_aat IS TABLE OF CHAR(9) INDEX BY PLS_INTEGER;
    TYPE l_c_phone_aat IS TABLE OF CHAR(16) INDEX BY PLS_INTEGER;
    TYPE l_c_credit_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_credit_lim_aat IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    TYPE l_c_discount_aat IS TABLE OF NUMBER(4,4) INDEX BY PLS_INTEGER;
    TYPE l_c_balance_aat IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    TYPE l_c_data_aat IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
    TYPE l_h_amount_aat IS TABLE OF HISTORY.H_AMOUNT%TYPE INDEX BY PLS_INTEGER;
    TYPE l_h_data_aat IS TABLE OF HISTORY.H_DATA%TYPE INDEX BY PLS_INTEGER;

l_c_id l_c_id_aat;
l_c_d_id l_c_d_id_aat;
l_c_w_id l_c_w_id_aat;
l_c_first l_c_first_aat;
l_c_middle l_c_middle_aat;
l_c_last l_c_last_aat;
l_c_street_1 l_c_street_1_aat;
l_c_street_2 l_c_street_2_aat;
l_c_city l_c_city_aat;
l_c_state l_c_state_aat;
l_c_zip l_c_zip_aat;
l_c_phone l_c_phone_aat;
l_c_credit l_c_credit_aat; 
l_c_credit_lim l_c_credit_lim_aat;
l_c_discount l_c_discount_aat;
l_c_balance l_c_balance_aat;
l_c_data l_c_data_aat;
l_h_amount l_h_amount_aat;
l_h_data l_h_data_aat;

  BEGIN
    WriteTrace ('Loading Customer for D='||p_d_id||' W='||p_w_id);

    FOR i IN 1 ..p_customers_per_district LOOP
      l_c_id(i) := i;
      l_c_d_id(i) := p_d_id;
      l_c_w_id(i) := p_w_id;
      l_c_first(i) := MakeAlphaString (8,16);
      l_c_middle(i) := 'OE';
      IF l_c_id(i) <= 1000 THEN
        l_c_last(i) := LastName (l_c_id(i) - 1);
      ELSE
        l_nrnd := NURand (255,0,999,123);
        l_c_last(i) := LastName (l_nrnd);
      END IF;
      l_c_add := MakeAddress;
        l_c_street_1(i) := l_c_add.street_1;
        l_c_street_2(i) := l_c_add.street_2;
        l_c_city(i) := l_c_add.city;
        l_c_state(i) := l_c_add.state;
        l_c_zip(i) := l_c_add.zip; 

      l_c_phone(i) := MakeNumberString;
      IF RandomNumber (0,1) = 1  THEN
        l_c_credit(i) := 'GC';
      ELSE
        l_c_credit(i) := 'BC';
      END IF;
      l_c_credit_lim(i) := 50000;
      l_c_discount(i) := RandomNumber (0,50) / 100.0;
      l_c_balance(i) := -10;
      l_c_data(i) := MakeAlphaString (300,500);

      l_h_amount(i) := 10;
      l_h_data(i) := MakeAlphastring (12,24);
   
      IF MOD (l_c_id(i) ,1000) = 0 THEN

IF
l_c_id(i) = p_customers_per_district
THEN
end_cust := 0;
END IF;

	FORALL indx IN l_c_id.FIRST .. l_c_id.LAST - end_cust
 INSERT INTO customer 
      (
        c_id, 
        c_d_id, 
        c_w_id, 
        c_first, 
        c_middle, 
        c_last, 
        c_street_1, 
        c_street_2, 
        c_city, 
        c_state, 
        c_zip, 
        c_phone, 
        c_since, 
        c_credit, 
        c_credit_lim, 
        c_discount, 
        c_balance, 
        c_data, 
        c_ytd_payment, 
        c_payment_cnt, 
        c_delivery_cnt
      ) 
      VALUES 
      (
        l_c_id(indx), 
        l_c_d_id(indx), 
        l_c_w_id(indx), 
        l_c_first(indx), 
        l_c_middle(indx), 
        l_c_last(indx), 
        l_c_street_1(indx), 
        l_c_street_2(indx), 
        l_c_city(indx), 
        l_c_state(indx), 
        l_c_zip(indx), 
        l_c_phone(indx), 
        SYSDATE,
        l_c_credit(indx), 
        l_c_credit_lim(indx), 
        l_c_discount(indx), 
        l_c_balance(indx), 
        l_c_data(indx), 
        10.0, 
        1, 
        0
      );
COMMIT;

FORALL indx IN l_c_id.FIRST .. l_c_id.LAST - end_cust
      INSERT INTO history 
      (
        h_c_id, 
        h_c_d_id, 
        h_c_w_id, 
        h_w_id, 
        h_d_id, 
        h_date, 
        h_amount, 
        h_data
      ) 
      VALUES 
      ( 
        l_c_id(indx),  
        l_c_d_id(indx),  
        l_c_w_id(indx),  
        l_c_w_id(indx),  
        l_c_d_id(indx),  
        SYSDATE,
        l_h_amount(indx),  
        l_h_data(indx)
      );
COMMIT;

l_c_id.delete(lst_indx,i-1);
l_c_d_id.delete(lst_indx,i-1);
l_c_w_id.delete(lst_indx,i-1);
l_c_first.delete(lst_indx,i-1);
l_c_middle.delete(lst_indx,i-1);
l_c_last.delete(lst_indx,i-1);
l_c_street_1.delete(lst_indx,i-1);
l_c_street_2.delete(lst_indx,i-1);
l_c_city.delete(lst_indx,i-1);
l_c_state.delete(lst_indx,i-1);
l_c_zip.delete(lst_indx,i-1);
l_c_phone.delete(lst_indx,i-1);
l_c_credit.delete(lst_indx,i-1);
l_c_credit_lim.delete(lst_indx,i-1);
l_c_discount.delete(lst_indx,i-1);
l_c_balance.delete(lst_indx,i-1);
l_c_data.delete(lst_indx,i-1);
l_h_amount.delete(lst_indx,i-1);
l_h_data.delete(lst_indx,i-1);

	lst_indx :=i-1;

      END IF;
 
      IF MOD (l_c_id(i) ,1000) = 0 THEN
	WriteTrace ('Loading Customer '||l_c_id(i));
      END IF;
    END LOOP;
    WriteTrace ('Customer Done');
  END;



  PROCEDURE Orders 
  (
    p_d_id NUMBER, 
    p_w_id NUMBER, 
    p_maxitems NUMBER,
    p_orders_per_district NUMBER
  )
  IS
  indx PLS_INTEGER := 0;
  jndx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    lst_jndx PLS_INTEGER := 0;
    ol_total PLS_INTEGER := 0;
    end_order PLS_INTEGER := 1;
   end_ol PLS_INTEGER := 1;
    l_cust numarray;
    l_r NUMBER;
    l_t NUMBER;
TYPE l_o_d_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_w_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_c_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_carrier_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_ol_cnt_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_i_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_supply_w_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_quantity_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_amount_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_dist_info_aat IS TABLE OF CHAR(24) INDEX BY PLS_INTEGER;
TYPE l_ol_delivery_d_aat IS TABLE OF DATE INDEX BY PLS_INTEGER;
    l_o_d_id l_o_d_id_aat;
    l_o_w_id l_o_w_id_aat;
    l_o_id l_o_id_aat;
    no_l_o_d_id l_o_d_id_aat;
    no_l_o_w_id l_o_w_id_aat;
    no_l_o_id l_o_id_aat;
    oli_l_o_id l_o_id_aat;
    oli_l_o_d_id l_o_d_id_aat;
    oli_l_o_w_id l_o_w_id_aat;
    l_o_c_id l_o_c_id_aat;
    l_o_carrier_id l_o_carrier_id_aat;
    l_o_ol_cnt l_o_ol_cnt_aat; 
    l_ol l_ol_aat;
    l_ol_i_id l_ol_i_id_aat; 
    l_ol_supply_w_id l_ol_supply_w_id_aat;
    l_ol_quantity l_ol_quantity_aat;
    l_ol_amount l_ol_amount_aat;
    l_ol_dist_info l_ol_dist_info_aat;
    l_ol_delivery_d l_ol_delivery_d_aat;
  BEGIN
    WriteTrace ('Loading Orders for D='||p_d_id||' W='||p_w_id);

    FOR i IN 0..p_orders_per_district LOOP
      l_cust (i) := 1;
    END LOOP;

    FOR i IN 0..p_orders_per_district LOOP
      l_r := RandomNumber (i,p_orders_per_district);
      l_t := l_cust(i);
      l_cust (i) := l_cust (l_r);
      l_cust (l_r) := l_t;
    END LOOP;

    FOR i IN 1..p_orders_per_district LOOP
l_o_d_id(i) := p_d_id;
l_o_w_id(i) := p_w_id;
      l_o_id(i) := i;
      l_o_c_id(i) := l_cust (l_o_id(i));

IF l_o_id(i) > 2100 THEN
 no_l_o_d_id(i) := l_o_d_id(i);
 no_l_o_w_id(i) := l_o_w_id(i);
 no_l_o_id(i) := l_o_id(i);
 l_o_carrier_id(i) := NULL;
ELSE
      l_o_carrier_id(i) := RandomNumber (1,10);
END IF;
 
     l_o_ol_cnt(i) := RandomNumber (5,15);  

FOR j IN 1 ..l_o_ol_cnt(i) LOOP
ol_total := ol_total + 1;
IF l_o_id(i) > 2100 THEN
l_ol_amount(ol_total) := 0;
l_ol_delivery_d(ol_total) := NULL;
ELSE
l_ol_amount(ol_total) := RandomNumber (10,10000) / 100;
l_ol_delivery_d(ol_total) := SYSDATE;
END IF;
    oli_l_o_id(ol_total) := l_o_id(i);
    oli_l_o_d_id(ol_total) := l_o_d_id(i);
    oli_l_o_w_id(ol_total) := l_o_w_id(i);
        l_ol(ol_total) := j;	
        l_ol_i_id(ol_total) := RandomNumber (1,p_maxitems);
        l_ol_supply_w_id(ol_total) := l_o_w_id(i);
        l_ol_quantity(ol_total) := 5;
        l_ol_dist_info(ol_total) := MakeAlphaString (24,24);
END LOOP;

    IF MOD (l_o_id(i),1000) = 0 THEN
        WriteTrace ('...'||l_o_id(i));
IF
l_o_id(i) = p_orders_per_district
THEN
end_order := 0;
END IF;
FORALL indx IN l_o_id.FIRST .. l_o_id.LAST - end_order
        INSERT INTO orders 
        (
          o_id, 
          o_c_id, 
          o_d_id, 
          o_w_id, 
          o_entry_d, 
          o_carrier_id, 
          o_ol_cnt, 
          o_all_local
        ) 
        VALUES 
        ( 
          l_o_id(indx), 
          l_o_c_id(indx), 
          l_o_d_id(indx), 
          l_o_w_id(indx), 
          SYSDATE,
          l_o_carrier_id(indx), 
          l_o_ol_cnt(indx), 
          1
        );

COMMIT;

FORALL indx IN no_l_o_id.FIRST .. no_l_o_id.LAST - end_order
      INSERT INTO new_order 
        (
          no_o_id, 
          no_d_id, 
          no_w_id
        ) 
        VALUES 
        (
          no_l_o_id(indx), 
          no_l_o_d_id(indx), 
          no_l_o_w_id(indx)
        );

COMMIT;
     
FORALL jndx IN oli_l_o_id.FIRST .. oli_l_o_id.LAST - end_order
       INSERT INTO order_line 
         (
           ol_o_id, 
           ol_d_id, 
           ol_w_id, 
           ol_number, 
           ol_i_id, 
            ol_supply_w_id, 
           ol_quantity, 
          ol_amount, 
          ol_dist_info, 
            ol_delivery_d
         ) 
         VALUES 
         (
           oli_l_o_id(jndx), 
           oli_l_o_d_id(jndx), 
            oli_l_o_w_id(jndx), 
            l_ol(jndx), 
           l_ol_i_id(jndx), 
           l_ol_supply_w_id(jndx), 
           l_ol_quantity(jndx), 
          l_ol_amount(jndx), 
           l_ol_dist_info(jndx), 
	l_ol_delivery_d(jndx)
         );

      COMMIT;

 	oli_l_o_id.delete(lst_jndx,ol_total-1); 
        oli_l_o_d_id.delete(lst_jndx,ol_total-1); 
        oli_l_o_w_id.delete(lst_jndx,ol_total-1);  
        l_ol.delete(lst_jndx,ol_total-1); 
        l_ol_i_id.delete(lst_jndx,ol_total-1); 
        l_ol_supply_w_id.delete(lst_jndx,ol_total-1);  
        l_ol_quantity.delete(lst_jndx,ol_total-1); 
        l_ol_amount.delete(lst_jndx,ol_total-1);  
        l_ol_dist_info.delete(lst_jndx,ol_total-1);  
	l_ol_delivery_d.delete(lst_jndx,ol_total-1); 

	lst_jndx := ol_total-1;

    l_o_d_id.delete(lst_indx,i-1);
    l_o_w_id.delete(lst_indx,i-1);
    l_o_id.delete(lst_indx,i-1);
    l_o_c_id.delete(lst_indx,i-1);
    l_o_carrier_id.delete(lst_indx,i-1);
    l_o_ol_cnt.delete(lst_indx,i-1); 
	
	lst_indx := i-1;


END IF;
    END LOOP;

    COMMIT;

    WriteTrace ('Orders Done');
  END;

PROCEDURE LoadItems (p_maxitems NUMBER)
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_item PLS_INTEGER := 1;
    l_orig numarray;
    l_first NUMBER;
    TYPE l_i_id_aat IS TABLE OF ITEM.I_ID%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_im_id_aat IS TABLE OF ITEM.I_IM_ID%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_name_aat IS TABLE OF ITEM.I_NAME%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_price_aat IS TABLE OF ITEM.I_PRICE%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_data_aat IS TABLE OF ITEM.I_DATA%TYPE 
    INDEX BY PLS_INTEGER;

    l_i_id	l_i_id_aat;
    l_i_im_id   l_i_im_id_aat;
    l_i_name	l_i_name_aat;
    l_i_price	l_i_price_aat;
    l_i_data	l_i_data_aat;

  BEGIN
    WriteTrace ('Loading Items');
  
    FOR i IN 0..p_maxitems - 1 LOOP
      l_orig(i) := 0;
    END LOOP;

    FOR i IN 0..(p_maxitems / 10) - 1 LOOP
      l_orig(RandomNumber (0,p_maxitems - 1)) := 1;
    END LOOP;

    FOR i IN 1..p_maxitems LOOP

      l_i_id(i)    := i;
      l_i_im_id(i) := RandomNumber (1,10000);
      l_i_name(i)  := MakeAlphaString (14,24);
      l_i_price(i) := TRUNC (RandomNumber (100,10000) / 100,2);
      l_i_data(i)  := MakeAlphaString (26,50);
      IF l_orig (i - 1) = 1 THEN
        l_first := RandomNumber (0,LENGTH (l_i_data(i)) - 8);
        l_i_data(i) := SUBSTR (l_i_data(i),0,l_first)||
        'original'||SUBSTR (l_i_data(i),l_first + 8);
      END IF;

IF MOD (l_i_id(i),10000) = 0
      THEN 
IF
l_i_id(i) = p_maxitems
THEN
end_item := 0;
END IF;
	FORALL indx IN l_i_id.FIRST .. l_i_id.LAST - end_item
      INSERT INTO item 
      (i_id, i_im_id, i_name, i_price, i_data) VALUES (l_i_id(indx), l_i_im_id(indx), l_i_name(indx), l_i_price(indx), l_i_data(indx));

      COMMIT;

l_i_id.delete(lst_indx,i-1);
l_i_im_id.delete(lst_indx,i-1);
l_i_name.delete(lst_indx,i-1);
l_i_price.delete(lst_indx,i-1);
l_i_data.delete(lst_indx,i-1);
lst_indx := i-1;
      
END IF;
     
      IF MOD (l_i_id(i),20000) = 0
      THEN  
        WriteTrace ('Loading Items - '||l_i_id(i));
      END IF;
    END LOOP;

    WriteTrace ('Items Done');
  END;


  PROCEDURE LoadStock (p_w_id NUMBER,p_maxitems NUMBER)
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_stock PLS_INTEGER := 1;
    l_orig numarray;
    l_first NUMBER;
    TYPE l_s_w_id_aat IS TABLE OF STOCK.S_W_ID%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_i_id_aat IS TABLE OF STOCK.S_I_ID%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_quantity_aat IS TABLE OF STOCK.S_QUANTITY%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_01_aat IS TABLE OF STOCK.S_DIST_01%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_02_aat IS TABLE OF STOCK.S_DIST_02%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_03_aat IS TABLE OF STOCK.S_DIST_03%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_04_aat IS TABLE OF STOCK.S_DIST_04%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_05_aat IS TABLE OF STOCK.S_DIST_05%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_06_aat IS TABLE OF STOCK.S_DIST_06%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_07_aat IS TABLE OF STOCK.S_DIST_07%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_08_aat IS TABLE OF STOCK.S_DIST_08%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_09_aat IS TABLE OF STOCK.S_DIST_09%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_10_aat IS TABLE OF STOCK.S_DIST_10%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_data_aat IS TABLE OF STOCK.S_DATA%TYPE INDEX BY PLS_INTEGER;  
  
    l_s_w_id l_s_w_id_aat;
    l_s_i_id l_s_i_id_aat;
    l_s_quantity l_s_quantity_aat;
    l_s_dist_01 l_s_dist_01_aat;
    l_s_dist_02 l_s_dist_02_aat;
    l_s_dist_03 l_s_dist_03_aat;
    l_s_dist_04 l_s_dist_04_aat;
    l_s_dist_05 l_s_dist_05_aat;
    l_s_dist_06 l_s_dist_06_aat;
    l_s_dist_07 l_s_dist_07_aat;
    l_s_dist_08 l_s_dist_08_aat;
    l_s_dist_09 l_s_dist_09_aat;
    l_s_dist_10 l_s_dist_10_aat;
    l_s_data l_s_data_aat;
  

  BEGIN
    WriteTrace ('Loading Stock W='||p_w_id);
  
    FOR i IN 0..p_maxitems - 1 LOOP
      l_orig(i) := 0;
    END LOOP;

    FOR i IN 0..(p_maxitems / 10) - 1 LOOP
      l_orig(RandomNumber (0,p_maxitems - 1)) := 1;
    END LOOP;

    FOR i IN 1..p_maxitems LOOP
      l_s_w_id(i) := p_w_id;
      l_s_i_id(i) := i;
      l_s_quantity(i) := RandomNumber (10,100);
      l_s_dist_01(i) := MakeAlphaString (24,24);
      l_s_dist_02(i) := MakeAlphaString (24,24);
      l_s_dist_03(i) := MakeAlphaString (24,24);
      l_s_dist_04(i) := MakeAlphaString (24,24);
      l_s_dist_05(i) := MakeAlphaString (24,24);
      l_s_dist_06(i) := MakeAlphaString (24,24);
      l_s_dist_07(i) := MakeAlphaString (24,24);
      l_s_dist_08(i) := MakeAlphaString (24,24);
      l_s_dist_09(i) := MakeAlphaString (24,24);
      l_s_dist_10(i) := MakeAlphaString (24,24);
      l_s_data(i) := MakeAlphaString (26,50);
      IF l_orig (i - 1) = 1 THEN
        l_first := RandomNumber (0,LENGTH (l_s_data(i)) - 8);
        l_s_data(i) := SUBSTR (l_s_data(i),0,l_first) || 'original' || SUBSTR (l_s_data(i),l_first + 8);
      END IF;
 
      IF MOD (l_s_i_id(i),10000) = 0
      THEN 
IF
l_s_i_id(i) = p_maxitems
THEN
end_stock := 0;
END IF;
      FORALL indx IN l_s_i_id.FIRST .. l_s_i_id.LAST - end_stock
      INSERT INTO STOCK  
      (
        s_i_id, 
        s_w_id, 
        s_quantity, 
        s_dist_01, 
        s_dist_02, 
        s_dist_03, 
        s_dist_04, 
        s_dist_05, 
        s_dist_06, 
        s_dist_07, 
        s_dist_08, 
        s_dist_09, 
        s_dist_10, 
        s_data, 
        s_ytd, 
        s_order_cnt, 
        s_remote_cnt
      ) 
      VALUES 
      (
        l_s_i_id(indx), 
        l_s_w_id(indx), 
        l_s_quantity(indx), 
        l_s_dist_01(indx), 
        l_s_dist_02(indx), 
        l_s_dist_03(indx), 
        l_s_dist_04(indx), 
        l_s_dist_05(indx), 
        l_s_dist_06(indx), 
        l_s_dist_07(indx), 
        l_s_dist_08(indx), 
        l_s_dist_09(indx), 
        l_s_dist_10(indx), 
        l_s_data(indx), 
        0, 
        0, 
        0
      );

	COMMIT;

    	l_s_i_id.delete(lst_indx,i-1); 
        l_s_w_id.delete(lst_indx,i-1); 
        l_s_quantity.delete(lst_indx,i-1); 
        l_s_dist_01.delete(lst_indx,i-1);
        l_s_dist_02.delete(lst_indx,i-1); 
        l_s_dist_03.delete(lst_indx,i-1); 
        l_s_dist_04.delete(lst_indx,i-1); 
        l_s_dist_05.delete(lst_indx,i-1); 
        l_s_dist_06.delete(lst_indx,i-1); 
        l_s_dist_07.delete(lst_indx,i-1); 
        l_s_dist_08.delete(lst_indx,i-1); 
        l_s_dist_09.delete(lst_indx,i-1); 
        l_s_dist_10.delete(lst_indx,i-1); 
        l_s_data.delete(lst_indx,i-1);

	lst_indx := i-1;

      END IF;
 
      IF MOD (l_s_i_id(i),20000) = 0
      THEN 
        WriteTrace ('Loading Stock '|| l_s_i_id(i));        
      END IF;

    END LOOP;

    COMMIT;
    WriteTrace ('Stock Done');
  END;

  PROCEDURE LoadDistrict (p_w_id NUMBER,p_districts_per_warehouse NUMBER)
  IS
    l_d_w_id NUMBER;
    l_d_ytd NUMBER;
    l_d_next_o_id NUMBER;
    l_d_id NUMBER;
    l_d_name VARCHAR2(10);
    l_d_add address;
    l_d_tax NUMBER;
  BEGIN
    WriteTrace ('Loading District');

    l_d_w_id := p_w_id;
    l_d_ytd := 30000;
    l_d_next_o_id := 3001;
    FOR i IN 1 .. p_districts_per_warehouse LOOP
      l_d_id := i;
      l_d_name := MakeAlphaString (6,10);
      l_d_add  := MakeAddress;
      l_d_tax := TRUNC (RandomNumber (10,20) / 100.0,2);

      INSERT INTO DISTRICT 
      (
        d_id, 
        d_w_id, 
        d_name, 
        d_street_1, 
        d_street_2, 
        d_city, 
        d_state, 
        d_zip, 
        d_tax, 
        d_ytd, 
        d_next_o_id
      ) 
      VALUES 
      (
        l_d_id, 
        l_d_w_id, 
        l_d_name, 
        l_d_add.street_1, 
        l_d_add.street_2, 
        l_d_add.city, 
        l_d_add.state, 
        l_d_add.zip, 
        l_d_tax, 
        l_d_ytd, 
        l_d_next_o_id
      );
    END LOOP;

    COMMIT;
    WriteTrace ('District done');
  END;

  PROCEDURE LoadWarehouses
  (
    p_count_ware NUMBER,
    p_maxitems NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    w_id NUMBER;
    w_name VARCHAR2(10);
    w_tax NUMBER;
    w_ytd NUMBER;
    w_add ADDRESS;
  BEGIN
    WriteTrace ('Loading Warehouses');

    FOR i IN 1..p_count_ware LOOP
      w_id := i;
      w_name := MakeAlphaString (6,10);
      w_add  := MakeAddress;
      w_tax := TRUNC (RandomNumber (10,20) / 100.0,2);
      w_ytd := 3000000;

      INSERT INTO WAREHOUSE 
      (
        w_id, 
        w_name, 
        w_street_1, 
        w_street_2, 
        w_city, 
        w_state, 
        w_zip, 
        w_tax, 
        w_ytd
      ) 
      VALUES 
      (
        w_id, 
        w_name, 
        w_add.street_1, 
        w_add.street_2, 
        w_add.city, 
        w_add.state, 
        w_add.zip, 
        w_tax, 
        w_ytd
      );
      LoadStock (w_id,c_maxitems);
      LoadDistrict (w_id,c_districts_per_warehouse);
      COMMIT;
    END LOOP;

    WriteTrace ('Warehouses done');
  END;

  PROCEDURE LoadCustomers 
  ( 
    p_count_ware NUMBER,
    p_customers_per_district NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    l_w_id NUMBER;
    l_d_id NUMBER;
  BEGIN
    WriteTrace ('Loading Customers');

    FOR i IN 1..p_count_ware LOOP
      l_w_id := i;
      FOR j IN 1..p_districts_per_warehouse LOOP
        l_d_id := j;
        Customer (l_d_id,l_w_id,p_customers_per_district);
      END LOOP;
    END LOOP;
    COMMIT;
    WriteTrace ('Customers done');
  END;

  PROCEDURE LoadOrders 
  ( 
    p_count_ware NUMBER,
    p_maxitems NUMBER,
    p_orders_per_district NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    l_w_id NUMBER;
    l_d_id NUMBER;
  BEGIN
    WriteTrace ('Loading Orders');
    FOR i IN 1..p_count_ware LOOP
      l_w_id := i;
      FOR j IN 1..p_districts_per_warehouse LOOP 
        l_d_id := j;
        Orders (l_d_id,l_w_id,p_maxitems,p_orders_per_district);
      END LOOP;
    END LOOP;
    COMMIT;
    WriteTrace ('Orders done');
  END;

  PROCEDURE LoadSchema(count_ware NUMBER) IS 
  BEGIN
    OpenTrace ('TPCC_LOG','tpcc_load.log');

    WriteTrace ('Loading Schema');

    LoadItems (c_maxitems);
    LoadWarehouses (count_ware,c_maxitems,c_districts_per_warehouse);
    LoadCustomers (count_ware,c_customers_per_district,c_districts_per_warehouse);
    LoadOrders (count_ware,c_maxitems,c_orders_per_district,c_districts_per_warehouse);
  
    WriteTrace ('Schema Load done');

    CloseTrace;
  END;

BEGIN
  namearr(0) := 'BAR';
  namearr(1) := 'OUGHT';
  namearr(2) := 'ABLE';
  namearr(3) := 'PRI';
  namearr(4) := 'PRES';
  namearr(5) := 'ESE';
  namearr(6) := 'ANTI';
  namearr(7) := 'CALLY';
  namearr(8) := 'ATION';
  namearr(9) := 'EING';

  list(0) := '0';
  list(1) := '1';
  list(2) := '2';
  list(3) := '3';
  list(4) := '4';
  list(5) := '5';
  list(6) := '6';
  list(7) := '7';
  list(8) := '8';
  list(9) := '9';
  list(10) := 'A';
  list(11) := 'B';
  list(12) := 'C';
  list(13) := 'D';
  list(14) := 'E';
  list(15) := 'F';
  list(16) := 'G';
  list(17) := 'H';
  list(18) := 'I';
  list(19) := 'J';
  list(20) := 'K';
  list(21) := 'L';
  list(22) := 'M';
  list(23) := 'N';
  list(24) := 'O';
  list(25) := 'P';
  list(26) := 'Q';
  list(27) := 'R';
  list(28) := 'S';
  list(29) := 'T';
  list(30) := 'U';
  list(31) := 'V';
  list(32) := 'W';
  list(33) := 'X';
  list(34) := 'Y';
  list(35) := 'Z';
  list(36) := 'a';
  list(37) := 'b';
  list(38) := 'c';
  list(39) := 'd';
  list(40) := 'e';
  list(41) := 'f';
  list(42) := 'g';
  list(43) := 'h';
  list(44) := 'i';
  list(45) := 'j';
  list(46) := 'k';
  list(47) := 'l';
  list(48) := 'm';
  list(49) := 'n';
  list(50) := 'o';
  list(51) := 'p';
  list(52) := 'q';
  list(53) := 'r';
  list(54) := 's';
  list(55) := 't';
  list(56) := 'u';
  list(57) := 'v';
  list(58) := 'w';
  list(59) := 'x';
  list(60) := 'y';
  list(61) := 'z';
END;"
if {[ catch {orasql $curn1 $sql(2)} message ] } {
puts "$message $sql(2)"
puts [ oramsg $curn1 all ]
}
set sql(3) "BEGIN tpcc_server_side.loadschema('$count_ware'); END;"
if {[ catch {orasql $curn1 $sql(3)} message ] } {
puts "$message $sql(3)"
puts [ oramsg $curn1 all ]
}
oraclose $curn1
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc TTCustomer { lda d_id w_id CUST_PER_DIST } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
set curn5 [oraopen $lda ]
set sql "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values (:c_id, :c_d_id, :c_w_id, :c_first, :c_middle, :c_last, :c_street_1, :c_street_2, :c_city, :c_state, :c_zip, :c_phone, to_date(:timestamp,'YYYYMMDDHH24MISS'), :c_credit, :c_credit_lim, :c_discount, :c_balance, :c_data, 10.0, 1, 0)"
oraparse $curn5 $sql
set curn6 [oraopen $lda ]
set sql2 "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values (:c_id, :c_d_id, :c_w_id, :c_w_id, :c_d_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :h_amount, :h_data)"
oraparse $curn6 $sql2
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
orabind $curn5 :c_id $c_id :c_d_id $c_d_id :c_w_id $c_w_id :c_first $c_first :c_middle $c_middle :c_last $c_last :c_street_1 [ lindex $c_add 0 ] :c_street_2 [ lindex $c_add 1 ] :c_city [ lindex $c_add 2 ] :c_state [ lindex $c_add 3 ] :c_zip [ lindex $c_add 4 ] :c_phone $c_phone :timestamp [ gettimestamp ] :c_credit $c_credit :c_credit_lim $c_credit_lim :c_discount $c_discount :c_balance $c_balance :c_data $c_data
if {[ catch {oraexec $curn5} message ] } {
puts "Error in cursor 5:$curn5 $message"
puts [ oramsg $curn5 all ]
}
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
orabind $curn6 :c_id $c_id :c_d_id $c_d_id :c_w_id $c_w_id :c_w_id $c_w_id :c_d_id $c_d_id :timestamp [ gettimestamp ] :h_amount $h_amount :h_data $h_data
if {[ catch {oraexec $curn6} message ] } {
puts "Error in cursor 6:$curn6 $message"
puts [ oramsg $curn6 all ]
		}
	}
oracommit $lda
oraclose $curn5
oraclose $curn6
puts "Customer Done"
return
}

proc TTOrders { lda d_id w_id MAXITEMS ORD_PER_DIST num_part } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
if { $num_part != 0 } {
set mywid $w_id
if { $mywid > 10 } { set mywid [ expr $mywid % 10 ] }
if { $mywid eq 0 } { set mywid 10 }
	}
set curn7 [ oraopen $lda ]
set sql "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), NULL, :o_ol_cnt, 1)"
oraparse $curn7 $sql
set curn8 [ oraopen $lda ]
set sql2 "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) values (:o_id, :o_d_id, :o_w_id)"
oraparse $curn8 $sql2
set curn9 [ oraopen $lda ]
set sql3 "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :o_carrier_id, :o_ol_cnt, 1)"
oraparse $curn9 $sql3
if { $num_part eq 0 } {
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
	} else {
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line_$mywid (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line_$mywid (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
	}
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
orabind $curn7 :o_id $o_id :o_c_id $o_c_id :o_d_id $o_d_id :o_w_id $o_w_id :timestamp [ gettimestamp ] :o_ol_cnt $o_ol_cnt
if {[ catch {oraexec $curn7} message ] } {
puts "Error in cursor 7:$curn7 $message"
puts [ oramsg $curn7 all ]
}
set e "no1"
orabind $curn8 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id
if {[ catch {oraexec $curn8} message ] } {
puts "Error in cursor 8:$curn8 $message"
puts [ oramsg $curn8 all ]
}
  } else {
  set e "o3"
orabind $curn9 :o_id $o_id :o_c_id $o_c_id :o_d_id $o_d_id :o_w_id $o_w_id :timestamp [ gettimestamp ] :o_carrier_id $o_carrier_id :o_ol_cnt $o_ol_cnt
if {[ catch {oraexec $curn9} message ] } {
puts "Error in cursor 9:$curn9 $message"
puts [ oramsg $curn9 all ]
		}
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
orabind $curn10 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id :ol $ol :ol_i_id $ol_i_id :ol_supply_w_id $ol_supply_w_id :ol_quantity $ol_quantity :ol_amount $ol_amount :ol_dist_info $ol_dist_info
if {[ catch {oraexec $curn10} message ] } {
puts "Error in cursor 10:$curn10 $message"
puts [ oramsg $curn10 all ]
	}
   } else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
orabind $curn11 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id :ol $ol :ol_i_id $ol_i_id :ol_supply_w_id $ol_supply_w_id :ol_quantity $ol_quantity :ol_amount $ol_amount :ol_dist_info $ol_dist_info :timestamp [ gettimestamp ]
if {[ catch {oraexec $curn11} message ] } {
puts "Error in cursor 11:$curn11 $message"
puts [ oramsg $curn11 all ]
				}
			}
		}
 if { ![ expr {$o_id % 50000} ] } {
	puts "...$o_id"
	oracommit $lda
			}
		}
	oracommit $lda
        oraclose $curn7
        oraclose $curn8
        oraclose $curn9
        oraclose $curn10
        oraclose $curn11
	puts "Orders Done"
	return;
	}

proc TTStock { lda w_id MAXITEMS } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set curn3 [oraopen $lda ]
set sql "INSERT INTO STOCK (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values (:s_i_id, :s_w_id, :s_quantity, :s_dist_01, :s_dist_02, :s_dist_03, :s_dist_04, :s_dist_05, :s_dist_06, :s_dist_07, :s_dist_08, :s_dist_09, :s_dist_10, :s_data, 0, 0, 0)"
oraparse $curn3 $sql
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
orabind $curn3 :s_i_id $s_i_id :s_w_id $s_w_id :s_quantity $s_quantity :s_dist_01 $s_dist_01 :s_dist_02 $s_dist_02 :s_dist_03 $s_dist_03 :s_dist_04 $s_dist_04 :s_dist_05 $s_dist_05 :s_dist_06 $s_dist_06 :s_dist_07 $s_dist_07 :s_dist_08 $s_dist_08 :s_dist_09 $s_dist_09 :s_dist_10 $s_dist_10 :s_data $s_data
if {[ catch {oraexec $curn3} message ] } {
puts "Error in cursor 3:$curn3 $message"
puts [ oramsg $curn3 all ]
                                }
      if { ![ expr {$s_i_id % 50000} ] } {
	puts "Loading Stock - $s_i_id"
	oracommit $lda
			}
	}
	oracommit $lda
	oraclose $curn3
	puts "Stock done"
	return
}

proc Customer { lda d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
set curn5 [oraopen $lda ]
set sql "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values (:c_id, :c_d_id, :c_w_id, :c_first, :c_middle, :c_last, :c_street_1, :c_street_2, :c_city, :c_state, :c_zip, :c_phone, to_date(:timestamp,'YYYYMMDDHH24MISS'), :c_credit, :c_credit_lim, :c_discount, :c_balance, :c_data, 10.0, 1, 0)"
oraparse $curn5 $sql
set curn6 [oraopen $lda ]
set sql2 "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values (:c_id, :c_d_id, :c_w_id, :c_w_id, :c_d_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :h_amount, :h_data)"
oraparse $curn6 $sql2
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
foreach  i {c_id_c5 c_d_id_c5 c_w_id_c5 c_first_c5 c_middle_c5 c_last_c5 c_phone_c5 c_credit_c5 c_credit_lim_c5 c_discount_c5 c_balance_c5 c_data_c5} j {c_id c_d_id c_w_id c_first c_middle c_last c_phone c_credit c_credit_lim c_discount c_balance c_data} {
lappend $i [set $j] 
}
foreach i {c_street_1_c5 c_street_2_c5 c_city_c5 c_state_c5 c_zip_c5 timestamp_c5} j "[ lindex $c_add 0 ] [ lindex $c_add 1 ] [ lindex $c_add 2 ] [ lindex $c_add 3 ] [ lindex $c_add 4 ] [ gettimestamp ]" {
lappend $i $j
}
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
foreach i {h_c_id_c6 h_c_d_id_c6 h_c_w_id_c6 h_w_id_c6 h_d_id_c6 h_amount_c6 h_data_c6} j {c_id c_d_id c_w_id c_w_id c_d_id h_amount h_data} {
lappend $i [set $j]
}
lappend h_date_c6 [ gettimestamp ]
if { ![ expr {$c_id % 1000} ] } {
oraparse $curn5 $sql
orabind $curn5 -arraydml :c_id $c_id_c5 :c_d_id $c_d_id_c5 :c_w_id $c_w_id_c5 :c_first $c_first_c5 :c_middle $c_middle_c5 :c_last $c_last_c5 :c_street_1 $c_street_1_c5 :c_street_2 $c_street_2_c5 :c_city $c_city_c5 :c_state $c_state_c5 :c_zip $c_zip_c5 :c_phone $c_phone_c5 :timestamp $timestamp_c5 :c_credit $c_credit_c5 :c_credit_lim $c_credit_lim_c5 :c_discount $c_discount_c5 :c_balance $c_balance_c5 :c_data $c_data_c5
if {[ catch {oraexec $curn5} message ] } {
puts "Error in cursor 5:$curn5 $message"
puts [ oramsg $curn5 all ]
			}
oraparse $curn6 $sql2
orabind $curn6 -arraydml :c_id $h_c_id_c6 :c_d_id $h_c_d_id_c6 :c_w_id $h_c_w_id_c6 :c_w_id $h_w_id_c6 :c_d_id $h_d_id_c6 :timestamp $h_date_c6 :h_amount $h_amount_c6 :h_data $h_data_c6
if {[ catch {oraexec $curn6} message ] } {
puts "Error in cursor 6:$curn6 $message"
puts [ oramsg $curn6 all ]
			}
unset c_id_c5 c_d_id_c5 c_w_id_c5 c_first_c5 c_middle_c5 c_last_c5 c_phone_c5 c_credit_c5 c_credit_lim_c5 c_discount_c5 c_balance_c5 c_data_c5 c_street_1_c5 c_street_2_c5 c_city_c5 c_state_c5 c_zip_c5 timestamp_c5 h_c_id_c6 h_c_d_id_c6 h_c_w_id_c6 h_w_id_c6 h_d_id_c6 h_amount_c6 h_data_c6 h_date_c6
		}		
	}
oracommit $lda
oraclose $curn5
oraclose $curn6
puts "Customer Done"
return
}

proc Orders { lda d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
set curn7 [ oraopen $lda ]
set sql "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), NULL, :o_ol_cnt, 1)"
oraparse $curn7 $sql
set curn8 [ oraopen $lda ]
set sql2 "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) values (:o_id, :o_d_id, :o_w_id)"
oraparse $curn8 $sql2
set curn9 [ oraopen $lda ]
set sql3 "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :o_carrier_id, :o_ol_cnt, 1)"
oraparse $curn9 $sql3
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
foreach i {o_id_c7 o_c_id_c7 o_d_id_c7 o_w_id_c7 o_ol_cnt_c7} j {o_id o_c_id o_d_id o_w_id o_ol_cnt} {
lappend $i [set $j]
}
lappend timestamp_c7 [ gettimestamp ]
set e "no1"
foreach i {o_id_c8 o_d_id_c8 o_w_id_c8} j {o_id o_d_id o_w_id} {
lappend $i [set $j]
}
  } else {
  set e "o3"
foreach i {o_id_c9 o_c_id_c9 o_d_id_c9 o_w_id_c9 o_carrier_id_c9 o_ol_cnt_c9} j {o_id o_c_id o_d_id o_w_id o_carrier_id o_ol_cnt} {
lappend $i [set $j]
}
lappend timestamp_c9 [ gettimestamp ]
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
foreach i {o_id_c10 o_d_id_c10 o_w_id_c10 ol_c10 ol_i_id_c10 ol_supply_w_id_c10 ol_quantity_c10 ol_amount_c10 ol_dist_info_c10} j {o_id o_d_id o_w_id ol ol_i_id ol_supply_w_id ol_quantity ol_amount ol_dist_info} {
lappend $i [set $j]
}
		} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
foreach i {o_id_c11 o_d_id_c11 o_w_id_c11 ol_c11 ol_i_id_c11 ol_supply_w_id_c11 ol_quantity_c11 ol_amount_c11 ol_dist_info_c11} j {o_id o_d_id o_w_id ol ol_i_id ol_supply_w_id ol_quantity ol_amount ol_dist_info} {
lappend $i [set $j]
}
lappend timestamp_c11 [ gettimestamp ]
			}
		}
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 50000} ] } {
	puts "...$o_id"
	oracommit $lda
			}
if { $o_id > 2100 } {
oraparse $curn7 $sql
oraparse $curn8 $sql2
oraparse $curn10 $sql4
orabind $curn7 -arraydml :o_id $o_id_c7 :o_c_id $o_c_id_c7 :o_d_id $o_d_id_c7 :o_w_id $o_w_id_c7 :timestamp $timestamp_c7 :o_ol_cnt $o_ol_cnt_c7
if {[ catch {oraexec $curn7} message ] } {
puts "Error in cursor 7:$curn7 $message"
puts [ oramsg $curn7 all ]
}
orabind $curn8 -arraydml :o_id $o_id_c8 :o_d_id $o_d_id_c8 :o_w_id $o_w_id_c8
if {[ catch {oraexec $curn8} message ] } {
puts "Error in cursor 8:$curn8 $message"
puts [ oramsg $curn8 all ]
}
orabind $curn10 -arraydml :o_id $o_id_c10 :o_d_id $o_d_id_c10 :o_w_id $o_w_id_c10 :ol $ol_c10 :ol_i_id $ol_i_id_c10 :ol_supply_w_id $ol_supply_w_id_c10 :ol_quantity $ol_quantity_c10 :ol_amount $ol_amount_c10 :ol_dist_info $ol_dist_info_c10
if {[ catch {oraexec $curn10} message ] } {
puts "Error in cursor 10:$curn10 $message"
puts [ oramsg $curn10 all ]
		}
unset o_id_c7 o_c_id_c7 o_d_id_c7 o_w_id_c7 timestamp_c7 o_ol_cnt_c7 o_id_c8 o_d_id_c8 o_w_id_c8 o_id_c10 o_d_id_c10 o_w_id_c10 ol_c10 ol_i_id_c10 ol_supply_w_id_c10 ol_quantity_c10 ol_amount_c10 ol_dist_info_c10
} else {
oraparse $curn9 $sql3
oraparse $curn11 $sql5
orabind $curn9 -arraydml :o_id $o_id_c9 :o_c_id $o_c_id_c9 :o_d_id $o_d_id_c9 :o_w_id $o_w_id_c9 :timestamp $timestamp_c9 :o_carrier_id $o_carrier_id_c9 :o_ol_cnt $o_ol_cnt_c9
if {[ catch {oraexec $curn9} message ] } {
puts "Error in cursor 9:$curn9 $message"
puts [ oramsg $curn9 all ]
               }
orabind $curn11 -arraydml :o_id $o_id_c11 :o_d_id $o_d_id_c11 :o_w_id $o_w_id_c11 :ol $ol_c11 :ol_i_id $ol_i_id_c11 :ol_supply_w_id $ol_supply_w_id_c11 :ol_quantity $ol_quantity_c11 :ol_amount $ol_amount_c11 :ol_dist_info $ol_dist_info_c11 :timestamp $timestamp_c11
if {[ catch {oraexec $curn11} message ] } {
puts "Error in cursor 11:$curn11 $message"
puts [ oramsg $curn11 all ]
				}
unset o_id_c9 o_c_id_c9 o_d_id_c9 o_w_id_c9 timestamp_c9 o_carrier_id_c9 o_ol_cnt_c9 o_id_c11 o_d_id_c11 o_w_id_c11 ol_c11 ol_i_id_c11 ol_supply_w_id_c11 ol_quantity_c11 ol_amount_c11 ol_dist_info_c11 timestamp_c11
			}
		}
	}
	oracommit $lda
        oraclose $curn7
        oraclose $curn8
        oraclose $curn9
        oraclose $curn10
        oraclose $curn11
	puts "Orders Done"
	return;
	}

proc LoadItems { lda MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
set curn1 [oraopen $lda ]
set sql "INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) values (:i_id, :i_im_id, :i_name, :i_price, :i_data)"
oraparse $curn1 $sql
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
orabind $curn1 :i_id $i_id :i_im_id $i_im_id :i_name $i_name :i_price $i_price :i_data $i_data
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
        }
       if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
	oracommit $lda
		}
	}
	oracommit $lda
	oraclose $curn1
	puts "Item done"
	return
	}

proc Stock { lda w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set curn3 [oraopen $lda ]
set sql "INSERT INTO STOCK (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values (:s_i_id, :s_w_id, :s_quantity, :s_dist_01, :s_dist_02, :s_dist_03, :s_dist_04, :s_dist_05, :s_dist_06, :s_dist_07, :s_dist_08, :s_dist_09, :s_dist_10, :s_data, 0, 0, 0)"
oraparse $curn3 $sql
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
foreach  i {s_i_id_c3 s_w_id_c3 s_quantity_c3 s_dist_01_c3 s_dist_02_c3 s_dist_03_c3 s_dist_04_c3 s_dist_05_c3 s_dist_06_c3 s_dist_07_c3 s_dist_08_c3 s_dist_09_c3 s_dist_10_c3 s_data_c3} j {s_i_id s_w_id s_quantity s_dist_01 s_dist_02 s_dist_03 s_dist_04 s_dist_05 s_dist_06 s_dist_07 s_dist_08 s_dist_09 s_dist_10 s_data} {
lappend $i [set $j] 
}
if { ![ expr {$s_i_id % 1000} ] } {
oraparse $curn3 $sql
orabind $curn3 -arraydml :s_i_id $s_i_id_c3 :s_w_id $s_w_id_c3 :s_quantity $s_quantity_c3 :s_dist_01 $s_dist_01_c3 :s_dist_02 $s_dist_02_c3 :s_dist_03 $s_dist_03_c3 :s_dist_04 $s_dist_04_c3 :s_dist_05 $s_dist_05_c3 :s_dist_06 $s_dist_06_c3 :s_dist_07 $s_dist_07_c3 :s_dist_08 $s_dist_08_c3 :s_dist_09 $s_dist_09_c3 :s_dist_10 $s_dist_10_c3 :s_data $s_data_c3
if {[ catch {oraexec $curn3} message ] } {
puts "Error in cursor 3:$curn3 $message"
puts [ oramsg $curn3 all ]
                                }
unset s_i_id_c3 s_w_id_c3 s_quantity_c3 s_dist_01_c3 s_dist_02_c3 s_dist_03_c3 s_dist_04_c3 s_dist_05_c3 s_dist_06_c3 s_dist_07_c3 s_dist_08_c3 s_dist_09_c3 s_dist_10_c3 s_data_c3
		}
      if { ![ expr {$s_i_id % 50000} ] } {
	puts "Loading Stock - $s_i_id"
	oracommit $lda
			}
	}
	oracommit $lda
	oraclose $curn3
	puts "Stock done"
	return
}

proc District { lda w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set curn4 [oraopen $lda ]
set sql "INSERT INTO DISTRICT (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values (:d_id, :d_w_id, :d_name, :d_street_1, :d_street_2, :d_city, :d_state, :d_zip, :d_tax, :d_ytd, :d_next_o_id)"
oraparse $curn4 $sql
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
orabind $curn4 :d_id $d_id :d_w_id $d_w_id :d_name $d_name :d_street_1 [ lindex $d_add 0 ] :d_street_2 [ lindex $d_add 1 ] :d_city [ lindex $d_add 2 ] :d_state [ lindex $d_add 3 ] :d_zip [ lindex $d_add 4 ] :d_tax $d_tax :d_ytd $d_ytd :d_next_o_id $d_next_o_id
if {[ catch {oraexec $curn4} message ] } {
puts "Error in cursor 4:$curn4 $message"
puts [ oramsg $curn4 all ]
                                }
	}
	oracommit $lda
	oraclose $curn4
	puts "District done"
	return
}

proc LoadWare { lda ware_start count_ware MAXITEMS DIST_PER_WARE timesten } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set curn2 [oraopen $lda ]
set sql "INSERT INTO WAREHOUSE (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values (:w_id, :w_name, :w_street_1, :w_street_2, :w_city, :w_state, :w_zip, :w_tax, :w_ytd)"
oraparse $curn2 $sql
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
orabind $curn2 :w_id $w_id :w_name $w_name :w_street_1 [ lindex $add 0 ] :w_street_2 [ lindex $add 1 ] :w_city [ lindex $add 2 ] :w_state [ lindex $add 3 ] :w_zip [ lindex $add 4 ] :w_tax $w_tax :w_ytd $w_ytd
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
         }
	if { $timesten } { 
	TTStock $lda $w_id $MAXITEMS
	} else {
	Stock $lda $w_id $MAXITEMS
	}
	District $lda $w_id $DIST_PER_WARE
	oracommit $lda
	}
	oraclose $curn2
}

proc LoadCust { lda ware_start count_ware CUST_PER_DIST DIST_PER_WARE timesten } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	if { $timesten } { 
	TTCustomer $lda $d_id $w_id $CUST_PER_DIST
	} else {
	Customer $lda $d_id $w_id $CUST_PER_DIST
	}
	}
	}
	oracommit $lda
	return
}

proc LoadOrd { lda ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE timesten num_part } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {	
	if { $timesten } { 
	TTOrders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST $num_part
	} else {
	Orders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST
	}
	}
	}
	oracommit $lda
	return
}

proc do_tpcc { system_user system_password instance count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp plsql directory partition timesten hash_clusters num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { [ string toupper $timesten ] eq "TRUE"} { set timesten 1 } else { set timesten 0 }
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $tpcc_user ] SCHEMA"
if { $timesten } {
puts "TimesTen expects the Database [ string toupper $instance ] and User [ string toupper $tpcc_user ] to have been created by the instance administrator in advance and be granted create table, session, procedure, view (and admin for checkpoints) privileges"
	} else {
set connect $system_user/$system_password@$instance
set lda [ oralogon $connect ]
SetNLS $lda
CreateUser $lda $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_def_temp $tpcc_ol_tab $partition
if { $plsql eq 1 } { CreateDirectory $lda $directory $tpcc_user }
oralogoff $lda
	}
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
set plsql 0
if { $partition eq "true" } {
set num_part 10
	} else {
set num_part 0
	}
   } else {
SetNLS $lda
if { $partition eq "true" } {
if {$count_ware < 200} {
set num_part 0
set hash_clusters "false"
	} else {
set num_part [ expr round($count_ware/100) ]
	}
	} else {
set num_part 0
set hash_clusters "false"
}}
CreateTables $lda $num_part $tpcc_ol_tab $timesten $hash_clusters $count_ware
if { $plsql eq 1 } { 
puts "DOING PL/SQL SERVER SIDE LOAD LOGGING TO $directory/tpcc_load.log"
set timesten 0
ServerSidePackage $lda $count_ware 
CreateIndexes $lda $timesten $num_part $hash_clusters
CreateStoredProcs $lda $timesten $num_part
GatherStatistics $lda [ string toupper $tpcc_user ] $timesten $num_part
puts "[ string toupper $tpcc_user ] SCHEMA COMPLETE"
oralogoff $lda
return
	} else {
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $lda $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {  
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
	}
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
	}
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000 
}} else {
LoadItems $lda $MAXITEMS
}}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {  
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } { 
puts "Monitor failed to notify ready state" 
return
	}
after 5000 
}
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
	;
	} else {
SetNLS $lda
	}
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
if { $timesten } { if { $partition eq "true" } { set num_part 10 } else { set num_part 0 }} else { set num_part 0 }
LoadWare $lda $mystart $myend $MAXITEMS $DIST_PER_WARE $timesten
LoadCust $lda $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $timesten
LoadOrd $lda $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $timesten $num_part
puts "End:[ clock format [ clock seconds ] ]"
oracommit $lda
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda $timesten $num_part $hash_clusters
if { $timesten } { TTPLSQLSettings $lda }
CreateStoredProcs $lda $timesten $num_part
GatherStatistics $lda [ string toupper $tpcc_user ] $timesten $num_part
puts "[ string toupper $tpcc_user ] SCHEMA COMPLETE"
oralogoff $lda
return
	}
    }
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 2951.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $system_user $system_password $instance  $count_ware $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_ol_tab $tpcc_def_temp $plsql $directory $partition $tpcc_tt_compat $hash_clusters $num_threads"
	} else { return }
}

proc loadoratpcc { } {
global instance tpcc_user tpcc_pass total_iterations raiseerror keyandthink _ED
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists total_iterations ] } { set total_iterations 1000 }
if {  ![ info exists raiseerror ] } { set raiseerror "false" }
if {  ![ info exists keyandthink ] } { set keyandthink "true" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Oratcl} \] { error \"Failed to load Oratcl - Oracle OCI Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 7.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 9.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#STANDARD SQL
proc standsql { curn sql } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
error "SQL statement failed: $sql : $message"
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
	}
return $ftch
    }
}
#Default NLS
proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { curn_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
orabind $curn_no :no_w_id $no_w_id :no_max_w_id $w_id_input :no_d_id $no_d_id :no_c_id $no_c_id :no_o_ol_cnt $ol_cnt :no_c_discount {} :no_c_last {} :no_c_credit {} :no_d_tax {} :no_w_tax {} :no_d_next_o_id {0} :timestamp $date
if {[catch {oraexec $curn_no} message]} {
if { $RAISEERROR } {
error "New Order : $message [ oramsg $curn_no all ]"
	} else {
puts $message
	} } else {
orafetch  $curn_no -datavariable output
puts $output
	}
}
#PAYMENT
proc payment { curn_py p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
orabind $curn_py :p_w_id $p_w_id :p_d_id $p_d_id :p_c_w_id $p_c_w_id :p_c_d_id $p_c_d_id :p_c_id $p_c_id :byname $byname :p_h_amount $p_h_amount :p_c_last $name :p_w_street_1 {} :p_w_street_2 {} :p_w_city {} :p_w_state {} :p_w_zip {} :p_d_street_1 {} :p_d_street_2 {} :p_d_city {} :p_d_state {} :p_d_zip {} :p_c_first {} :p_c_middle {} :p_c_street_1 {} :p_c_street_2 {} :p_c_city {} :p_c_state {} :p_c_zip {} :p_c_phone {} :p_c_since {} :p_c_credit {0} :p_c_credit_lim {} :p_c_discount {} :p_c_balance {0} :p_c_data {} :timestamp $h_date
if {[ catch {oraexec $curn_py} message]} {
if { $RAISEERROR } {
error "Payment : $message [ oramsg $curn_py all ]"
	} else {
puts $message
} } else {
orafetch  $curn_py -datavariable output
puts $output
	}
}
#ORDER_STATUS
proc ostat { curn_os w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
orabind $curn_os :os_w_id $w_id :os_d_id $d_id :os_c_id $c_id :byname $byname :os_c_last $name :os_c_first {} :os_c_middle {} :os_c_balance {0} :os_o_id {} :os_entdate {} :os_o_carrier_id {}
if {[catch {oraexec $curn_os} message]} {
if { $RAISEERROR } {
error "Order Status : $message [ oramsg $curn_os all ]"
	} else {
puts $message
} } else {
orafetch  $curn_os -datavariable output
puts $output
	}
}
#DELIVERY
proc delivery { curn_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
orabind $curn_dl :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $date
if {[ catch {oraexec $curn_dl} message ]} {
if { $RAISEERROR } {
error "Delivery : $message [ oramsg $curn_dl all ]"
	} else {
puts $message
} } else {
orafetch  $curn_dl -datavariable output
puts $output
	}
}
#STOCK LEVEL
proc slev { curn_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold 
if {[catch {oraexec $curn_sl} message]} { 
if { $RAISEERROR } {
error "Stock Level : $message [ oramsg $curn_sl all ]"
	} else {
puts $message
} } else {
orafetch  $curn_sl -datavariable output
puts $output
	}
}

proc prep_statement { lda curn_st } {
switch $curn_st {
curn_sl {
set curn_sl [oraopen $lda ]
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold); END;"
oraparse $curn_sl $sql_sl
return $curn_sl
	}
curn_dl {
set curn_dl [oraopen $lda ]
set sql_dl "BEGIN delivery(:d_w_id,:d_o_carrier_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_dl $sql_dl
return $curn_dl
	}
curn_os {
set curn_os [oraopen $lda ]
set sql_os "BEGIN ostat(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id); END;"
oraparse $curn_os $sql_os
return $curn_os
	}
curn_py {
set curn_py [oraopen $lda ]
set sql_py "BEGIN payment(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_py $sql_py
return $curn_py
	}
curn_no {
set curn_no [oraopen $lda ]
set sql_no "begin neword(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_no $sql_no
return $curn_no
	}
    }
}
#RUN TPC-C
set lda [oralogon $connect]
SetNLS $lda
oraautocom $lda on
foreach curn_st {curn_no curn_py curn_dl curn_sl curn_os} { set $curn_st [ prep_statement $lda $curn_st ] }
set curn1 [oraopen $lda ]
set sql1 "select max(w_id) from warehouse"
set w_id_input [ standsql $curn1 $sql1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set sql2 "select max(d_id) from district"
set d_id_input [ standsql $curn1 $sql2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
set sql3 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;"
oraparse $curn1 $sql3
if {[catch {oraplexec $curn1 $sql3} message]} {
error "Failed to initialise DBMS_RANDOM $message have you run catoctk.sql as sys?" }
oraclose $curn1
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $curn_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $curn_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $curn_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $curn_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
oraclose $curn_no
oraclose $curn_py
oraclose $curn_dl
oraclose $curn_sl
oraclose $curn_os
oralogoff $lda
	}
}

proc loadoraawrtpcc { } {
global system_user system_password instance tpcc_user tpcc_pass total_iterations raiseerror keyandthink rampup duration allwarehouse timeprofile opmode checkpoint tpcc_tt_compat _ED
if {  ![ info exists system_user ] } { set system_user "system" }
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists total_iterations ] } { set total_iterations 1000 }
if {  ![ info exists raiseerror ] } { set raiseerror "false" }
if {  ![ info exists keyandthink ] } { set keyandthink "true" }
if {  ![ info exists rampup ] } { set rampup "2" }
if {  ![ info exists duration ] } { set duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
if {  ![ info exists checkpoint ] } { set checkpoint "false" }
if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
if {  ![ info exists allwarehouse ] } { set allwarehouse "false" }
if {  ![ info exists timeprofile ] } { set timeprofile "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C AWR"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Oratcl} \] { error \"Failed to load Oratcl - Oracle OCI Library Error\" }
#AWR SNAPSHOT DRIVER SCRIPT#######################################
#THIS SCRIPT TO BE RUN WITH VIRTUAL USER OUTPUT ENABLED
#EDITABLE OPTIONS##################################################
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$checkpoint\" ;# Perform Oracle checkpoint when complete (true or false)
set rampup $rampup;  # Rampup time in minutes before first snapshot is taken
set duration $duration;  # Duration in minutes before second AWR snapshot is taken
set mode \"$opmode\" ;# HammerDB operational mode
set timesten \"$tpcc_tt_compat\" ;# Database is TimesTen
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "set systemconnect $system_user/$system_password@$instance ;# Oracle connect string for system user
set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
#STANDARD SQL
proc standsql { curn sql } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
error "SQL statement failed: $sql : $message"
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
	}
return $ftch
    }
}
#Default NLS
proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

if { [ chk_thread ] eq "FALSE" } {
error "AWR Snapshot Script must be run in Thread Enabled Interpreter"
}
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
if { [ string toupper $timesten ] eq "TRUE"} { 
set timesten 1 
set systemconnect $connect
} else { 
set timesten 0 
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
set lda [oralogon $systemconnect]
if { !$timesten } { SetNLS $lda }
set lda1 [oralogon $connect]
if { !$timesten } { SetNLS $lda1 }
oraautocom $lda on
oraautocom $lda1 on
set curn1 [oraopen $lda ] 
set curn2 [oraopen $lda1 ]
if { $timesten } {
puts "For TimesTen use external ttStats utility for performance reports"
set sql1 "select (xact_commits + xact_rollbacks) from sys.monitor"
	} else {
set sql1 "BEGIN dbms_workload_repository.create_snapshot(); END;"
oraparse $curn1 $sql1
	}
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
if { $timesten } {
puts "Rampup complete, Taking start Transaction Count."
set start_trans [ standsql $curn2 $sql1 ]
	} else {
puts "Rampup complete, Taking start AWR snapshot."
if {[catch {oraplexec $curn1 $sql1} message]} { error "Failed to create snapshot : $message" }
set sql2 "SELECT INSTANCE_NUMBER, INSTANCE_NAME, DB_NAME, DBID, SNAP_ID, TO_CHAR(END_INTERVAL_TIME,'DD MON YYYY HH24:MI') FROM (SELECT DI.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.DB_NAME, DI.DBID, DS.SNAP_ID, DS.END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT DS, DBA_HIST_DATABASE_INSTANCE DI WHERE DS.DBID=DI.DBID AND DS.INSTANCE_NUMBER=DI.INSTANCE_NUMBER AND DS.STARTUP_TIME=DI.STARTUP_TIME ORDER BY DS.SNAP_ID DESC) WHERE ROWNUM=1"
if {[catch {orasql $curn1 $sql2} message]} {
error "SQL statement failed: $sql2 : $message"
} else {
orafetch  $curn1 -datavariable firstsnap
split  $firstsnap " "
puts "Start Snapshot [ lindex $firstsnap 4 ] taken at [ lindex $firstsnap 5 ] of instance [ lindex $firstsnap 1 ] ([lindex $firstsnap 0]) of database [ lindex $firstsnap 2 ] ([lindex $firstsnap 3])"
}}
set sql4 "select sum(d_next_o_id) from district"
set start_nopm [ standsql $curn2 $sql4 ]
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
if { $timesten } {
puts "Test complete, Taking end Transaction Count."
set end_trans [ standsql $curn2 $sql1 ]
set end_nopm [ standsql $curn2 $sql4 ]
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm TimesTen TPM at $nopm NOPM"
	} else {
puts "Test complete, Taking end AWR snapshot."
oraparse $curn1 $sql1
if {[catch {oraplexec $curn1 $sql1} message]} { error "Failed to create snapshot : $message" }
if {[catch {orasql $curn1 $sql2} message]} {
error "SQL statement failed: $sql2 : $message"
} else {
orafetch  $curn1 -datavariable endsnap
split  $endsnap " "
puts "End Snapshot [ lindex $endsnap 4 ] taken at [ lindex $endsnap 5 ] of instance [ lindex $endsnap 1 ] ([lindex $endsnap 0]) of database [ lindex $endsnap 2 ] ([lindex $endsnap 3])"
puts "Test complete: view report from SNAPID  [ lindex $firstsnap 4 ] to [ lindex $endsnap 4 ]"
set sql3 "select round((sum(tps)*60)) as TPM from (select e.stat_name, (e.value - b.value) / (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ extract( second from (e1.end_interval_time-b1.end_interval_time)) ) from dba_hist_snapshot b1, dba_hist_snapshot e1 where b1.snap_id = [ lindex $firstsnap 4 ] and e1.snap_id = [ lindex $endsnap 4 ] and b1.dbid = [lindex $firstsnap 3] and e1.dbid = [lindex $endsnap 3] and b1.instance_number = [lindex $firstsnap 0] and e1.instance_number = [lindex $endsnap 0] and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) as tps from dba_hist_sysstat b, dba_hist_sysstat e where b.snap_id = [ lindex $firstsnap 4 ] and e.snap_id = [ lindex $endsnap 4 ] and b.dbid = [lindex $firstsnap 3] and e.dbid = [lindex $endsnap 3] and b.instance_number = [lindex $firstsnap 0] and e.instance_number = [lindex $endsnap 0] and b.stat_id = e.stat_id and b.stat_name in ('user commits','user rollbacks') and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"
set tpm [ standsql $curn1 $sql3 ]
set end_nopm [ standsql $curn2 $sql4 ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
set sql6 {select value from v$parameter where name = 'cluster_database'}
oraparse $curn1 $sql6
set israc [ standsql $curn1 $sql6 ]
if { $israc != "FALSE" } {
set ractpm 0
set sql7 {select max(inst_number) from v$active_instances}
oraparse $curn1 $sql7
set activinst [ standsql $curn1 $sql7 ]
for { set a 1 } { $a <= $activinst } { incr a } {
set firstsnap [ lreplace $firstsnap 0 0 $a ]
set endsnap [ lreplace $endsnap 0 0 $a ]
set sqlrac "select round((sum(tps)*60)) as TPM from (select e.stat_name, (e.value - b.value) / (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ extract( second from (e1.end_interval_time-b1.end_interval_time)) ) from dba_hist_snapshot b1, dba_hist_snapshot e1 where b1.snap_id = [ lindex $firstsnap 4 ] and e1.snap_id = [ lindex $endsnap 4 ] and b1.dbid = [lindex $firstsnap 3] and e1.dbid = [lindex $endsnap 3] and b1.instance_number = [lindex $firstsnap 0] and e1.instance_number = [lindex $endsnap 0] and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) as tps from dba_hist_sysstat b, dba_hist_sysstat e where b.snap_id = [ lindex $firstsnap 4 ] and e.snap_id = [ lindex $endsnap 4 ] and b.dbid = [lindex $firstsnap 3] and e.dbid = [lindex $endsnap 3] and b.instance_number = [lindex $firstsnap 0] and e.instance_number = [lindex $endsnap 0] and b.stat_id = e.stat_id and b.stat_name in ('user commits','user rollbacks') and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"
set ractpm [ expr $ractpm + [ standsql $curn1 $sqlrac ]]
                }
set tpm $ractpm
        }
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm Oracle TPM at $nopm NOPM"
	}
}
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
if { $CHECKPOINT } {
puts "Checkpoint"
if { $timesten } {
set sql4 "call ttCkptBlocking"
      }	else {
set sql4 "alter system checkpoint"
if {[catch {orasql $curn1 $sql4} message]} {
error "SQL statement failed: $sql4 : $message"
}
set sql5 "alter system switch logfile"
if {[catch {orasql $curn1 $sql5} message]} {
error "SQL statement failed: $sql5 : $message"
	}}
puts "Checkpoint Complete"
        }
oraclose $curn1
oraclose $curn2
oralogoff $lda
oralogoff $lda1
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { curn_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
orabind $curn_no :no_w_id $no_w_id :no_max_w_id $w_id_input :no_d_id $no_d_id :no_c_id $no_c_id :no_o_ol_cnt $ol_cnt :no_c_discount {} :no_c_last {} :no_c_credit {} :no_d_tax {} :no_w_tax {} :no_d_next_o_id {0} :timestamp $date
if {[catch {oraexec $curn_no} message]} {
if { $RAISEERROR } {
error "New Order : $message [ oramsg $curn_no all ]"
	} else {
;
	} } else {
orafetch  $curn_no -datavariable output
;
	}
}
#PAYMENT
proc payment { curn_py p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
orabind $curn_py :p_w_id $p_w_id :p_d_id $p_d_id :p_c_w_id $p_c_w_id :p_c_d_id $p_c_d_id :p_c_id $p_c_id :byname $byname :p_h_amount $p_h_amount :p_c_last $name :p_w_street_1 {} :p_w_street_2 {} :p_w_city {} :p_w_state {} :p_w_zip {} :p_d_street_1 {} :p_d_street_2 {} :p_d_city {} :p_d_state {} :p_d_zip {} :p_c_first {} :p_c_middle {} :p_c_street_1 {} :p_c_street_2 {} :p_c_city {} :p_c_state {} :p_c_zip {} :p_c_phone {} :p_c_since {} :p_c_credit {0} :p_c_credit_lim {} :p_c_discount {} :p_c_balance {0} :p_c_data {} :timestamp $h_date
if {[ catch {oraexec $curn_py} message]} {
if { $RAISEERROR } {
error "Payment : $message [ oramsg $curn_py all ]"
	} else {
;
} } else {
orafetch  $curn_py -datavariable output
;
	}
}
#ORDER_STATUS
proc ostat { curn_os w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
orabind $curn_os :os_w_id $w_id :os_d_id $d_id :os_c_id $c_id :byname $byname :os_c_last $name :os_c_first {} :os_c_middle {} :os_c_balance {0} :os_o_id {} :os_entdate {} :os_o_carrier_id {}
if {[catch {oraexec $curn_os} message]} {
if { $RAISEERROR } {
error "Order Status : $message [ oramsg $curn_os all ]"
	} else {
;
} } else {
orafetch  $curn_os -datavariable output
;
	}
}
#DELIVERY
proc delivery { curn_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
orabind $curn_dl :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $date
if {[ catch {oraexec $curn_dl} message ]} {
if { $RAISEERROR } {
error "Delivery : $message [ oramsg $curn_dl all ]"
	} else {
;
} } else {
orafetch  $curn_dl -datavariable output
;
	}
}
#STOCK LEVEL
proc slev { curn_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold 
if {[catch {oraexec $curn_sl} message]} { 
if { $RAISEERROR } {
error "Stock Level : $message [ oramsg $curn_sl all ]"
	} else {
;
} } else {
orafetch  $curn_sl -datavariable output
;
	}
}

proc prep_statement { lda curn_st } {
switch $curn_st {
curn_sl {
set curn_sl [oraopen $lda ]
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold); END;"
oraparse $curn_sl $sql_sl
return $curn_sl
	}
curn_dl {
set curn_dl [oraopen $lda ]
set sql_dl "BEGIN delivery(:d_w_id,:d_o_carrier_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_dl $sql_dl
return $curn_dl
	}
curn_os {
set curn_os [oraopen $lda ]
set sql_os "BEGIN ostat(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id); END;"
oraparse $curn_os $sql_os
return $curn_os
	}
curn_py {
set curn_py [oraopen $lda ]
set sql_py "BEGIN payment(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_py $sql_py
return $curn_py
	}
curn_no {
set curn_no [oraopen $lda ]
set sql_no "begin neword(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_no $sql_no
return $curn_no
	}
    }
}
#RUN TPC-C
set lda [oralogon $connect]
if { !$timesten } { SetNLS $lda }
oraautocom $lda on
foreach curn_st {curn_no curn_py curn_dl curn_sl curn_os} { set $curn_st [ prep_statement $lda $curn_st ] }
set curn1 [oraopen $lda ]
set sql1 "select max(w_id) from warehouse"
set w_id_input [ standsql $curn1 $sql1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set sql2 "select max(d_id) from district"
set d_id_input [ standsql $curn1 $sql2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
set sql3 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;"
oraparse $curn1 $sql3
if {[catch {oraplexec $curn1 $sql3} message]} {
error "Failed to initialise DBMS_RANDOM $message have you run catoctk.sql as sys?" }
oraclose $curn1
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $curn_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $curn_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $curn_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $curn_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
oraclose $curn_no
oraclose $curn_py
oraclose $curn_dl
oraclose $curn_sl
oraclose $curn_os
oralogoff $lda
	}
     }} 
}

proc check_mssqltpcc {} {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_count_ware mssqls_num_threads mssqls_uid mssqls_pass mssqls_dbase mssqls_imdb mssqls_bucket mssqls_durability maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_count_ware ] } { set mssqls_count_ware "1" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 11.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_imdb ] } { set mssqls_imdb "false" }
if {  ![ info exists mssqls_bucket ] } { set mssqls_bucket "1" }
if {  ![ info exists mssqls_durability ] } { set mssqls_durability "SCHEMA_AND_DATA" }
if {  ![ info exists mssqls_num_threads ] } { set mssqls_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $mssqls_count_ware Warehouse MS SQL Server TPC-C schema\nin host [string toupper $mssqls_server:$mssqls_port] in database [ string toupper $mssqls_dbase ]?" -type yesno ] == yes} { 
if { $mssqls_num_threads eq 1 || $mssqls_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mssqls_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require tclodbc 2.5.1} ] { error "Failed to load tclodbc - ODBC Library Error" }
proc CreateStoredProcs { odbc imdb } {
puts "CREATING TPCC STORED PROCEDURES"
if { $imdb } {
set sql(1) {CREATE PROCEDURE [dbo].[neword]  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY

SET @no_o_all_local = 0
SELECT @no_c_discount = customer.c_discount
, @no_c_last = customer.c_last
, @no_c_credit = customer.c_credit
, @no_w_tax = warehouse.w_tax 
FROM dbo.customer, dbo.warehouse
WHERE warehouse.w_id = @no_w_id 
AND customer.c_w_id = @no_w_id 
AND customer.c_d_id = @no_d_id 
AND customer.c_id = @no_c_id

UPDATE dbo.district 
SET @no_d_tax = d_tax
, @o_id = d_next_o_id
,  d_next_o_id = district.d_next_o_id + 1 
WHERE district.d_id = @no_d_id 
AND district.d_w_id = @no_w_id
SET @no_d_next_o_id = @o_id+1

INSERT dbo.orders( o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)

INSERT dbo.new_order(no_o_id, no_d_id, no_w_id) 
VALUES (@o_id, @no_d_id, @no_w_id)

SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)

SELECT @no_i_price = item.i_price
, @no_i_name = item.i_name
, @no_i_data = item.i_data 
FROM dbo.item 
WHERE item.i_id = @no_ol_i_id

SELECT @no_s_quantity = stock.s_quantity
, @no_s_data = stock.s_data
, @no_s_dist_01 = stock.s_dist_01
, @no_s_dist_02 = stock.s_dist_02
, @no_s_dist_03 = stock.s_dist_03
, @no_s_dist_04 = stock.s_dist_04
, @no_s_dist_05 = stock.s_dist_05
, @no_s_dist_06 = stock.s_dist_06
, @no_s_dist_07 = stock.s_dist_07
, @no_s_dist_08 = stock.s_dist_08
, @no_s_dist_09 = stock.s_dist_09
, @no_s_dist_10 = stock.s_dist_10 
FROM dbo.stock
WHERE stock.s_i_id = @no_ol_i_id 
AND stock.s_w_id = @no_ol_supply_w_id


IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)

UPDATE dbo.stock
SET s_quantity = @no_s_quantity 
WHERE stock.s_i_id = @no_ol_i_id 
AND stock.s_w_id = @no_ol_supply_w_id

SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.order_line( ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'

END TRY
BEGIN CATCH
IF (error_number() in (701, 41839, 41823, 41302, 41305, 41325, 41301))
SELECT 'IMOLTPERROR',ERROR_NUMBER() AS ErrorNumber
ELSE
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;

END}
set sql(2) {CREATE PROCEDURE [dbo].[delivery]  
@d_w_id int,
@d_o_carrier_id int,
@timestamp datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter


DECLARE @d_out TABLE (d_no_o_id INT)

DELETE TOP (1) 
FROM dbo.new_order 
OUTPUT deleted.no_o_id INTO @d_out -- @d_no_o_id
WHERE new_order.no_w_id = @d_w_id 
AND new_order.no_d_id = @d_d_id 

SELECT @d_no_o_id = d_no_o_id FROM @d_out
 

UPDATE dbo.orders 
SET o_carrier_id = @d_o_carrier_id 
, @d_c_id = orders.o_c_id 
WHERE orders.o_id = @d_no_o_id 
AND orders.o_d_id = @d_d_id 
AND orders.o_w_id = @d_w_id


 SET @d_ol_total = 0

UPDATE dbo.order_line 
SET ol_delivery_d = @timestamp
	, @d_ol_total = @d_ol_total + ol_amount
WHERE order_line.ol_o_id = @d_no_o_id 
AND order_line.ol_d_id = @d_d_id 
AND order_line.ol_w_id = @d_w_id


UPDATE dbo.customer SET c_balance = customer.c_balance + @d_ol_total 
WHERE customer.c_id = @d_c_id 
AND customer.c_d_id = @d_d_id 
AND customer.c_w_id = @d_w_id


PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(4000)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(4000)), '')
+ 
'time '
+ 
ISNULL(CAST(@timestamp AS nvarchar(4000)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT	@d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @timestamp as N'@TIMESTAMP'
END TRY
BEGIN CATCH
IF (error_number() in (701, 41839, 41823, 41302, 41305, 41325, 41301))
SELECT 'IMOLTPERROR',ERROR_NUMBER() AS ErrorNumber
ELSE
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE [dbo].[payment]  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY

SELECT @p_w_street_1 = warehouse.w_street_1
, @p_w_street_2 = warehouse.w_street_2
, @p_w_city = warehouse.w_city
, @p_w_state = warehouse.w_state
, @p_w_zip = warehouse.w_zip
, @p_w_name = warehouse.w_name 
FROM dbo.warehouse
WHERE warehouse.w_id = @p_w_id

UPDATE dbo.district 
SET d_ytd = district.d_ytd + @p_h_amount 
WHERE district.d_w_id = @p_w_id 
AND district.d_id = @p_d_id

SELECT @p_d_street_1 = district.d_street_1
, @p_d_street_2 = district.d_street_2
, @p_d_city = district.d_city
, @p_d_state = district.d_state
, @p_d_zip = district.d_zip
, @p_d_name = district.d_name 
FROM dbo.district
WHERE district.d_w_id = @p_w_id 
AND district.d_id = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(customer.c_id) 
FROM dbo.customer
WHERE customer.c_last = @p_c_last 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_w_id = @p_c_w_id

DECLARE
c_byname CURSOR STATIC LOCAL FOR 
SELECT customer.c_first
, customer.c_middle
, customer.c_id
, customer.c_street_1
, customer.c_street_2
, customer.c_city
, customer.c_state
, customer.c_zip
, customer.c_phone
, customer.c_credit
, customer.c_credit_lim
, customer.c_discount
, C_BAL.c_balance
, customer.c_since 
FROM dbo.customer  AS customer
INNER LOOP JOIN dbo.customer AS C_BAL
ON C_BAL.c_w_id = customer.c_w_id
  AND C_BAL.c_d_id = customer.c_d_id
  AND C_BAL.c_id = customer.c_id
WHERE customer.c_w_id = @p_c_w_id 
  AND customer.c_d_id = @p_c_d_id 
  AND customer.c_last = @p_c_last 
ORDER BY customer.c_first
OPTION ( MAXDOP 1)
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = customer.c_first, @p_c_middle = customer.c_middle, @p_c_last = customer.c_last
, @p_c_street_1 = customer.c_street_1, @p_c_street_2 = customer.c_street_2
, @p_c_city = customer.c_city, @p_c_state = customer.c_state
, @p_c_zip = customer.c_zip, @p_c_phone = customer.c_phone
, @p_c_credit = customer.c_credit, @p_c_credit_lim = customer.c_credit_lim
, @p_c_discount = customer.c_discount, @p_c_balance = customer.c_balance
, @p_c_since = customer.c_since 
FROM dbo.customer 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_id = @p_c_id 

END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = customer.c_data FROM dbo.customer WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id AND customer.c_id = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.customer SET c_balance = @p_c_balance, c_data = @p_c_new_data 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id AND customer.c_id = @p_c_id
END
ELSE 
UPDATE dbo.customer SET c_balance = @p_c_balance 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_id = @p_c_id

SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))

INSERT dbo.history( h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT	@p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1'
, @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city'
, @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip'
, @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2'
, @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state'
, @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first'
, @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1'
, @p_c_street_2 as N'@p_c_street_2'
, @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip'
, @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit'
, @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance'
, @p_c_data as N'@p_c_data'


UPDATE dbo.warehouse
SET w_ytd = warehouse.w_ytd + @p_h_amount 
WHERE warehouse.w_id = @p_w_id

END TRY
BEGIN CATCH
IF (error_number() in (701, 41839, 41823, 41302, 41305, 41325, 41301))
SELECT 'IMOLTPERROR',ERROR_NUMBER() AS ErrorNumber
ELSE
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE [dbo].[ostat] 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id 	INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount 	INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN

SELECT @namecnt = count_big(customer.c_id) 
FROM dbo.customer 
WHERE customer.c_last = @os_c_last AND customer.c_d_id = @os_d_id AND customer.c_w_id = @os_w_id

IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT customer.c_balance
, customer.c_first
, customer.c_middle
, customer.c_id 
FROM dbo.customer 
WHERE customer.c_last = @os_c_last 
AND customer.c_d_id = @os_d_id 
AND customer.c_w_id = @os_w_id 
ORDER BY customer.c_first

OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = customer.c_balance, @os_c_first = customer.c_first
, @os_c_middle = customer.c_middle, @os_c_last = customer.c_last 
FROM dbo.customer
WHERE customer.c_id = @os_c_id AND customer.c_d_id = @os_d_id AND customer.c_w_id = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.o_id, @os_o_carrier_id = fci.o_carrier_id, @os_entdate = fci.o_entry_d
FROM 
(SELECT TOP 9223372036854775807 orders.o_id, orders.o_carrier_id, orders.o_entry_d 
FROM dbo.orders
WHERE orders.o_d_id = @os_d_id 
AND orders.o_w_id = @os_w_id 
AND orders.o_c_id = @os_c_id 
ORDER BY orders.o_id DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT order_line.ol_i_id
, order_line.ol_supply_w_id
, order_line.ol_quantity
, order_line.ol_amount
, order_line.ol_delivery_d 
FROM dbo.order_line 
WHERE order_line.ol_o_id = @os_o_id 
AND order_line.ol_d_id = @os_d_id 
AND order_line.ol_w_id = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT	@os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
IF (error_number() in (701, 41839, 41823, 41302, 41305, 41325, 41301))
SELECT 'IMOLTPERROR',ERROR_NUMBER() AS ErrorNumber
ELSE
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE [dbo].[slev]  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY

SELECT @st_o_id = district.d_next_o_id 
FROM dbo.district 
WHERE district.d_w_id = @st_w_id AND district.d_id = @st_d_id

SELECT @stock_count = count_big(DISTINCT stock.s_i_id) 
FROM dbo.order_line
, dbo.stock
WHERE order_line.ol_w_id = @st_w_id 
AND order_line.ol_d_id = @st_d_id 
AND (order_line.ol_o_id < @st_o_id) 
AND order_line.ol_o_id >= (@st_o_id - 20) 
AND stock.s_w_id = @st_w_id 
AND stock.s_i_id = order_line.ol_i_id 
AND stock.s_quantity < @threshold
OPTION (LOOP JOIN, MAXDOP 1)

SELECT	@st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
IF (error_number() in (701, 41839, 41823, 41302, 41305, 41325, 41301))
SELECT 'IMOLTPERROR',ERROR_NUMBER() AS ErrorNumber
ELSE
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END} 
} else {
set sql(1) {CREATE PROCEDURE [dbo].[neword]  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY

SET @no_o_all_local = 0
SELECT @no_c_discount = customer.c_discount
, @no_c_last = customer.c_last
, @no_c_credit = customer.c_credit
, @no_w_tax = warehouse.w_tax 
FROM dbo.customer, dbo.warehouse WITH (INDEX = w_details)
WHERE warehouse.w_id = @no_w_id 
AND customer.c_w_id = @no_w_id 
AND customer.c_d_id = @no_d_id 
AND customer.c_id = @no_c_id

UPDATE dbo.district 
SET @no_d_tax = d_tax
, @o_id = d_next_o_id
,  d_next_o_id = district.d_next_o_id + 1 
WHERE district.d_id = @no_d_id 
AND district.d_w_id = @no_w_id
SET @no_d_next_o_id = @o_id+1

INSERT dbo.orders( o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)

INSERT dbo.new_order(no_o_id, no_d_id, no_w_id) 
VALUES (@o_id, @no_d_id, @no_w_id)

SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)

SELECT @no_i_price = item.i_price
, @no_i_name = item.i_name
, @no_i_data = item.i_data 
FROM dbo.item 
WHERE item.i_id = @no_ol_i_id

SELECT @no_s_quantity = stock.s_quantity
, @no_s_data = stock.s_data
, @no_s_dist_01 = stock.s_dist_01
, @no_s_dist_02 = stock.s_dist_02
, @no_s_dist_03 = stock.s_dist_03
, @no_s_dist_04 = stock.s_dist_04
, @no_s_dist_05 = stock.s_dist_05
, @no_s_dist_06 = stock.s_dist_06
, @no_s_dist_07 = stock.s_dist_07
, @no_s_dist_08 = stock.s_dist_08
, @no_s_dist_09 = stock.s_dist_09
, @no_s_dist_10 = stock.s_dist_10 
FROM dbo.stock
WHERE stock.s_i_id = @no_ol_i_id 
AND stock.s_w_id = @no_ol_supply_w_id


IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)

UPDATE dbo.stock
SET s_quantity = @no_s_quantity 
WHERE stock.s_i_id = @no_ol_i_id 
AND stock.s_w_id = @no_ol_supply_w_id

SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.order_line( ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;

END}
set sql(2) {CREATE PROCEDURE [dbo].[delivery]  
@d_w_id int,
@d_o_carrier_id int,
@timestamp datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter


DECLARE @d_out TABLE (d_no_o_id INT)

DELETE TOP (1) 
FROM dbo.new_order 
OUTPUT deleted.no_o_id INTO @d_out -- @d_no_o_id
WHERE new_order.no_w_id = @d_w_id 
AND new_order.no_d_id = @d_d_id 

SELECT @d_no_o_id = d_no_o_id FROM @d_out
 

UPDATE dbo.orders 
SET o_carrier_id = @d_o_carrier_id 
, @d_c_id = orders.o_c_id 
WHERE orders.o_id = @d_no_o_id 
AND orders.o_d_id = @d_d_id 
AND orders.o_w_id = @d_w_id


 SET @d_ol_total = 0

UPDATE dbo.order_line 
SET ol_delivery_d = @timestamp
	, @d_ol_total = @d_ol_total + ol_amount
WHERE order_line.ol_o_id = @d_no_o_id 
AND order_line.ol_d_id = @d_d_id 
AND order_line.ol_w_id = @d_w_id


UPDATE dbo.customer SET c_balance = customer.c_balance + @d_ol_total 
WHERE customer.c_id = @d_c_id 
AND customer.c_d_id = @d_d_id 
AND customer.c_w_id = @d_w_id


PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(4000)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(4000)), '')
+ 
'time '
+ 
ISNULL(CAST(@timestamp AS nvarchar(4000)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT	@d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @timestamp as N'@TIMESTAMP'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE [dbo].[payment]  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY

SELECT @p_w_street_1 = warehouse.w_street_1
, @p_w_street_2 = warehouse.w_street_2
, @p_w_city = warehouse.w_city
, @p_w_state = warehouse.w_state
, @p_w_zip = warehouse.w_zip
, @p_w_name = warehouse.w_name 
FROM dbo.warehouse WITH (INDEX = [w_details])
WHERE warehouse.w_id = @p_w_id

UPDATE dbo.district 
SET d_ytd = district.d_ytd + @p_h_amount 
WHERE district.d_w_id = @p_w_id 
AND district.d_id = @p_d_id

SELECT @p_d_street_1 = district.d_street_1
, @p_d_street_2 = district.d_street_2
, @p_d_city = district.d_city
, @p_d_state = district.d_state
, @p_d_zip = district.d_zip
, @p_d_name = district.d_name 
FROM dbo.district WITH (INDEX = d_details)
WHERE district.d_w_id = @p_w_id 
AND district.d_id = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(customer.c_id) 
FROM dbo.customer WITH (repeatableread) 
WHERE customer.c_last = @p_c_last 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_w_id = @p_c_w_id

DECLARE
c_byname CURSOR STATIC LOCAL FOR 
SELECT customer.c_first
, customer.c_middle
, customer.c_id
, customer.c_street_1
, customer.c_street_2
, customer.c_city
, customer.c_state
, customer.c_zip
, customer.c_phone
, customer.c_credit
, customer.c_credit_lim
, customer.c_discount
, C_BAL.c_balance
, customer.c_since 
FROM dbo.customer  AS customer WITH (INDEX = [customer_i2], repeatableread)
INNER LOOP JOIN dbo.customer AS C_BAL WITH (INDEX = [customer_i1], repeatableread) 
ON C_BAL.c_w_id = customer.c_w_id
  AND C_BAL.c_d_id = customer.c_d_id
  AND C_BAL.c_id = customer.c_id
WHERE customer.c_w_id = @p_c_w_id 
  AND customer.c_d_id = @p_c_d_id 
  AND customer.c_last = @p_c_last 
ORDER BY customer.c_first
OPTION ( MAXDOP 1)
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = customer.c_first, @p_c_middle = customer.c_middle, @p_c_last = customer.c_last
, @p_c_street_1 = customer.c_street_1, @p_c_street_2 = customer.c_street_2
, @p_c_city = customer.c_city, @p_c_state = customer.c_state
, @p_c_zip = customer.c_zip, @p_c_phone = customer.c_phone
, @p_c_credit = customer.c_credit, @p_c_credit_lim = customer.c_credit_lim
, @p_c_discount = customer.c_discount, @p_c_balance = customer.c_balance
, @p_c_since = customer.c_since 
FROM dbo.customer 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_id = @p_c_id 

END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = customer.c_data FROM dbo.customer WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id AND customer.c_id = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.customer SET c_balance = @p_c_balance, c_data = @p_c_new_data 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id AND customer.c_id = @p_c_id
END
ELSE 
UPDATE dbo.customer SET c_balance = @p_c_balance 
WHERE customer.c_w_id = @p_c_w_id 
AND customer.c_d_id = @p_c_d_id 
AND customer.c_id = @p_c_id

SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))

INSERT dbo.history( h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT	@p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1'
, @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city'
, @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip'
, @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2'
, @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state'
, @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first'
, @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1'
, @p_c_street_2 as N'@p_c_street_2'
, @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip'
, @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit'
, @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance'
, @p_c_data as N'@p_c_data'


UPDATE dbo.warehouse WITH (XLOCK)
SET w_ytd = warehouse.w_ytd + @p_h_amount 
WHERE warehouse.w_id = @p_w_id

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE [dbo].[ostat] 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id 	INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount 	INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN

SELECT @namecnt = count_big(customer.c_id) 
FROM dbo.customer 
WHERE customer.c_last = @os_c_last AND customer.c_d_id = @os_d_id AND customer.c_w_id = @os_w_id

IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT customer.c_balance
, customer.c_first
, customer.c_middle
, customer.c_id 
FROM dbo.customer 
WHERE customer.c_last = @os_c_last 
AND customer.c_d_id = @os_d_id 
AND customer.c_w_id = @os_w_id 
ORDER BY customer.c_first

OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = customer.c_balance, @os_c_first = customer.c_first
, @os_c_middle = customer.c_middle, @os_c_last = customer.c_last 
FROM dbo.customer WITH (repeatableread) 
WHERE customer.c_id = @os_c_id AND customer.c_d_id = @os_d_id AND customer.c_w_id = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.o_id, @os_o_carrier_id = fci.o_carrier_id, @os_entdate = fci.o_entry_d
FROM 
(SELECT TOP 9223372036854775807 orders.o_id, orders.o_carrier_id, orders.o_entry_d 
FROM dbo.orders WITH (serializable) 
WHERE orders.o_d_id = @os_d_id 
AND orders.o_w_id = @os_w_id 
AND orders.o_c_id = @os_c_id 
ORDER BY orders.o_id DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT order_line.ol_i_id
, order_line.ol_supply_w_id
, order_line.ol_quantity
, order_line.ol_amount
, order_line.ol_delivery_d 
FROM dbo.order_line WITH (repeatableread) 
WHERE order_line.ol_o_id = @os_o_id 
AND order_line.ol_d_id = @os_d_id 
AND order_line.ol_w_id = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT	@os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE [dbo].[slev]  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY

SELECT @st_o_id = district.d_next_o_id 
FROM dbo.district 
WHERE district.d_w_id = @st_w_id AND district.d_id = @st_d_id

SELECT @stock_count = count_big(DISTINCT stock.s_i_id) 
FROM dbo.order_line
, dbo.stock
WHERE order_line.ol_w_id = @st_w_id 
AND order_line.ol_d_id = @st_d_id 
AND (order_line.ol_o_id < @st_o_id) 
AND order_line.ol_o_id >= (@st_o_id - 20) 
AND stock.s_w_id = @st_w_id 
AND stock.s_i_id = order_line.ol_i_id 
AND stock.s_quantity < @threshold
OPTION (LOOP JOIN, MAXDOP 1)

SELECT	@st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
}
for { set i 1 } { $i <= 5 } { incr i } {
odbc  $sql($i)
		}
return
}


proc UpdateStatistics { odbc db } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "USE $db"
set sql(2) "EXEC sp_updatestats"
for { set i 1 } { $i <= 2 } { incr i } {
odbc  $sql($i)
		}
return
}

proc CreateDatabase { odbc db imdb } {
set table_count 0
puts "CHECKING IF DATABASE $db EXISTS"
set db_exists [ odbc "IF DB_ID('$db') is not null SELECT 1 AS res ELSE SELECT 0 AS res" ]
if { $db_exists } {
odbc "use $db"
set table_count [ odbc "select COUNT(*) from sys.tables" ]
if { $table_count == 0 } {
puts "Empty database $db exists"
if { $imdb } {
odbc "ALTER DATABASE $db SET AUTO_CREATE_STATISTICS OFF"
odbc "ALTER DATABASE $db SET AUTO_UPDATE_STATISTICS OFF"
set imdb_fg [ odbc {SELECT TOP 1 1 FROM sys.filegroups FG JOIN sys.database_files F ON FG.data_space_id = F.data_space_id WHERE FG.type = 'FX' AND F.type = 2} ]
if { $imdb_fg eq "1" } { 
set elevatetosnap [ odbc "SELECT is_memory_optimized_elevate_to_snapshot_on FROM sys.databases WHERE name = '$db'" ]
if { $elevatetosnap eq "1" } {
puts "Using existing Memory Optimized Database $db with ELEVATE_TO_SNAPSHOT for Schema build"
	} else {
puts "Existing Memory Optimized Database $db exists, setting ELEVATE_TO_SNAPSHOT"
unset -nocomplain elevatetosnap
odbc "ALTER DATABASE $db SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON"
set elevatetosnap [ odbc "SELECT is_memory_optimized_elevate_to_snapshot_on FROM sys.databases WHERE name = '$db'" ]
if { $elevatetosnap eq "1" } {
puts "Success: Set ELEVATE_TO_SNAPSHOT for Database $db"
	} else {
puts "Failed to set ELEVATE_TO_SNAPSHOT for Database $db"
error "Set ELEVATE_TO_SNAPSHOT for Database $db and retry build"
	}
	}
	} else {
puts "Database $db must be in a MEMORY_OPTIMIZED_DATA filegroup"
error "Database $db exists but is not in a MEMORY_OPTIMIZED_DATA filegroup"
	}
      } else {
puts "Using existing empty Database $db for Schema build"
	}
      } else {
puts "Database with tables $db exists"
error "Database $db exists but is not empty, specify a new or empty database name"
        }
      } else {
if { $imdb } {
puts "In Memory Database chosen but $db does not exist"
error "Database $db must be pre-created in a MEMORY_OPTIMIZED_DATA filegroup and empty, to specify an In-Memory build"
      } else {
puts "CREATING DATABASE $db"
odbc "create database $db"
		}
        }
}

proc CreateTables { odbc imdb count_ware bucket_factor durability } {
puts "CREATING TPCC TABLES"
if { $imdb } {
set stmnt_cnt 9 
set ware_bc  [ expr $count_ware * 1 ]
set dist_bc  [ expr $count_ware * 10 ]
set item_bc 131072
set cust_bc [ expr $count_ware * 30000 ]
set stock_bc  [ expr $count_ware * 100000 ]
set neword_bc  [ expr $count_ware * (40000 * $bucket_factor) ]
set orderl_bc  [ expr $count_ware * (400000 * $bucket_factor) ]
set order_bc  [ expr $count_ware * (40000 * $bucket_factor) ]
set sql(1) [ subst -nocommands {CREATE TABLE [dbo].[customer] ( [c_id] [int] NOT NULL, [c_d_id] [tinyint] NOT NULL, [c_w_id] [int] NOT NULL, [c_discount] [smallmoney] NULL, [c_credit_lim] [money] NULL, [c_last] [char](16) COLLATE Latin1_General_CI_AS NULL, [c_first] [char](16) COLLATE Latin1_General_CI_AS NULL, [c_credit] [char](2) COLLATE Latin1_General_CI_AS NULL, [c_balance] [money] NULL, [c_ytd_payment] [money] NULL, [c_payment_cnt] [smallint] NULL, [c_delivery_cnt] [smallint] NULL, [c_street_1] [char](20) COLLATE Latin1_General_CI_AS NULL, [c_street_2] [char](20) COLLATE Latin1_General_CI_AS NULL, [c_city] [char](20) COLLATE Latin1_General_CI_AS NULL, [c_state] [char](2) COLLATE Latin1_General_CI_AS NULL, [c_zip] [char](9) COLLATE Latin1_General_CI_AS NULL, [c_phone] [char](16) COLLATE Latin1_General_CI_AS NULL, [c_since] [datetime] NULL, [c_middle] [char](2) COLLATE Latin1_General_CI_AS NULL, [c_data] [char](500) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [customer_i1] PRIMARY KEY NONCLUSTERED HASH ([c_id], [c_d_id], [c_w_id]) WITH (BUCKET_COUNT = $cust_bc), INDEX [customer_i2] NONCLUSTERED ([c_last], [c_w_id], [c_d_id], [c_first], [c_id])) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}]
set sql(2) [ subst -nocommands {CREATE TABLE [dbo].[district] ( [d_id] [tinyint] NOT NULL, [d_w_id] [int] NOT NULL, [d_ytd] [money] NOT NULL, [d_next_o_id] [int] NULL, [d_tax] [smallmoney] NULL, [d_name] [char](10) COLLATE Latin1_General_CI_AS NULL, [d_street_1] [char](20) COLLATE Latin1_General_CI_AS NULL, [d_street_2] [char](20) COLLATE Latin1_General_CI_AS NULL, [d_city] [char](20) COLLATE Latin1_General_CI_AS NULL, [d_state] [char](2) COLLATE Latin1_General_CI_AS NULL, [d_zip] [char](9) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [district_i1] PRIMARY KEY NONCLUSTERED HASH ([d_id], [d_w_id]) WITH (BUCKET_COUNT = $dist_bc)) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}]
set sql(3) [ subst -nocommands {CREATE TABLE [dbo].[history] ( [h_id] [int] IDENTITY(1,1) NOT NULL, [h_c_id] [int] NOT NULL, [h_c_d_id] [tinyint] NULL, [h_c_w_id] [int] NULL, [h_d_id] [tinyint] NULL, [h_w_id] [int] NULL, [h_date] [datetime] NOT NULL, [h_amount] [smallmoney] NULL, [h_data] [char](24) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [history_i1] PRIMARY KEY NONCLUSTERED ([h_id])) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}]
set sql(4) [ subst -nocommands {CREATE TABLE [dbo].[item] ( [i_id] [int] NOT NULL, [i_name] [char](24) COLLATE Latin1_General_CI_AS NULL, [i_price] [smallmoney] NULL, [i_data] [char](50) COLLATE Latin1_General_CI_AS NULL, [i_im_id] [int] NULL, CONSTRAINT [item_i1]  PRIMARY KEY NONCLUSTERED HASH ([i_id]) WITH (BUCKET_COUNT = $item_bc)) WITH (MEMORY_OPTIMIZED = ON , DURABILITY = $durability)}]
set sql(5) [ subst -nocommands {CREATE TABLE [dbo].[new_order] ( [no_o_id] [int] NOT NULL, [no_d_id] [tinyint] NOT NULL, [no_w_id] [int] NOT NULL, CONSTRAINT [new_order_i1]  PRIMARY KEY NONCLUSTERED HASH ([no_w_id], [no_d_id], [no_o_id]) WITH (BUCKET_COUNT = $neword_bc)) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}] 
set sql(6) [ subst -nocommands {CREATE TABLE [dbo].[order_line] ([ol_o_id] [int] NOT NULL, [ol_d_id] [tinyint] NOT NULL, [ol_w_id] [int] NOT NULL, [ol_number] [tinyint] NOT NULL, [ol_i_id] [int] NULL, [ol_delivery_d] [datetime] NULL, [ol_amount] [smallmoney] NULL, [ol_supply_w_id] [int] NULL, [ol_quantity] [smallint] NULL, [ol_dist_info] [char](24) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [order_line_i1] PRIMARY KEY NONCLUSTERED HASH ([ol_o_id], [ol_d_id], [ol_w_id], [ol_number]) WITH (BUCKET_COUNT = $orderl_bc), INDEX [orderline_i2] NONCLUSTERED ([ol_d_id], [ol_w_id], [ol_o_id])) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability )}]
set sql(7) [ subst -nocommands {CREATE TABLE [dbo].[orders] ( [o_id] [int] NOT NULL, [o_d_id] [tinyint] NOT NULL, [o_w_id] [int] NOT NULL, [o_c_id] [int] NOT NULL, [o_carrier_id] [tinyint] NULL, [o_ol_cnt] [tinyint] NULL, [o_all_local] [tinyint] NULL, [o_entry_d] [datetime] NULL, CONSTRAINT [orders_i1]  PRIMARY KEY NONCLUSTERED HASH ([o_w_id], [o_d_id], [o_id]) WITH (BUCKET_COUNT = $order_bc), INDEX [orders_i2] NONCLUSTERED ([o_c_id], [o_d_id], [o_w_id], [o_id])) WITH (MEMORY_OPTIMIZED = ON , DURABILITY = $durability)}]
set sql(8) [ subst -nocommands {CREATE TABLE [dbo].[stock] ( [s_i_id] [int] NOT NULL, [s_w_id] [int] NOT NULL, [s_quantity] [smallint] NOT NULL, [s_ytd] [int] NOT NULL, [s_order_cnt] [smallint] NULL, [s_remote_cnt] [smallint] NULL, [s_data] [char](50) COLLATE Latin1_General_CI_AS NULL, [s_dist_01] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_02] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_03] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_04] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_05] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_06] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_07] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_08] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_09] [char](24) COLLATE Latin1_General_CI_AS NULL, [s_dist_10] [char](24) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [stock_i1]  PRIMARY KEY NONCLUSTERED HASH ( [s_i_id], [s_w_id]) WITH (BUCKET_COUNT = $stock_bc)) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}]
set sql(9) [ subst -nocommands {CREATE TABLE [dbo].[warehouse] ([w_id] [int] NOT NULL, [w_ytd] [money] NOT NULL, [w_tax] [smallmoney] NOT NULL, [w_name] [char](10) COLLATE Latin1_General_CI_AS NULL, [w_street_1] [char](20) COLLATE Latin1_General_CI_AS NULL, [w_street_2] [char](20) COLLATE Latin1_General_CI_AS NULL, [w_city] [char](20) COLLATE Latin1_General_CI_AS NULL, [w_state] [char](2) COLLATE Latin1_General_CI_AS NULL, [w_zip] [char](9) COLLATE Latin1_General_CI_AS NULL, CONSTRAINT [warehouse_i1]  PRIMARY KEY NONCLUSTERED HASH ([w_id]) WITH (BUCKET_COUNT = $ware_bc)) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = $durability)}]
	} else {
set stmnt_cnt 20 
set sql(1) {CREATE TABLE [dbo].[customer]( [c_id] [int] NOT NULL, [c_d_id] [tinyint] NOT NULL, [c_w_id] [int] NOT NULL, [c_discount] [smallmoney] NULL, [c_credit_lim] [money] NULL, [c_last] [char](16) NULL, [c_first] [char](16) NULL, [c_credit] [char](2) NULL, [c_balance] [money] NULL, [c_ytd_payment] [money] NULL, [c_payment_cnt] [smallint] NULL, [c_delivery_cnt] [smallint] NULL, [c_street_1] [char](20) NULL, [c_street_2] [char](20) NULL, [c_city] [char](20) NULL, [c_state] [char](2) NULL, [c_zip] [char](9) NULL, [c_phone] [char](16) NULL, [c_since] [datetime] NULL, [c_middle] [char](2) NULL, [c_data] [char](500) NULL)}
set sql(2) {CREATE TABLE [dbo].[district]( [d_id] [tinyint] NOT NULL, [d_w_id] [int] NOT NULL, [d_ytd] [money] NOT NULL, [d_next_o_id] [int] NULL, [d_tax] [smallmoney] NULL, [d_name] [char](10) NULL, [d_street_1] [char](20) NULL, [d_street_2] [char](20) NULL, [d_city] [char](20) NULL, [d_state] [char](2) NULL, [d_zip] [char](9) NULL, [padding] [char](6000) NOT NULL, CONSTRAINT [PK_DISTRICT] PRIMARY KEY CLUSTERED ( [d_w_id] ASC, [d_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(3) {CREATE TABLE [dbo].[history]( [h_c_id] [int] NULL, [h_c_d_id] [tinyint] NULL, [h_c_w_id] [int] NULL, [h_d_id] [tinyint] NULL, [h_w_id] [int] NULL, [h_date] [datetime] NULL, [h_amount] [smallmoney] NULL, [h_data] [char](24) NULL)} 
set sql(4) {CREATE TABLE [dbo].[item]( [i_id] [int] NOT NULL, [i_name] [char](24) NULL, [i_price] [smallmoney] NULL, [i_data] [char](50) NULL, [i_im_id] [int] NULL, CONSTRAINT [PK_ITEM] PRIMARY KEY CLUSTERED ( [i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(5) {CREATE TABLE [dbo].[new_order]( [no_o_id] [int] NOT NULL, [no_d_id] [tinyint] NOT NULL, [no_w_id] [int] NOT NULL)} 
set sql(6) {CREATE TABLE [dbo].[orders]( [o_id] [int] NOT NULL, [o_d_id] [tinyint] NOT NULL, [o_w_id] [int] NOT NULL, [o_c_id] [int] NOT NULL, [o_carrier_id] [tinyint] NULL, [o_ol_cnt] [tinyint] NULL, [o_all_local] [tinyint] NULL, [o_entry_d] [datetime] NULL)} 
set sql(7) {CREATE TABLE [dbo].[order_line]( [ol_o_id] [int] NOT NULL, [ol_d_id] [tinyint] NOT NULL, [ol_w_id] [int] NOT NULL, [ol_number] [tinyint] NOT NULL, [ol_i_id] [int] NULL, [ol_delivery_d] [datetime] NULL, [ol_amount] [smallmoney] NULL, [ol_supply_w_id] [int] NULL, [ol_quantity] [smallint] NULL, [ol_dist_info] [char](24) NULL)} 
set sql(8) {CREATE TABLE [dbo].[stock]( [s_i_id] [int] NOT NULL, [s_w_id] [int] NOT NULL, [s_quantity] [smallint] NOT NULL, [s_ytd] [int] NOT NULL, [s_order_cnt] [smallint] NULL, [s_remote_cnt] [smallint] NULL, [s_data] [char](50) NULL, [s_dist_01] [char](24) NULL, [s_dist_02] [char](24) NULL, [s_dist_03] [char](24) NULL, [s_dist_04] [char](24) NULL, [s_dist_05] [char](24) NULL, [s_dist_06] [char](24) NULL, [s_dist_07] [char](24) NULL, [s_dist_08] [char](24) NULL, [s_dist_09] [char](24) NULL, [s_dist_10] [char](24) NULL, CONSTRAINT [PK_STOCK] PRIMARY KEY CLUSTERED ( [s_w_id] ASC, [s_i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(9) {CREATE TABLE [dbo].[warehouse]( [w_id] [int] NOT NULL, [w_ytd] [money] NOT NULL, [w_tax] [smallmoney] NOT NULL, [w_name] [char](10) NULL, [w_street_1] [char](20) NULL, [w_street_2] [char](20) NULL, [w_city] [char](20) NULL, [w_state] [char](2) NULL, [w_zip] [char](9) NULL, [padding] [char](4000) NOT NULL, CONSTRAINT [PK_WAREHOUSE] PRIMARY KEY CLUSTERED ( [w_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(10) {ALTER TABLE [dbo].[customer] SET (LOCK_ESCALATION = DISABLE)}
set sql(11) {ALTER TABLE [dbo].[district] SET (LOCK_ESCALATION = DISABLE)}
set sql(12) {ALTER TABLE [dbo].[history] SET (LOCK_ESCALATION = DISABLE)}
set sql(13) {ALTER TABLE [dbo].[item] SET (LOCK_ESCALATION = DISABLE)}
set sql(14) {ALTER TABLE [dbo].[new_order] SET (LOCK_ESCALATION = DISABLE)}
set sql(15) {ALTER TABLE [dbo].[orders] SET (LOCK_ESCALATION = DISABLE)}
set sql(16) {ALTER TABLE [dbo].[order_line] SET (LOCK_ESCALATION = DISABLE)}
set sql(17) {ALTER TABLE [dbo].[stock] SET (LOCK_ESCALATION = DISABLE)}
set sql(18) {ALTER TABLE [dbo].[warehouse] SET (LOCK_ESCALATION = DISABLE)}
set sql(19) {ALTER TABLE [dbo].[district] ADD  CONSTRAINT [DF__DISTRICT__paddin__282DF8C2]  DEFAULT (replicate('X',(6000))) FOR [padding]}
set sql(20) {ALTER TABLE [dbo].[warehouse] ADD  CONSTRAINT [DF__WAREHOUSE__paddi__14270015]  DEFAULT (replicate('x',(4000))) FOR [padding]}
	}
for { set i 1 } { $i <= $stmnt_cnt } { incr i } {
odbc  $sql($i)
		}
return
}

proc CreateIndexes { odbc imdb } {
puts "CREATING TPCC INDEXES"
if { $imdb } {
#In-memory Indexes created with tables
   } else {
set sql(1) {CREATE UNIQUE CLUSTERED INDEX [customer_i1] ON [dbo].[customer] ( [c_w_id] ASC, [c_d_id] ASC, [c_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(2) {CREATE UNIQUE CLUSTERED INDEX [new_order_i1] ON [dbo].[new_order] ( [no_w_id] ASC, [no_d_id] ASC, [no_o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(3) {CREATE UNIQUE CLUSTERED INDEX [orders_i1] ON [dbo].[orders] ( [o_w_id] ASC, [o_d_id] ASC, [o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(4) {CREATE UNIQUE CLUSTERED INDEX [order_line_i1] ON [dbo].[order_line] ( [ol_w_id] ASC, [ol_d_id] ASC, [ol_o_id] ASC, [ol_number] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)} 
set sql(5) {CREATE UNIQUE NONCLUSTERED INDEX [customer_i2] ON [dbo].[customer] ( [c_w_id] ASC, [c_d_id] ASC, [c_last] ASC, [c_id] ASC) INCLUDE ([c_credit], [c_street_1], [c_street_2], [c_city], [c_state], [c_zip], [c_phone], [c_middle], [c_credit_lim], [c_since], [c_discount], [c_first]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(6) {CREATE NONCLUSTERED INDEX [d_details] ON [dbo].[district] ( [d_id] ASC, [d_w_id] ASC) INCLUDE ([d_name], [d_street_1], [d_street_2], [d_city], [d_state], [d_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)}
set sql(7) {CREATE NONCLUSTERED INDEX [orders_i2] ON [dbo].[orders] ( [o_w_id] ASC, [o_d_id] ASC, [o_c_id] ASC, [o_id] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(8) {CREATE UNIQUE NONCLUSTERED INDEX [w_details] ON [dbo].[warehouse] ( [w_id] ASC) INCLUDE ([w_tax], [w_name], [w_street_1], [w_street_2], [w_city], [w_state], [w_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
for { set i 1 } { $i <= 8 } { incr i } {
odbc  $sql($i)
		}
     }
return
}

proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { odbc d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $$c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', getdate(), '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', getdate(), '$h_amount', '$h_data')
if { $bld_cnt<= 1 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 2} ] } {
odbc "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list"
odbc "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list"
	odbc commit
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { odbc d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', getdate())
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 1 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 2} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
odbc "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
if { $o_id > 2100 } {
odbc "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
	}
odbc "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list"
	odbc commit 
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	odbc commit
	puts "Orders Done"
	return
}

proc LoadItems { odbc MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
	odbc "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	odbc commit 
	puts "Item done"
	return
	}

proc Stock { odbc w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 1 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 2} ] } {
odbc "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
	odbc commit
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	odbc commit
	puts "Stock done"
	return
}

proc District { odbc w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
odbc "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	odbc commit
	puts "District done"
	return
}

proc LoadWare { odbc ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
odbc "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock odbc $w_id $MAXITEMS
	District odbc $w_id $DIST_PER_WARE
	odbc commit 
	}
}

proc LoadCust { odbc ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer odbc $d_id $w_id $CUST_PER_DIST
		}
	}
	odbc commit 
	return
}

proc LoadOrd { odbc ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	odbc commit 
	return
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

proc do_tpcc { server port odbc_driver authentication uid pwd count_ware db imdb bucket_factor durability num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
CreateDatabase odbc $db $imdb 
odbc "use $db"
CreateTables odbc $imdb $count_ware $bucket_factor $durability
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems odbc $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems odbc $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {database connect odbc $connection} message ] {
puts stderr "error, the database connection to $connection could not be established"
error $message
return
 } else {
odbc "use $db"
odbc set autocommit off 
} 
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare odbc $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust odbc $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd odbc $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
odbc commit 
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes odbc $imdb 
CreateStoredProcs odbc $imdb 
UpdateStatistics odbc $db
puts "[ string toupper $db ] SCHEMA COMPLETE"
odbc disconnect
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 2024.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc {$mssqls_server} $mssqls_port {$mssqls_odbc_driver} $mssqls_authentication $mssqls_uid $mssqls_pass $mssqls_count_ware $mssqls_dbase $mssqls_imdb $mssqls_bucket $mssqls_durability $mssqls_num_threads"
        } else { return }
}

proc loadmssqlstpcc { } {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 11.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_total_iterations ] } { set mssqls_total_iterations 1000000 }
if {  ![ info exists mssqls_raiseerror ] } { set mssqls_raiseerror "false" }
if {  ![ info exists mssqls_keyandthink ] } { set mssqls_keyandthink "false" }
if {  ![ info exists mssqlsdriver ] } { set mssqlsdriver "standard" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tclodbc 2.5.1} \] { error \"Failed to load tclodbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $mssqls_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$mssqls_raiseerror\" ;# Exit script on SQL Server error (true or false)
set KEYANDTHINK \"$mssqls_keyandthink\" ;# Time for user thinking and keying (true or false)
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server \{$mssqls_server\};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver \{$mssqls_odbc_driver\};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set database \"$mssqls_dbase\";# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 16.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { neword_st no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if {[ catch {neword_st execute [ list $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date ]} message]} {
if { $RAISEERROR } {
error "New Order : $message"
	} else {
puts $message
} } else {
neword_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#PAYMENT
proc payment { payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if {[ catch {payment_st execute [ list $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date ]} message]} {
if { $RAISEERROR } {
error "Payment : $message"
	} else {
puts $message
} } else {
payment_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#ORDER_STATUS
proc ostat { ostat_st w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if {[ catch {ostat_st execute [ list $w_id $d_id $c_id $byname $name ]} message]} {
if { $RAISEERROR } {
error "Order Status : $message"
	} else {
puts $message
} } else {
ostat_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#DELIVERY
proc delivery { delivery_st w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {delivery_st execute [ list $w_id $carrier_id $date ]} message]} {
if { $RAISEERROR } {
error "Delivery : $message"
	} else {
puts $message
} } else {
delivery_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#STOCK LEVEL
proc slev { slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {slev_st execute [ list $w_id $stock_level_d_id $threshold ]} message]} {
if { $RAISEERROR } {
error "Stock Level : $message"
	} else {
puts $message
} } else {
slev_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
odbc statement slev_st "EXEC slev @st_w_id = ?, @st_d_id = ?, @threshold = ?" {INTEGER INTEGER INTEGER} 
return slev_st
	}
delivery_st {
odbc statement delivery_st "EXEC delivery @d_w_id = ?, @d_o_carrier_id = ?, @timestamp = ?" {INTEGER INTEGER TIMESTAMP}
return delivery_st
	}
ostat_st {
odbc statement ostat_st "EXEC ostat @os_w_id = ?, @os_d_id = ?, @os_c_id = ?, @byname = ?, @os_c_last = ?" {INTEGER INTEGER INTEGER INTEGER {CHAR 16}}
return ostat_st
	}
payment_st {
odbc statement payment_st "EXEC payment @p_w_id = ?, @p_d_id = ?, @p_c_w_id = ?, @p_c_d_id = ?, @p_c_id = ?, @byname = ?, @p_h_amount = ?, @p_c_last = ?, @TIMESTAMP =?" {INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER {CHAR 16} TIMESTAMP}
return payment_st
	}
neword_st {
odbc statement neword_st "EXEC neword @no_w_id = ?, @no_max_w_id = ?, @no_d_id = ?, @no_c_id = ?, @no_o_ol_cnt = ?, @TIMESTAMP = ?" {INTEGER INTEGER INTEGER INTEGER INTEGER TIMESTAMP}
return neword_st
	}
    }
}

#RUN TPC-C
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
}
foreach st {neword_st payment_st ostat_st delivery_st slev_st} { set $st [ prep_statement odbc $st ] }
set w_id_input [ odbc  "select max(w_id) from warehouse" ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ odbc "select max(d_id) from district" ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc commit
neword_st drop 
payment_st drop
delivery_st drop
slev_st drop
ostat_st drop
odbc disconnect
	}
}

proc loadtimedmssqlstpcc { } {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver mssqls_rampup mssqls_duration mssqls_checkpoint _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 11.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_total_iterations ] } { set mssqls_total_iterations 1000000 }
if {  ![ info exists mssqls_raiseerror ] } { set mssqls_raiseerror "false" }
if {  ![ info exists mssqls_keyandthink ] } { set mssqls_keyandthink "false" }
if {  ![ info exists mssqlsdriver ] } { set mssqlsdriver "timed" }
if {  ![ info exists mssqls_rampup ] } { set mssqls_rampup "2" }
if {  ![ info exists mssqls_duration ] } { set mssqls_duration "5" }
if {  ![ info exists mssqls_checkpoint ] } { set mssqls_checkpoint "false" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tclodbc 2.5.1} \] { error \"Failed to load tclodbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $mssqls_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$mssqls_raiseerror\" ;# Exit script on SQL Server error (true or false)
set KEYANDTHINK \"$mssqls_keyandthink\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$mssqls_checkpoint\" ;# Perform SQL Server checkpoint when complete (true or false)
set rampup $mssqls_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $mssqls_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server \{$mssqls_server\};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver \{$mssqls_odbc_driver\};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set database \"$mssqls_dbase\";# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 19.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "SQL Server Timed Test Script must be run in Thread Enabled Interpreter"
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit on
}
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
if {[catch {set start_nopm [ odbc "select sum(d_next_o_id) from district" ]}]} {
puts stderr {error, failed to query district table}
return
}
if {[catch {set start_trans [ odbc "select cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'" ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} 
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
if {[catch {set end_nopm [ odbc "select sum(d_next_o_id) from district" ]}]} {
puts stderr {error, failed to query district table}
return
}
if {[catch {set end_trans [ odbc "select cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'" ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} 
if { [ string is integer -strict $end_trans ] && [ string is integer -strict $start_trans ] } {
if { $start_trans < $end_trans }  {
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
	} else {
puts "Error: SQL Server returned end transaction count data greater than start data"
set tpm 0
	} 
} else {
puts "Error: SQL Server returned non-numeric transaction count data"
set tpm 0
	}
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm SQL Server TPM at $nopm NOPM"
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
if { $CHECKPOINT } {
puts "Checkpoint"
if  [catch {odbc "checkpoint"} message ]  {
puts stderr {error, failed to execute checkpoint}
error message
return
	}
puts "Checkpoint Complete"
        }
odbc commit
odbc disconnect
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { neword_st no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if {[ catch {neword_st execute [ list $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date ]} message]} {
if { $RAISEERROR } {
error "New Order : $message"
	} else {
puts $message
} } else {
neword_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#PAYMENT
proc payment { payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if {[ catch {payment_st execute [ list $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date ]} message]} {
if { $RAISEERROR } {
error "Payment : $message"
	} else {
puts $message
} } else {
payment_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#ORDER_STATUS
proc ostat { ostat_st w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if {[ catch {ostat_st execute [ list $w_id $d_id $c_id $byname $name ]} message]} {
if { $RAISEERROR } {
error "Order Status : $message"
	} else {
puts $message
} } else {
ostat_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#DELIVERY
proc delivery { delivery_st w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {delivery_st execute [ list $w_id $carrier_id $date ]} message]} {
if { $RAISEERROR } {
error "Delivery : $message"
	} else {
puts $message
} } else {
delivery_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#STOCK LEVEL
proc slev { slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {slev_st execute [ list $w_id $stock_level_d_id $threshold ]} message]} {
if { $RAISEERROR } {
error "Stock Level : $message"
	} else {
puts $message
} } else {
slev_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
;
}
odbc commit
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
odbc statement slev_st "EXEC slev @st_w_id = ?, @st_d_id = ?, @threshold = ?" {INTEGER INTEGER INTEGER} 
return slev_st
	}
delivery_st {
odbc statement delivery_st "EXEC delivery @d_w_id = ?, @d_o_carrier_id = ?, @timestamp = ?" {INTEGER INTEGER TIMESTAMP}
return delivery_st
	}
ostat_st {
odbc statement ostat_st "EXEC ostat @os_w_id = ?, @os_d_id = ?, @os_c_id = ?, @byname = ?, @os_c_last = ?" {INTEGER INTEGER INTEGER INTEGER {CHAR 16}}
return ostat_st
	}
payment_st {
odbc statement payment_st "EXEC payment @p_w_id = ?, @p_d_id = ?, @p_c_w_id = ?, @p_c_d_id = ?, @p_c_id = ?, @byname = ?, @p_h_amount = ?, @p_c_last = ?, @TIMESTAMP =?" {INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER {CHAR 16} TIMESTAMP}
return payment_st
	}
neword_st {
odbc statement neword_st "EXEC neword @no_w_id = ?, @no_max_w_id = ?, @no_d_id = ?, @no_c_id = ?, @no_o_ol_cnt = ?, @TIMESTAMP = ?" {INTEGER INTEGER INTEGER INTEGER INTEGER TIMESTAMP}
return neword_st
	}
    }
}

#RUN TPC-C
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
}
foreach st {neword_st payment_st ostat_st delivery_st slev_st} { set $st [ prep_statement odbc $st ] }
set w_id_input [ odbc  "select max(w_id) from warehouse" ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ odbc "select max(d_id) from district" ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc commit
neword_st drop 
payment_st drop
delivery_st drop
slev_st drop
ostat_st drop
odbc disconnect
	}
   }}
}

proc check_db2tpcc {} {
global db2_count_ware db2_num_threads db2_user db2_pass db2_dbase db2_def_tab  db2_tab_list db2_partition maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists db2_count_ware ] } { set db2_count_ware "1" }
if {  ![ info exists db2_user ] } { set db2_user "db2inst1" }
if {  ![ info exists db2_pass ] } { set db2_pass "ibmdb2" }
if {  ![ info exists db2_dbase ] } { set db2_dbase "tpcc" }
if {  ![ info exists db2_def_tab ] } { set db2_def_tab "userspace1" }
if {  ![ info exists db2_tab_list ] } { set db2_tab_list {C "" D "" H "" I "" W "" S "" NO "" OR "" OL ""}}
if {  ![ info exists db2_partition ] } { set db2_partition "false" }
if {  ![ info exists db2_num_threads ] } { set db2_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $db2_count_ware Warehouse DB2 TPC-C schema\nunder user [ string toupper $db2_user ] in existing database [ string toupper $db2_dbase ]?" -type yesno ] == yes} { 
if { $db2_num_threads eq 1 || $db2_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $db2_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require db2tcl} ] { error "Failed to load db2tcl - DB2 Library Error" }
proc CreateStoredProcs { db_handle } {
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id	INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
OUT no_c_discount 	DECIMAL(4,4),
OUT no_c_last 		VARCHAR(16),
OUT no_c_credit		VARCHAR(2),
OUT no_d_tax 		DECIMAL(4,4),
OUT no_w_tax 		DECIMAL(4,4),
INOUT no_d_next_o_id 	INTEGER,
IN timestamp 		DATE
)
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE no_ol_supply_w_id	INTEGER;
DECLARE no_ol_i_id		INTEGER;
DECLARE no_ol_quantity 		INTEGER;
DECLARE no_o_all_local 		INTEGER;
DECLARE o_id 			INTEGER;
DECLARE no_i_name		VARCHAR(24);
DECLARE no_i_price		DECIMAL(5,2);
DECLARE no_i_data		VARCHAR(50);
DECLARE no_s_quantity		DECIMAL(6);
DECLARE no_ol_amount		DECIMAL(6,2);
DECLARE no_s_dist_01		CHAR(24);
DECLARE no_s_dist_02		CHAR(24);
DECLARE no_s_dist_03		CHAR(24);
DECLARE no_s_dist_04		CHAR(24);
DECLARE no_s_dist_05		CHAR(24);
DECLARE no_s_dist_06		CHAR(24);
DECLARE no_s_dist_07		CHAR(24);
DECLARE no_s_dist_08		CHAR(24);
DECLARE no_s_dist_09		CHAR(24);
DECLARE no_s_dist_10		CHAR(24);
DECLARE no_ol_dist_info 	CHAR(24);
DECLARE no_s_data	   	VARCHAR(50);
DECLARE x		        INTEGER;
DECLARE rbk		       	INTEGER;
DECLARE loop_counter    	INT;
SET no_o_all_local = 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
SELECT d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax
FROM OLD TABLE ( UPDATE district 
SET d_next_o_id = d_next_o_id + 1 
WHERE d_id = no_d_id 
AND d_w_id = no_w_id );
SET o_id = no_d_next_o_id;
INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
SET rbk = FLOOR(1 + (RAND() * 99));
SET loop_counter = 1;
WHILE loop_counter <= no_o_ol_cnt DO
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
SET no_ol_i_id = 100001;
ELSE
SET no_ol_i_id = FLOOR(1 + (RAND() * 100000));
END IF;
SET x = FLOOR(1 + (RAND() * 100));
IF ( x > 1 )
THEN
SET no_ol_supply_w_id = no_w_id;
ELSE
SET no_ol_supply_w_id = no_w_id;
SET no_o_all_local = 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1)) DO
SET no_ol_supply_w_id = FLOOR(1 + (RAND() * no_max_w_id));
END WHILE;
END IF;
SET no_ol_quantity = FLOOR(1 + (RAND() * 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10 
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10
FROM NEW TABLE (UPDATE STOCK
SET s_quantity = CASE WHEN ( s_quantity > no_ol_quantity )
THEN ( s_quantity - no_ol_quantity )
ELSE ( s_quantity - no_ol_quantity + 91 )
END
WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id
) AS US;
SET no_ol_amount = (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );
CASE no_d_id
WHEN 1 THEN
SET no_ol_dist_info = no_s_dist_01;
WHEN 2 THEN
SET no_ol_dist_info = no_s_dist_02;
WHEN 3 THEN
SET no_ol_dist_info = no_s_dist_03;
WHEN 4 THEN
SET no_ol_dist_info = no_s_dist_04;
WHEN 5 THEN
SET no_ol_dist_info = no_s_dist_05;
WHEN 6 THEN
SET no_ol_dist_info = no_s_dist_06;
WHEN 7 THEN
SET no_ol_dist_info = no_s_dist_07;
WHEN 8 THEN
SET no_ol_dist_info = no_s_dist_08;
WHEN 9 THEN
SET no_ol_dist_info = no_s_dist_09;
WHEN 10 THEN
SET no_ol_dist_info = no_s_dist_10;
END CASE;
INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);
set loop_counter = loop_counter + 1;
END WHILE;
END }
set sql(2) { CREATE OR REPLACE PROCEDURE PAYMENT (
IN p_w_id               INTEGER,
IN p_d_id               INTEGER,
IN p_c_w_id             INTEGER,
IN p_c_d_id             INTEGER,
INOUT p_c_id            INTEGER,
IN byname               INTEGER,
IN p_h_amount           DECIMAL(6,2),
INOUT p_c_last          VARCHAR(16),
OUT p_w_street_1        VARCHAR(20),
OUT p_w_street_2        VARCHAR(20),
OUT p_w_city            VARCHAR(20),
OUT p_w_state           CHAR(2),
OUT p_w_zip             CHAR(9),
OUT p_d_street_1        VARCHAR(20),
OUT p_d_street_2        VARCHAR(20),
OUT p_d_city            VARCHAR(20),
OUT p_d_state           CHAR(2),
OUT p_d_zip             CHAR(9),
OUT p_c_first           VARCHAR(16),
OUT p_c_middle          CHAR(2),
OUT p_c_street_1        VARCHAR(20),
OUT p_c_street_2        VARCHAR(20),
OUT p_c_city            VARCHAR(20),
OUT p_c_state           CHAR(2),
OUT p_c_zip             CHAR(9),
OUT p_c_phone           CHAR(16),
OUT p_c_since           DATE,
INOUT p_c_credit        CHAR(2),
OUT p_c_credit_lim      DECIMAL(12,2),
OUT p_c_discount        DECIMAL(4,4),
INOUT p_c_balance       DECIMAL(12,2),
OUT p_c_data            VARCHAR(500),
IN timestamp            DATE
)
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE done                    INT DEFAULT 0;
DECLARE namecnt                 INTEGER;
DECLARE p_d_name                VARCHAR(11);
DECLARE p_w_name                VARCHAR(11);
DECLARE p_c_new_data    VARCHAR(500);
DECLARE h_data                  VARCHAR(30);
DECLARE loop_counter    INT;
DECLARE c_byname CURSOR FOR
SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM OLD TABLE ( UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id ) AS UP;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM OLD TABLE ( UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id ) AS UP;
IF (byname = 1)
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
SET loop_counter = 0;
WHILE loop_counter <= (namecnt/2) DO
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
set loop_counter = loop_counter + 1;
END WHILE;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id WITH RR USE AND KEEP UPDATE LOCKS;
END IF;
SET p_c_balance = ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC'
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
SET h_data = ( p_w_name || ' ' || p_d_name );
SET p_c_new_data = (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' || TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || VARCHAR_FORMAT(p_h_amount,'9999.99') || VARCHAR_FORMAT(timestamp,'YYYYMMDDHH24MISS') || h_data);
SET p_c_new_data = SUBSTR(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
SET h_data = ( p_w_name || ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, timestamp, p_h_amount, h_data);
END }
set sql(3) { CREATE TYPE DELIVARRAY AS INTEGER ARRAY[10] }
set sql(4) { CREATE OR REPLACE PROCEDURE DELIVERY (
IN d_w_id                       INTEGER,
IN d_o_carrier_id               INTEGER,
IN tstamp                       TIMESTAMP,
OUT deliv_data                  DELIVARRAY
        )
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE d_no_o_id               INTEGER;
DECLARE d_d_id                  INTEGER;
DECLARE d_c_id                  INTEGER;
DECLARE d_ol_total              DECIMAL(6,2);
DECLARE loop_counter            INTEGER DEFAULT 1;
WHILE loop_counter <= 10 DO
SET d_d_id = loop_counter;
SELECT no_o_id INTO d_no_o_id FROM OLD TABLE ( DELETE FROM (
SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id 
ORDER BY no_o_id ASC 
FETCH FIRST 1 ROW ONLY ) 
);
SELECT o_c_id INTO d_c_id FROM OLD TABLE (
UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id ); 
SELECT SUM(ol_amount) INTO d_ol_total 
FROM OLD TABLE ( UPDATE order_line 
SET ol_delivery_d = tstamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id);
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
set deliv_data[loop_counter] = d_no_o_id;
set loop_counter = loop_counter + 1;
END WHILE;
END }
set sql(5) { CREATE OR REPLACE PROCEDURE OSTAT (
IN os_w_id                 INTEGER,
IN os_d_id                 INTEGER,
INOUT os_c_id              INTEGER,
IN byname                  INTEGER,
INOUT os_c_last            VARCHAR(16),
OUT os_c_first             VARCHAR(16),
OUT os_c_middle            VARCHAR(16),
OUT os_c_balance           DECIMAL(12,2),
OUT os_o_id                INTEGER,
OUT os_entdate             TIMESTAMP,
OUT os_o_carrier_id        INTEGER 
	)
READS SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE sqlstate		CHAR(5) DEFAULT '00000';
DECLARE namecnt			INTEGER;
DECLARE i			INTEGER;
DECLARE loop_counter    	INTEGER;
DECLARE done		    	INTEGER;
DECLARE os_ol_i_id INTEGER;	
DECLARE os_ol_supply_w_id INTEGER;	
DECLARE os_ol_quantity INTEGER;	
DECLARE os_ol_amount DECIMAL(6,2);
DECLARE os_ol_delivery_d TIMESTAMP;
DECLARE c_name CURSOR FOR
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
DECLARE c_line CURSOR FOR
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
OPEN c_name;
WHILE loop_counter <= (namecnt/2) DO
FETCH FROM c_name
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
set loop_counter = loop_counter + 1;
END WHILE;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
SELECT o_id, o_carrier_id, o_entry_d
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id = os_c_id
ORDER BY o_id DESC FETCH FIRST 1 ROW ONLY);
IF SQLSTATE = '02000'
THEN 
SET os_c_first = 'NO CUST ORDERS';
END IF;
OPEN c_line;
FETCH FROM c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
WHILE (SQLSTATE = '00000') DO
FETCH FROM c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
END WHILE;
CLOSE c_line;
END }
set sql(6) { CREATE OR REPLACE PROCEDURE SLEV (
IN st_w_id			INTEGER,
IN st_d_id			INTEGER,
IN threshold 			INTEGER, 
OUT stock_count			INTEGER
)
READS SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE st_o_id			INTEGER;	
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold WITH CS;
END }
for { set i 1 } { $i <= 6 } { incr i } {
db2_exec_direct $db_handle $sql($i)
    }
return
}

proc CreateDB2GlobalVars  { db_handle } {
puts "CREATING DB2 GLOBAL VARIABLES"
foreach vars {{no_c_discount DECIMAL(4,4)} {no_c_last VARCHAR(16)} {no_c_credit VARCHAR(2)} {no_d_tax DECIMAL(4,4)} {no_w_tax DECIMAL(4,4)} {no_d_next_o_id INTEGER} {p_c_id INTEGER} {p_c_last VARCHAR(16)} {p_w_street_1 VARCHAR(20)} {p_w_street_2 VARCHAR(20)} {p_w_city VARCHAR(20)} {p_w_state CHAR(2)} {p_w_zip CHAR(9)} {p_d_street_1 VARCHAR(20)} {p_d_street_2 VARCHAR(20)} {p_d_city VARCHAR(20)} {p_d_state CHAR(2)} {p_d_zip CHAR(9)} {p_c_first VARCHAR(16)} {p_c_middle CHAR(2)} {p_c_street_1 VARCHAR(20)} {p_c_street_2 VARCHAR(20)} {p_c_city VARCHAR(20)} {p_c_state CHAR(2)} {p_c_zip CHAR(9)} {p_c_phone CHAR(16)} {p_c_since TIMESTAMP} {p_c_credit CHAR(2)} {p_c_credit_lim DECIMAL(12, 2)} {p_c_discount DECIMAL(4,4)} {p_c_balance DECIMAL(12, 2)} {p_c_data VARCHAR(500)} {os_c_id INTEGER} {os_c_last VARCHAR(16)} {os_c_first VARCHAR(16)} {os_c_middle CHAR(2)} {os_c_balance DECIMAL(12, 2)} {os_o_id INTEGER} {os_entdate TIMESTAMP} {os_o_carrier_id INTEGER} {stock_count INTEGER} {deliv_data DELIVARRAY}} {
db2_exec_direct $db_handle "CREATE OR REPLACE VARIABLE $vars"
        }
}

proc GatherStatistics { db_handle num_part } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "call admin_cmd('runstats on table warehouse with distribution and detailed indexes all')"
set sql(2) "call admin_cmd('runstats on table district with distribution and detailed indexes all')"
set sql(3) "call admin_cmd('runstats on table new_order with distribution and detailed indexes all')"
set sql(4) "call admin_cmd('runstats on table history with distribution and detailed indexes all')"
set sql(5) "call admin_cmd('runstats on table item with distribution and detailed indexes all')"
for { set i 1 } { $i <= 5 } { incr i } {
puts -nonewline "$i.."
db2_exec_direct $db_handle $sql($i)
    }
if { $num_part eq 0 } {
set sql(1) "call admin_cmd('runstats on table customer with distribution and detailed indexes all')"
set sql(2) "call admin_cmd('runstats on table orders with distribution and detailed indexes all')"
set sql(3) "call admin_cmd('runstats on table order_line with distribution and detailed indexes all')"
set sql(4) "call admin_cmd('runstats on table stock with distribution and detailed indexes all')"
for { set i 1 } { $i <= 4 } { incr i } {
puts -nonewline "$i.."
db2_exec_direct $db_handle $sql($i)
    	} 
    } else {
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]]
db2_exec_direct $db_handle "call admin_cmd('runstats on table customer_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table orders_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table order_line_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table stock_$p with distribution and detailed indexes all')"
	}
     }
puts "Statistics Complete"
return
}

proc ConnectToDB2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password ]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}

proc CreateTables { db_handle num_part count_ware tspace_dict } {
puts "CREATING TPCC TABLES"
set sql(2) "CREATE TABLE DISTRICT (D_NEXT_O_ID INTEGER, D_TAX REAL, D_YTD DECIMAL(12, 2), D_NAME CHAR(10), D_STREET_1 CHAR(20), D_STREET_2 CHAR(20), D_CITY CHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9), D_ID SMALLINT NOT NULL, D_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict D ] INDEX IN [ dict get $tspace_dict D ] ORGANIZE BY KEY SEQUENCE ( D_ID STARTING FROM 1 ENDING AT 10, D_W_ID STARTING FROM 1 ENDING AT $count_ware ) ALLOW OVERFLOW"
set sql(3) "CREATE TABLE HISTORY (H_C_ID INTEGER, H_C_D_ID SMALLINT, H_C_W_ID INTEGER, H_D_ID SMALLINT, H_W_ID INTEGER, H_DATE TIMESTAMP, H_AMOUNT DECIMAL(6,2), H_DATA CHAR(24)) IN [ dict get $tspace_dict H ] INDEX IN [ dict get $tspace_dict H ]"
set sql(4) "CREATE TABLE ITEM (I_NAME CHAR(24) NOT NULL, I_PRICE DECIMAL(5,2) NOT NULL, I_DATA VARCHAR(50) NOT NULL, I_IM_ID INTEGER NOT NULL, I_ID INTEGER NOT NULL) IN [ dict get $tspace_dict I ] INDEX IN [ dict get $tspace_dict I ] ORGANIZE BY KEY SEQUENCE ( I_ID STARTING FROM 1 ENDING AT 100000) ALLOW OVERFLOW"
set sql(5) "CREATE TABLE WAREHOUSE (W_NAME CHAR(10), W_STREET_1 CHAR(20), W_STREET_2 CHAR(20), W_CITY CHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9), W_TAX REAL, W_YTD DECIMAL(12, 2), W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict W ] INDEX IN [ dict get $tspace_dict W ] ORGANIZE BY KEY SEQUENCE ( W_ID STARTING FROM 1 ENDING AT $count_ware ) ALLOW OVERFLOW"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID INTEGER NOT NULL, NO_D_ID SMALLINT NOT NULL, NO_O_ID INTEGER NOT NULL, PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID)) IN [ dict get $tspace_dict NO ] INDEX IN [ dict get $tspace_dict NO ]"
if {$num_part eq 0} {
set sql(1) "CREATE TABLE CUSTOMER (C_ID INTEGER NOT NULL, C_D_ID SMALLINT NOT NULL, C_W_ID INTEGER NOT NULL, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM DECIMAL(12, 2), C_DISCOUNT REAL, C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT INTEGER, C_DATA VARCHAR(500)) IN [ dict get $tspace_dict C ] INDEX IN [ dict get $tspace_dict C ] ORGANIZE BY KEY SEQUENCE ( C_ID STARTING FROM 1 ENDING AT 3000, C_W_ID STARTING FROM 1 ENDING at $count_ware, C_D_ID STARTING FROM 1 ENDING AT 10 ) ALLOW OVERFLOW"
set sql(6) "CREATE TABLE STOCK (S_REMOTE_CNT INTEGER, S_QUANTITY INTEGER, S_ORDER_CNT INTEGER, S_YTD INTEGER, S_DATA VARCHAR(50), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_I_ID INTEGER NOT NULL, S_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict S ] INDEX IN [ dict get $tspace_dict S ] ORGANIZE BY KEY SEQUENCE ( S_I_ID STARTING FROM 1 ENDING AT 100000, S_W_ID STARTING FROM 1 ENDING at $count_ware ) ALLOW OVERFLOW"
set sql(8) "CREATE TABLE ORDERS (O_ID INTEGER NOT NULL, O_W_ID INTEGER NOT NULL, O_D_ID SMALLINT NOT NULL, O_C_ID INTEGER, O_CARRIER_ID SMALLINT, O_OL_CNT SMALLINT, O_ALL_LOCAL SMALLINT, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_ID, O_W_ID, O_D_ID)) IN [ dict get $tspace_dict OR ] INDEX IN [ dict get $tspace_dict OR ]"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID INTEGER NOT NULL, OL_D_ID SMALLINT NOT NULL, OL_O_ID INTEGER NOT NULL, OL_NUMBER SMALLINT NOT NULL, OL_I_ID INTEGER, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT DECIMAL(6,2), OL_SUPPLY_W_ID INTEGER, OL_QUANTITY SMALLINT, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_O_ID, OL_W_ID, OL_D_ID, OL_NUMBER)) IN [ dict get $tspace_dict OL ] INDEX IN [ dict get $tspace_dict OL ]"
	} else {
#Manual Partition DB2
set partdiv [ expr round(ceil(double($count_ware)/10)) ]
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set idx [ lindex $partidx [ expr $p - 1]]
set sql(1$idx) "CREATE TABLE CUSTOMER_$p (C_ID INTEGER NOT NULL, C_D_ID SMALLINT NOT NULL, C_W_ID INTEGER NOT NULL, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM DECIMAL(12, 2), C_DISCOUNT REAL, C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT INTEGER, C_DATA VARCHAR(500)) IN [ dict get $tspace_dict C ] INDEX IN [ dict get $tspace_dict C ] ORGANIZE BY KEY SEQUENCE ( C_ID STARTING FROM 1 ENDING AT 3000, C_W_ID STARTING FROM $startpart ENDING at $endpart, C_D_ID STARTING FROM 1 ENDING AT 10 ) ALLOW OVERFLOW"
set sql(6$idx) "CREATE TABLE STOCK_$p (S_REMOTE_CNT INTEGER, S_QUANTITY INTEGER, S_ORDER_CNT INTEGER, S_YTD INTEGER, S_DATA VARCHAR(50), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_I_ID INTEGER NOT NULL, S_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict S ] INDEX IN [ dict get $tspace_dict S ] ORGANIZE BY KEY SEQUENCE ( S_I_ID STARTING FROM 1 ENDING AT 100000, S_W_ID STARTING FROM $startpart ENDING at $endpart ) ALLOW OVERFLOW"
set sql(8$idx) "CREATE TABLE ORDERS_$p (O_ID INTEGER NOT NULL, O_W_ID INTEGER NOT NULL, O_D_ID SMALLINT NOT NULL, O_C_ID INTEGER, O_CARRIER_ID SMALLINT, O_OL_CNT SMALLINT, O_ALL_LOCAL SMALLINT, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_ID, O_W_ID, O_D_ID)) IN [ dict get $tspace_dict OR ] INDEX IN [ dict get $tspace_dict OR ]"
set sql(9$idx) "CREATE TABLE ORDER_LINE_$p (OL_W_ID INTEGER NOT NULL, OL_D_ID SMALLINT NOT NULL, OL_O_ID INTEGER NOT NULL, OL_NUMBER SMALLINT NOT NULL, OL_I_ID INTEGER, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT DECIMAL(6,2), OL_SUPPLY_W_ID INTEGER, OL_QUANTITY SMALLINT, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_O_ID, OL_W_ID, OL_D_ID, OL_NUMBER)) IN [ dict get $tspace_dict OL ] INDEX IN [ dict get $tspace_dict OL ]"
if { $idx eq "j" } {
#Last constraint
set sql(1$idx-CHECK) "ALTER TABLE CUSTOMER_$p ADD CONSTRAINT C_CHK_$p CHECK (C_W_ID >= $startpart)"
set sql(6$idx-CHECK) "ALTER TABLE STOCK_$p ADD CONSTRAINT ST_CHK_$p CHECK (S_W_ID >= $startpart)"
set sql(8$idx-CHECK) "ALTER TABLE ORDERS_$p ADD CONSTRAINT ORD_CHK_$p CHECK (O_W_ID >= $startpart)"
set sql(9$idx-CHECK) "ALTER TABLE ORDER_LINE_$p ADD CONSTRAINT OL_CHK_$p CHECK (OL_W_ID >= $startpart)"
        } else {
set sql(1$idx-CHECK) "ALTER TABLE CUSTOMER_$p ADD CONSTRAINT C_CHK_$p CHECK (C_W_ID BETWEEN $startpart AND $endpart)"
set sql(6$idx-CHECK) "ALTER TABLE STOCK_$p ADD CONSTRAINT ST_CHK_$p CHECK (S_W_ID BETWEEN $startpart AND $endpart)"
set sql(8$idx-CHECK) "ALTER TABLE ORDERS_$p ADD CONSTRAINT ORD_CHK_$p CHECK (O_W_ID BETWEEN $startpart AND $endpart)"
set sql(9$idx-CHECK) "ALTER TABLE ORDER_LINE_$p ADD CONSTRAINT OL_CHK_$p CHECK (OL_W_ID BETWEEN $startpart AND $endpart)"
                }
           }
set idx k
set sql(1$idx) "create view CUSTOMER AS "
set sql(6$idx) "create view STOCK AS "
set sql(8$idx) "create view ORDERS AS "
set sql(9$idx) "create view ORDER_LINE AS "
for { set p 1 } { $p <= 9 } { incr p } {
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set sql(1$idx) "$sql(1$idx) SELECT * FROM CUSTOMER_$p UNION ALL"
set sql(6$idx) "$sql(6$idx) SELECT * FROM STOCK_$p UNION ALL"
set sql(8$idx) "$sql(8$idx) SELECT * FROM ORDERS_$p UNION ALL"
set sql(9$idx) "$sql(9$idx) SELECT * FROM ORDER_LINE_$p UNION ALL"
                }
set p 10
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set sql(1$idx) "$sql(1$idx) SELECT * FROM CUSTOMER_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(6$idx) "$sql(6$idx) SELECT * FROM STOCK_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(8$idx) "$sql(8$idx) SELECT * FROM ORDERS_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(9$idx) "$sql(9$idx) SELECT * FROM ORDER_LINE_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
        }
for { set i 1 } { $i <= 9 } { incr i } {
if {(($i eq 1)||($i eq 9)||($i eq 6)||($i eq 8)) && $num_part eq 10 } {
set parttype $i
set partidx [ list a b c d e f g h i j k ]
for { set p 1 } { $p <= 11 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]]
db2_exec_direct $db_handle $sql($parttype$idx)
if { $idx != "k" } {
db2_exec_direct $db_handle $sql($parttype$idx-CHECK)
	}
     }
 } else {
db2_exec_direct $db_handle $sql($i)
    }
  }
}

proc CreateIndexes { db_handle num_part } {
puts "CREATING TPCC INDEXES"
#DB2 I1 indexes implemented as primary keys
set sql(1) "ALTER TABLE HISTORY APPEND ON"
set sql(2) "ALTER TABLE ITEM LOCKSIZE TABLE"
if { $num_part eq 0 } {
set stmt_cnt 5
set sql(3) "create index ORDERS_I2 on ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(4) "create index CUSTOMER_I2 on CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
set sql(5) "ALTER TABLE ORDER_LINE APPEND ON"
		} else {
set stmt_cnt 32
for { set p 1 } { $p <= 10 } { incr p } {
set sql([ expr $p + 2]) "create index ORDERS_I2_$p on ORDERS_$p (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql([ expr $p + 12]) "create index CUSTOMER_I2_$p on CUSTOMER_$p (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
set sql([ expr $p + 22]) "ALTER TABLE ORDER_LINE_$p APPEND ON"
		}
	}
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
db2_exec_direct $db_handle $sql($i)
	}
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { db_handle d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
proc date_function {} {
set df "timestamp_format('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', [ date_function ], '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', [ date_function ], '$h_amount', '$h_data')
if { $bld_cnt<= 99 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 100} ] } {
db2_exec_direct $db_handle "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list" 
db2_exec_direct $db_handle "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list"
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { db_handle d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
proc date_function {} {
set df "timestamp_format('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 9 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', [ date_function ])
if { $bld_cnt<= 9 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 9 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 10} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
db2_exec_direct $db_handle "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
if { $o_id > 2100 } {
db2_exec_direct $db_handle "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
	}
db2_exec_direct $db_handle "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list"
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { db_handle MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
db2_exec_direct $db_handle "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 10000} ] } {
	puts "Loading Items - $i_id"
			}
		}
puts "Item done"
return
	}

proc Stock { db_handle w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 99 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 100} ] } {
db2_exec_direct $db_handle "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	puts "Stock done"
	return
}

proc District { db_handle w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
db2_exec_direct $db_handle "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	puts "District done"
	return
}

proc LoadWare { db_handle ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
db2_exec_direct $db_handle "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock $db_handle $w_id $MAXITEMS
	District $db_handle $w_id $DIST_PER_WARE
	}
}

proc LoadCust { db_handle ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $db_handle $d_id $w_id $CUST_PER_DIST
		}
	}
	return
}

proc LoadOrd { db_handle ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $db_handle $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	return
}
proc do_tpcc { dbname user password count_ware partition num_threads tpcc_def_tab tpcc_part_tabs} {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
set db_handle [ ConnectToDB2 $dbname $user $password ]
if { $partition eq "true" && [ expr $count_ware >= 10 ] } {
set num_part 10
set tspace_dict $tpcc_part_tabs
dict for {tbl tblspc} $tspace_dict {
if { $tblspc eq "" } { dict set tspace_dict $tbl $tpcc_def_tab }
	}
	} else {
set num_part 0
#All tablespaces are default
set tspace_dict [ dict create ]
foreach tbl {C D H I W S NO OR OL} {
dict set tspace_dict $tbl $tpcc_def_tab
		}
	}
if { [ dict size $tspace_dict ] != 9 } {
error "Incorrect number of tablspaces defined"
	}
CreateTables $db_handle $num_part $count_ware $tspace_dict
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $db_handle $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {  
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
	}
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
	}
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000 
}} else {
LoadItems $db_handle $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {  
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 480 } { 
puts "Monitor failed to notify ready state" 
return
	}
after 5000 
}
set db_handle [ ConnectToDB2 $dbname $user $password ]
if { $partition eq "true" && [ expr $count_ware >= 10 ] } {
set num_part 10
	} else {
set num_part 0
	}
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $db_handle $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $db_handle $mystart $myend $CUST_PER_DIST $DIST_PER_WARE 
LoadOrd $db_handle $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
db2_disconnect $db_handle
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
#108 Monitoring Virtual User disconnects during DB2 TPCC schema build
catch {db2_disconnect $db_handle}
set db_handle [ ConnectToDB2 $dbname $user $password ]
CreateIndexes $db_handle $num_part
CreateStoredProcs $db_handle 
CreateDB2GlobalVars $db_handle 
GatherStatistics $db_handle $num_part 
puts "[ string toupper $user ] SCHEMA COMPLETE"
db2_disconnect $db_handle
return
	}
    }
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 984.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $db2_dbase $db2_user $db2_pass $db2_count_ware $db2_partition $db2_num_threads $db2_def_tab \{$db2_tab_list\}"
	} else { return }
}

proc loaddb2tpcc {} {
global  db2_user db2_pass db2_dbase db2_total_iterations db2_raiseerror db2_keyandthink _ED
if {  ![ info exists db2_user ] } { set db2_user "db2inst1" }
if {  ![ info exists db2_pass ] } { set db2_pass "ibmdb2" }
if {  ![ info exists db2_dbase ] } { set db2_dbase "tpcc" }
if {  ![ info exists db2_total_iterations ] } { set db2_total_iterations 1000000 }
if {  ![ info exists db2_raiseerror ] } { set db2_raiseerror "false" }
if {  ![ info exists db2_keyandthink ] } { set db2_keyandthink "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]

.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require db2tcl} \] { error \"Failed to load db2tcl - DB2 Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $db2_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$db2_raiseerror\" ;# Exit script on DB2 (true or false)
set KEYANDTHINK \"$db2_keyandthink\" ;# Time for user thinking and keying (true or false)
set user \"$db2_user\" ;# DB2 user
set password \"$db2_pass\" ;# Password for the DB2 user
set dbname \"$db2_dbase\" ;#Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 11.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#DB2 CONNECTION
proc ConnectToDB2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}
#NEW ORDER
proc neword { set_handle_no stmnt_handle_no select_handle_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
db2_exec_prepared $set_handle_no
if {[ catch {db2_bind_exec $stmnt_handle_no "$no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date"} message]} {
if {$RAISEERROR} {
error "New Order: $message"
	}
	} else {
set stmnt_fetch [ db2_select_prepared $select_handle_no ]
puts "New Order: $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt 0 [ db2_fetchrow $stmnt_fetch ]"
	}
}
#PAYMENT
proc payment { set_handle_py stmnt_handle_py select_handle_py p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name NULL
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
db2_bind_exec $set_handle_py "$p_c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_py "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $byname $p_h_amount $h_date"} message]} {
if {$RAISEERROR} {
error "Payment: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_py ]
puts "Payment: $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name 0 0 [ db2_fetchrow $stmnt_fetch ]"
	}
}
#ORDER_STATUS
proc ostat { set_handle_os stmnt_handle_os select_handle_os w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name NULL
}
db2_bind_exec $set_handle_os "$c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_os "$w_id $d_id $byname"} message]} {
if {$RAISEERROR} {
error "Order Status: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_os ]
puts "Order Status: $w_id $d_id $c_id $byname $name [ db2_fetchrow $stmnt_fetch ]"
	}
}
#DELIVERY
proc delivery { stmnt_handle_dl select_handle_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {db2_bind_exec $stmnt_handle_dl "$w_id $carrier_id $date"} message]} {
if {$RAISEERROR} {
error "Delivery: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_dl ]
while {[set line [ db2_fetchrow $stmnt_fetch]] != ""} { lappend deliv_data $line }
}
puts "Delivery: $w_id $carrier_id $date $deliv_data"
}
#STOCK LEVEL
proc slev { stmnt_handle_sl select_handle_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {db2_bind_exec $stmnt_handle_sl "$w_id $stock_level_d_id $threshold"} message]} {
if {$RAISEERROR} {
error "Stock Level: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_sl ]
puts "Stock Level: $w_id $stock_level_d_id $threshold [ db2_fetchrow $stmnt_fetch ]"
	}
}

proc prep_statement { db_handle handle_st } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_st {
stmnt_handle_sl {
set stmnt_handle_sl [ db2_prepare $db_handle "CALL SLEV(?,?,?,stock_count)" ]
return $stmnt_handle_sl
}
stmnt_handle_dl {
set stmnt_handle_dl [ db2_prepare $db_handle "CALL DELIVERY(?,?,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'),deliv_data)" ]
return $stmnt_handle_dl
	}
stmnt_handle_os {
set stmnt_handle_os [ db2_prepare $db_handle "CALL OSTAT (?,?,os_c_id,?,os_c_last,os_c_first,os_c_middle,os_c_balance,os_o_id,os_entdate,os_o_carrier_id)" ]
return $stmnt_handle_os
	}
stmnt_handle_py {
set stmnt_handle_py [ db2_prepare $db_handle "CALL PAYMENT (?,?,?,?,p_c_id,?,?,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,p_c_since,p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_py
	}
stmnt_handle_no {
set stmnt_handle_no [ db2_prepare $db_handle "CALL NEWORD (?,?,?,?,?,no_c_discount,no_c_last,no_c_credit,no_d_tax,no_w_tax,no_d_next_o_id,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_no
	}
    }
}

proc prep_select { db_handle handle_se } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_se {
select_handle_sl {
set select_handle_sl [ db2_prepare $db_handle "select stock_count from $dummy" ]
return $select_handle_sl
	}
select_handle_dl {
set select_handle_dl [ db2_prepare $db_handle "select * from UNNEST(deliv_data)" ]
return $select_handle_dl
     }
select_handle_os {
set select_handle_os [ db2_prepare $db_handle "select os_c_id, os_c_last, os_c_first,os_c_middle,os_c_balance,os_o_id,VARCHAR_FORMAT(os_entdate, 'YYYY-MM-DD HH24:MI:SS'),os_o_carrier_id from $dummy" ]
return $select_handle_os
	}
select_handle_py {
set select_handle_py [ db2_prepare $db_handle "select p_c_id,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,VARCHAR_FORMAT(p_c_since, 'YYYY-MM-DD HH24:MI:SS'),p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data from $dummy" ]
return $select_handle_py
	}
select_handle_no {
set select_handle_no [ db2_prepare $db_handle "select no_c_discount, no_c_last, no_c_credit, no_d_tax, no_w_tax, no_d_next_o_id from $dummy" ]
return $select_handle_no
	}
    }
}

proc prep_set_db2_global_var { db_handle handle_gv } {
switch $handle_gv {
set_handle_os {
set set_handle_os [ db2_prepare $db_handle "SET (os_c_id,os_c_last)=(?,?)" ]
return $set_handle_os
}
set_handle_py {
set set_handle_py [ db2_prepare $db_handle "SET (p_c_id,p_c_last,p_c_credit,p_c_balance)=(?,?,'0',0.0)" ]
return $set_handle_py
}
set_handle_no {
set set_handle_no [ db2_prepare $db_handle "SET (no_d_next_o_id)=(0)" ]
return $set_handle_no
       }
   }
}
#RUN TPC-C
set db_handle [ ConnectToDB2 $dbname $user $password ]
foreach handle_gv {set_handle_os set_handle_py set_handle_no} {set $handle_gv [ prep_set_db2_global_var $db_handle $handle_gv ]}
foreach handle_st {stmnt_handle_dl stmnt_handle_sl stmnt_handle_os stmnt_handle_py stmnt_handle_no} {set $handle_st [ prep_statement $db_handle $handle_st ]}
foreach handle_se {select_handle_sl select_handle_dl select_handle_os select_handle_py select_handle_no} {set $handle_se [ prep_select $db_handle $handle_se ]}
set stmnt_handle1 [ db2_select_direct $db_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $db_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR 
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
db2_finish $set_handle_os
db2_finish $set_handle_py
db2_finish $set_handle_no
db2_finish $stmnt_handle_sl
db2_finish $stmnt_handle_dl
db2_finish $stmnt_handle_os
db2_finish $stmnt_handle_py
db2_finish $stmnt_handle_no
db2_finish $select_handle_sl
db2_finish $select_handle_os
db2_finish $select_handle_py
db2_finish $select_handle_no
db2_finish $select_handle_dl
db2_disconnect $db_handle
	}
}

proc loadtimeddb2tpcc {} {
global  db2_user db2_pass db2_dbase db2_total_iterations db2_raiseerror db2_keyandthink db2_rampup db2_duration db2_monreport opmode _ED
if {  ![ info exists db2_user ] } { set db2_user "db2inst1" }
if {  ![ info exists db2_pass ] } { set db2_pass "ibmdb2" }
if {  ![ info exists db2_dbase ] } { set db2_dbase "tpcc" }
if {  ![ info exists db2_total_iterations ] } { set db2_total_iterations 1000000 }
if {  ![ info exists db2_raiseerror ] } { set db2_raiseerror "false" }
if {  ![ info exists db2_keyandthink ] } { set db2_keyandthink "false" }
if {  ![ info exists db2_rampup ] } { set db2_rampup "2" }
if {  ![ info exists db2_duration ] } { set db2_duration "5" }
if {  ![ info exists db2_monreport ] } { set db2_monreport "0" }
if {  ![ info exists opmode ] } { set opmode "Local" }
if { $db2_monreport >= $db2_duration } {
set db2_monreport 0
	}
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require db2tcl} \] { error \"Failed to load db2tcl - DB2 Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $db2_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$db2_raiseerror\" ;# Exit script on DB2 (true or false)
set KEYANDTHINK \"$db2_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $db2_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $db2_duration;  # Duration in minutes before second Transaction Count is taken
set monreportinterval $db2_monreport; #Portion of duration to capture monreport
set mode \"$opmode\" ;# HammerDB operational mode
set user \"$db2_user\" ;# DB2 user
set password \"$db2_pass\" ;# Password for the DB2 user
set dbname \"$db2_dbase\" ;#Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 15.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }
if { [ chk_thread ] eq "FALSE" } {
error "DB2 Timed Test Script must be run in Thread Enabled Interpreter"
}

#DB2 CONNECTION
proc ConnectToDB2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}

set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
1 {
if { $mode eq "Local" || $mode eq "Master" } {
set db_handle [ ConnectToDB2 $dbname $user $password ]
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
set stmnt_handle1 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set start_trans [ db2_fetchrow $stmnt_handle1 ]
db2_finish $stmnt_handle1
set stmnt_handle2 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set start_nopm [ db2_fetchrow $stmnt_handle2 ]
db2_finish $stmnt_handle2
set durmin $duration
set testtime 0
set doingmonreport "false"
if { $monreportinterval > 0 } { 
if { $monreportinterval >= $duration } { 
set monreportinterval 0 
puts "Timing test period of $duration in minutes"
	} else {
set doingmonreport "true"
set monreportsecs [ expr $monreportinterval * 60 ] 
set duration [ expr $duration - $monreportinterval ]
puts "Capturing MONREPORT DBSUMMARY for $monreportsecs seconds (This Virtual User cannot be terminated while capturing report)"
set monreport_handle [ db2_select_direct $db_handle "call monreport.dbsummary($monreportsecs)" ]
while {[set line [db2_fetchrow $monreport_handle]] != ""} {
append monreport [ join $line ] 
append monreport "\\n"
}
db2_finish $monreport_handle
puts "MONREPORT duration complete"
puts "Timing remaining test period of $duration in minutes"
}}
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
set stmnt_handle3 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set end_trans [ db2_fetchrow $stmnt_handle3 ]
db2_finish $stmnt_handle3
set stmnt_handle4 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set end_nopm [ db2_fetchrow $stmnt_handle4 ]
db2_finish $stmnt_handle4
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm DB2 TPM at $nopm NOPM"
if { $doingmonreport eq "true" } {
puts "---MONREPORT OUTPUT---"
puts $monreport
	}
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
db2_disconnect $db_handle
               } else {
puts "Operating in Slave Mode, No Snapshots taken..."
                }
	    }
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#DB2 CONNECTION
proc ConnectToDB2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}
#NEW ORDER
proc neword { set_handle_no stmnt_handle_no select_handle_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
db2_exec_prepared $set_handle_no
if {[ catch {db2_bind_exec $stmnt_handle_no "$no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date"} message]} {
if {$RAISEERROR} {
error "New Order: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_no ]
	}
}
#PAYMENT
proc payment { set_handle_py stmnt_handle_py select_handle_py p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name NULL
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
db2_bind_exec $set_handle_py "$p_c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_py "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $byname $p_h_amount $h_date"} message]} {
if {$RAISEERROR} {
error "Payment: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_py ]
	}
}
#ORDER_STATUS
proc ostat { set_handle_os stmnt_handle_os select_handle_os w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name NULL
}
db2_bind_exec $set_handle_os "$c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_os "$w_id $d_id $byname"} message]} {
if {$RAISEERROR} {
error "Order Status: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_os ]
	}
}
#DELIVERY
proc delivery { stmnt_handle_dl select_handle_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {db2_bind_exec $stmnt_handle_dl "$w_id $carrier_id $date"} message]} {
if {$RAISEERROR} {
error "Delivery: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_dl ]
	}
}
#STOCK LEVEL
proc slev { stmnt_handle_sl select_handle_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {db2_bind_exec $stmnt_handle_sl "$w_id $stock_level_d_id $threshold"} message]} {
if {$RAISEERROR} {
error "Stock Level: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_sl ]
	}
}

proc prep_statement { db_handle handle_st } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_st {
stmnt_handle_sl {
set stmnt_handle_sl [ db2_prepare $db_handle "CALL SLEV(?,?,?,stock_count)" ]
return $stmnt_handle_sl
}
stmnt_handle_dl {
set stmnt_handle_dl [ db2_prepare $db_handle "CALL DELIVERY(?,?,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'),deliv_data)" ]
return $stmnt_handle_dl
}
stmnt_handle_os {
set stmnt_handle_os [ db2_prepare $db_handle "CALL OSTAT (?,?,os_c_id,?,os_c_last,os_c_first,os_c_middle,os_c_balance,os_o_id,os_entdate,os_o_carrier_id)" ]
return $stmnt_handle_os
	}
stmnt_handle_py {
set stmnt_handle_py [ db2_prepare $db_handle "CALL PAYMENT (?,?,?,?,p_c_id,?,?,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,p_c_since,p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_py
	}
stmnt_handle_no {
set stmnt_handle_no [ db2_prepare $db_handle "CALL NEWORD (?,?,?,?,?,no_c_discount,no_c_last,no_c_credit,no_d_tax,no_w_tax,no_d_next_o_id,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_no
	}
    }
}

proc prep_select { db_handle handle_se } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_se {
select_handle_sl {
set select_handle_sl [ db2_prepare $db_handle "select stock_count from $dummy" ]
return $select_handle_sl
	}
select_handle_dl {
set select_handle_dl [ db2_prepare $db_handle "select * from UNNEST(deliv_data)" ]
return $select_handle_dl
        }
select_handle_os {
set select_handle_os [ db2_prepare $db_handle "select os_c_id, os_c_last, os_c_first,os_c_middle,os_c_balance,os_o_id,VARCHAR_FORMAT(os_entdate, 'YYYY-MM-DD HH24:MI:SS'),os_o_carrier_id from $dummy" ]
return $select_handle_os
	}
select_handle_py {
set select_handle_py [ db2_prepare $db_handle "select p_c_id,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,VARCHAR_FORMAT(p_c_since, 'YYYY-MM-DD HH24:MI:SS'),p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data from $dummy" ]
return $select_handle_py
	}
select_handle_no {
set select_handle_no [ db2_prepare $db_handle "select no_c_discount, no_c_last, no_c_credit, no_d_tax, no_w_tax, no_d_next_o_id from $dummy" ]
return $select_handle_no
	}
   }
}

proc prep_set_db2_global_var { db_handle handle_gv } {
switch $handle_gv {
set_handle_os {
set set_handle_os [ db2_prepare $db_handle "SET (os_c_id,os_c_last)=(?,?)" ]
return $set_handle_os
}
set_handle_py {
set set_handle_py [ db2_prepare $db_handle "SET (p_c_id,p_c_last,p_c_credit,p_c_balance)=(?,?,'0',0.0)" ]
return $set_handle_py
}
set_handle_no {
set set_handle_no [ db2_prepare $db_handle "SET (no_d_next_o_id)=(0)" ]
return $set_handle_no
       }
   }
}
#RUN TPC-C
set db_handle [ ConnectToDB2 $dbname $user $password ]
foreach handle_gv {set_handle_os set_handle_py set_handle_no} {set $handle_gv [ prep_set_db2_global_var $db_handle $handle_gv ]}
foreach handle_st {stmnt_handle_dl stmnt_handle_sl stmnt_handle_os stmnt_handle_py stmnt_handle_no} {set $handle_st [ prep_statement $db_handle $handle_st ]}
foreach handle_se {select_handle_sl select_handle_dl select_handle_os select_handle_py select_handle_no} {set $handle_se [ prep_select $db_handle $handle_se ]}
set stmnt_handle1 [ db2_select_direct $db_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $db_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR 
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
  }
db2_finish $set_handle_os
db2_finish $set_handle_py
db2_finish $set_handle_no
db2_finish $stmnt_handle_sl
db2_finish $stmnt_handle_dl
db2_finish $stmnt_handle_os
db2_finish $stmnt_handle_py
db2_finish $stmnt_handle_no
db2_finish $select_handle_sl
db2_finish $select_handle_os
db2_finish $select_handle_py
db2_finish $select_handle_no
db2_finish $select_handle_dl
db2_disconnect $db_handle
	}
   }}
}

proc check_mytpcc {} {
global mysql_host mysql_port my_count_ware mysql_user mysql_pass mysql_dbase storage_engine mysql_partition mysql_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists my_count_ware ] } { set my_count_ware "1" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists storage_engine ] } { set storage_engine "innodb" }
if {  ![ info exists mysql_partition ] } { set mysql_partition "false" }
if {  ![ info exists mysql_num_threads ] } { set mysql_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $my_count_ware Warehouse MySQL TPC-C schema\nin host [string toupper $mysql_host:$mysql_port] under user [ string toupper $mysql_user ] in database [ string toupper $mysql_dbase ] with storage engine [ string toupper $storage_engine ]?" -type yesno ] == yes} { 
if { $mysql_num_threads eq 1 || $my_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mysql_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require mysqltcl} ] { error "Failed to load mysqltcl - MySQL Library Error" }
proc CreateStoredProcs { mysql_handler } {
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) { CREATE PROCEDURE `NEWORD` (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
OUT no_c_discount 	DECIMAL(4,4),
OUT no_c_last 		VARCHAR(16),
OUT no_c_credit 		VARCHAR(2),
OUT no_d_tax 		DECIMAL(4,4),
OUT no_w_tax 		DECIMAL(4,4),
INOUT no_d_next_o_id 	INTEGER,
IN timestamp 		DATE
)
BEGIN
DECLARE no_ol_supply_w_id	INTEGER;
DECLARE no_ol_i_id		INTEGER;
DECLARE no_ol_quantity 		INTEGER;
DECLARE no_o_all_local 		INTEGER;
DECLARE o_id 			INTEGER;
DECLARE no_i_name		VARCHAR(24);
DECLARE no_i_price		DECIMAL(5,2);
DECLARE no_i_data		VARCHAR(50);
DECLARE no_s_quantity		DECIMAL(6);
DECLARE no_ol_amount		DECIMAL(6,2);
DECLARE no_s_dist_01		CHAR(24);
DECLARE no_s_dist_02		CHAR(24);
DECLARE no_s_dist_03		CHAR(24);
DECLARE no_s_dist_04		CHAR(24);
DECLARE no_s_dist_05		CHAR(24);
DECLARE no_s_dist_06		CHAR(24);
DECLARE no_s_dist_07		CHAR(24);
DECLARE no_s_dist_08		CHAR(24);
DECLARE no_s_dist_09		CHAR(24);
DECLARE no_s_dist_10		CHAR(24);
DECLARE no_ol_dist_info 	CHAR(24);
DECLARE no_s_data	   	VARCHAR(50);
DECLARE x		        INTEGER;
DECLARE rbk		       	INTEGER;
DECLARE loop_counter    	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
SET no_o_all_local = 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
START TRANSACTION;
SELECT d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax
FROM district
WHERE d_id = no_d_id AND d_w_id = no_w_id FOR UPDATE;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id;
SET o_id = no_d_next_o_id;
INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
SET rbk = FLOOR(1 + (RAND() * 99));
SET loop_counter = 1;
WHILE loop_counter <= no_o_ol_cnt DO
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
SET no_ol_i_id = 100001;
ELSE
SET no_ol_i_id = FLOOR(1 + (RAND() * 100000));
END IF;
SET x = FLOOR(1 + (RAND() * 100));
IF ( x > 1 )
THEN
SET no_ol_supply_w_id = no_w_id;
ELSE
SET no_ol_supply_w_id = no_w_id;
SET no_o_all_local = 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1)) DO
SET no_ol_supply_w_id = FLOOR(1 + (RAND() * no_max_w_id));
END WHILE;
END IF;
SET no_ol_quantity = FLOOR(1 + (RAND() * 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10
FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
SET no_s_quantity = ( no_s_quantity - no_ol_quantity );
ELSE
SET no_s_quantity = ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;
SET no_ol_amount = (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );
CASE no_d_id
WHEN 1 THEN
SET no_ol_dist_info = no_s_dist_01;
WHEN 2 THEN
SET no_ol_dist_info = no_s_dist_02;
WHEN 3 THEN
SET no_ol_dist_info = no_s_dist_03;
WHEN 4 THEN
SET no_ol_dist_info = no_s_dist_04;
WHEN 5 THEN
SET no_ol_dist_info = no_s_dist_05;
WHEN 6 THEN
SET no_ol_dist_info = no_s_dist_06;
WHEN 7 THEN
SET no_ol_dist_info = no_s_dist_07;
WHEN 8 THEN
SET no_ol_dist_info = no_s_dist_08;
WHEN 9 THEN
SET no_ol_dist_info = no_s_dist_09;
WHEN 10 THEN
SET no_ol_dist_info = no_s_dist_10;
END CASE;
INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);
set loop_counter = loop_counter + 1;
END WHILE;
COMMIT;
END }
set sql(2) { CREATE PROCEDURE `DELIVERY`(
d_w_id			INTEGER,
d_o_carrier_id  	INTEGER,
IN timestamp 		DATE
)
BEGIN
DECLARE d_no_o_id	INTEGER;
DECLARE current_rowid 	INTEGER;
DECLARE d_d_id	    	INTEGER;
DECLARE d_c_id        	INTEGER;
DECLARE d_ol_total	INTEGER;
DECLARE deliv_data	VARCHAR(100);
DECLARE loop_counter  	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
SET loop_counter = 1;
WHILE loop_counter <= 10 DO
SET d_d_id = loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
SET deliv_data = CONCAT(d_d_id,' ',d_no_o_id,' ',timestamp);
COMMIT;
set loop_counter = loop_counter + 1;
END WHILE;
END }
set sql(3) { CREATE PROCEDURE `PAYMENT` (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
INOUT p_c_id		INTEGER,
byname			INTEGER,
p_h_amount		DECIMAL(6,2),
INOUT p_c_last	  	VARCHAR(16),
OUT p_w_street_1  	VARCHAR(20),
OUT p_w_street_2  	VARCHAR(20),
OUT p_w_city		VARCHAR(20),
OUT p_w_state		CHAR(2),
OUT p_w_zip		CHAR(9),
OUT p_d_street_1	VARCHAR(20),
OUT p_d_street_2	VARCHAR(20),
OUT p_d_city		VARCHAR(20),
OUT p_d_state		CHAR(2),
OUT p_d_zip		CHAR(9),
OUT p_c_first		VARCHAR(16),
OUT p_c_middle		CHAR(2),
OUT p_c_street_1	VARCHAR(20),
OUT p_c_street_2	VARCHAR(20),
OUT p_c_city		VARCHAR(20),
OUT p_c_state		CHAR(2),
OUT p_c_zip		CHAR(9),
OUT p_c_phone		CHAR(16),
OUT p_c_since		DATE,
INOUT p_c_credit	CHAR(2),
OUT p_c_credit_lim 	DECIMAL(12,2),
OUT p_c_discount	DECIMAL(4,4),
INOUT p_c_balance 	DECIMAL(12,2),
OUT p_c_data		VARCHAR(500),
IN timestamp		DATE
)
BEGIN
DECLARE done      	INT DEFAULT 0;
DECLARE	namecnt		INTEGER;
DECLARE p_d_name	VARCHAR(11);
DECLARE p_w_name	VARCHAR(11);
DECLARE p_c_new_data	VARCHAR(500);
DECLARE h_data		VARCHAR(30);
DECLARE loop_counter  	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE c_byname CURSOR FOR
SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
START TRANSACTION;
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF (byname = 1)
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
SET loop_counter = 0;
WHILE loop_counter <= (namecnt/2) DO
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
set loop_counter = loop_counter + 1;
END WHILE;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
SET p_c_balance = ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC'
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
SET h_data = CONCAT(p_w_name,' ',p_d_name);
SET p_c_new_data = CONCAT(CAST(p_c_id AS CHAR),' ',CAST(p_c_d_id AS CHAR),' ',CAST(p_c_w_id AS CHAR),' ',CAST(p_d_id AS CHAR),' ',CAST(p_w_id AS CHAR),' ',CAST(FORMAT(p_h_amount,2) AS CHAR),CAST(timestamp AS CHAR),h_data);
SET p_c_new_data = SUBSTR(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
SET h_data = CONCAT(p_w_name,' ',p_d_name);
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, timestamp, p_h_amount, h_data);
COMMIT;
END }
set sql(4) { CREATE PROCEDURE `OSTAT` (
os_w_id                 INTEGER,
os_d_id                 INTEGER,
INOUT os_c_id           INTEGER,
byname                  INTEGER,
INOUT os_c_last         VARCHAR(16),
OUT os_c_first          VARCHAR(16),
OUT os_c_middle         CHAR(2),
OUT os_c_balance        DECIMAL(12,2),
OUT os_o_id             INTEGER,
OUT os_entdate          DATE,
OUT os_o_carrier_id     INTEGER
)
BEGIN 
DECLARE  os_ol_i_id 	INTEGER;
DECLARE  os_ol_supply_w_id INTEGER;
DECLARE  os_ol_quantity INTEGER;
DECLARE  os_ol_amount 	INTEGER;
DECLARE  os_ol_delivery_d 	DATE;
DECLARE done            INT DEFAULT 0;
DECLARE namecnt         INTEGER;
DECLARE i               INTEGER;
DECLARE loop_counter    INT;
DECLARE no_order_status VARCHAR(100);
DECLARE os_ol_i_id_array VARCHAR(200);
DECLARE os_ol_supply_w_id_array VARCHAR(200);
DECLARE os_ol_quantity_array VARCHAR(200);
DECLARE os_ol_amount_array VARCHAR(200);
DECLARE os_ol_delivery_d_array VARCHAR(210);
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE c_name CURSOR FOR
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
DECLARE c_line CURSOR FOR
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
set no_order_status = '';
set os_ol_i_id_array = 'CSV,';
set os_ol_supply_w_id_array = 'CSV,';
set os_ol_quantity_array = 'CSV,';
set os_ol_amount_array = 'CSV,';
set os_ol_delivery_d_array = 'CSV,';
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
OPEN c_name;
SET loop_counter = 0;
WHILE loop_counter <= (namecnt/2) DO
FETCH c_name
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
set loop_counter = loop_counter + 1;
END WHILE;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
set done = 0;
SELECT o_id, o_carrier_id, o_entry_d
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id = os_c_id
ORDER BY o_id DESC) AS sb LIMIT 1;
IF done THEN
set no_order_status = 'No orders for customer';
END IF;
set done = 0;
set i = 0;
OPEN c_line;
REPEAT
FETCH c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
IF NOT done THEN
set os_ol_i_id_array = CONCAT(os_ol_i_id_array,',',CAST(i AS CHAR),',',CAST(os_ol_i_id AS CHAR));
set os_ol_supply_w_id_array = CONCAT(os_ol_supply_w_id_array,',',CAST(i AS CHAR),',',CAST(os_ol_supply_w_id AS CHAR));
set os_ol_quantity_array = CONCAT(os_ol_quantity_array,',',CAST(i AS CHAR),',',CAST(os_ol_quantity AS CHAR));
set os_ol_amount_array = CONCAT(os_ol_amount_array,',',CAST(i AS CHAR),',',CAST(os_ol_amount AS CHAR));
set os_ol_delivery_d_array = CONCAT(os_ol_delivery_d_array,',',CAST(i AS CHAR),',',CAST(os_ol_delivery_d AS CHAR));
set i = i+1;
END IF;
UNTIL done END REPEAT;
CLOSE c_line;
END }
set sql(5) { CREATE PROCEDURE `SLEV` (
st_w_id                 INTEGER,
st_d_id                 INTEGER,
threshold               INTEGER
)
BEGIN 
DECLARE st_o_id         INTEGER;
DECLARE stock_count     INTEGER;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
END }
for { set i 1 } { $i <= 5 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc GatherStatistics { mysql_handler } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "analyze table customer, district, history, item, new_order, orders, order_line, stock, warehouse"
mysqlexec $mysql_handler $sql(1)
return
}

proc CreateDatabase { mysql_handler db } {
puts "CREATING DATABASE $db"
set sql(1) "SET FOREIGN_KEY_CHECKS = 0"
set sql(2) "CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET latin1 COLLATE latin1_swedish_ci"
for { set i 1 } { $i <= 2 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc CreateTables { mysql_handler storage_engine num_part } {
puts "CREATING TPCC TABLES"
set sql(1) "CREATE TABLE `customer` (
  `c_id` INT(5) NOT NULL,
  `c_d_id` INT(2) NOT NULL,
  `c_w_id` INT(4) NOT NULL,
  `c_first` VARCHAR(16) BINARY NULL,
  `c_middle` CHAR(2) BINARY NULL,
  `c_last` VARCHAR(16) BINARY NULL,
  `c_street_1` VARCHAR(20) BINARY NULL,
  `c_street_2` VARCHAR(20) BINARY NULL,
  `c_city` VARCHAR(20) BINARY NULL,
  `c_state` CHAR(2) BINARY NULL,
  `c_zip` CHAR(9) BINARY NULL,
  `c_phone` CHAR(16) BINARY NULL,
  `c_since` DATETIME NULL,
  `c_credit` CHAR(2) BINARY NULL,
  `c_credit_lim` DECIMAL(12, 2) NULL,
  `c_discount` DECIMAL(4, 4) NULL,
  `c_balance` DECIMAL(12, 2) NULL,
  `c_ytd_payment` DECIMAL(12, 2) NULL,
  `c_payment_cnt` INT(8) NULL,
  `c_delivery_cnt` INT(8) NULL,
  `c_data` VARCHAR(500) BINARY NULL,
PRIMARY KEY (`c_w_id`,`c_d_id`,`c_id`),
KEY c_w_id (`c_w_id`,`c_d_id`,`c_last`(16),`c_first`(16))
)
ENGINE = $storage_engine"
set sql(2) "CREATE TABLE `district` (
  `d_id` INT(2) NOT NULL,
  `d_w_id` INT(4) NOT NULL,
  `d_ytd` DECIMAL(12, 2) NULL,
  `d_tax` DECIMAL(4, 4) NULL,
  `d_next_o_id` INT NULL,
  `d_name` VARCHAR(10) BINARY NULL,
  `d_street_1` VARCHAR(20) BINARY NULL,
  `d_street_2` VARCHAR(20) BINARY NULL,
  `d_city` VARCHAR(20) BINARY NULL,
  `d_state` CHAR(2) BINARY NULL,
  `d_zip` CHAR(9) BINARY NULL,
PRIMARY KEY (`d_w_id`,`d_id`)
)
ENGINE = $storage_engine"
set sql(3) "CREATE TABLE `history` (
  `h_c_id` INT NULL,
  `h_c_d_id` INT NULL,
  `h_c_w_id` INT NULL,
  `h_d_id` INT NULL,
  `h_w_id` INT NULL,
  `h_date` DATETIME NULL,
  `h_amount` DECIMAL(6, 2) NULL,
  `h_data` VARCHAR(24) BINARY NULL
)
ENGINE = $storage_engine"
set sql(4) "CREATE TABLE `item` (
  `i_id` INT(6) NOT NULL,
  `i_im_id` INT NULL,
  `i_name` VARCHAR(24) BINARY NULL,
  `i_price` DECIMAL(5, 2) NULL,
  `i_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`i_id`)
)
ENGINE = $storage_engine"
set sql(5) "CREATE TABLE `new_order` (
  `no_w_id` INT NOT NULL,
  `no_d_id` INT NOT NULL,
  `no_o_id` INT NOT NULL,
PRIMARY KEY (`no_w_id`, `no_d_id`, `no_o_id`)
)
ENGINE = $storage_engine"
set sql(6) "CREATE TABLE `orders` (
  `o_id` INT NOT NULL,
  `o_w_id` INT NOT NULL,
  `o_d_id` INT NOT NULL,
  `o_c_id` INT NULL,
  `o_carrier_id` INT NULL,
  `o_ol_cnt` INT NULL,
  `o_all_local` INT NULL,
  `o_entry_d` DATETIME NULL,
PRIMARY KEY (`o_w_id`,`o_d_id`,`o_id`),
KEY o_w_id (`o_w_id`,`o_d_id`,`o_c_id`,`o_id`)
)
ENGINE = $storage_engine"
if {$num_part eq 0} {
set sql(7) "CREATE TABLE `order_line` (
  `ol_w_id` INT NOT NULL,
  `ol_d_id` INT NOT NULL,
  `ol_o_id` iNT NOT NULL,
  `ol_number` INT NOT NULL,
  `ol_i_id` INT NULL,
  `ol_delivery_d` DATETIME NULL,
  `ol_amount` INT NULL,
  `ol_supply_w_id` INT NULL,
  `ol_quantity` INT NULL,
  `ol_dist_info` CHAR(24) BINARY NULL,
PRIMARY KEY (`ol_w_id`,`ol_d_id`,`ol_o_id`,`ol_number`)
)
ENGINE = $storage_engine"
	} else {
set sql(7) "CREATE TABLE `order_line` (
  `ol_w_id` INT NOT NULL,
  `ol_d_id` INT NOT NULL,
  `ol_o_id` iNT NOT NULL,
  `ol_number` INT NOT NULL,
  `ol_i_id` INT NULL,
  `ol_delivery_d` DATETIME NULL,
  `ol_amount` INT NULL,
  `ol_supply_w_id` INT NULL,
  `ol_quantity` INT NULL,
  `ol_dist_info` CHAR(24) BINARY NULL,
PRIMARY KEY (`ol_w_id`,`ol_d_id`,`ol_o_id`,`ol_number`)
)
ENGINE = $storage_engine
PARTITION BY HASH (`ol_w_id`)
PARTITIONS $num_part"
	}
set sql(8) "CREATE TABLE `stock` (
  `s_i_id` INT(6) NOT NULL,
  `s_w_id` INT(4) NOT NULL,
  `s_quantity` INT(6) NULL,
  `s_dist_01` CHAR(24) BINARY NULL,
  `s_dist_02` CHAR(24) BINARY NULL,
  `s_dist_03` CHAR(24) BINARY NULL,
  `s_dist_04` CHAR(24) BINARY NULL,
  `s_dist_05` CHAR(24) BINARY NULL,
  `s_dist_06` CHAR(24) BINARY NULL,
  `s_dist_07` CHAR(24) BINARY NULL,
  `s_dist_08` CHAR(24) BINARY NULL,
  `s_dist_09` CHAR(24) BINARY NULL,
  `s_dist_10` CHAR(24) BINARY NULL,
  `s_ytd` BIGINT(10) NULL,
  `s_order_cnt` INT(6) NULL,
  `s_remote_cnt` INT(6) NULL,
  `s_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`s_w_id`,`s_i_id`)
)
ENGINE = $storage_engine"
set sql(9) "CREATE TABLE `warehouse` (
  `w_id` INT(4) NOT NULL,
  `w_ytd` DECIMAL(12, 2) NULL,
  `w_tax` DECIMAL(4, 4) NULL,
  `w_name` VARCHAR(10) BINARY NULL,
  `w_street_1` VARCHAR(20) BINARY NULL,
  `w_street_2` VARCHAR(20) BINARY NULL,
  `w_city` VARCHAR(20) BINARY NULL,
  `w_state` CHAR(2) BINARY NULL,
  `w_zip` CHAR(9) BINARY NULL,
PRIMARY KEY (`w_id`)
)
ENGINE = $storage_engine"
for { set i 1 } { $i <= 9 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { mysql_handler d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', str_to_date('[ gettimestamp ]','%Y%m%d%H%i%s'), '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), '$h_amount', '$h_data')
if { $bld_cnt<= 999 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 1000} ] } {
mysql::exec $mysql_handler "insert into customer (`c_id`, `c_d_id`, `c_w_id`, `c_first`, `c_middle`, `c_last`, `c_street_1`, `c_street_2`, `c_city`, `c_state`, `c_zip`, `c_phone`, `c_since`, `c_credit`, `c_credit_lim`, `c_discount`, `c_balance`, `c_data`, `c_ytd_payment`, `c_payment_cnt`, `c_delivery_cnt`) values $c_val_list"
mysql::exec $mysql_handler "insert into history (`h_c_id`, `h_c_d_id`, `h_c_w_id`, `h_w_id`, `h_d_id`, `h_date`, `h_amount`, `h_data`) values $h_val_list"
	mysql::commit $mysql_handler
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { mysql_handler d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'))
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 99 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
mysql::exec $mysql_handler "insert into orders (`o_id`, `o_c_id`, `o_d_id`, `o_w_id`, `o_entry_d`, `o_carrier_id`, `o_ol_cnt`, `o_all_local`) values $o_val_list"
if { $o_id > 2100 } {
mysql::exec $mysql_handler "insert into new_order (`no_o_id`, `no_d_id`, `no_w_id`) values $no_val_list"
	}
mysql::exec $mysql_handler "insert into order_line (`ol_o_id`, `ol_d_id`, `ol_w_id`, `ol_number`, `ol_i_id`, `ol_supply_w_id`, `ol_quantity`, `ol_amount`, `ol_dist_info`, `ol_delivery_d`) values $ol_val_list"
	mysql::commit $mysql_handler 
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	mysql::commit $mysql_handler 
	puts "Orders Done"
	return
}

proc LoadItems { mysql_handler MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
	mysql::exec $mysql_handler "insert into item (`i_id`, `i_im_id`, `i_name`, `i_price`, `i_data`) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	mysql::commit $mysql_handler 
	puts "Item done"
	return
	}

proc Stock { mysql_handler w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 999 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 1000} ] } {
mysql::exec $mysql_handler "insert into stock (`s_i_id`, `s_w_id`, `s_quantity`, `s_dist_01`, `s_dist_02`, `s_dist_03`, `s_dist_04`, `s_dist_05`, `s_dist_06`, `s_dist_07`, `s_dist_08`, `s_dist_09`, `s_dist_10`, `s_data`, `s_ytd`, `s_order_cnt`, `s_remote_cnt`) values $val_list"
	mysql::commit $mysql_handler
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	mysql::commit $mysql_handler
	puts "Stock done"
	return
}

proc District { mysql_handler w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
mysql::exec $mysql_handler "insert into district (`d_id`, `d_w_id`, `d_name`, `d_street_1`, `d_street_2`, `d_city`, `d_state`, `d_zip`, `d_tax`, `d_ytd`, `d_next_o_id`) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	mysql::commit $mysql_handler 
	puts "District done"
	return
}

proc LoadWare { mysql_handler ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
mysql::exec $mysql_handler "insert into warehouse (`w_id`, `w_name`, `w_street_1`, `w_street_2`, `w_city`, `w_state`, `w_zip`, `w_tax`, `w_ytd`) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock $mysql_handler $w_id $MAXITEMS
	District $mysql_handler $w_id $DIST_PER_WARE
	mysql::commit $mysql_handler 
	}
}

proc LoadCust { mysql_handler ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $mysql_handler $d_id $w_id $CUST_PER_DIST
		}
	}
	mysql::commit $mysql_handler 
	return
}

proc LoadOrd { mysql_handler ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $mysql_handler $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	mysql::commit $mysql_handler 
	return
}

proc do_tpcc { host port count_ware user password db storage_engine partition num_threads } {
global mysqlstatus
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts "the database connection to $host could not be established"
error $mysqlstatus(message)
 } else {
CreateDatabase $mysql_handler $db
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
if { $partition eq "true" } {
if {$count_ware < 200} {
set num_part 0
        } else {
set num_part [ expr round($count_ware/100) ]
        }
        } else {
set num_part 0
}
CreateTables $mysql_handler $storage_engine $num_part
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $mysql_handler $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems $mysql_handler $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts "the database connection to $host could not be established"
error $mysqlstatus(message)
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
} 
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $mysql_handler $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $mysql_handler $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd $mysql_handler $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
mysql::commit $mysql_handler 
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateStoredProcs $mysql_handler
GatherStatistics $mysql_handler
puts "[ string toupper $db ] SCHEMA COMPLETE"
mysqlclose $mysql_handler
return
		}
	}
}

set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1070.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $mysql_host $mysql_port $my_count_ware $mysql_user $mysql_pass $mysql_dbase $storage_engine $mysql_partition $mysql_num_threads"
	} else { return }
}

proc loadmytpcc { } {
global  mysql_host mysql_port mysql_user mysql_pass mysql_dbase my_total_iterations my_raiseerror my_keyandthink _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists my_total_iterations ] } { set my_total_iterations 1000 }
if {  ![ info exists my_raiseerror ] } { set my_raiseerror "false" }
if {  ![ info exists my_keyandthink ] } { set my_keyandthink "true" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require mysqltcl} \] { error \"Failed to load mysqltcl - MySQL Library Error\" }
global mysqlstatus
#EDITABLE OPTIONS##################################################
set total_iterations $my_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$my_raiseerror\" ;# Exit script on MySQL error (true or false)
set KEYANDTHINK \"$my_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$mysql_host\" ;# Address of the server hosting MySQL 
set port \"$mysql_port\" ;# Port of the MySQL Server, defaults to 3306
set user \"$mysql_user\" ;# MySQL user
set password \"$mysql_pass\" ;# Password for the MySQL user
set db \"$mysql_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { mysql_handler no_w_id w_id_input RAISEERROR } {
global mysqlstatus
#open new order cursor
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
mysqlexec $mysql_handler "set @next_o_id = 0"
catch { mysqlexec $mysql_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,$date)" }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "New Order : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
      } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @disc,@last,@credit,@dtax,@wtax,@next_o_id" -list ] ]
   }
}
#PAYMENT
proc payment { mysql_handler p_w_id w_id_input RAISEERROR } {
global mysqlstatus
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
mysqlexec $mysql_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
catch { mysqlexec $mysql_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,$h_date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Payment : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @p_c_id,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data" -list ] ]
    }
}
#ORDER_STATUS
proc ostat { mysql_handler w_id RAISEERROR } {
global mysqlstatus
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
mysqlexec $mysql_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
catch { mysqlexec $mysql_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Order Status : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @os_c_id,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id" -list ] ]
    }
}
#DELIVERY
proc delivery { mysql_handler w_id RAISEERROR } {
global mysqlstatus
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
catch { mysqlexec $mysql_handler "CALL DELIVERY($w_id,$carrier_id,$date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Delivery : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts "$w_id $carrier_id $date"
    }
}
#STOCK LEVEL
proc slev { mysql_handler w_id stock_level_d_id RAISEERROR } {
global mysqlstatus
set threshold [ RandomNumber 10 20 ]
mysqlexec $mysql_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold)"
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Stock Level : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts "$w_id $stock_level_d_id $threshold"
    }
}
#RUN TPC-C
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts "the database connection to $host could not be established"
error $mysqlstatus(message)
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
set w_id_input [ list [ mysql::sel $mysql_handler "select max(w_id) from warehouse" -list ] ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ list [ mysql::sel $mysql_handler "select max(d_id) from district" -list ] ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $mysql_handler $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
mysqlclose $mysql_handler
	}
}

proc loadtimedmytpcc { } {
global  mysql_host mysql_port mysql_user mysql_pass mysql_dbase my_total_iterations my_raiseerror my_keyandthink my_rampup my_duration opmode _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists my_total_iterations ] } { set my_total_iterations 1000 }
if {  ![ info exists my_raiseerror ] } { set my_raiseerror "false" }
if {  ![ info exists my_keyandthink ] } { set my_keyandthink "true" }
if {  ![ info exists my_rampup ] } { set my_rampup "2" }
if {  ![ info exists my_duration ] } { set my_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C Timed Test"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[ catch {package require mysqltcl} \] { error \"Failed to load mysqltcl - MySQL Library Error\" }
global mysqlstatus
#EDITABLE OPTIONS##################################################
set total_iterations $my_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$my_raiseerror\" ;# Exit script on MySQL error (true or false)
set KEYANDTHINK \"$my_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $my_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $my_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$mysql_host\" ;# Address of the server hosting MySQL 
set port \"$mysql_port\" ;# Port of the MySQL Server, defaults to 3306
set user \"$mysql_user\" ;# MySQL user
set password \"$mysql_pass\" ;# Password for the MySQL user
set db \"$mysql_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "MYSQL Timed Test Script must be run in Thread Enabled Interpreter"
}
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts "the database connection to $host could not be established"
error $mysqlstatus(message)
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 1
}
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler "show global status where Variable_name = 'Handler_commit' or Variable_name =  'Handler_rollback'" -list ] ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} else {
regexp {\{\{Handler_commit\ ([0-9]+)\}\ \{Handler_rollback\ ([0-9]+)\}\}} $handler_stat all handler_comm handler_roll
set start_trans [ expr $handler_comm + $handler_roll ]
	}
if {[catch {set start_nopm [ list [ mysql::sel $mysql_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
puts stderr {error, failed to query district table}
return
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler "show global status where Variable_name = 'Handler_commit' or Variable_name =  'Handler_rollback'" -list ] ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} else {
regexp {\{\{Handler_commit\ ([0-9]+)\}\ \{Handler_rollback\ ([0-9]+)\}\}} $handler_stat all handler_comm handler_roll
set end_trans [ expr $handler_comm + $handler_roll ]
	}
if {[catch {set end_nopm [ list [ mysql::sel $mysql_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
puts stderr {error, failed to query district table}
return
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm MySQL TPM at $nopm NOPM"
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
catch { mysqlclose $mysql_handler }
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { mysql_handler no_w_id w_id_input RAISEERROR } {
global mysqlstatus
#open new order cursor
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
mysqlexec $mysql_handler "set @next_o_id = 0"
catch { mysqlexec $mysql_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,$date)" }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "New Order : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
      } 
  } else {
;
   }
}
#PAYMENT
proc payment { mysql_handler p_w_id w_id_input RAISEERROR } {
global mysqlstatus
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
mysqlexec $mysql_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
catch { mysqlexec $mysql_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,$h_date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Payment : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#ORDER_STATUS
proc ostat { mysql_handler w_id RAISEERROR } {
global mysqlstatus
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
mysqlexec $mysql_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
catch { mysqlexec $mysql_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Order Status : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#DELIVERY
proc delivery { mysql_handler w_id RAISEERROR } {
global mysqlstatus
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
catch { mysqlexec $mysql_handler "CALL DELIVERY($w_id,$carrier_id,$date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Delivery : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#STOCK LEVEL
proc slev { mysql_handler w_id stock_level_d_id RAISEERROR } {
global mysqlstatus
set threshold [ RandomNumber 10 20 ]
mysqlexec $mysql_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold)"
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Stock Level : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#RUN TPC-C
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts "the database connection to $host could not be established"
error $mysqlstatus(message)
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
set w_id_input [ list [ mysql::sel $mysql_handler "select max(w_id) from warehouse" -list ] ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ list [ mysql::sel $mysql_handler "select max(d_id) from district" -list ] ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $mysql_handler $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
mysqlclose $mysql_handler
	}
   }}
}

proc check_pgtpcc {} {
global pg_host pg_port pg_count_ware pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_oracompat pg_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_count_ware ] } { set pg_count_ware "1" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_num_threads ] } { set pg_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $pg_count_ware Warehouse PostgreSQL TPC-C schema\nin host [string toupper $pg_host:$pg_port] under user [ string toupper $pg_user ] in database [ string toupper $pg_dbase ]?" -type yesno ] == yes} { 
if { $pg_num_threads eq 1 || $pg_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $pg_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require Pgtcl} ] { error "Failed to load Pgtcl - Postgres Library Error" }
proc CreateStoredProcs { lda ora_compatible } {
puts "CREATING TPCC STORED PROCEDURES"
if { $ora_compatible eq "true" } {
set sql(1) { CREATE OR REPLACE FUNCTION DBMS_RANDOM (INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
    start_int ALIAS FOR $1;
    end_int ALIAS FOR $2;
BEGIN
    RETURN trunc(random() * (end_int-start_int) + start_int);
END;
$$ LANGUAGE 'plpgsql' STRICT;
}
set sql(2) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
tstamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, tstamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM(1,100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM(1,100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM(1,100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM(1,no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM(1,10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;

COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(3) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
tstamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
loop_counter            INTEGER;
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = tstamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || tstamp);
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(4) { CREATE OR REPLACE PROCEDURE PAYMENT (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
p_c_id			IN OUT NUMBER(5,0),
byname			INTEGER,
p_h_amount		NUMBER,
p_c_last		IN OUT VARCHAR2(16),
p_w_street_1		OUT VARCHAR2(20),
p_w_street_2		OUT VARCHAR2(20),
p_w_city		OUT VARCHAR2(20),
p_w_state		OUT CHAR(2),
p_w_zip			OUT CHAR(9),
p_d_street_1		OUT VARCHAR2(20),
p_d_street_2		OUT VARCHAR2(20),
p_d_city		OUT VARCHAR2(20),
p_d_state		OUT CHAR(2),
p_d_zip			OUT CHAR(9),
p_c_first		OUT VARCHAR2(16),
p_c_middle		OUT CHAR(2),
p_c_street_1		OUT VARCHAR2(20),
p_c_street_2		OUT VARCHAR2(20),
p_c_city		OUT VARCHAR2(20),
p_c_state		OUT CHAR(2),
p_c_zip			OUT CHAR(9),
p_c_phone		OUT CHAR(16),
p_c_since		OUT DATE,
p_c_credit		IN OUT CHAR(2),
p_c_credit_lim		OUT NUMBER(12, 2),
p_c_discount		OUT NUMBER(4, 4),
p_c_balance		IN OUT NUMBER(12, 2),
p_c_data		OUT VARCHAR2(500),
tstamp		IN DATE )
IS
namecnt			INTEGER;
p_d_name		VARCHAR2(11);
p_w_name		VARCHAR2(11);
p_c_new_data		VARCHAR2(500);
h_data			VARCHAR2(30);
CURSOR c_byname IS
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
BEGIN
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
-- The following statement in the TPC-C specification appendix is incorrect
-- copied setting of h_data from later on in the procedure to here as well
h_data := ( p_w_name || ' ' || p_d_name );
p_c_new_data := (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' ||
TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || TO_CHAR(p_h_amount,'9999.99') || TO_CHAR(tstamp) || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
--setting of h_data is here in the TPC-C appendix
h_data := ( p_w_name|| ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, tstamp, p_h_amount, h_data);
COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(5) { CREATE OR REPLACE PROCEDURE OSTAT (
os_w_id			INTEGER,
os_d_id			INTEGER,
os_c_id			IN OUT INTEGER,
byname			INTEGER,
os_c_last		IN OUT VARCHAR2,
os_c_first		OUT VARCHAR2,
os_c_middle		OUT VARCHAR2,
os_c_balance		OUT NUMBER,
os_o_id			OUT INTEGER,
os_entdate		OUT DATE,
os_o_carrier_id		OUT INTEGER )
IS
TYPE numbertable IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
os_ol_i_id numbertable;	
os_ol_supply_w_id numbertable;	
os_ol_quantity numbertable;	
TYPE amounttable IS TABLE OF NUMBER(6,2) INDEX BY BINARY_INTEGER;
os_ol_amount amounttable;
TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
os_ol_delivery_d datetable;
namecnt			INTEGER;
i			BINARY_INTEGER;
CURSOR c_name IS
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
CURSOR c_line IS
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
os_c_line c_line%ROWTYPE;
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
BEGIN
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC)
WHERE ROWNUM = 1;
EXCEPTION
WHEN NO_DATA_FOUND THEN
dbms_output.put_line('No orders for customer');
END;
i := 0;
FOR os_c_line IN c_line
LOOP
os_ol_i_id(i) := os_c_line.ol_i_id;
os_ol_supply_w_id(i) := os_c_line.ol_supply_w_id;
os_ol_quantity(i) := os_c_line.ol_quantity;
os_ol_amount(i) := os_c_line.ol_amount;
os_ol_delivery_d(i) := os_c_line.ol_delivery_d;
i := i+1;
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(6) { CREATE OR REPLACE PROCEDURE SLEV (
st_w_id			INTEGER,
st_d_id			INTEGER,
threshold		INTEGER )
IS 
st_o_id			NUMBER;	
stock_count		INTEGER;
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
for { set i 1 } { $i <= 6 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
} else {
set sql(1) { CREATE OR REPLACE FUNCTION DBMS_RANDOM (INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
    start_int ALIAS FOR $1;
    end_int ALIAS FOR $2;
BEGIN
    RETURN trunc(random() * (end_int-start_int) + start_int);
END;
$$ LANGUAGE 'plpgsql' STRICT;
}
set sql(2) { CREATE OR REPLACE FUNCTION NEWORD (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) RETURNS NUMERIC AS '
DECLARE
no_w_id		ALIAS FOR $1;	
no_max_w_id	ALIAS FOR $2;
no_d_id		ALIAS FOR $3;
no_c_id		ALIAS FOR $4;
no_o_ol_cnt	ALIAS FOR $5;
no_d_next_o_id	ALIAS FOR $6;
no_c_discount	NUMERIC;
no_c_last	VARCHAR;
no_c_credit	VARCHAR;
no_d_tax	NUMERIC;
no_w_tax	NUMERIC;
tstamp		TIMESTAMP;
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMERIC;
no_ol_quantity		NUMERIC;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR(24);
no_i_price		NUMERIC(5,2);
no_i_data		VARCHAR(50);
no_s_quantity		NUMERIC(6);
no_ol_amount		NUMERIC(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR(50);
x			NUMERIC;
rbk			NUMERIC;
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, current_timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM(1,100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM(1,100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM(1,100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM(1,no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM(1,10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;
RETURN no_s_quantity;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
set sql(3) { CREATE OR REPLACE FUNCTION DELIVERY (INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
d_w_id		ALIAS FOR $1;	
d_o_carrier_id  ALIAS FOR $2;	
d_d_id	       	INTEGER;
d_c_id	       	NUMERIC;
d_no_o_id		INTEGER;
d_ol_total		NUMERIC;
loop_counter		INTEGER;
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = current_timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
END LOOP;
RETURN 1;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
}
set sql(4) { CREATE OR REPLACE FUNCTION PAYMENT (INTEGER, INTEGER, INTEGER, INTEGER, NUMERIC, INTEGER, NUMERIC, VARCHAR, VARCHAR, NUMERIC ) RETURNS INTEGER AS '
DECLARE
p_w_id			ALIAS FOR $1;
p_d_id			ALIAS FOR $2;
p_c_w_id		ALIAS FOR $3;
p_c_d_id		ALIAS FOR $4;
p_c_id_in		ALIAS FOR $5;
byname			ALIAS FOR $6;
p_h_amount		ALIAS FOR $7;
p_c_last_in		ALIAS FOR $8;
p_c_credit_in		ALIAS FOR $9;
p_c_balance_in		ALIAS FOR $10;
p_c_balance             NUMERIC(12, 2);
p_c_credit              CHAR(2);
p_c_last		VARCHAR(16);
p_c_id			NUMERIC(5,0);
p_w_street_1            VARCHAR(20);
p_w_street_2            VARCHAR(20);
p_w_city                VARCHAR(20);
p_w_state               CHAR(2);
p_w_zip                 CHAR(9);
p_d_street_1            VARCHAR(20);
p_d_street_2            VARCHAR(20);
p_d_city                VARCHAR(20);
p_d_state               CHAR(2);
p_d_zip                 CHAR(9);
p_c_first               VARCHAR(16);
p_c_middle              CHAR(2);
p_c_street_1            VARCHAR(20);
p_c_street_2            VARCHAR(20);
p_c_city                VARCHAR(20);
p_c_state               CHAR(2);
p_c_zip                 CHAR(9);
p_c_phone               CHAR(16);
p_c_since		TIMESTAMP;
p_c_credit_lim          NUMERIC(12, 2);
p_c_discount            NUMERIC(4, 4);
p_c_data                VARCHAR(500);
tstamp			TIMESTAMP;
namecnt			INTEGER;
p_d_name		VARCHAR(11);
p_w_name		VARCHAR(11);
p_c_new_data		VARCHAR(500);
h_data			VARCHAR(30);
c_byname CURSOR FOR
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
BEGIN
p_c_balance := p_c_balance_in;
p_c_id := p_c_id_in;
p_c_last := p_c_last_in;
p_c_credit := p_c_credit_in;
tstamp := current_timestamp;
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = ''BC'' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
h_data := p_w_name || '' '' || p_d_name;
p_c_new_data := (p_c_id || '' '' || p_c_d_id || '' '' || p_c_w_id || '' '' || p_d_id || '' '' || p_w_id || '' '' || TO_CHAR(p_h_amount,''9999.99'') || TO_CHAR(tstamp,''YYYYMMDDHH24MISS'') || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
h_data := p_w_name || '' '' || p_d_name;
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, tstamp, p_h_amount, h_data);
RETURN p_c_id;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
set sql(5) { CREATE OR REPLACE FUNCTION OSTAT (INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR) RETURNS SETOF record AS '
DECLARE
os_w_id		ALIAS FOR $1;
os_d_id		ALIAS FOR $2;		
os_c_id	 	ALIAS FOR $3;
byname		ALIAS FOR $4;	
os_c_last	ALIAS FOR $5;
out_os_c_id	INTEGER;
out_os_c_last	VARCHAR;
os_c_first	VARCHAR;
os_c_middle	VARCHAR;
os_c_balance	NUMERIC;
os_o_id		INTEGER;
os_entdate	TIMESTAMP;
os_o_carrier_id	INTEGER;
os_ol 		RECORD;
namecnt		INTEGER;
c_name CURSOR FOR
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC) AS SUBQUERY
LIMIT 1;
FOR os_ol IN
SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d, out_os_c_id, out_os_c_last, os_c_first, os_c_middle, os_c_balance, os_o_id, os_entdate, os_o_carrier_id	
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id
LOOP
RETURN NEXT os_ol;
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
}
set sql(6) { CREATE OR REPLACE FUNCTION SLEV (INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
st_w_id			ALIAS FOR $1;
st_d_id			ALIAS FOR $2;
threshold		ALIAS FOR $3; 

st_o_id			NUMERIC;	
stock_count		INTEGER;
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;

SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
RETURN stock_count;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
for { set i 1 } { $i <= 6 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}
return
}

proc GatherStatistics { lda } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "ANALYZE"
for { set i 1 } { $i <= 1 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
set lda "Failed" ; puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

proc CreateUserDatabase { lda db superuser user password } {
puts "CREATING DATABASE $db under OWNER $user"  
set sql(1) "CREATE USER $user PASSWORD '$password'"
set sql(2) "GRANT $user to $superuser"
set sql(3) "CREATE DATABASE $db OWNER $user"
for { set i 1 } { $i <= 3 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc CreateTables { lda ora_compatible } {
puts "CREATING TPCC TABLES"
if { $ora_compatible eq "true" } {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500))"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(4, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9))"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24))"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50))"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(4, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9))"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50))"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER)"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE)"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24))"
	} else {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMERIC(5,0), C_D_ID NUMERIC(2,0), C_W_ID NUMERIC(4,0), C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM NUMERIC(12, 2), C_DISCOUNT NUMERIC(4,4), C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT NUMERIC(8,0), C_DATA VARCHAR(500)) WITH (FILLFACTOR=50)"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMERIC(2,0), D_W_ID NUMERIC(4,0), D_YTD NUMERIC(12, 2), D_TAX NUMERIC(4,4), D_NEXT_O_ID NUMERIC, D_NAME VARCHAR(10), D_STREET_1 VARCHAR(20), D_STREET_2 VARCHAR(20), D_CITY VARCHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9)) WITH (FILLFACTOR=10)"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMERIC, H_C_D_ID NUMERIC, H_C_W_ID NUMERIC, H_D_ID NUMERIC, H_W_ID NUMERIC, H_DATE TIMESTAMP, H_AMOUNT NUMERIC(6,2), H_DATA VARCHAR(24)) WITH (FILLFACTOR=50)"
set sql(4) "CREATE TABLE ITEM (I_ID NUMERIC(6,0), I_IM_ID NUMERIC, I_NAME VARCHAR(24), I_PRICE NUMERIC(5,2), I_DATA VARCHAR(50)) WITH (FILLFACTOR=50)"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMERIC(4,0), W_YTD NUMERIC(12, 2), W_TAX NUMERIC(4,4), W_NAME VARCHAR(10), W_STREET_1 VARCHAR(20), W_STREET_2 VARCHAR(20), W_CITY VARCHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9)) WITH (FILLFACTOR=10)"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMERIC(6,0), S_W_ID NUMERIC(4,0), S_QUANTITY NUMERIC(6,0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMERIC(10, 0), S_ORDER_CNT NUMERIC(6,0), S_REMOTE_CNT NUMERIC(6,0), S_DATA VARCHAR(50)) WITH (FILLFACTOR=50)"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMERIC, NO_D_ID NUMERIC, NO_O_ID NUMERIC) WITH (FILLFACTOR=50)"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMERIC, O_W_ID NUMERIC, O_D_ID NUMERIC, O_C_ID NUMERIC, O_CARRIER_ID NUMERIC, O_OL_CNT NUMERIC, O_ALL_LOCAL NUMERIC, O_ENTRY_D TIMESTAMP) WITH (FILLFACTOR=50)"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMERIC, OL_D_ID NUMERIC, OL_O_ID NUMERIC, OL_NUMBER NUMERIC, OL_I_ID NUMERIC, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT NUMERIC, OL_SUPPLY_W_ID NUMERIC, OL_QUANTITY NUMERIC, OL_DIST_INFO CHAR(24)) WITH (FILLFACTOR=50)"
	}
for { set i 1 } { $i <= 9 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}

proc CreateIndexes { lda } {
puts "CREATING TPCC INDEXES"
set sql(1) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_I1 PRIMARY KEY (C_W_ID, C_D_ID, C_ID)"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_W_ID, C_D_ID, C_LAST, C_FIRST, C_ID)"
set sql(3) "ALTER TABLE DISTRICT ADD CONSTRAINT DISTRICT_I1 PRIMARY KEY (D_W_ID, D_ID) WITH (FILLFACTOR = 100)"
set sql(4) "ALTER TABLE NEW_ORDER ADD CONSTRAINT NEW_ORDER_I1 PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(5) "ALTER TABLE ITEM ADD CONSTRAINT ITEM_I1 PRIMARY KEY (I_ID)"
set sql(6) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_I1 PRIMARY KEY (O_W_ID, O_D_ID, O_ID)"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(8) "ALTER TABLE ORDER_LINE ADD CONSTRAINT ORDER_LINE_I1 PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(9) "ALTER TABLE STOCK ADD CONSTRAINT STOCK_I1 PRIMARY KEY (S_W_ID, S_I_ID)"
set sql(10) "ALTER TABLE WAREHOUSE ADD CONSTRAINT WAREHOUSE_I1 PRIMARY KEY (W_ID) WITH (FILLFACTOR = 100)"
for { set i 1 } { $i <= 10 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	}  else {
	pg_result $result -clear
	}
    }
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { lda d_id w_id CUST_PER_DIST ora_compatible } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
if { $ora_compatible eq "true" } {
proc date_function {} {
set df "to_date('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	} else {
proc date_function {} {
set df "to_timestamp('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	}
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', [ date_function ], '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', [ date_function ], '$h_amount', '$h_data')
if { $bld_cnt<= 999 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 1000} ] } {
set result [ pg_exec $lda "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
set result [ pg_exec $lda "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { lda d_id w_id MAXITEMS ORD_PER_DIST ora_compatible } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
if { $ora_compatible eq "true" } {
proc date_function {} {
set df "to_date('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	} else {
proc date_function {} {
set df "to_timestamp('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	}
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', [ date_function ])
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 99 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
set result [ pg_exec $lda  "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if { $o_id > 2100 } {
set result [ pg_exec $lda "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	}
set result [ pg_exec $lda "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Orders Done"
	return
}

proc LoadItems { lda MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
set result [ pg_exec $lda "begin" ]
pg_result $result -clear
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
set result [ pg_exec $lda "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')" ]
 if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
      if { ![ expr {$i_id % 10000} ] } {
	puts "Loading Items - $i_id"
			}
		}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
puts "Item done"
return
	}

proc Stock { lda w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 999 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 1000} ] } {
set result [ pg_exec $lda "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Stock done"
	return
}

proc District { lda w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
set result [ pg_exec $lda "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "District done"
	return
}

proc LoadWare { lda ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
set result [ pg_exec $lda "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')" ]
 if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	Stock $lda $w_id $MAXITEMS
	District $lda $w_id $DIST_PER_WARE
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
}

proc LoadCust { lda ware_start count_ware CUST_PER_DIST DIST_PER_WARE ora_compatible } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $lda $d_id $w_id $CUST_PER_DIST $ora_compatible
		}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	return
}

proc LoadOrd { lda ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE ora_compatible } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST $ora_compatible
		}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	return
}
proc do_tpcc { host port count_ware superuser superuser_password defaultdb db user password ora_compatible num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $user ] SCHEMA"
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $defaultdb ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateUserDatabase $lda $db $superuser $user $password
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
pg_disconnect $lda
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateTables $lda $ora_compatible
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
        }
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $lda $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {  
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
	}
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
	}
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000 
}} else {
LoadItems $lda $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {  
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } { 
puts "Monitor failed to notify ready state" 
return
	}
after 5000 
}
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 }
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $lda $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $lda $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $ora_compatible
LoadOrd $lda $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $ora_compatible
puts "End:[ clock format [ clock seconds ] ]"
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda
CreateStoredProcs $lda $ora_compatible
GatherStatistics $lda 
puts "[ string toupper $user ] SCHEMA COMPLETE"
pg_disconnect $lda
return
	}
    }
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1511.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $pg_host $pg_port $pg_count_ware $pg_superuser $pg_superuserpass $pg_defaultdbase $pg_user $pg_pass $pg_dbase $pg_oracompat $pg_num_threads"
	} else { return }
}

proc loadpgtpcc { } {
global pg_host pg_port pg_user pg_pass pg_dbase pg_oracompat pg_total_iterations pg_raiseerror pg_keyandthink _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_total_iterations ] } { set pg_total_iterations 1000000 }
if {  ![ info exists pg_raiseerror ] } { set pg_raiseerror "false" }
if {  ![ info exists pg_keyandthink ] } { set pg_keyandthink "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Pgtcl} \] { error \"Failed to load Pgtcl - Postgres Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $pg_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$pg_raiseerror\" ;# Exit script on PostgreSQL (true or false)
set KEYANDTHINK \"$pg_keyandthink\" ;# Time for user thinking and keying (true or false)
set ora_compatible \"$pg_oracompat\" ;#Postgres Plus Oracle Compatible Schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL Server
set user \"$pg_user\" ;# PostgreSQL user
set password \"$pg_pass\" ;# Password for the PostgreSQL user
set db \"$pg_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#POSTGRES CONNECTION
proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
set lda "Failed" ; puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}
#NEW ORDER
proc neword { lda no_w_id w_id_input RAISEERROR ora_compatible } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "New Order Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "New Order: $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt 0 [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#PAYMENT
proc payment { lda p_w_id w_id_input RAISEERROR ora_compatible } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0,TO_TIMESTAMP($h_date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Payment Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Payment: $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name 0 0 [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#ORDER_STATUS
proc ostat { lda w_id RAISEERROR ora_compatible } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec ostat($w_id,$d_id,$c_id,$byname,'$name')" ]
} else {
set result [pg_exec $lda "select * from ostat($w_id,$d_id,$c_id,$byname,'$name') as (ol_i_id NUMERIC,  ol_supply_w_id NUMERIC, ol_quantity NUMERIC, ol_amount NUMERIC, ol_delivery_d TIMESTAMP,  out_os_c_id INTEGER, out_os_c_last VARCHAR, os_c_first VARCHAR, os_c_middle VARCHAR, os_c_balance NUMERIC, os_o_id INTEGER, os_entdate TIMESTAMP, os_o_carrier_id INTEGER)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Order Status Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Order Status: $w_id $d_id $c_id $byname $name [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#DELIVERY
proc delivery { lda w_id RAISEERROR ora_compatible } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec delivery($w_id,$carrier_id,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select delivery($w_id,$carrier_id)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Delivery Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Delivery: $w_id $carrier_id [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#STOCK LEVEL
proc slev { lda w_id stock_level_d_id RAISEERROR ora_compatible } {
set threshold [ RandomNumber 10 20 ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec slev($w_id,$stock_level_d_id,$threshold)" ]
} else {
set result [pg_exec $lda "select slev($w_id,$stock_level_d_id,$threshold)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Stock Level Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Stock Level: $w_id $stock_level_d_id $threshold [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#RUN TPC-C
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
if { $ora_compatible eq "true" } {
set result [ pg_exec $lda "exec dbms_output.disable" ]
pg_result $result -clear
	}
 }
pg_select $lda "select max(w_id) from warehouse" w_id_input_arr {
set w_id_input $w_id_input_arr(max)
	}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
pg_select $lda "select max(d_id) from district" d_id_input_arr {
set d_id_input $d_id_input_arr(max)
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $lda $w_id $stock_level_d_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
	}
}
pg_disconnect $lda
	}
}

proc loadtimedpgtpcc { } {
global pg_host pg_port pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_vacuum pg_dritasnap pg_oracompat pg_total_iterations pg_raiseerror pg_keyandthink pg_rampup pg_duration opmode _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_vacuum ] } { set pg_vacuum "false" }
if {  ![ info exists pg_dritasnap ] } { set pg_dritasnap "false" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_total_iterations ] } { set pg_total_iterations 1000000 }
if {  ![ info exists pg_raiseerror ] } { set pg_raiseerror "false" }
if {  ![ info exists pg_keyandthink ] } { set pg_keyandthink "false" }
if {  ![ info exists pg_rampup ] } { set pg_rampup "2" }
if {  ![ info exists pg_duration ] } { set pg_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Pgtcl} \] { error \"Failed to load Pgtcl - Postgres Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $pg_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$pg_raiseerror\" ;# Exit script on PostgreSQL (true or false)
set KEYANDTHINK \"$pg_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $pg_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $pg_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set VACUUM \"$pg_vacuum\" ;# Perform checkpoint and vacuuum when complete (true or false)
set DRITA_SNAPSHOTS \"$pg_dritasnap\";#Take DRITA Snapshots
set ora_compatible \"$pg_oracompat\" ;#Postgres Plus Oracle Compatible Schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL server
set superuser \"$pg_superuser\" ;# Superuser privilege user
set superuser_password \"$pg_superuserpass\" ;# Password for Superuser
set default_database \"$pg_defaultdbase\" ;# Default Database for Superuser
set user \"$pg_user\" ;# PostgreSQL user
set password \"$pg_pass\" ;# Password for the PostgreSQL user
set db \"$pg_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 22.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "PostgreSQL Timed Test Script must be run in Thread Enabled Interpreter"
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
set lda "Failed" ; puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $default_database ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	} 
}
set lda1 [ ConnectToPostgres $host $port $user $password $db ]
if { $lda1 eq "Failed" } {
error "error, the database connection to $host could not be established"
 	} 
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
if { $DRITA_SNAPSHOTS eq "true" } {
puts "Rampup complete, Taking start DRITA snapshot."
set result [pg_exec $lda "select * from edbsnap()" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "DRITA Snapshot Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr {
set firstsnap $snap_arr(edb_id)
set first_snaptime $snap_arr(snap_tm)
	}
puts "Start Snapshot $firstsnap taken at $first_snaptime"
	}
   } else {
puts "Rampup complete, Taking start Transaction Count."
	}
pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
set start_trans $tx_arr(sum)
	}
pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
set start_nopm $o_id_arr(sum)
	}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
if { $DRITA_SNAPSHOTS eq "true" } {
puts "Test complete, Taking end DRITA snapshot."
set result [pg_exec $lda "select * from edbsnap()" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Snapshot Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr  {
set endsnap $snap_arr(edb_id)
set end_snaptime $snap_arr(snap_tm)
	}
puts "End Snapshot $endsnap taken at $end_snaptime"
puts "Test complete: view DRITA report from SNAPID $firstsnap to $endsnap"
	}
   } else {
puts "Test complete, Taking end Transaction Count."
	}
pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
set end_trans $tx_arr(sum)
	}
pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
set end_nopm $o_id_arr(sum)
	}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm PostgreSQL TPM at $nopm NOPM"
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
if { $VACUUM } {
	set RAISEERROR "true"
puts "Checkpoint and Vacuum"
set result [pg_exec $lda "checkpoint" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Checkpoint Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
set result [pg_exec $lda "vacuum" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Vacuum Error set RAISEERROR for Details"
		}
	} else {
puts "Checkpoint and Vacuum Complete"
pg_result $result -clear
	}
}
if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
pg_disconnect $lda
	}
pg_disconnect $lda1
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { lda no_w_id w_id_input RAISEERROR ora_compatible } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "New Order Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#PAYMENT
proc payment { lda p_w_id w_id_input RAISEERROR ora_compatible } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0,TO_TIMESTAMP($h_date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Payment Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#ORDER_STATUS
proc ostat { lda w_id RAISEERROR ora_compatible } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec ostat($w_id,$d_id,$c_id,$byname,'$name')" ]
} else {
set result [pg_exec $lda "select * from ostat($w_id,$d_id,$c_id,$byname,'$name') as (ol_i_id NUMERIC,  ol_supply_w_id NUMERIC, ol_quantity NUMERIC, ol_amount NUMERIC, ol_delivery_d TIMESTAMP,  out_os_c_id INTEGER, out_os_c_last VARCHAR, os_c_first VARCHAR, os_c_middle VARCHAR, os_c_balance NUMERIC, os_o_id INTEGER, os_entdate TIMESTAMP, os_o_carrier_id INTEGER)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Order Status Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#DELIVERY
proc delivery { lda w_id RAISEERROR ora_compatible } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec delivery($w_id,$carrier_id,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select delivery($w_id,$carrier_id)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Delivery Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#STOCK LEVEL
proc slev { lda w_id stock_level_d_id RAISEERROR ora_compatible } {
set threshold [ RandomNumber 10 20 ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec slev($w_id,$stock_level_d_id,$threshold)" ]
} else {
set result [pg_exec $lda "select slev($w_id,$stock_level_d_id,$threshold)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Stock Level Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#RUN TPC-C
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
if { $ora_compatible eq "true" } {
set result [ pg_exec $lda "exec dbms_output.disable" ]
pg_result $result -clear
	}
 }
pg_select $lda "select max(w_id) from warehouse" w_id_input_arr {
set w_id_input $w_id_input_arr(max)
	}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
pg_select $lda "select max(d_id) from district" d_id_input_arr {
set d_id_input $d_id_input_arr(max)
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $lda $w_id $stock_level_d_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
	}
}
pg_disconnect $lda
		}
      }}
}

proc check_redistpcc { } {
global redis_host redis_port redis_namespace redis_count_ware redis_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_count_ware ] } { set redis_count_ware "1" }
if {  ![ info exists redis_num_threads ] } { set redis_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $redis_count_ware Warehouse Redis TPC-C schema\nin host [string toupper $redis_host:$redis_port] in namespace $redis_namespace?" -type yesno ] == yes} { 
if { $redis_num_threads eq 1 || $redis_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $redis_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require redis} ] { error "Failed to load Redis - Redis Package Error" }
proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc Customer { redis d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
$redis HMSET CUSTOMER:$c_w_id:$c_d_id:$c_id C_ID $c_id C_D_ID $c_d_id C_W_ID $c_w_id C_FIRST $c_first C_MIDDLE $c_middle C_LAST $c_last C_STREET_1 [ lindex $c_add 0 ] C_STREET_2 [ lindex $c_add 1 ] C_CITY [ lindex $c_add 2 ] C_STATE [ lindex $c_add 3 ] C_ZIP [ lindex $c_add 4 ] C_PHONE $c_phone C_SINCE [ gettimestamp ] C_CREDIT $c_credit C_CREDIT_LIM $c_credit_lim C_DISCOUNT $c_discount C_BALANCE $c_balance C_DATA $c_data C_YTD_PAYMENT 10.0 C_PAYMENT_CNT 1 C_DELIVERY_CNT 0
$redis LPUSH CUSTOMER_OSTAT_PMT_QUERY:$c_w_id:$c_d_id:$c_last $c_id
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
set tstamp [ gettimestamp ]
$redis HMSET HISTORY:$c_w_id:$c_d_id:$c_id:$tstamp H_C_ID $c_id H_C_D_ID $c_d_id H_C_W_ID $c_w_id H_W_ID $c_w_id H_D_ID $c_d_id H_DATE $tstamp H_AMOUNT $h_amount H_DATA $h_data
	}
puts "Customer Done"
return
}

proc Orders { redis d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
$redis HMSET ORDERS:$o_w_id:$o_d_id:$o_id O_ID $o_id O_C_ID $o_c_id O_D_ID $o_d_id O_W_ID $o_w_id O_ENTRY_D [ gettimestamp ] O_CARRIER_ID "" O_OL_CNT $o_ol_cnt O_ALL_LOCAL 1
#Maintain list of orders per customer for Order Status
$redis LPUSH ORDERS_OSTAT_QUERY:$o_w_id:$o_d_id:$o_c_id $o_id
set e "no1"
$redis HMSET NEW_ORDER:$o_w_id:$o_d_id:$o_id NO_O_ID $o_id NO_D_ID $o_d_id NO_W_ID $o_w_id 
$redis LPUSH NEW_ORDER_IDS:$o_w_id:$o_d_id $o_id
  } else {
  set e "o3"
$redis HMSET ORDERS:$o_w_id:$o_d_id:$o_id O_ID $o_id O_C_ID $o_c_id O_D_ID $o_d_id O_W_ID $o_w_id O_ENTRY_D [ gettimestamp ] O_CARRIER_ID $o_carrier_id O_OL_CNT $o_ol_cnt O_ALL_LOCAL 1
#Maintain list of orders per customer for Order Status
$redis LPUSH ORDERS_OSTAT_QUERY:$o_w_id:$o_d_id:$o_c_id $o_id
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
$redis HMSET ORDER_LINE:$o_w_id:$o_d_id:$o_id:$ol OL_O_ID $o_id OL_D_ID $o_d_id OL_W_ID $o_w_id OL_NUMBER $ol OL_I_ID $ol_i_id OL_SUPPLY_W_ID $ol_supply_w_id OL_QUANTITY $ol_quantity OL_AMOUNT $ol_amount OL_DIST_INFO $ol_dist_info OL_DELIVERY_D ""
#Maintain a list of order line numbers for delivery procedure to update
$redis LPUSH ORDER_LINE_NUMBERS:$o_w_id:$o_d_id:$o_id $ol 
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
$redis HMSET ORDER_LINE:$o_w_id:$o_d_id:$o_id:$ol OL_O_ID $o_id OL_D_ID $o_d_id OL_W_ID $o_w_id OL_NUMBER $ol OL_I_ID $ol_i_id OL_SUPPLY_W_ID $ol_supply_w_id OL_QUANTITY $ol_quantity OL_AMOUNT $ol_amount OL_DIST_INFO $ol_dist_info OL_DELIVERY_D [ gettimestamp ]
	}
#maintain a sorted set of order lines with order id as score and item id as element so slev procedure can get item_ids from 20 most recent orders 
$redis ZADD ORDER_LINE_SLEV_QUERY:$o_w_id:$o_d_id $o_id $ol_i_id
}
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { redis MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
$redis HMSET ITEM:$i_id I_ID $i_id I_IM_ID $i_im_id I_NAME $i_name I_PRICE $i_price I_DATA $i_data
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	puts "Item done"
	return
	}

proc Stock { redis w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
$redis HMSET STOCK:$s_w_id:$s_i_id S_I_ID $s_i_id S_W_ID $s_w_id S_QUANTITY $s_quantity S_DIST_01 $s_dist_01 S_DIST_02 $s_dist_02 S_DIST_03 $s_dist_03 S_DIST_04 $s_dist_04 S_DIST_05 $s_dist_05 S_DIST_06 $s_dist_06 S_DIST_07 $s_dist_07 S_DIST_08 $s_dist_08 S_DIST_09 $s_dist_09 S_DIST_10 $s_dist_10 S_DATA $s_data S_YTD 0 S_ORDER_CNT 0 S_REMOTE_CNT 0
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	puts "Stock done"
	return
}

proc District { redis w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
$redis HMSET DISTRICT:$d_w_id:$d_id D_ID $d_id D_W_ID $d_w_id D_NAME $d_name D_STREET_1 [ lindex $d_add 0 ] D_STREET_2 [ lindex $d_add 1 ] D_CITY [ lindex $d_add 2 ] D_STATE [ lindex $d_add 3 ] D_ZIP [ lindex $d_add 4 ] D_TAX $d_tax D_YTD $d_ytd D_NEXT_O_ID $d_next_o_id
	}
	puts "District done"
	return
}

proc LoadWare { redis ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
$redis HMSET WAREHOUSE:$w_id W_ID $w_id W_NAME $w_name W_STREET_1 [ lindex $add 0 ] W_STREET_2 [ lindex $add 1 ] W_CITY [ lindex $add 2 ] W_STATE [ lindex $add 3 ] W_ZIP [ lindex $add 4 ] W_TAX $w_tax W_YTD $w_ytd
	Stock $redis $w_id $MAXITEMS
	District $redis $w_id $DIST_PER_WARE
	}
}

proc LoadCust { redis ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $redis $d_id $w_id $CUST_PER_DIST
		}
	}
	return
}

proc LoadOrd { redis ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $redis $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	return
}

proc do_tpcc { host port namespace count_ware num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING REDIS SCHEMA IN NAMESPACE $namespace"
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
$redis SET COUNT_WARE $count_ware
$redis SET DIST_PER_WARE $DIST_PER_WARE
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $redis $MAXITEMS
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems $redis $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $redis $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $redis $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd $redis $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "REDIS SCHEMA COMPLETE"
$redis QUIT
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 429.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $redis_host $redis_port $redis_namespace $redis_count_ware $redis_num_threads"
	} else { return }
}

proc loadredistpcc {} {
global redis_host redis_port redis_namespace redis_total_iterations redis_raiseerror redis_keyandthink redis_driver _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_total_iterations ] } { set redis_total_iterations 1000000 }
if {  ![ info exists redis_raiseerror ] } { set redis_raiseerror "false" }
if {  ![ info exists redis_keyandthink ] } { set redis_keyandthink "false" }
if {  ![ info exists redis_driver ] } { set redis_driver "standard" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require redis} \] { error \"Failed to load Redis - Redis Package Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 11.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { redis no_w_id w_id_input RAISEERROR } {
set no_d_id [ RandomNumber 1 10 ]
set no_c_id [ RandomNumber 1 3000 ]
set ol_cnt [ RandomNumber 5 15 ]
set date [ gettimestamp ]
set no_o_all_local 0
foreach { no_c_discount no_c_last no_c_credit } [ $redis HMGET CUSTOMER:$no_w_id:$no_d_id:$no_c_id C_DISCOUNT C_LAST C_CREDIT ] {}
set no_w_tax [ $redis HMGET WAREHOUSE:$no_w_id W_TAX ]
set no_d_tax [ $redis HMGET DISTRICT:$no_w_id:$no_d_id D_TAX ]
set d_next_o_id [ $redis HINCRBY DISTRICT:$no_w_id:$no_d_id D_NEXT_O_ID 1 ]
set o_id $d_next_o_id
$redis HMSET ORDERS:$no_w_id:$no_d_id:$o_id O_ID $o_id O_C_ID $no_c_id O_D_ID $no_d_id O_W_ID $no_w_id O_ENTRY_D $date O_CARRIER_ID "" O_OL_CNT $ol_cnt NO_ALL_LOCAL $no_o_all_local
$redis LPUSH ORDERS_OSTAT_QUERY:$no_w_id:$no_d_id:$no_c_id $o_id
$redis HMSET NEW_ORDER:$no_w_id:$no_d_id:$o_id NO_O_ID $o_id NO_D_ID $no_d_id NO_W_ID $no_w_id
$redis LPUSH NEW_ORDER_IDS:$no_w_id:$no_d_id $o_id
set rbk [ RandomNumber 1 100 ]  
for {set loop_counter 1} {$loop_counter <= $ol_cnt} {incr loop_counter} {
if { ($loop_counter eq $ol_cnt) && ($rbk eq 1) } {
#No Rollback Support in Redis
set no_ol_i_id 100001
puts "New Order:Invalid Item id:$no_ol_i_id (intentional error)" 
return
	     } else {
set no_ol_i_id [ RandomNumber 1 100000 ]  
		}
set x [ RandomNumber 1 100 ]  
if { $x > 1 } {
set no_ol_supply_w_id $no_w_id
	} else {
set no_ol_supply_w_id $no_w_id
set no_o_all_local 0
while { ($no_ol_supply_w_id eq $no_w_id) && ($w_id_input != 1) } {
set no_ol_supply_w_id [ RandomNumber 1 $w_id_input ]  
		}
	}
set no_ol_quantity [ RandomNumber 1 10 ]  
foreach { no_i_name no_i_price no_i_data } [ $redis HMGET ITEM:$no_ol_i_id I_NAME I_PRICE I_DATA ] {}
foreach { no_s_quantity no_s_data no_s_dist_01 no_s_dist_02 no_s_dist_03 no_s_dist_04 no_s_dist_05 no_s_dist_06 no_s_dist_07 no_s_dist_08 no_s_dist_09 no_s_dist_10 } [ $redis HMGET STOCK:$no_ol_supply_w_id:$no_ol_i_id S_QUANTITY S_DATA S_DIST_01 S_DIST_02 S_DIST_03 S_DIST_04 S_DIST_05 S_DIST_06 S_DIST_07 S_DIST_08 S_DIST_09 S_DIST_10 ] {}
if { $no_s_quantity > $no_ol_quantity } {
set no_s_quantity [ expr $no_s_quantity - $no_ol_quantity ]
	} else {
set no_s_quantity [ expr ($no_s_quantity - $no_ol_quantity) + 91 ]
	}
$redis HMSET STOCK:$no_ol_supply_w_id:$no_ol_i_id  S_QUANTITY $no_s_quantity 
set no_ol_amount [ expr $no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ) ]
switch $no_d_id {
1 { set no_ol_dist_info $no_s_dist_01 }
2 { set no_ol_dist_info $no_s_dist_02 }
3 { set no_ol_dist_info $no_s_dist_03 }
4 { set no_ol_dist_info $no_s_dist_04 }
5 { set no_ol_dist_info $no_s_dist_05 }
6 { set no_ol_dist_info $no_s_dist_06 }
7 { set no_ol_dist_info $no_s_dist_07 }
8 { set no_ol_dist_info $no_s_dist_08 }
9 { set no_ol_dist_info $no_s_dist_09 }
10 { set no_ol_dist_info $no_s_dist_10 }
	     }
$redis HMSET ORDER_LINE:$no_w_id:$no_d_id:$o_id:$loop_counter OL_O_ID $o_id OL_D_ID $no_d_id OL_W_ID $no_w_id OL_NUMBER $loop_counter OL_I_ID $no_ol_i_id OL_SUPPLY_W_ID $no_ol_supply_w_id OL_QUANTITY $no_ol_quantity OL_AMOUNT $no_ol_amount OL_DIST_INFO $no_ol_dist_info OL_DELIVERY_D ""
$redis LPUSH ORDER_LINE_NUMBERS:$no_w_id:$no_d_id:$o_id $loop_counter 
$redis ZADD ORDER_LINE_SLEV_QUERY:$no_w_id:$no_d_id $o_id $no_ol_i_id
	}
puts "$no_c_discount $no_c_last $no_c_credit $no_w_tax $no_d_tax $d_next_o_id" 
   }

#PAYMENT
proc payment { redis p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT WAREHOUSE:$p_w_id W_YTD $p_h_amount
$redis HMSET WAREHOUSE:$p_w_id W_YTD [ expr  [ $redis HMGET WAREHOUSE:$p_w_id W_YTD ] + $p_h_amount ]
foreach { p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name } [ $redis HMGET WAREHOUSE:$p_w_id W_STREET_1 W_STREET_2 W_CITY W_STATE W_ZIP W_NAME ] {}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT DISTRICT:$p_w_id:$p_d_id D_YTD $p_h_amount
$redis HMSET DISTRICT:$p_w_id:$p_d_id D_YTD [ expr  [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_YTD ] + $p_h_amount ]
foreach { p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name } [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_STREET_1 D_STREET_2 D_CITY D_STATE D_ZIP D_NAME ]  {}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$p_w_id:$p_d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$id_to_query C_FIRST C_MIDDLE C_ID C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
set p_c_last $name
	} else {
foreach { p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_FIRST C_MIDDLE C_LAST C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
	}
set p_c_balance [ expr $p_c_balance + $p_h_amount ]
set p_c_data [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_DATA ] 
set tstamp [ gettimestamp ]
if { $p_c_credit eq "BC" } {
set h_data "$p_w_name $p_d_name"
set p_c_new_data "$p_c_id $p_c_d_id $p_c_w_id $p_d_id $p_w_id $p_h_amount $tstamp $h_data"
set p_c_new_data [ string range "$p_c_new_data $p_c_data" 0 [ expr 500 - [ string length $p_c_new_data ] ] ]
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance C_DATA $p_c_new_data
	} else {
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance
set h_data "$p_w_name $p_d_name"
	}
$redis HMSET HISTORY:$p_c_w_id:$p_c_d_id:$p_c_id:$tstamp H_C_ID $p_c_id H_C_D_ID $p_c_d_id H_C_W_ID $p_c_w_id H_W_ID $p_w_id H_D_ID $p_d_id H_DATE $tstamp H_AMOUNT $p_h_amount H_DATA $h_data
puts "$p_c_id,$p_c_last,$p_w_street_1,$p_w_street_2,$p_w_city,$p_w_state,$p_w_zip,$p_d_street_1,$p_d_street_2,$p_d_city,$p_d_state,$p_d_zip,$p_c_first,$p_c_middle,$p_c_street_1,$p_c_street_2,$p_c_city,$p_c_state,$p_c_zip,$p_c_phone,$p_c_since,$p_c_credit,$p_c_credit_lim,$p_c_discount,$p_c_balance,$p_c_data"
	}

#ORDER_STATUS
proc ostat { redis w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$w_id:$d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { os_c_balance os_c_first os_c_middle os_c_id } [ $redis HMGET CUSTOMER:$w_id:$d_id:$id_to_query C_BALANCE C_FIRST C_MIDDLE C_ID ] {}
set os_c_last $name
	} else {
foreach { os_c_balance os_c_first os_c_middle os_c_last } [ $redis HMGET CUSTOMER:$w_id:$d_id:$c_id C_BALANCE C_FIRST C_MIDDLE C_LAST ] {}
set os_c_id $c_id
	}
set o_id_len [ $redis LLEN ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id ]
if { $o_id_len eq 0 } {
puts "No orders for customer"
	} else {
set o_id_list [ lindex [ lsort [ $redis LRANGE ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id 0 $o_id_len ] ] end ]
foreach { o_id o_carrier_id o_entry_d } [ $redis HMGET ORDERS:$w_id:$d_id:$o_id_list O_ID O_CARRIER_ID O_ENTRY_D ] {}
set os_cline_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id ]
set os_cline_list [ lsort -integer [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id 0 $os_cline_len ] ]
set i 0
foreach ol [ split $os_cline_list ] { 
foreach { ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d } [ $redis HMGET ORDER_LINE:$w_id:$d_id:$o_id:$ol OL_I_ID OL_SUPPLY_W_ID OL_QUANTITY OL_AMOUNT OL_DELIVERY_D ] {}
set os_ol_i_id($i) $ol_i_id
set os_ol_supply_w_id($i) $ol_supply_w_id
set os_ol_quantity($i) $ol_quantity
set os_ol_amount($i) $ol_amount
set os_ol_delivery_d($i) $ol_delivery_d
incr i
#puts "Item Status $i:$ol_i_id $ol_supply_w_id $ol_quantity $ol_amount $ol_delivery_d"
	}
puts "$os_c_id,$os_c_last,$os_c_first,$os_c_middle,$os_c_balance,$o_id,$o_entry_d,$o_carrier_id"
  }
}
#DELIVERY
proc delivery { redis w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
for {set loop_counter 1} {$loop_counter <= 10} {incr loop_counter} {
set d_d_id $loop_counter 
set d_no_o_id [ $redis LPOP NEW_ORDER_IDS:$w_id:$d_d_id ]
$redis DEL NEW_ORDER:$w_id:$d_d_id:$d_no_o_id
set d_c_id [ $redis HMGET ORDERS:$w_id:$d_d_id:$d_no_o_id O_C_ID ]
$redis HMSET ORDERS:$w_id:$d_d_id:$d_no_o_id O_CARRIER_ID $carrier_id
set ol_deliv_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id ]
set ol_deliv_list [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id 0 $ol_deliv_len ] 
set d_ol_total 0
foreach ol [ split $ol_deliv_list ] { 
set d_ol_total [expr $d_ol_total + [ $redis HMGET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_AMOUNT ]]
$redis HMSET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_DELIVERY_D $date
	}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE $d_ol_total 
$redis HMSET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE [ expr [ $redis HMGET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE ] + $d_ol_total ]
	}
puts "W:$w_id D:$d_d_id O:$d_no_o_id C:$carrier_id time:$date"
}
#STOCK LEVEL
proc slev { redis w_id stock_level_d_id RAISEERROR } {
set stock_level 0
set threshold [ RandomNumber 10 20 ]
set st_o_id [ $redis HMGET DISTRICT:$w_id:$stock_level_d_id D_NEXT_O_ID ]
set item_id_list [ $redis ZRANGE ORDER_LINE_SLEV_QUERY:$w_id:$stock_level_d_id [ expr $st_o_id - 19 ] $st_o_id ]
foreach item_id [ split [ lsort -unique $item_id_list ] ] { 
	if { [ $redis HMGET STOCK:$w_id:$item_id S_QUANTITY ] < $threshold } { incr stock_level } }
puts "$w_id $stock_level_d_id $threshold: $stock_level"
	}

#RUN TPC-C
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set w_id_input [ $redis GET COUNT_WARE ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ $redis GET DIST_PER_WARE ]
set stock_level_d_id [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $redis $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
$redis QUIT
	}
}

proc loadtimedredistpcc {} {
global redis_host redis_port redis_namespace redis_total_iterations redis_raiseerror redis_keyandthink redis_driver redis_rampup redis_duration opmode _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_total_iterations ] } { set redis_total_iterations 1000000 }
if {  ![ info exists redis_raiseerror ] } { set redis_raiseerror "false" }
if {  ![ info exists redis_keyandthink ] } { set redis_keyandthink "false" }
if {  ![ info exists redis_driver ] } { set redis_driver "standard" }
if {  ![ info exists redis_rampup ] } { set redis_rampup "2" }
if {  ![ info exists redis_duration ] } { set redis_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require redis} \] { error \"Failed to load Redis - Redis Package Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $redis_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $redis_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "Redis Timed Test Script must be run in Thread Enabled Interpreter"
}
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all start_trans
	}
}
set COUNT_WARE [ $redis GET COUNT_WARE ]
set DIST_PER_WARE [ $redis GET DIST_PER_WARE ]
set start_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr start_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all end_trans
	}
}
set end_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr end_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm Redis TPM at $nopm NOPM"
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { redis no_w_id w_id_input RAISEERROR } {
set no_d_id [ RandomNumber 1 10 ]
set no_c_id [ RandomNumber 1 3000 ]
set ol_cnt [ RandomNumber 5 15 ]
set date [ gettimestamp ]
set no_o_all_local 0
foreach { no_c_discount no_c_last no_c_credit } [ $redis HMGET CUSTOMER:$no_w_id:$no_d_id:$no_c_id C_DISCOUNT C_LAST C_CREDIT ] {}
set no_w_tax [ $redis HMGET WAREHOUSE:$no_w_id W_TAX ]
set no_d_tax [ $redis HMGET DISTRICT:$no_w_id:$no_d_id D_TAX ]
set d_next_o_id [ $redis HINCRBY DISTRICT:$no_w_id:$no_d_id D_NEXT_O_ID 1 ]
set o_id $d_next_o_id
$redis HMSET ORDERS:$no_w_id:$no_d_id:$o_id O_ID $o_id O_C_ID $no_c_id O_D_ID $no_d_id O_W_ID $no_w_id O_ENTRY_D $date O_CARRIER_ID "" O_OL_CNT $ol_cnt NO_ALL_LOCAL $no_o_all_local
$redis LPUSH ORDERS_OSTAT_QUERY:$no_w_id:$no_d_id:$no_c_id $o_id
$redis HMSET NEW_ORDER:$no_w_id:$no_d_id:$o_id NO_O_ID $o_id NO_D_ID $no_d_id NO_W_ID $no_w_id
$redis LPUSH NEW_ORDER_IDS:$no_w_id:$no_d_id $o_id
set rbk [ RandomNumber 1 100 ]  
for {set loop_counter 1} {$loop_counter <= $ol_cnt} {incr loop_counter} {
if { ($loop_counter eq $ol_cnt) && ($rbk eq 1) } {
#No Rollback Support in Redis
set no_ol_i_id 100001
#puts "New Order:Invalid Item id:$no_ol_i_id (intentional error)" 
return
	     } else {
set no_ol_i_id [ RandomNumber 1 100000 ]  
		}
set x [ RandomNumber 1 100 ]  
if { $x > 1 } {
set no_ol_supply_w_id $no_w_id
	} else {
set no_ol_supply_w_id $no_w_id
set no_o_all_local 0
while { ($no_ol_supply_w_id eq $no_w_id) && ($w_id_input != 1) } {
set no_ol_supply_w_id [ RandomNumber 1 $w_id_input ]  
		}
	}
set no_ol_quantity [ RandomNumber 1 10 ]  
foreach { no_i_name no_i_price no_i_data } [ $redis HMGET ITEM:$no_ol_i_id I_NAME I_PRICE I_DATA ] {}
foreach { no_s_quantity no_s_data no_s_dist_01 no_s_dist_02 no_s_dist_03 no_s_dist_04 no_s_dist_05 no_s_dist_06 no_s_dist_07 no_s_dist_08 no_s_dist_09 no_s_dist_10 } [ $redis HMGET STOCK:$no_ol_supply_w_id:$no_ol_i_id S_QUANTITY S_DATA S_DIST_01 S_DIST_02 S_DIST_03 S_DIST_04 S_DIST_05 S_DIST_06 S_DIST_07 S_DIST_08 S_DIST_09 S_DIST_10 ] {}
if { $no_s_quantity > $no_ol_quantity } {
set no_s_quantity [ expr $no_s_quantity - $no_ol_quantity ]
	} else {
set no_s_quantity [ expr ($no_s_quantity - $no_ol_quantity) + 91 ]
	}
$redis HMSET STOCK:$no_ol_supply_w_id:$no_ol_i_id  S_QUANTITY $no_s_quantity 
set no_ol_amount [ expr $no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ) ]
switch $no_d_id {
1 { set no_ol_dist_info $no_s_dist_01 }
2 { set no_ol_dist_info $no_s_dist_02 }
3 { set no_ol_dist_info $no_s_dist_03 }
4 { set no_ol_dist_info $no_s_dist_04 }
5 { set no_ol_dist_info $no_s_dist_05 }
6 { set no_ol_dist_info $no_s_dist_06 }
7 { set no_ol_dist_info $no_s_dist_07 }
8 { set no_ol_dist_info $no_s_dist_08 }
9 { set no_ol_dist_info $no_s_dist_09 }
10 { set no_ol_dist_info $no_s_dist_10 }
	     }
$redis HMSET ORDER_LINE:$no_w_id:$no_d_id:$o_id:$loop_counter OL_O_ID $o_id OL_D_ID $no_d_id OL_W_ID $no_w_id OL_NUMBER $loop_counter OL_I_ID $no_ol_i_id OL_SUPPLY_W_ID $no_ol_supply_w_id OL_QUANTITY $no_ol_quantity OL_AMOUNT $no_ol_amount OL_DIST_INFO $no_ol_dist_info OL_DELIVERY_D ""
$redis LPUSH ORDER_LINE_NUMBERS:$no_w_id:$no_d_id:$o_id $loop_counter 
$redis ZADD ORDER_LINE_SLEV_QUERY:$no_w_id:$no_d_id $o_id $no_ol_i_id
	}
	;
   }

#PAYMENT
proc payment { redis p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT WAREHOUSE:$p_w_id W_YTD $p_h_amount
$redis HMSET WAREHOUSE:$p_w_id W_YTD [ expr  [ $redis HMGET WAREHOUSE:$p_w_id W_YTD ] + $p_h_amount ]
foreach { p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name } [ $redis HMGET WAREHOUSE:$p_w_id W_STREET_1 W_STREET_2 W_CITY W_STATE W_ZIP W_NAME ] {}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT DISTRICT:$p_w_id:$p_d_id D_YTD $p_h_amount
$redis HMSET DISTRICT:$p_w_id:$p_d_id D_YTD [ expr  [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_YTD ] + $p_h_amount ]
foreach { p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name } [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_STREET_1 D_STREET_2 D_CITY D_STATE D_ZIP D_NAME ]  {}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$p_w_id:$p_d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$id_to_query C_FIRST C_MIDDLE C_ID C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
set p_c_last $name
	} else {
foreach { p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_FIRST C_MIDDLE C_LAST C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
	}
set p_c_balance [ expr $p_c_balance + $p_h_amount ]
set p_c_data [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_DATA ] 
set tstamp [ gettimestamp ]
if { $p_c_credit eq "BC" } {
set h_data "$p_w_name $p_d_name"
set p_c_new_data "$p_c_id $p_c_d_id $p_c_w_id $p_d_id $p_w_id $p_h_amount $tstamp $h_data"
set p_c_new_data [ string range "$p_c_new_data $p_c_data" 0 [ expr 500 - [ string length $p_c_new_data ] ] ]
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance C_DATA $p_c_new_data
	} else {
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance
set h_data "$p_w_name $p_d_name"
	}
$redis HMSET HISTORY:$p_c_w_id:$p_c_d_id:$p_c_id:$tstamp H_C_ID $p_c_id H_C_D_ID $p_c_d_id H_C_W_ID $p_c_w_id H_W_ID $p_w_id H_D_ID $p_d_id H_DATE $tstamp H_AMOUNT $p_h_amount H_DATA $h_data
	;
	}

#ORDER_STATUS
proc ostat { redis w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$w_id:$d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { os_c_balance os_c_first os_c_middle os_c_id } [ $redis HMGET CUSTOMER:$w_id:$d_id:$id_to_query C_BALANCE C_FIRST C_MIDDLE C_ID ] {}
set os_c_last $name
	} else {
foreach { os_c_balance os_c_first os_c_middle os_c_last } [ $redis HMGET CUSTOMER:$w_id:$d_id:$c_id C_BALANCE C_FIRST C_MIDDLE C_LAST ] {}
set os_c_id $c_id
	}
set o_id_len [ $redis LLEN ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id ]
if { $o_id_len eq 0 } {
#puts "No orders for customer"
	} else {
set o_id_list [ lindex [ lsort [ $redis LRANGE ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id 0 $o_id_len ] ] end ]
foreach { o_id o_carrier_id o_entry_d } [ $redis HMGET ORDERS:$w_id:$d_id:$o_id_list O_ID O_CARRIER_ID O_ENTRY_D ] {}
set os_cline_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id ]
set os_cline_list [ lsort -integer [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id 0 $os_cline_len ] ]
set i 0
foreach ol [ split $os_cline_list ] { 
foreach { ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d } [ $redis HMGET ORDER_LINE:$w_id:$d_id:$o_id:$ol OL_I_ID OL_SUPPLY_W_ID OL_QUANTITY OL_AMOUNT OL_DELIVERY_D ] {}
set os_ol_i_id($i) $ol_i_id
set os_ol_supply_w_id($i) $ol_supply_w_id
set os_ol_quantity($i) $ol_quantity
set os_ol_amount($i) $ol_amount
set os_ol_delivery_d($i) $ol_delivery_d
incr i
#puts "Item Status $i:$ol_i_id $ol_supply_w_id $ol_quantity $ol_amount $ol_delivery_d"
	}
	;
  }
}
#DELIVERY
proc delivery { redis w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
for {set loop_counter 1} {$loop_counter <= 10} {incr loop_counter} {
set d_d_id $loop_counter 
set d_no_o_id [ $redis LPOP NEW_ORDER_IDS:$w_id:$d_d_id ]
$redis DEL NEW_ORDER:$w_id:$d_d_id:$d_no_o_id
set d_c_id [ $redis HMGET ORDERS:$w_id:$d_d_id:$d_no_o_id O_C_ID ]
$redis HMSET ORDERS:$w_id:$d_d_id:$d_no_o_id O_CARRIER_ID $carrier_id
set ol_deliv_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id ]
set ol_deliv_list [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id 0 $ol_deliv_len ] 
set d_ol_total 0
foreach ol [ split $ol_deliv_list ] { 
set d_ol_total [expr $d_ol_total + [ $redis HMGET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_AMOUNT ]]
$redis HMSET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_DELIVERY_D $date
	}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE $d_ol_total 
$redis HMSET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE [ expr [ $redis HMGET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE ] + $d_ol_total ]
	}
	;
}
#STOCK LEVEL
proc slev { redis w_id stock_level_d_id RAISEERROR } {
set stock_level 0
set threshold [ RandomNumber 10 20 ]
set st_o_id [ $redis HMGET DISTRICT:$w_id:$stock_level_d_id D_NEXT_O_ID ]
set item_id_list [ $redis ZRANGE ORDER_LINE_SLEV_QUERY:$w_id:$stock_level_d_id [ expr $st_o_id - 19 ] $st_o_id ]
foreach item_id [ split [ lsort -unique $item_id_list ] ] { 
	if { [ $redis HMGET STOCK:$w_id:$item_id S_QUANTITY ] < $threshold } { incr stock_level } }
	;
	}

#RUN TPC-C
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set w_id_input [ $redis GET COUNT_WARE ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ $redis GET DIST_PER_WARE ]
set stock_level_d_id [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $redis $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	      }
	}
    }
}
$redis QUIT}
}

proc check_traftpcc { } {
global trafodion_dsn trafodion_odbc_driver trafodion_server trafodion_port trafodion_userid trafodion_password trafodion_schema trafodion_count_ware trafodion_num_threads trafodion_load_type trafodion_load_data trafodion_node_list trafodion_copy_remote trafodion_build_jsps num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists trafodion_dsn ] } { set trafodion_dsn "Default_DataSource" }
if {  ![ info exists trafodion_odbc_driver ] } { set trafodion_odbc_driver "Trafodion" }
if {  ![ info exists trafodion_server ] } { set trafodion_server "sandbox" }
if {  ![ info exists trafodion_port ] } { set trafodion_port "37800" }
if {  ![ info exists trafodion_userid ] } { set trafodion_userid "trafodion" }
if {  ![ info exists trafodion_password ] } { set trafodion_password "traf123" }
if {  ![ info exists trafodion_schema ] } { set trafodion_schema "tpcc" }
if {  ![ info exists trafodion_count_ware ] } { set trafodion_count_ware "1" }
if {  ![ info exists trafodion_num_threads ] } { set trafodion_num_threads "1" }
if {  ![ info exists trafodion_load_type ] } { set trafodion_load_type "upsert" }
if {  ![ info exists trafodion_load_data ] } { set trafodion_load_data "true" }
if {  ![ info exists trafodion_build_jsps ] } { set trafodion_build_jsps "true" }
if {  ![ info exists trafodion_copy_remote ] } { set trafodion_copy_remote "false" }
if {  ![ info exists trafodion_node_list ] } { set trafodion_load_type "sandbox" }
if { $trafodion_load_data eq "true" && $trafodion_build_jsps eq "true" } {
set trafmsg "Ready to create a $trafodion_count_ware Warehouse Trafodion TPC-C schema\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema with JSPs?"
	} else {
if { $trafodion_load_data eq "true" && $trafodion_build_jsps eq "false" } {
set trafmsg "Ready to create a $trafodion_count_ware Warehouse Trafodion TPC-C schema\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema without JSPs?"
	} else {
if { $trafodion_load_data eq "false" && $trafodion_build_jsps eq "true" } {
set trafmsg "Ready to create Trafodion JSPs only without data\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema?"
		} else {
set trafmsg "No Trafodion Data to load or JSPs to create\nin host [string toupper TCP:$trafodion_server:$trafodion_port] in schema $trafodion_schema"
		}
	}
} 
if {[ tk_messageBox -title "Create Schema" -icon question -message $trafmsg -type yesno ] == yes} { 
if { $trafodion_num_threads eq 1 || $trafodion_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $trafodion_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require tdbc::odbc} ] { error "Failed to load tdbc::odbc - ODBC Library Error" }

proc finddirforstoredprocs {} {
        set result [ pwd ]       ;
        if {[file writable [ pwd ]]} {
            return [ pwd ]
        }
        if {[string match windows $::tcl_platform(platform)]} {
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            }
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[file isdirectory C:/TEMP] && [file writable C:/TEMP]} {
                return C:/TEMP
            }
            if {[file isdirectory C:/] && [file writable C:/]} {
                return C:/
            }
        } else { ;
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            }
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[file isdirectory /tmp] && [file writable /tmp]} {
                return /tmp
            }
 	}
        return "nodir"
	}

proc CreateStoredProcs { odbc schema nodelist copyremote } {
puts "CREATING TPCC STORED PROCEDURES"
set NEWORDER {import java.sql.*;
import java.math.*;
import java.util.Random;

public class NEWORDER {
public static int randInt(int min, int max) {
Random rand = new Random();
int randomNum = rand.nextInt((max - min) + 1) + min;
return randomNum;
}
public static void NEWORD (int no_w_id, int no_max_w_id, int no_d_id, int no_c_id, int no_o_ol_cnt, BigDecimal[] no_c_discount, String[] no_c_last, String[] no_c_credit, BigDecimal[] no_d_tax, BigDecimal[] no_w_tax, int[] no_d_next_o_id, Timestamp tstamp, ResultSet[] opres)   
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
BigDecimal no_o_all_local = new BigDecimal(0);
PreparedStatement getDiscTax =
conn.prepareStatement("SELECT c_discount, c_last, c_credit, w_tax " +
"FROM customer, warehouse " +
"WHERE warehouse.w_id = ? AND customer.c_w_id = ? AND " +
"customer.c_d_id = ? AND customer.c_id = ?");
getDiscTax.setInt(1, no_w_id);
getDiscTax.setInt(2, no_w_id);
getDiscTax.setInt(3, no_d_id);
getDiscTax.setInt(4, no_c_id);
ResultSet rs = getDiscTax.executeQuery();
rs.next();
no_c_discount[0] = rs.getBigDecimal(1);
no_c_last[0] = rs.getString(2);
no_c_credit[0] = rs.getString(3);
no_w_tax[0] = rs.getBigDecimal(4);
rs.close();
PreparedStatement getOidTax =
conn.prepareStatement("SELECT d_next_o_id, d_tax " +
"FROM district " +
"WHERE d_id = ? AND d_w_id = ? FOR UPDATE");
getOidTax.setInt(1, no_d_id);
getOidTax.setInt(2, no_w_id);
ResultSet rs1 = getOidTax.executeQuery();
rs1.next();
no_d_next_o_id[0] = rs1.getInt(1); 
no_d_tax[0] = rs1.getBigDecimal(2);
rs1.close();
PreparedStatement UpdDisc =
conn.prepareStatement("UPDATE district SET d_next_o_id = d_next_o_id + 1 " +
"WHERE d_id = ? AND d_w_id = ?");
UpdDisc.setInt(1, no_d_id);
UpdDisc.setInt(2, no_w_id);
UpdDisc.executeUpdate();
int o_id = no_d_next_o_id[0];
PreparedStatement InsOrd =
conn.prepareStatement("INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) " +
"VALUES (?, ?, ?, ?, ?, ?, ?)");
InsOrd.setInt(1, o_id);
InsOrd.setInt(2, no_d_id);
InsOrd.setInt(3, no_w_id);
InsOrd.setInt(4, no_c_id);
InsOrd.setTimestamp(5, tstamp);
InsOrd.setInt(6, no_o_ol_cnt);
InsOrd.setBigDecimal(7, no_o_all_local);
InsOrd.executeUpdate();
PreparedStatement InsNewOrd =
conn.prepareStatement("INSERT INTO new_order (no_o_id, no_d_id, no_w_id) " +
"VALUES (?, ?, ?)");
InsNewOrd.setInt(1, o_id);
InsNewOrd.setInt(2, no_d_id);
InsNewOrd.setInt(3, no_w_id);
InsNewOrd.executeUpdate();
int rbk = randInt(1,100);
int no_ol_i_id;
int no_ol_supply_w_id;
/* In Loop Statements Prepared Outside of Loop */
PreparedStatement SelNameData =
conn.prepareStatement("SELECT i_price, i_name, i_data FROM item " +
"WHERE i_id = ?");
PreparedStatement SelStock =
conn.prepareStatement("SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10 FROM stock " +
"WHERE s_i_id = ? AND s_w_id = ?");
PreparedStatement UpdStock =
conn.prepareStatement("UPDATE stock SET s_quantity = ? " +
"WHERE s_i_id = ? " +
"AND s_w_id = ?");
PreparedStatement InsLine =
conn.prepareStatement("INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) " +
"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
/* In Loop Statements Prepared Outside of Loop */
for (int loop_counter=1; loop_counter<=no_o_ol_cnt; loop_counter++) {
if ((loop_counter == no_o_ol_cnt) && (rbk == 1)) {
no_ol_i_id = 100001;
	}
	else {
no_ol_i_id = randInt(1,100000);
	}
int x = randInt(1,100);
if (x > 1) {
no_ol_supply_w_id = no_w_id;
	}
	else
	{
no_ol_supply_w_id = no_w_id;
//NOTE IN SPECIFICATION no_o_all_local set to 0 here but not needed
while ((no_ol_supply_w_id == no_w_id) && (no_max_w_id != 1)) {
no_ol_supply_w_id = randInt(1,no_max_w_id);
		}
	}
int no_ol_quantity = randInt(1,10);
SelNameData.setInt(1, no_ol_i_id);
ResultSet rs2 = SelNameData.executeQuery();
rs2.next();
BigDecimal no_i_price = rs2.getBigDecimal(1);
String no_i_name = rs2.getString(2);
String no_i_data = rs2.getString(3);
rs2.close();
SelStock.setInt(1, no_ol_i_id);
SelStock.setInt(2, no_ol_supply_w_id);
ResultSet rs3 = SelStock.executeQuery();
rs3.next();
int no_s_quantity = rs3.getInt(1);
String no_s_data = rs3.getString(2);
String no_s_dist_01 = rs3.getString(3);
String no_s_dist_02 = rs3.getString(4);
String no_s_dist_03 = rs3.getString(5);
String no_s_dist_04 = rs3.getString(6);
String no_s_dist_05 = rs3.getString(7);
String no_s_dist_06 = rs3.getString(8);
String no_s_dist_07 = rs3.getString(9);
String no_s_dist_08 = rs3.getString(10);
String no_s_dist_09 = rs3.getString(11);
String no_s_dist_10 = rs3.getString(12);
rs3.close();
if (no_s_quantity > no_ol_quantity) {
no_s_quantity = (no_s_quantity - no_ol_quantity);
	}
	else {
no_s_quantity = (no_s_quantity - no_ol_quantity + 91);
	}
UpdStock.setInt(1, no_s_quantity);
UpdStock.setInt(2, no_ol_i_id);
UpdStock.setInt(3, no_ol_supply_w_id);
UpdStock.executeUpdate();
BigDecimal onebd, disc, tax, no_ol_amount, quant, quant2;
onebd = new BigDecimal("1.0");
disc = onebd.subtract(no_c_discount[0]);
tax = onebd.add(no_w_tax[0].add(no_d_tax[0]));
quant = new BigDecimal(String.valueOf(no_ol_quantity));
quant2 = quant.multiply(no_i_price.multiply(tax.multiply(disc)));
no_ol_amount = quant2.setScale(2, RoundingMode.HALF_UP);
String no_ol_dist_info = "";
switch(no_d_id) {
case 1: no_ol_dist_info = no_s_dist_01;
	break;
case 2: no_ol_dist_info = no_s_dist_02;
	break;
case 3: no_ol_dist_info = no_s_dist_03;
	break;
case 4: no_ol_dist_info = no_s_dist_04;
	break;
case 5: no_ol_dist_info = no_s_dist_05;
	break;
case 6: no_ol_dist_info = no_s_dist_06;
	break;
case 7: no_ol_dist_info = no_s_dist_07;
	break;
case 8: no_ol_dist_info = no_s_dist_08;
	break;
case 9: no_ol_dist_info = no_s_dist_09;
	break;
case 10:no_ol_dist_info = no_s_dist_10;
	break;
	}
InsLine.setInt(1, o_id);
InsLine.setInt(2, no_d_id);
InsLine.setInt(3, no_w_id);
InsLine.setInt(4, loop_counter);
InsLine.setInt(5, no_ol_i_id);
InsLine.setInt(6, no_ol_supply_w_id);
InsLine.setInt(7, no_ol_quantity);
InsLine.setBigDecimal(8, no_ol_amount);
InsLine.setString(9, no_ol_dist_info);
InsLine.executeUpdate();
        }
conn.commit();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS NO_C_DISCOUNT,? AS NO_C_LAST,? AS NO_C_CREDIT,? AS NO_D_TAX,? AS NO_W_TAX,? AS NO_D_NEXT_O_ID from (values(1))x");
getOutput.setBigDecimal(1,no_c_discount[0]);
getOutput.setString(2,no_c_last[0]);
getOutput.setString(3,no_c_credit[0]);
getOutput.setBigDecimal(4,no_d_tax[0]);
getOutput.setBigDecimal(5,no_w_tax[0]);
getOutput.setInt(6,no_d_next_o_id[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set NEWORDER.proc "create procedure neworder(IN no_w_id INT, IN no_max_w_id INT, IN no_d_id INT, IN no_c_id INT, IN no_o_ol_cnt INT, OUT no_c_discount NUMERIC(4,4), OUT no_c_last VARCHAR(16), OUT no_c_credit CHAR(2), OUT no_d_tax NUMERIC(4,4), OUT no_w_tax NUMERIC(4,4), OUT no_d_next_o_id INT, IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'NEWORDER.NEWORD\' library NEWORDER dynamic result sets 1"
set DELIVERY {import java.sql.*;
import java.math.*;
import java.io.*;
import java.util.*;

public class DELIVERY {
public static void DELIV (int d_w_id, int d_o_carrier_id, Timestamp tstamp)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
int d_d_id;
/* In Loop Statements Prepared Outside of Loop */
PreparedStatement getNewOrd =
conn.prepareStatement("SELECT no_o_id FROM new_order " +
"WHERE no_w_id = ? " +
"AND no_d_id = ? " +
"ORDER BY no_o_id ASC LIMIT 1");
PreparedStatement delNewOrd =
conn.prepareStatement("DELETE FROM new_order " +
"WHERE no_w_id = ? " +
"AND no_d_id = ? " +
"AND no_o_id = ?");
PreparedStatement getCOrd =
conn.prepareStatement("SELECT o_c_id FROM orders " +
"WHERE o_id = ? " +
"AND o_d_id = ? " +
"AND o_w_id = ?");
PreparedStatement UpdOrd =
conn.prepareStatement("UPDATE orders SET o_carrier_id = ? " +
"WHERE o_id = ? " + 
"AND o_d_id = ? " +
"AND o_w_id = ?");
PreparedStatement UpdLine =
conn.prepareStatement("UPDATE order_line SET ol_delivery_d = ? " +
"WHERE ol_o_id = ? " +
"AND ol_d_id = ? " +
"AND ol_w_id = ?");
PreparedStatement getOrdAm =
conn.prepareStatement("SELECT SUM(ol_amount) " +
"FROM order_line " +
"WHERE ol_o_id = ? AND ol_d_id = ? " +
"AND ol_w_id = ?");
PreparedStatement UpdCust =
conn.prepareStatement("UPDATE customer SET c_balance = c_balance + ? " +
"WHERE c_id = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
/* In Loop Statements Prepared Outside of Loop */
for (int loop_counter=1; loop_counter<=10; loop_counter++) {
d_d_id = loop_counter;
getNewOrd.setInt(1, d_w_id);
getNewOrd.setInt(2, d_d_id);
ResultSet rs = getNewOrd.executeQuery();
rs.next();
int d_no_o_id = rs.getInt(1);
rs.close();
delNewOrd.setInt(1, d_w_id);
delNewOrd.setInt(2, d_d_id);
delNewOrd.setInt(3, d_no_o_id);
delNewOrd.executeUpdate();
getCOrd.setInt(1, d_no_o_id);
getCOrd.setInt(2, d_d_id);
getCOrd.setInt(3, d_w_id);
ResultSet rs1 = getCOrd.executeQuery();
rs1.next();
int d_c_id = rs1.getInt(1);
rs1.close();
UpdOrd.setInt(1, d_o_carrier_id);
UpdOrd.setInt(2, d_no_o_id);
UpdOrd.setInt(3, d_d_id);
UpdOrd.setInt(4, d_w_id);
UpdOrd.executeUpdate();
UpdLine.setTimestamp(1, tstamp);
UpdLine.setInt(2, d_no_o_id); 
UpdLine.setInt(3, d_d_id); 
UpdLine.setInt(4, d_w_id); 
UpdLine.executeUpdate();
getOrdAm.setInt(1, d_no_o_id); 
getOrdAm.setInt(2, d_d_id); 
getOrdAm.setInt(3, d_w_id); 
ResultSet rs2 = getOrdAm.executeQuery();
rs2.next();
BigDecimal d_ol_total = rs2.getBigDecimal(1);
rs2.close();
UpdCust.setBigDecimal(1, d_ol_total);
UpdCust.setInt(2, d_d_id); 
UpdCust.setInt(3, d_d_id); 
UpdCust.setInt(4, d_w_id); 
UpdCust.executeUpdate();
System.out.println("D: " + d_d_id + "O: " + d_no_o_id + "time " + tstamp);
	}
/* No output parameters to return as a result set as uses print instead*/
conn.commit();
conn.close();
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
} 
set DELIVERY.proc "create procedure delivery(IN d_w_id INT, IN d_o_carrier_id INT, IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'DELIVERY.DELIV\' library DELIVERY"
set PAYMENT {import java.sql.*;
import java.math.*;

public class PAYMENT {
public static void PAY (int p_w_id, int p_d_id, int p_c_w_id, int p_c_d_id, int[] p_c_id, int byname, BigDecimal p_h_amount, String[] p_c_last, String[] p_w_street_1, String[] p_w_street_2, String[] p_w_city, String[] p_w_state, String[] p_w_zip, String[] p_d_street_1, String[] p_d_street_2, String[] p_d_city, String[] p_d_state, String[] p_d_zip, String[] p_c_first, String[] p_c_middle, String[] p_c_street_1, String[] p_c_street_2, String[] p_c_city, String[] p_c_state, String[] p_c_zip,  String[] p_c_phone, Timestamp[] p_c_since, String[] p_c_credit, BigDecimal[] p_c_credit_lim, BigDecimal[] p_c_discount, BigDecimal[] p_c_balance, String[] p_c_data, Timestamp tstamp, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
PreparedStatement updWare =
conn.prepareStatement("UPDATE warehouse SET w_ytd = w_ytd + ? " +
"WHERE w_id = ?");
updWare.setBigDecimal(1, p_h_amount);
updWare.setInt(2, p_w_id); 
updWare.executeUpdate();
PreparedStatement selWare =
conn.prepareStatement("SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name " +
"FROM warehouse " +
"WHERE w_id = ?");
selWare.setInt(1, p_w_id); 
ResultSet rs = selWare.executeQuery();
rs.next();
p_w_street_1[0] = rs.getString(1);
p_w_street_2[0] = rs.getString(2);
p_w_city[0] = rs.getString(3);
p_w_state[0] = rs.getString(4);
p_w_zip[0] = rs.getString(5);
String p_w_name = rs.getString(6);
rs.close();
PreparedStatement updDisc =
conn.prepareStatement("UPDATE district SET d_ytd = d_ytd + ? " +
"WHERE d_w_id = ? AND d_id = ?");
updDisc.setBigDecimal(1, p_h_amount);
updDisc.setInt(2, p_w_id);
updDisc.setInt(3, p_d_id);
updDisc.executeUpdate();
PreparedStatement selDisc =
conn.prepareStatement("SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name " +
"FROM district " +
"WHERE d_w_id = ? AND d_id = ?");
selDisc.setInt(1, p_w_id); 
selDisc.setInt(2, p_d_id); 
ResultSet rs1 = selWare.executeQuery();
rs1.next();
p_d_street_1[0] = rs1.getString(1);
p_d_street_2[0] = rs1.getString(2);
p_d_city[0] = rs1.getString(3);
p_d_state[0] = rs1.getString(4);
p_d_zip[0] = rs1.getString(5);
String p_d_name = rs1.getString(6);
rs1.close();
if (byname == 1) {
PreparedStatement getCust =
conn.prepareStatement("SELECT count(c_id) " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
getCust.setString(1, p_c_last[0]);
getCust.setInt(2, p_c_d_id);
getCust.setInt(3, p_c_w_id);
ResultSet rs2 = getCust.executeQuery();
rs2.next();
int namecnt = rs2.getInt(1);
rs2.close();
if ((namecnt % 2) == 1) {
namecnt = namecnt + 1;
	}
PreparedStatement CurCust =
conn.prepareStatement("SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_last = ? " +
"ORDER BY c_first");
CurCust.setInt(1, p_c_w_id);
CurCust.setInt(2, p_c_d_id);
CurCust.setString(3, p_c_last[0]);
ResultSet rs3 = CurCust.executeQuery();
for (int loop_counter=0; loop_counter<=(namecnt / 2); loop_counter++) {
if(rs3.next()) {
p_c_first[0] = rs3.getString(1);
p_c_middle[0] = rs3.getString(2);
p_c_id[0] = rs3.getInt(3);
p_c_street_1[0] = rs3.getString(4);
p_c_street_2[0] = rs3.getString(5);
p_c_city[0] = rs3.getString(6);
p_c_state[0] = rs3.getString(7);
p_c_zip[0] = rs3.getString(8);
p_c_phone[0] = rs3.getString(9);
p_c_credit[0] = rs3.getString(10);
p_c_credit_lim[0] = rs3.getBigDecimal(11);
p_c_discount[0] = rs3.getBigDecimal(12);
p_c_balance[0] = rs3.getBigDecimal(13);
p_c_since[0] = rs3.getTimestamp(14);
		}
	}
rs3.close();
} else {
PreparedStatement IdCust =
conn.prepareStatement("SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_id = ?");
IdCust.setInt(1, p_c_w_id);
IdCust.setInt(2, p_c_d_id);
IdCust.setInt(3, p_c_id[0]);
ResultSet rs4 = IdCust.executeQuery();
rs4.next();
p_c_first[0] = rs4.getString(1);
p_c_middle[0] = rs4.getString(2);
p_c_last[0] = rs4.getString(3);
p_c_street_1[0] = rs4.getString(4);
p_c_street_2[0] = rs4.getString(5);
p_c_city[0] = rs4.getString(6);
p_c_state[0] = rs4.getString(7);
p_c_zip[0] = rs4.getString(8);
p_c_phone[0] = rs4.getString(9);
p_c_credit[0] = rs4.getString(10);
p_c_credit_lim[0] = rs4.getBigDecimal(11);
p_c_discount[0] = rs4.getBigDecimal(12);
p_c_balance[0] = rs4.getBigDecimal(13);
p_c_since[0] = rs4.getTimestamp(14);
rs4.close();
}
p_c_balance[0] = p_c_balance[0].add(p_h_amount);
String badc = new String("BC");
if (p_c_credit[0].equals(badc)) {
PreparedStatement dataCust =
conn.prepareStatement("SELECT c_data " +
"FROM customer " +
"WHERE c_w_id = ? " +
"AND c_d_id = ? " +
"AND c_id = ?");
dataCust.setInt(1, p_c_w_id);
dataCust.setInt(2, p_c_d_id);
dataCust.setInt(3, p_c_id[0]);
ResultSet rs5 = dataCust.executeQuery();
rs5.next();
p_c_data[0] = rs5.getString(1);
String h_data = p_w_name + " " + p_d_name;
String p_c_new_data = p_c_id[0] + " " + p_c_d_id + " " + p_c_w_id + " " + p_d_id + " " + p_w_id + " " + String.format("%.2f",p_h_amount) + " " + tstamp + " " + h_data;
int new_data_len = p_c_new_data.length();
String tmp_new_data = p_c_new_data + "," + p_c_data[0];
if (tmp_new_data.length() <= 500) {
p_c_new_data = tmp_new_data;
	} else {
p_c_new_data = tmp_new_data.substring(1,500);
	}
PreparedStatement updBal =
conn.prepareStatement("UPDATE customer " +
"SET c_balance = ?, c_data = ? " +
"WHERE c_w_id = ? AND c_d_id = ? " +
"AND c_id = ?");
updBal.setBigDecimal(1, p_c_balance[0]);
updBal.setString(2, p_c_new_data);
updBal.setInt(3, p_c_w_id); 
updBal.setInt(4, p_c_d_id); 
updBal.setInt(5, p_c_id[0]); 
updBal.executeUpdate();
	} else {
p_c_data[0] = "NO P_C_DATA FOR GOOD CREDIT";
PreparedStatement updBal2 =
conn.prepareStatement("UPDATE customer " +
"SET c_balance = ? " +
"WHERE c_w_id = ? AND c_d_id = ? " +
"AND c_id = ?");
updBal2.setBigDecimal(1, p_c_balance[0]);
updBal2.setInt(2, p_c_w_id); 
updBal2.setInt(3, p_c_d_id); 
updBal2.setInt(4, p_c_id[0]); 
updBal2.executeUpdate();
	}
String h_data = p_w_name + " " + p_d_name;
PreparedStatement insHist =
conn.prepareStatement("INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) " +
"VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
insHist.setInt(1, p_c_d_id); 
insHist.setInt(2, p_c_w_id); 
insHist.setInt(3, p_c_id[0]); 
insHist.setInt(4, p_d_id); 
insHist.setInt(5, p_w_id); 
insHist.setTimestamp(6, tstamp);
insHist.setBigDecimal(7, p_h_amount);
insHist.setString(8, h_data);
insHist.executeUpdate();
if (p_c_data[0].length() <= 255) {
	;
	} else {
p_c_data[0] = p_c_data[0].substring(1,255);
	}
conn.commit();
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS P_C_ID,? AS P_C_LAST,? AS P_W_STREET_1,? AS P_W_STREET_2,? AS P_W_CITY,? AS P_W_STATE,? AS P_W_ZIP,? AS P_D_STREET_1,? AS P_D_STREET_2,? AS P_D_CITY,? AS P_D_STATE,? AS P_D_ZIP,? AS P_C_FIRST,? AS P_C_MIDDLE,? AS P_C_STREET_1,? AS P_C_STREET_2, ? AS P_C_CITY,? AS P_C_STATE,? AS P_C_ZIP,? AS P_C_PHONE,? AS P_C_SINCE,? AS P_C_CREDIT,? AS P_C_CREDIT_LIM,? AS P_C_DISCOUNT,? AS P_C_BALANCE,? AS P_C_DATA from (values(1))x");
getOutput.setInt(1, p_c_id[0]);
getOutput.setString(2, p_c_last[0]);
getOutput.setString(3, p_w_street_1[0]);
getOutput.setString(4, p_w_street_2[0]);
getOutput.setString(5, p_w_city[0]);
getOutput.setString(6, p_w_state[0]);
getOutput.setString(7, p_w_zip[0]);
getOutput.setString(8, p_d_street_1[0]);
getOutput.setString(9, p_d_street_2[0]);
getOutput.setString(10,  p_d_city[0]);
getOutput.setString(11, p_d_state[0]);
getOutput.setString(12, p_d_zip[0]);
getOutput.setString(13, p_c_first[0]);
getOutput.setString(14, p_c_middle[0]);
getOutput.setString(15, p_c_street_1[0]);
getOutput.setString(16, p_c_street_2[0]);
getOutput.setString(17, p_c_city[0]);
getOutput.setString(18, p_c_state[0]);
getOutput.setString(19, p_c_zip[0]);
getOutput.setString(20, p_c_phone[0]);
getOutput.setTimestamp(21, p_c_since[0]);
getOutput.setString(22, p_c_credit[0]);
getOutput.setBigDecimal(23, p_c_credit_lim[0]);
getOutput.setBigDecimal(24, p_c_discount[0]);
getOutput.setBigDecimal(25, p_c_balance[0]);
getOutput.setString(26, p_c_data[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
try {
conn.rollback();
    } catch (SQLException se2) {
se2.printStackTrace();
    }
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set PAYMENT.proc "create procedure payment(IN p_w_id INT, IN p_d_id INT, IN p_c_w_id INT, IN p_c_d_id INT, INOUT p_c_id INT, IN byname INT, IN p_h_amount NUMERIC(6,2), INOUT p_c_last VARCHAR(16), OUT p_w_street_1 VARCHAR(20), OUT p_w_street_2 VARCHAR(20), OUT p_w_city VARCHAR(20), OUT p_w_state CHAR(2), OUT p_w_zip CHAR(9), OUT p_d_street_1 VARCHAR(20), OUT p_d_street_2 VARCHAR(20), OUT p_d_city VARCHAR(20), OUT p_d_state CHAR(2), OUT p_d_zip CHAR(9), OUT p_c_first VARCHAR(16), OUT p_c_middle CHAR(2), OUT p_c_street_1 VARCHAR(20), OUT p_c_street_2 VARCHAR(20), OUT p_c_city VARCHAR(20), OUT p_c_state CHAR(2), OUT p_c_zip CHAR(9), OUT p_c_phone CHAR(16), OUT p_c_since TIMESTAMP, INOUT p_c_credit CHAR(2), OUT p_c_credit_lim NUMERIC(12,2), OUT p_c_discount NUMERIC(4,4), INOUT p_c_balance NUMERIC(12,2), OUT p_c_data VARCHAR(500), IN tstamp TIMESTAMP) language java parameter style java reads sql data no transaction required external name \'PAYMENT.PAY\' library PAYMENT dynamic result sets 1"
set ORDERSTATUS {import java.sql.*;
import java.math.*;

public class ORDERSTATUS {
public static void OSTAT (int os_w_id, int os_d_id, int[] os_c_id, int byname, String[] os_c_last, String[] os_c_first, String[] os_c_middle, BigDecimal[] os_c_balance, int[] os_o_id, Timestamp[] os_entdate, int[] os_o_carrier_id, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
if (byname == 1) {
PreparedStatement getCust =
conn.prepareStatement("SELECT count(c_id) " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
getCust.setString(1, os_c_last[0]);
getCust.setInt(2, os_d_id);
getCust.setInt(3, os_w_id);
ResultSet rs = getCust.executeQuery();
rs.next();
int namecnt = rs.getInt(1);
rs.close();
if ((namecnt % 2) == 1) {
namecnt = namecnt + 1;
	}
PreparedStatement CurCust =
conn.prepareStatement("SELECT c_balance, c_first, c_middle, c_id " +
"FROM customer " +
"WHERE c_last = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ? " +
"ORDER BY c_first");
CurCust.setString(1, os_c_last[0]);
CurCust.setInt(2, os_d_id);
CurCust.setInt(3, os_w_id);
ResultSet rs1 = CurCust.executeQuery();
for (int loop_counter=0; loop_counter<=(namecnt / 2); loop_counter++) {
if(rs1.next()) {
os_c_balance[0] = rs1.getBigDecimal(1);
os_c_first[0] = rs1.getString(2);
os_c_middle[0] = rs1.getString(3);
os_c_id[0] = rs1.getInt(4);
		}
	}
rs1.close();
} else {
PreparedStatement IdCust =
conn.prepareStatement("SELECT c_balance, c_first, c_middle, c_last " +
"FROM customer " +
"WHERE c_id = ? " +
"AND c_d_id = ? " +
"AND c_w_id = ?");
IdCust.setInt(1, os_c_id[0]);
IdCust.setInt(2, os_d_id);
IdCust.setInt(3, os_w_id);
ResultSet rs2 = IdCust.executeQuery();
rs2.next();
os_c_balance[0] = rs2.getBigDecimal(1);
os_c_first[0] = rs2.getString(2);
os_c_middle[0] = rs2.getString(3);
os_c_last[0] = rs2.getString(4);
rs2.close();
}
PreparedStatement SubOrd =
conn.prepareStatement("SELECT o_id, o_carrier_id, o_entry_d " +
"FROM orders where o_d_id = ? AND o_w_id = ? and o_c_id = ? " +
"ORDER BY o_id DESC LIMIT 1");
SubOrd.setInt(1, os_d_id);
SubOrd.setInt(2, os_w_id);
SubOrd.setInt(3, os_c_id[0]);
ResultSet rs3 = SubOrd.executeQuery();
if (rs3.next()) {
os_o_id[0] = rs3.getInt(1);
os_o_carrier_id[0] = rs3.getInt(2);
os_entdate[0] = rs3.getTimestamp(3);
	} else {
System.out.println("No Orders for Customer");
rs3.close();
PreparedStatement getOutput =
conn.prepareStatement("select 'no orders for customer' as NOORD from (values(1))x");
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set
conn.close();
*/
return;
	}
PreparedStatement CLine =
conn.prepareStatement("SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d " +
"FROM order_line " +
"WHERE ol_o_id = ? AND ol_d_id = ? AND ol_w_id = ?");
CLine.setInt(1, os_o_id[0]);
CLine.setInt(2, os_d_id);
CLine.setInt(3, os_w_id);
ResultSet rs4 = CLine.executeQuery();
int i=0;
int[] os_ol_i_id = new int[15];
int[] os_ol_supply_w_id = new int[15];
int[] os_ol_quantity  = new int[15];
int[] os_ol_amount = new int[15];
Timestamp [] os_ol_delivery_d = new Timestamp[15];
while (rs4.next()) {
os_ol_i_id[i] = rs4.getInt(1);
os_ol_supply_w_id[i] = rs4.getInt(2);
os_ol_quantity[i] = rs4.getInt(3);
os_ol_amount[i] = rs4.getInt(4);
os_ol_delivery_d[i] = rs4.getTimestamp(5);
i++;
	}
rs4.close();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS OS_C_ID,? AS OS_C_LAST,? AS OS_C_FIRST,? AS OS_C_MIDDLE,? AS OS_C_BALANCE,? AS OS_O_ID,? AS OS_ENTDATE,? AS OS_O_CARRIER_ID from (values(1))x");
getOutput.setInt(1, os_c_id[0]);
getOutput.setString(2, os_c_last[0]);
getOutput.setString(3, os_c_first[0]);
getOutput.setString(4, os_c_middle[0]);
getOutput.setBigDecimal(5, os_c_balance[0]);
getOutput.setInt(6, os_o_id[0]);
getOutput.setTimestamp(7, os_entdate[0]);
getOutput.setInt(8, os_o_carrier_id[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set ORDERSTATUS.proc "create procedure orderstatus(IN os_w_id INT, IN os_d_id INT, INOUT os_c_id INT, IN byname INT, INOUT os_c_last VARCHAR(16), OUT os_c_first VARCHAR(16), OUT os_c_middle CHAR(2), OUT os_c_balance NUMERIC(12,2), OUT os_o_id INT, OUT os_entdate TIMESTAMP, OUT os_o_carrier_id INT) language java parameter style java reads sql data no transaction required external name \'ORDERSTATUS.OSTAT\' library ORDERSTATUS dynamic result sets 1"
set STOCKLEVEL {import java.sql.*;

public class STOCKLEVEL {
public static void SLEV (int st_w_id, int st_d_id, int threshold, int[] st_o_id, int[] stock_count, ResultSet[] opres)
throws SQLException
{
Connection conn = DriverManager.getConnection("jdbc:default:connection");
try {
conn.setAutoCommit(false);
Statement stmt = conn.createStatement();
stmt.executeUpdate("set schema trafodion.tpcc");
PreparedStatement getNextOid =
conn.prepareStatement("SELECT d_next_o_id " +
"FROM district " +
"WHERE d_w_id = ? and d_id = ?");
getNextOid.setInt(1, st_w_id);
getNextOid.setInt(2, st_d_id);
ResultSet rs = getNextOid.executeQuery();
rs.next();
st_o_id[0] = rs.getInt(1);
rs.close();
PreparedStatement getStockCount =
conn.prepareStatement("SELECT COUNT(DISTINCT (STOCK.s_i_id)) " +
"FROM order_line, stock " +
"WHERE ORDER_LINE.ol_w_id = ? " +
"AND ORDER_LINE.ol_d_id = ? " +
"AND (ORDER_LINE.ol_o_id < ?) " +
"AND ORDER_LINE.ol_o_id >= (? - 20) " +
"AND STOCK.s_w_id = ? " + 
"AND STOCK.s_i_id = ORDER_LINE.ol_i_id " +
"AND STOCK.s_quantity < ?");
getStockCount.setInt(1, st_w_id);
getStockCount.setInt(2, st_d_id);
getStockCount.setInt(3, st_o_id[0]);
getStockCount.setInt(4, st_o_id[0]);
getStockCount.setInt(5, st_w_id);
getStockCount.setInt(6, threshold);
ResultSet rs2 = getStockCount.executeQuery();
rs2.next();
stock_count[0] = rs2.getInt(1);
rs2.close();
/* Return output parameters as a result set */
PreparedStatement getOutput =
conn.prepareStatement("SELECT ? AS ST_O_ID,? AS STOCK_COUNT from (values(1))x");
getOutput.setInt(1, st_o_id[0]);
getOutput.setInt(2, stock_count[0]);
opres[0] =  getOutput.executeQuery();
/* Do not close to retrieve result set, database engine will close
conn.close();
*/
	}
catch (SQLException se)
{
System.out.println("ERROR: SQLException");
se.printStackTrace();
System.out.println(se.getMessage());
conn.close();
return;
}
catch (Exception e)
{
System.out.println("ERROR: Exception");
e.printStackTrace();
System.out.println(e.getMessage());
System.exit(1);
}
}
}
}
set STOCKLEVEL.proc "create procedure stocklevel(IN st_w_id INT, IN st_d_id INT, IN threshold INT, OUT st_o_id INT, OUT stock_count INT) language java parameter style java reads sql data no transaction required external name \'STOCKLEVEL.SLEV\' library STOCKLEVEL dynamic result sets 1"
set present [ pwd ]
set dir [ finddirforstoredprocs ]
if { $dir eq "nodir" } {
error "No directory found to create stored procedures"
return
	} else {
if { $present eq $dir } {
	;
	} else {
cd $dir
	}
foreach java {NEWORDER DELIVERY PAYMENT ORDERSTATUS STOCKLEVEL} {
set data [ set $java ]
set filename $java.java
set classfile $java.class
set jarfile [ file join $dir $java.jar ]
set sqllib "create library $java file \'$jarfile\'"
set sqlproc [ set $java.proc ]
set fileId [ open $filename "w"]
puts -nonewline $fileId $data
close $fileId
eval exec [auto_execok javac] $filename
eval exec [auto_execok jar] [ list cvf $jarfile $classfile ]
if [ catch {set stmnt [ odbc prepare $sqllib ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to create library $jarfile"
error $message
} else {
$rs close
$stmnt close
     }
    }
if [ catch {set stmnt [ odbc prepare $sqlproc ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
puts -nonewline "Creating $java"
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to create procedure $java"
error $message
} else {
$rs close
$stmnt close
     }
    }
if { $copyremote } {
puts -nonewline "Copying $jarfile to $nodelist using pdcp"
catch { exec pdcp } msg
if { [ string match "*pcp requires source and dest filenames" $msg ] } {
eval exec [ auto_execok pdcp ] [ list -w [ list $nodelist ] $jarfile $jarfile ]
	} else {
error "command pdcp does not exist, install the pdsh package to copy remote"
	}
    } else {
puts "Library on local node only"
}
catch {file delete -force $filename}
catch {file delete -force $classfile}
   }
if { $present eq $dir } {
	;
	} else {
cd $present
	}
  }
return
}

proc UpdateStatistics { odbc schema } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "set schema trafodion.$schema"
set sql(2) "update statistics for table CUSTOMER on every column sample"
set sql(3) "update statistics for table DISTRICT on every column sample"
set sql(4) "update statistics for table HISTORY on every column sample"
set sql(5) "update statistics for table ITEM on every column sample"
set sql(6) "update statistics for table WAREHOUSE on every column sample"
set sql(7) "update statistics for table STOCK on every column sample"
set sql(8) "update statistics for table NEW_ORDER on every column sample"
set sql(9) "update statistics for table ORDERS on every column sample"
set sql(10) "update statistics for table ORDER_LINE on every column sample"
for { set i 1 } { $i <= 10 } { incr i } {
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
puts -nonewline "$i..."
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Update Statistics"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc CreateSchema { odbc schema } {
if [ catch {set stmnt [ odbc prepare "create schema trafodion.$schema" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Schema trafodion.$schema"
error $message
} else {
$rs close
$stmnt close
    }
 }
return
}

proc SetSchema { odbc schema } {
if [ catch {set stmnt [ odbc prepare "set schema trafodion.$schema" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema trafodion.$schema"
error $message
} else {
$rs close
$stmnt close
    }
 }
return
}

proc CreateTables { odbc schema } {
puts "CREATING TPCC TABLES"
set sql(1) "set schema trafodion.$schema"
set sql(2) "CREATE TABLE CUSTOMER (C_ID NUMERIC(5,0) NOT NULL NOT DROPPABLE, C_D_ID NUMERIC(2,0) NOT NULL NOT DROPPABLE, C_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM NUMERIC(12, 2), C_DISCOUNT NUMERIC(4,4), C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT NUMERIC(8,0), C_DATA VARCHAR(500), PRIMARY KEY (C_W_ID, C_D_ID, C_ID))"
set sql(3) "CREATE TABLE DISTRICT (D_ID NUMERIC(2,0) NOT NULL NOT DROPPABLE, D_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, D_YTD NUMERIC(12, 2), D_TAX NUMERIC(4,4), D_NEXT_O_ID NUMERIC, D_NAME VARCHAR(10), D_STREET_1 VARCHAR(20), D_STREET_2 VARCHAR(20), D_CITY VARCHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9), PRIMARY KEY (D_W_ID, D_ID))"
set sql(4) "CREATE TABLE HISTORY (H_C_ID NUMERIC, H_C_D_ID NUMERIC, H_C_W_ID NUMERIC, H_D_ID NUMERIC, H_W_ID NUMERIC, H_DATE TIMESTAMP, H_AMOUNT NUMERIC(6,2), H_DATA VARCHAR(24))"
set sql(5) "CREATE TABLE ITEM (I_ID NUMERIC(6,0) NOT NULL NOT DROPPABLE, I_IM_ID NUMERIC, I_NAME VARCHAR(24), I_PRICE NUMERIC(5,2), I_DATA VARCHAR(50), PRIMARY KEY (I_ID))"
set sql(6) "CREATE TABLE WAREHOUSE (W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, W_YTD NUMERIC(12, 2), W_TAX NUMERIC(4,4), W_NAME VARCHAR(10), W_STREET_1 VARCHAR(20), W_STREET_2 VARCHAR(20), W_CITY VARCHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9), PRIMARY KEY (W_ID))"
set sql(7) "CREATE TABLE STOCK (S_I_ID NUMERIC(6,0) NOT NULL NOT DROPPABLE, S_W_ID NUMERIC(4,0) NOT NULL NOT DROPPABLE, S_QUANTITY NUMERIC(6,0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMERIC(10, 0), S_ORDER_CNT NUMERIC(6,0), S_REMOTE_CNT NUMERIC(6,0), S_DATA VARCHAR(50), PRIMARY KEY (S_W_ID, S_I_ID))"
set sql(8) "CREATE TABLE NEW_ORDER (NO_W_ID NUMERIC NOT NULL NOT DROPPABLE, NO_D_ID NUMERIC NOT NULL NOT DROPPABLE, NO_O_ID NUMERIC NOT NULL NOT DROPPABLE, PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID))"
set sql(9) "CREATE TABLE ORDERS (O_ID NUMERIC NOT NULL NOT DROPPABLE, O_W_ID NUMERIC NOT NULL NOT DROPPABLE, O_D_ID NUMERIC NOT NULL NOT DROPPABLE, O_C_ID NUMERIC, O_CARRIER_ID NUMERIC DEFAULT NULL, O_OL_CNT NUMERIC, O_ALL_LOCAL NUMERIC, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_W_ID, O_D_ID, O_ID))"
set sql(10) "CREATE TABLE ORDER_LINE (OL_W_ID NUMERIC NOT NULL NOT DROPPABLE, OL_D_ID NUMERIC NOT NULL NOT DROPPABLE, OL_O_ID NUMERIC NOT NULL NOT DROPPABLE, OL_NUMBER NUMERIC NOT NULL NOT DROPPABLE, OL_I_ID NUMERIC, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT NUMERIC(6,2), OL_SUPPLY_W_ID NUMERIC, OL_QUANTITY NUMERIC, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER))"
for { set i 1 } { $i <= 10 } { incr i } {
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Table"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc CreateIndexes { odbc schema } {
puts "CREATING TPCC INDEXES"
set sql(1) "set schema trafodion.$schema"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_W_ID, C_D_ID, C_LAST, C_FIRST, C_ID)"
set sql(3) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
for { set i 1 } { $i <= 3 } { incr i } {
if { $i eq 2 } {
puts "Creating Index CUSTOMER_I2..."
	}
if { $i eq 3 } {
puts "Creating Index ORDERS_I2..."
	}
if [ catch {set stmnt [ odbc prepare $sql($i) ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Create Index"
error $message
} else {
$rs close
$stmnt close
     }
  }
}
return
}

proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}

proc SetLoadString { loadtype } {
if { $loadtype eq "upsert" } { 
	set insupsert "upsert using load" 
	} else {
	set insupsert "insert" 
	}
return $insupsert
}

proc MakeValueBinds { values count } {
set len [ llength [ tdbc::tokenize $values ]] 
set TokLst "VALUES ("
for {set i 1} {$i <= $count } {incr i } {
set tokcnt 1
foreach token [ tdbc::tokenize $values ] {
append TokLst $token "_" $i
if { $tokcnt < $len } { append TokLst ", "}
incr tokcnt
	}
if { $i < $count } { append TokLst "),(" }
}
append TokLst ")"
return $TokLst
}

proc Customer { odbc d_id w_id CUST_PER_DIST loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set bld_cnt 1
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt_cust [ odbc prepare "$insupsert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) [ MakeValueBinds {:c_id:c_d_id:c_w_id:c_first:c_middle:c_last:c_street_1:c_street_2:c_city:c_state:c_zip:c_phone:c_since:c_credit:c_credit_lim:c_discount:c_balance:c_data:c_ytd_payment:c_payment_cnt:c_delivery_cnt} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
if [ catch {set stmnt_hist [ odbc prepare "$insupsert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) [ MakeValueBinds {:h_c_id:h_c_d_id:h_c_w_id:h_w_id:h_d_id:h_date:h_amount:h_data} 100 ]"]} message ] {
puts "Failed to prepare statement"
error $message
        } 
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
lappend valdict_cust c_id_$bld_cnt $c_id c_d_id_$bld_cnt $c_d_id c_w_id_$bld_cnt $c_w_id c_first_$bld_cnt $c_first c_middle_$bld_cnt $c_middle c_last_$bld_cnt $c_last c_street_1_$bld_cnt [ lindex $c_add 0 ] c_street_2_$bld_cnt [ lindex $c_add 1 ] c_city_$bld_cnt [ lindex $c_add 2 ] c_state_$bld_cnt [ lindex $c_add 3 ] c_zip_$bld_cnt [ lindex $c_add 4 ] c_phone_$bld_cnt $c_phone c_since_$bld_cnt [ gettimestamp ] c_credit_$bld_cnt $c_credit c_credit_lim_$bld_cnt $c_credit_lim c_discount_$bld_cnt $c_discount c_balance_$bld_cnt $c_balance c_data_$bld_cnt $c_data c_ytd_payment_$bld_cnt 10.0 c_payment_cnt_$bld_cnt 1 c_delivery_cnt_$bld_cnt 0
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
lappend valdict_hist h_c_id_$bld_cnt $c_id h_c_d_id_$bld_cnt $c_d_id h_c_w_id_$bld_cnt $c_w_id h_w_id_$bld_cnt $c_w_id h_d_id_$bld_cnt $c_d_id h_date_$bld_cnt [ gettimestamp ] h_amount_$bld_cnt $h_amount h_data_$bld_cnt $h_data
incr bld_cnt
if { ![ expr {$c_id % 100} ] } {
if [catch {set rs_1 [ $stmnt_cust execute $valdict_cust ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
	$rs_1 close
        }
if [catch {set rs_2 [ $stmnt_hist execute $valdict_hist ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
	$rs_2 close
        }
	set bld_cnt 1
	unset valdict_cust
	unset valdict_hist
	}
       }
$stmnt_cust close
$stmnt_hist close
puts "Customer Done"
return
}

proc Orders { odbc d_id w_id MAXITEMS ORD_PER_DIST loadtype} {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt_ord [ odbc prepare "$insupsert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) [ MakeValueBinds {:o_id:o_c_id:o_d_id:o_w_id:o_entry_d:o_carrier_id:o_ol_cnt:o_all_local} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        }
if [ catch {set stmnt_new_ord [ odbc prepare "$insupsert into new_order (no_o_id, no_d_id, no_w_id) [ MakeValueBinds {:no_o_id:no_d_id:no_w_id} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
for {set olc 5} {$olc <= 15 } {incr olc } {
if [ catch {set stmnt_ord_lin_$olc [ odbc prepare "$insupsert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) [ MakeValueBinds {:ol_o_id:ol_d_id:ol_w_id:ol_number:ol_i_id:ol_supply_w_id:ol_quantity:ol_amount:ol_dist_info:ol_delivery_d} $olc ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
 }
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
#Note o_carrier_id is null so omitted below 
lappend valdict_ord o_id_$bld_cnt $o_id o_c_id_$bld_cnt $o_c_id o_d_id_$bld_cnt $o_d_id o_w_id_$bld_cnt $o_w_id o_entry_d_$bld_cnt [ gettimestamp ] o_ol_cnt_$bld_cnt $o_ol_cnt o_all_local_$bld_cnt 1
set e "no1"
lappend valdict_new_ord no_o_id_$bld_cnt $o_id no_d_id_$bld_cnt $o_d_id no_w_id_$bld_cnt $o_w_id
  } else {
  set e "o3"
lappend valdict_ord o_id_$bld_cnt $o_id o_c_id_$bld_cnt $o_c_id o_d_id_$bld_cnt $o_d_id o_w_id_$bld_cnt $o_w_id o_entry_d_$bld_cnt [gettimestamp ] o_carrier_id_$bld_cnt $o_carrier_id o_ol_cnt_$bld_cnt $o_ol_cnt o_all_local_$bld_cnt 1
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 00.00
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
#Note ol_delivery_d is null so omitted below
lappend valdict_line ol_o_id_$ol $o_id ol_d_id_$ol $o_d_id ol_w_id_$ol $o_w_id ol_number_$ol $ol ol_i_id_$ol $ol_i_id ol_supply_w_id_$ol $ol_supply_w_id ol_quantity_$ol $ol_quantity ol_amount_$ol $ol_amount ol_dist_info_$ol $ol_dist_info
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.00} ]
set e "ol2"
lappend valdict_line ol_o_id_$ol $o_id ol_d_id_$ol $o_d_id ol_w_id_$ol $o_w_id ol_number_$ol $ol ol_i_id_$ol $ol_i_id ol_supply_w_id_$ol $ol_supply_w_id ol_quantity_$ol $ol_quantity ol_amount_$ol $ol_amount ol_dist_info_$ol $ol_dist_info ol_delivery_d_$ol [ gettimestamp ]
	}
}
set stmnt stmnt_ord_lin_$o_ol_cnt
if [catch {set rs_3 [ [ set $stmnt ] execute $valdict_line ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs_3 close
	unset valdict_line
       }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
if [catch {set rs_1 [ $stmnt_ord execute $valdict_ord ]} message ] {
puts "Failed to execute statement"
error $message
	} else {
        $rs_1 close
        }
if { $o_id > 2100 } {
if [catch {set rs_2 [ $stmnt_new_ord execute $valdict_new_ord ]} message ] {
puts "Failed to execute statement"
error $message
} else {
       $rs_2 close
       }
      }
	set bld_cnt 1
	unset valdict_ord
	unset -nocomplain valdict_new_ord
			}
		}
	$stmnt_ord close
	$stmnt_new_ord close
	for {set olc 5} {$olc <= 15 } {incr olc } {
	set stmnt stmnt_ord_lin_$olc
	[ set $stmnt ] close
	}
	puts "Orders Done"
	return
}

proc OrdersforWindows { odbc d_id w_id MAXITEMS ORD_PER_DIST loadtype} {
#High performance Linux build fails on Windows
#Orders procedure duplicated in anticipation of being dropped when Linux proc above works on Windows
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Orders for D=$d_id W=$w_id"
set insupsert [ SetLoadString $loadtype ]
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
append o_val_list ($o_id, $o_c_id, $o_d_id, $o_w_id, CURRENT, null, $o_ol_cnt, 1)
set e "no1"
append no_val_list ($o_id, $o_d_id, $o_w_id)
  } else {
  set e "o3"
append o_val_list ($o_id, $o_c_id, $o_d_id, $o_w_id, CURRENT, $o_carrier_id, $o_ol_cnt, 1)
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 00.00
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', null)
if { $bld_cnt<= 49 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.00} ]
set e "ol2"
append ol_val_list ($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', CURRENT)
if { $bld_cnt<= 49 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 49 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 50} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
if [ catch {set stmnt [ odbc prepare "$insupsert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
if { $o_id > 2100 } {
if [ catch {set stmnt [ odbc prepare "$insupsert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
     }
if [ catch {set stmnt [ odbc prepare "$insupsert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { odbc MAXITEMS loadtype } {
puts "Start:[ clock format [ clock seconds ] ]"
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Item"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt [ odbc prepare "$insupsert into item (i_id, i_im_id, i_name, i_price, i_data) [ MakeValueBinds {:i_id:i_im_id:i_name:i_price:i_data} 100 ]" ]} message ] {
puts "Failed to prepare item statement"
error $message
        } 
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
lappend valdict i_id_$bld_cnt $i_id i_im_id_$bld_cnt $i_im_id i_name_$bld_cnt $i_name i_price_$bld_cnt $i_price i_data_$bld_cnt $i_data
incr bld_cnt
 if { ![ expr {$i_id % 100} ] } {
if [catch {set rs [ $stmnt execute $valdict ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
       }
	set bld_cnt 1
        unset valdict
	}
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	$stmnt close
	puts "Item done"
	return
	}

proc Stock { odbc w_id MAXITEMS loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
puts "Loading Stock Wid=$w_id"
set insupsert [ SetLoadString $loadtype ]
if [ catch {set stmnt [ odbc prepare "$insupsert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt)[ MakeValueBinds {:s_i_id:s_w_id:s_quantity:s_dist_01:s_dist_02:s_dist_03:s_dist_04:s_dist_05:s_dist_06:s_dist_07:s_dist_08:s_dist_09:s_dist_10:s_data:s_ytd:s_order_cnt:s_remote_cnt} 100 ]" ]} message ] {
puts "Failed to prepare statement"
error $message
        } 
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
lappend valdict s_i_id_$bld_cnt $s_i_id s_w_id_$bld_cnt $s_w_id s_quantity_$bld_cnt $s_quantity s_dist_01_$bld_cnt $s_dist_01 s_dist_02_$bld_cnt $s_dist_02 s_dist_03_$bld_cnt $s_dist_03 s_dist_04_$bld_cnt $s_dist_04 s_dist_05_$bld_cnt $s_dist_05 s_dist_06_$bld_cnt $s_dist_06 s_dist_07_$bld_cnt $s_dist_07 s_dist_08_$bld_cnt $s_dist_08 s_dist_09_$bld_cnt $s_dist_09 s_dist_10_$bld_cnt $s_dist_10 s_data_$bld_cnt $s_data s_ytd_$bld_cnt 0 s_order_cnt_$bld_cnt 0 s_remote_cnt_$bld_cnt 0
incr bld_cnt
      if { ![ expr {$s_i_id % 100} ] } {
if [catch {set rs [ $stmnt execute $valdict ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
       }
	set bld_cnt 1
	unset valdict
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	$stmnt close
	puts "Stock done"
	return
}

proc District { odbc w_id DIST_PER_WARE loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set insupsert [ SetLoadString $loadtype ]
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
if [ catch {set stmnt [ odbc prepare "$insupsert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ($d_id, $d_w_id, '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', $d_tax, $d_ytd, $d_next_o_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
     }
   }
	puts "District done"
	return
}

proc LoadWare { odbc ware_start count_ware MAXITEMS DIST_PER_WARE loadtype } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set insupsert [ SetLoadString $loadtype ]
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
if [ catch {set stmnt [ odbc prepare "$insupsert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ($w_id, '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', $w_tax, $w_ytd)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to execute statement"
error $message
} else {
	$rs close
	$stmnt close
       }
      }
puts "Start:[ clock format [ clock seconds ] ]"
	Stock odbc $w_id $MAXITEMS $loadtype
	District odbc $w_id $DIST_PER_WARE $loadtype
puts "End:[ clock format [ clock seconds ] ]"
      }
}

proc LoadCust { odbc ware_start count_ware CUST_PER_DIST DIST_PER_WARE loadtype } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer odbc $d_id $w_id $CUST_PER_DIST $loadtype
		}
	}
	return
}

proc LoadOrd { odbc ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE loadtype } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
        if {[string match windows $::tcl_platform(platform)]} {
	OrdersforWindows odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST $loadtype
			} else {
	Orders odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST $loadtype
			}
		}
	}
	return
}

proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
puts "WARNING:BUILD PERFORMANCE SIGNIFCANTLY LOWER ON WINDOWS, LINUX RECOMMENDED" 
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
	} else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
	}
return $connection
}

proc do_tpcc { dsn odbc_driver server port uid pwd count_ware schema num_threads loadtype load_data build_jsps nodelist copyremote } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if {[string match windows $::tcl_platform(platform)] && $odbc_driver eq "Trafodion"} {
puts "For Windows Client ODBC Driver Name is TRAF ODBC 1.0 or higher and not Trafodion"
	}
set server "TCP:$server/$port"
#force fixed schema of tpcc as stored procedures do
set schema tpcc
if { $build_jsps eq "false" && $load_data eq "false" } {
puts "You have chosen to neither load data or create JSPs"
puts "EXIT WITH NO ACTION TAKEN"
return
	}
#jsps 0 for create all, 1 for just jsps but no data, anything > 1 for date but no jsps
if { $build_jsps eq "true" && $load_data eq "true" } {
set jsps 0 } else {
if { $build_jsps eq "true" && $load_data eq "false" } {
set jsps 1 } else {
set jsps 2
		}
	    }
set connection [ connect_string $dsn $odbc_driver $server $uid $pwd ]
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
switch $myposition {
        1 {
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
                        }
tsv::set application load "WAIT"
                }
        }
        default {
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $schema ] SCHEMA"
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
if { $jsps eq 1 } {
if {[string match windows $::tcl_platform(platform)]} {
puts "Stored Procedure build chosen but cannot be done on Windows"
	} else {
puts "Creating Stored Procedures Only"
SetSchema odbc $schema
CreateStoredProcs odbc $schema $nodelist $copyremote
puts "Stored Procedures Only Complete"
	}
return
	} else {
CreateSchema odbc $schema
SetSchema odbc $schema
CreateTables odbc $schema
	}
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems odbc $MAXITEMS $loadtype
puts "Monitoring Workers..."
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
LoadItems odbc $MAXITEMS $loadtype
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
SetSchema odbc $schema
#Usually set autocommit off here
#odbc set autocommit off 
} 
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare odbc $mystart $myend $MAXITEMS $DIST_PER_WARE $loadtype
LoadCust odbc $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $loadtype
LoadOrd odbc $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $loadtype
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
odbc close
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
odbc close
#LogOff and reconnect due to Issue with COMMUNICATION LINK FAILURE. THE SERVER TIMED OUT OR DISAPPEARED occuring after a connection has been idle waiting for workers to complete. 
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
if { $jsps eq 0 } {
if {[string match windows $::tcl_platform(platform)]} {
puts "Cannot build stored procedures on Windows"
	} else {
SetSchema odbc $schema
CreateStoredProcs odbc $schema $nodelist $copyremote
		}
	}
SetSchema odbc $schema
CreateIndexes odbc $schema
UpdateStatistics odbc $schema
odbc close
	}
puts "End:[ clock format [ clock seconds ] ]"
puts "[ string toupper $schema ] SCHEMA COMPLETE"
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1805.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $trafodion_dsn $trafodion_odbc_driver $trafodion_server $trafodion_port $trafodion_userid $trafodion_password $trafodion_count_ware $trafodion_schema $trafodion_num_threads $trafodion_load_type $trafodion_load_data $trafodion_build_jsps {$trafodion_node_list} $trafodion_copy_remote"
	} else { return }
}

proc loadtraftpcc {} {
global trafodion_dsn trafodion_odbc_driver trafodion_server trafodion_port trafodion_userid trafodion_password trafodion_schema trafodion_total_iterations trafodion_raiseerror trafodion_keyandthink trafodion_driver _ED
if {  ![ info exists trafodion_dsn ] } { set trafodion_dsn "Default_DataSource" }
if {  ![ info exists trafodion_odbc_driver ] } { set trafodion_odbc_driver "Trafodion" }
if {  ![ info exists trafodion_server ] } { set trafodion_server "sandbox" }
if {  ![ info exists trafodion_port ] } { set trafodion_port "37800" }
if {  ![ info exists trafodion_userid ] } { set trafodion_userid "trafodion" }
if {  ![ info exists trafodion_password ] } { set trafodion_password "traf123" }
if {  ![ info exists trafodion_schema ] } { set trafodion_schema "tpcc" }
if {  ![ info exists trafodion_total_iterations ] } { set trafodion_total_iterations 1000000 }
if {  ![ info exists trafodion_raiseerror ] } { set trafodion_raiseerror "false" }
if {  ![ info exists trafodion_keyandthink ] } { set trafodion_keyandthink "false" }
if {  ![ info exists trafodion_driver ] } { set trafodion_driver "standard" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tdbc::odbc} \] { error \"Failed to load tdbc::odbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $trafodion_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$trafodion_raiseerror\" ;# Exit script on Trafodion error (true or false)
set KEYANDTHINK \"$trafodion_keyandthink\" ;# Time for user thinking and keying (true or false)
set odbc_driver \"$trafodion_odbc_driver\" ;# ODBC Driver default Trafodion for Linux and TRAF ODBC 1.0 for Windows
set dsn \"$trafodion_dsn\" ;# ODBC Datasource Name
set server \"TCP:$trafodion_server/$trafodion_port\" ;# Trafodion Server and Port in Trafodion format
set user \"$trafodion_userid\" ;# User ID for the Trafodion user
set password \"$trafodion_password\" ;# Password for the Trafodion user
set schema \"$trafodion_schema\" ;# Schema containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CONNECT STRING
proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
        }
return $connection
}
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { odbc neword_st no_w_id no_max_w_id RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set no_o_ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
#set as CURRENT in statement
if [catch { $neword_st foreach row {
puts -nonewline "$no_w_id $no_max_w_id $no_d_id $no_c_id $no_o_ol_cnt: "
puts "$row"
} } message ] {
puts "Failed to execute new order"
if { $RAISEERROR } {
error $message
	}
}
}
#PAYMENT
proc payment { odbc payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
set p_c_credit "GC"
set p_c_balance 0.00
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set p_c_last [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
#set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if [catch { $payment_st foreach row {
puts -nonewline "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $p_c_last $p_c_credit $p_c_balance: "
puts "$row"
} } message ] {
puts "Failed to execute payment"
if { $RAISEERROR } {
error $message
	}
}
}
#ORDER_STATUS
proc ostat { odbc ostat_st os_w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set os_d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set os_c_last [ randname $nrnd ]
set os_c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if [catch { $ostat_st foreach row {
puts -nonewline "$os_w_id $os_d_id $os_c_id $byname $os_c_last: "
puts "$row"
} } message ] {
puts "Failed to execute order status"
if { $RAISEERROR } {
error $message
	}
}
}
#DELIVERY
proc delivery { odbc delivery_st d_w_id RAISEERROR } {
set d_o_carrier_id [ RandomNumber 1 10 ]
if [catch { $delivery_st foreach row {
#Delivery uses print so no inline output
puts "$row"
} } message ] {
puts "Failed to execute delivery"
if { $RAISEERROR } {
error $message
	}
} else {
puts "$d_w_id $d_o_carrier_id"
	}
}
#STOCK LEVEL
proc slev { odbc slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
set st_w_id $w_id 
set st_d_id $stock_level_d_id 
if [catch { $slev_st foreach row {
puts -nonewline "$w_id $stock_level_d_id $threshold: "
puts "$row"
} } message ] {
puts "Failed to execute stock level"
if { $RAISEERROR } {
error $message
	}
}  
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
if [ catch {set slev_st [ odbc prepare "call STOCKLEVEL(:st_w_id,:st_d_id,:threshold,:st_o_id,:stock_count)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $slev_st
	}
   }
delivery_st {
if [ catch {set delivery_st [ odbc prepare "call DELIVERY(:d_w_id,:d_o_carrier_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $delivery_st
	}
   }
ostat_st {
if [ catch {set ostat_st [ odbc prepare "call ORDERSTATUS(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $ostat_st
	}
   }
payment_st {
if [ catch {set payment_st [ odbc prepare "call PAYMENT(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $payment_st
        }
   }
neword_st {
if [ catch {set neword_st [ odbc prepare "call NEWORDER(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $neword_st
        }
     }
  }
}
#RUN TPC-C
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
foreach st {neword_st payment_st slev_st delivery_st ostat_st} { set $st [ prep_statement odbc $st ] }
if [ catch {set stmnt [ odbc prepare "select max(w_id) from warehouse" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set w_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get max w_id"
error $message
} else {
$stmnt close
  }
}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
if [ catch {set stmnt [ odbc prepare "select max(d_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set d_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get Max d_id"
error $message
} else {
$stmnt close
  }
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword odbc $neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment odbc $payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery odbc $delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev odbc $slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat odbc $ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc close}
}

proc loadtimedtraftpcc {} {
global trafodion_dsn trafodion_odbc_driver trafodion_server trafodion_port trafodion_userid trafodion_password trafodion_schema trafodion_total_iterations trafodion_raiseerror trafodion_keyandthink trafodion_rampup trafodion_duration trafodion_driver opmode _ED
if {  ![ info exists trafodion_dsn ] } { set trafodion_dsn "Default_DataSource" }
if {  ![ info exists trafodion_odbc_driver ] } { set trafodion_odbc_driver "Trafodion" }
if {  ![ info exists trafodion_server ] } { set trafodion_server "sandbox" }
if {  ![ info exists trafodion_port ] } { set trafodion_port "37800" }
if {  ![ info exists trafodion_userid ] } { set trafodion_userid "trafodion" }
if {  ![ info exists trafodion_password ] } { set trafodion_password "traf123" }
if {  ![ info exists trafodion_schema ] } { set trafodion_schema "tpcc" }
if {  ![ info exists trafodion_total_iterations ] } { set trafodion_total_iterations 1000000 }
if {  ![ info exists trafodion_raiseerror ] } { set trafodion_raiseerror "false" }
if {  ![ info exists trafodion_keyandthink ] } { set trafodion_keyandthink "false" }
if {  ![ info exists trafodion_driver ] } { set trafodion_driver "timed" }
if {  ![ info exists trafodion_rampup ] } { set trafodion_rampup "2" }
if {  ![ info exists trafodion_duration ] } { set trafodion_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tdbc::odbc} \] { error \"Failed to load tdbc::odbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $trafodion_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$trafodion_raiseerror\" ;# Exit script on Trafodion error (true or false)
set KEYANDTHINK \"$trafodion_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $trafodion_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $trafodion_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set odbc_driver \"$trafodion_odbc_driver\" ;# ODBC Driver default Trafodion for Linux and TRAF ODBC 1.0 for Windows
set dsn \"$trafodion_dsn\" ;# ODBC Datasource Name
set server \"TCP:$trafodion_server/$trafodion_port\" ;# Trafodion Server and Port in Trafodion format
set user \"$trafodion_userid\" ;# User ID for the Trafodion user
set password \"$trafodion_password\" ;# Password for the Trafodion user
set schema \"$trafodion_schema\" ;# Schema containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }
if { [ chk_thread ] eq "FALSE" } {
error "Trafodion Timed Test Script must be run in Thread Enabled Interpreter"
}
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
set totalvirtualusers [ expr $totalvirtualusers - 1 ]
set myposition [ expr $myposition - 1 ]
        }
}
#CONNECT STRING
proc connect_string { dsn odbc_driver server uid pwd } {
        if {[string match windows $::tcl_platform(platform)]} {
set connection "Driver=$odbc_driver;DSN=$dsn;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
set connection "Driver=$odbc_driver;DSN=$dsn;UID=$uid;PWD=$pwd"
        }
return $connection
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
#No current statement for querying Trafodion transactions ie commits + rollbacks
set start_trans 0
if [ catch {set stmnt [ odbc prepare "select sum(d_next_o_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set start_nopm [dict get $row (EXPR)]
} } message ] {
puts "Failed to query district table"
error $message
} else {
$stmnt close
  }
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
#No current statement for querying Trafodion transactions ie commits + rollbacks
set end_trans 0
if [ catch {set stmnt [ odbc prepare "select sum(d_next_o_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set end_nopm [dict get $row (EXPR)]
} } message ] {
puts "Failed to query district table"
error $message
} else {
$stmnt close 
  }
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm Trafodion TPM at $nopm NOPM"
tsv::set application abort 1
if { $mode eq "Master" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
odbc close
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { odbc neword_st no_w_id no_max_w_id RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set no_o_ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
#set as CURRENT in statement
if [catch { $neword_st foreach row { ; } } message ] {
puts "Failed to execute new order"
if { $RAISEERROR } {
error $message
	}
}
}
#PAYMENT
proc payment { odbc payment_st p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
set p_c_credit "GC"
set p_c_balance 0.00
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set p_c_last [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
#set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
if [catch { $payment_st foreach row { ; } } message ] {
puts "Failed to execute payment"
if { $RAISEERROR } {
error $message
	}
}
}
#ORDER_STATUS
proc ostat { odbc ostat_st os_w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set os_d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set os_c_last [ randname $nrnd ]
set os_c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if [catch { $ostat_st foreach row { ; } } message ] {
puts "Failed to execute order status"
if { $RAISEERROR } {
error $message
	}
}
}
#DELIVERY
proc delivery { odbc delivery_st d_w_id RAISEERROR } {
set d_o_carrier_id [ RandomNumber 1 10 ]
if [catch { $delivery_st foreach row { ; } } message ] {
puts "Failed to execute delivery"
if { $RAISEERROR } {
error $message
	}
} else { ; }
}
#STOCK LEVEL
proc slev { odbc slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
set st_w_id $w_id 
set st_d_id $stock_level_d_id 
if [catch { $slev_st foreach row { ; } } message ] {
puts "Failed to execute stock level"
if { $RAISEERROR } {
error $message
	}
}  
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
if [ catch {set slev_st [ odbc prepare "call STOCKLEVEL(:st_w_id,:st_d_id,:threshold,:st_o_id,:stock_count)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $slev_st
	}
   }
delivery_st {
if [ catch {set delivery_st [ odbc prepare "call DELIVERY(:d_w_id,:d_o_carrier_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $delivery_st
	}
   }
ostat_st {
if [ catch {set ostat_st [ odbc prepare "call ORDERSTATUS(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id)" ]} message ] {
puts "Failed to prepare statement"
error $message
	} else {
return $ostat_st
	}
   }
payment_st {
if [ catch {set payment_st [ odbc prepare "call PAYMENT(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $payment_st
        }
   }
neword_st {
if [ catch {set neword_st [ odbc prepare "call NEWORDER(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,CURRENT)" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
return $neword_st
        }
     }
  }
}
#RUN TPC-C
set connection [ connect_string $dsn $odbc_driver $server $user $password ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
puts "Trafodion connected"
#odbc configure -encoding utf-16
   }
if [ catch {set stmnt [ odbc prepare "set schema tpcc" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch {set rs [ $stmnt execute ]} message ] {
puts "Failed to Set Schema $schema"
error $message
} else {
$rs close
$stmnt close
    }
}
foreach st {neword_st payment_st slev_st delivery_st ostat_st} { set $st [ prep_statement odbc $st ] }
if [ catch {set stmnt [ odbc prepare "select max(w_id) from warehouse" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set w_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get max w_id"
error $message
} else {
$stmnt close
  }
}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
if [ catch {set stmnt [ odbc prepare "select max(d_id) from district" ]} message ] {
puts "Failed to prepare statement"
error $message
        } else {
if [catch { $stmnt foreach row {
set d_id_input  [dict get $row (EXPR)]
} } message ] {
puts "Failed to get Max d_id"
error $message
} else {
$stmnt close
  }
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword odbc $neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment odbc $payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery odbc $delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev odbc $slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat odbc $ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc close
}
}}
}

proc shared_tpcc_functions { tpccfunc } {
switch $tpccfunc {
allwarehouse {
#set additional text for all warehouses
set allwt(1) {set allwarehouses "true";# Use all warehouses to increase I/O
}
set allwt(2) {#2.4.1.1 does not apply when allwarehouses is true 
if { $allwarehouses == "true" } {
set loadUserCount [expr $totalvirtualusers - 1]
set myWarehouses {}
lappend myWarehouses $myposition
set addMore 1
while {$addMore > 0} {
set wh [expr $myposition + ($addMore * $loadUserCount)]
if {$wh > $w_id_input || $wh eq 1} {
set addMore 0
} else {
lappend myWarehouses $wh
set addMore [expr $addMore + 1]
}}
set myWhCount [llength $myWarehouses]
}
}
set allwt(3) {if { $allwarehouses == "true" } {
set w_id [lindex $myWarehouses [expr [RandomNumber 1 $myWhCount] -1]]
}
}
#search for insert points and insert functions
set allwi(1) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#EDITABLE OPTIONS##################################################" end ] 
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(1) $allwt(1)
set allwi(2) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "#2.4.1.1" $allwi(1) ] 
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(2) $allwt(2)
set allwi(3) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "set choice" $allwi(2) ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(3) $allwt(3)
   }
timeprofile {
#set additional text for all warehouses
set timept(1) {set timeprofile "true";# Output virtual user response times
}
set timept(2) {if {$timeprofile eq "true" && $myposition eq 2} {package require etprof}
}
set timept(3) {if {$timeprofile eq "true" && $myposition eq 2} {::etprof::printLiveInfo}
}
#search for insert points and insert functions
set timepi(1) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#EDITABLE OPTIONS##################################################" end ] 
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(1) $timept(1)
set timepi(2) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "default \{" end ] 
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(2)+1l $timept(2)
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end-2l $timept(3)
  }
 }
}
