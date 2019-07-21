USE employees;

-- 41. 构造一个触发器audit_log，在向employees_test表中插入一条数据的时候，触发插入相关的数据到audit中
-- 这是题目所给的前提
CREATE TABLE employees_test(
	ID INT PRIMARY KEY NOT NULL,
	NAME TEXT NOT NULL,
	AGE INT NOT NULL,
	ADDRESS CHAR(50),
	SALARY REAL
);

CREATE TABLE audit(
	EMP_no INT NOT NULL,
	NAME TEXT NOT NULL
);
-- 查看表结构
DESC employees_test;
DESC audit;
-- 触发器trigger的建立
CREATE TRIGGER audit_log
AFTER INSERT
ON employees_test FOR EACH ROW
INSERT INTO audit VALUES(NEW.ID, NEW.NAME);

-- 又是dbeaver客户端的锅 不支持delimiter语法。。。
-- 以下程序在命令行是可以执行的
-- DELIMITER $$
-- CREATE TRIGGER audit_log 
-- AFTER INSERT ON employees_test FOR EACH ROW
-- BEGIN
--     INSERT INTO audit VALUES(NEW.ID, NEW.NAME);
-- END$$
-- DELIMITER ;

-- 显示触发器内容
SHOW CREATE TRIGGER audit_log;
-- 显示表内容
SELECT * FROM employees_test;
SELECT * FROM audit;
-- 测试 触发器是否生效 在给test表插入数据后，audit表也获得数据
INSERT INTO employees_test
VALUES(2, 'Mary', 22, 'Beijing, China', 56712);
-- 删除触发器
DROP TRIGGER audit_log;


-- 42. 删除emp_no重复的记录，只保留最小的id对应的记录。  
-- 这是题目所给的前提
CREATE TABLE IF NOT EXISTS titles_test (
	id int(11) not null primary key,
	emp_no int(11) NOT NULL,
	title varchar(50) NOT NULL,
	from_date date NOT NULL,
	to_date date DEFAULT NULL);

INSERT INTO titles_test 
VALUES
('1', '10001', 'Senior Engineer', '1986-06-26', '9999-01-01'),
('2', '10002', 'Staff', '1996-08-03', '9999-01-01'),
('3', '10003', 'Senior Engineer', '1995-12-03', '9999-01-01'),
('4', '10004', 'Senior Engineer', '1995-12-03', '9999-01-01'),
('5', '10001', 'Senior Engineer', '1986-06-26', '9999-01-01'),
('6', '10002', 'Staff', '1996-08-03', '9999-01-01'),
('7', '10003', 'Senior Engineer', '1995-12-03', '9999-01-01');

-- 备份/恢复 tt为备份 titles_test为被操作表
CREATE TABLE IF NOT EXISTS tt AS SELECT * FROM titles_test;

-- 如何恢复 先删除数据 再导入数据
DELETE FROM titles_test;
-- CREATE TABLE IF NOT EXISTS titles_test AS SELECT * FROM tt;
INSERT INTO titles_test SELECT * FROM tt;

-- 查看表数据
SELECT * FROM titles_test;
SELECT * FROM tt;

-- 删除表格
DROP TABLE tt;
DROP TABLE titles_test;

-- 删除重复emp_no 保留最小id
-- DELETE FROM titles_test 
-- WHERE id NOT IN (
-- 	SELECT MIN(id) FROM titles_test GROUP BY emp_no
-- );
-- You can't specify target table 'titles_test' for update in FROM clause
-- 不允许在删除条件内 使用要处理的表

-- 带条件的删除操作 删除重复emp_no 保留最小id
-- 注意：delete 的where语句内不能直接出现正在进行操作的数据表
-- 另外再套一层查询就可以了
DELETE FROM titles_test 
WHERE id NOT IN (
	SELECT id FROM (
		SELECT MIN(id) AS id FROM titles_test GROUP BY emp_no
	) AS tmp_t
);


-- 43. 将所有to_date为9999-01-01的全部更新为NULL,且 from_date更新为2001-01-01。
-- 此处前置条件使用上一题

-- 如何恢复 先删除数据 再导入数据
DELETE FROM titles_test;
INSERT INTO titles_test SELECT * FROM tt;

-- 为验证条件 额外插入to_date不为9999-01-01的数据
INSERT INTO titles_test 
VALUES
('8', '10001', 'Senior Engineer', '1986-06-26', '1999-01-01');
-- 查看表格内容
SELECT * FROM titles_test;
DESC titles_test;

-- 更新数据 UPDATE
-- to_date, from_date 同时更新 绑定
UPDATE titles_test 
SET to_date=NULL, from_date='2001-01-01'
WHERE to_date='9999-01-01';

-- 更新数据 
-- 使用case when 使得to_date有选择更新 from_date一定更新
UPDATE titles_test
SET to_date=(
	CASE to_date
		WHEN '9999-01-01' THEN NULL
		ELSE to_date
	END
), from_date='2001-01-01';


-- 44. 将id=5以及emp_no=10001的行数据替换成id=5以及emp_no=10005,其他数据保持不变，使用replace实现。
-- 此处前置条件使用上一题

-- 如何恢复 先删除数据 再导入数据
DELETE FROM titles_test;
INSERT INTO titles_test SELECT * FROM tt;
SELECT * FROM titles_test;
DESC titles_test;

SELECT * FROM titles_test WHERE id=5;
-- 使用replace更新数据 直接全字段更新
REPLACE INTO titles_test
VALUES('5', '10005', 'Senior Engineer', '1986-06-26', '9999-01-01');
-- 使用replace函数更新数据 选择字段更新
UPDATE titles_test
SET emp_no=REPLACE(emp_no, 10001, 10005)
WHERE id=5;

-- 使用update更新
UPDATE titles_test
SET emp_no=10001
WHERE id=5;


-- 45. 将titles_test表名修改为titles_2017。
-- 此处前置条件使用上一题

-- 如何恢复 先删除数据 再导入数据
DELETE FROM titles_test;
INSERT INTO titles_test SELECT * FROM tt;
SELECT * FROM titles_test;
DESC titles_test;

-- 修改表名
ALTER TABLE titles_test RENAME titles_2019;
ALTER TABLE titles_2019 RENAME TO titles_test;

DESC titles_2019;
SELECT * FROM titles_2019;


-- 46. 在audit表上创建外键约束，其emp_no对应employees_test表的主键id。
-- 此处前置条件使用以前
DESC audit;
DESC employees_test;

-- 添加外键约束
ALTER TABLE audit ADD FOREIGN KEY (emp_no) REFERENCES employees_test(id);

-- 查看添加外键是否成功
SHOW CREATE TABLE audit;


-- 47. 如何获取emp_v和employees有相同的数据？
-- 
-- 存在如下的视图：
-- create view emp_v as select * from employees where emp_no >10005;
-- CREATE TABLE `employees` (
-- `emp_no` int(11) NOT NULL,
-- `birth_date` date NOT NULL,
-- `first_name` varchar(14) NOT NULL,
-- `last_name` varchar(16) NOT NULL,
-- `gender` char(1) NOT NULL,
-- `hire_date` date NOT NULL,
-- PRIMARY KEY (`emp_no`));
CREATE VIEW emp_v AS SELECT * FROM employees WHERE emp_no >10005;

DESC emp_v;
DESC employees;

-- 最直观的 emp_v只是在employees的基础上生成的
SELECT * FROM emp_v;

-- 使用where
SELECT em.*
FROM employees AS em, emp_v AS ev 
WHERE em.emp_no=ev.emp_no;

-- 使用连接 找交集
SELECT em.*
FROM employees AS em 
INNER JOIN emp_v AS ev 
ON em.emp_no=ev.emp_no;


-- 48. 将所有获取奖金的员工当前的薪水增加10%。
-- 创建奖金表 emp_bonus
CREATE TABLE emp_bonus(
	emp_no int NOT NULL,
	recevied datetime NOT NULL,
	btype smallint NOT NULL
);

-- 薪水表使用示例数据库的
-- CREATE TABLE salaries (
-- 	emp_no int(11) NOT NULL,
-- 	salary int(11) NOT NULL,
-- 	from_date date NOT NULL,
-- 	to_date date NOT NULL, 
-- 	PRIMARY KEY (emp_no,from_date)
-- );

DESC emp_bonus;
SELECT * FROM emp_bonus;
DELETE FROM emp_bonus;
DESC salaries;

-- 创建一份数据表 取个巧 导入数据量小一些
-- CREATE TABLE IF NOT EXISTS salaries_test AS SELECT * FROM salaries WHERE emp_no < 20000;
INSERT INTO salaries_test SELECT * FROM salaries WHERE emp_no < 20000;
DELETE FROM salaries_test;
SELECT * FROM salaries_test;

-- 自建相关数据 获得奖金的员工信息
-- 将salaries_test表的员工编号小于10050且当前还在公司的员工放入奖金表内 并设置btype=3
INSERT INTO emp_bonus 
SELECT emp_no, from_date, 3
FROM salaries_test
WHERE emp_no < 10050 AND to_date='9999-01-01';

-- 借助其他表，更新薪水表数据 获得奖金的员工 薪水有变化
UPDATE salaries_test
SET salary = salary*1.1
WHERE emp_no IN (
	SELECT emp_no FROM emp_bonus	
) AND to_date='9999-01-01';

-- 对比查看
SELECT st.emp_no, st.salary, s.emp_no, s.salary, st.from_date, s.from_date
FROM salaries_test AS st, salaries AS s 
WHERE st.emp_no=s.emp_no AND st.emp_no < 10055 AND st.from_date=s.from_date
-- 	以上语句可以看出 只是在当前进行薪水修改
	AND st.to_date='9999-01-01' AND s.to_date='9999-01-01';
-- 这里看出只有emp_no < 10050才有加薪
-- 结果表明 变化是生效的

-- 上一更新方法是有瑕疵的
UPDATE salaries_test
SET salary = salary*1.1
WHERE emp_no IN (
	-- 关键在这里 emp_bonus内的员工是有可能不存在薪水表内
	SELECT s.emp_no FROM emp_bonus AS eb 
	INNER JOIN salaries_test AS s 
	-- 	注意加上当前条件 不然emp_no会出现重复的
	ON eb.emp_no=s.emp_no AND s.to_date='9999-01-01'
) AND to_date='9999-01-01';


-- 49. 针对库中的所有表生成select count(*)对应的SQL语句
-- 难点在于获得库内所有表的名称

-- 通过information_schema.TABLES获得所有数据库的表名，指定获取哪个数据库的表名
SELECT table_name FROM information_schema.TABLES WHERE TABLE_SCHEMA='employees';
-- 字符串拼接
SELECT CONCAT('SELECT COUNT(*) FROM ', table_name, ';') AS cnts FROM information_schema.TABLES WHERE TABLE_SCHEMA='employees';

-- show 列举数据库表名 可以指定数据库名称
SHOW tables FROM sakila;


-- 50. 将employees表中的所有员工的last_name和first_name通过"'"连接起来
-- 简单的字符串拼接
SELECT CONCAT(last_name, "'", first_name)
FROM employees;


-- 51. 查找字符串'10,A,B' 中逗号','出现的次数cnt。
-- 除去','之前字符长度
SELECT LENGTH('10,A,B') AS length_str;
-- 这是除去','之后字符
SELECT REPLACE('10,A,B', ',','') AS only_str;
-- 除去','之后字符长度
SELECT LENGTH(REPLACE('10,A,B', ',','')) AS length_only_str;
-- 逗号出现次数
SELECT (LENGTH('10,A,B') - LENGTH(REPLACE('10,A,B', ',',''))) AS cnt;


-- 52. 获取Employees中的first_name，查询按照first_name最后两个字母，按照升序进行排列
-- 按照first_name升序排序
SELECT DISTINCT first_name
FROM employees
ORDER BY first_name;

-- 使用RIGHT(s,n)函数 获取first_name最后两个字母 并以此进行排序
SELECT DISTINCT first_name
FROM employees
ORDER BY RIGHT(first_name, 2);

-- 使用substr(s,start,len)函数 截取first_name最后两个字母 并以此排序
SELECT DISTINCT first_name
FROM employees
ORDER BY SUBSTR(first_name, LENGTH(first_name)-1, 2);


-- 53. 按照dept_no进行汇总，属于同一个部门的emp_no按照逗号进行连接，结果给出dept_no以及连接出的结果employees
-- group_concat()函数的基本使用
SELECT dept_no, group_concat(emp_no) AS employees
FROM dept_emp
GROUP BY dept_no


-- 54. 查找排除当前最大、最小salary之后的员工的平均工资avg_salary。
-- 选出最大、最小薪水 再排除
SELECT AVG(salary) AS avg_salary
FROM salaries AS s, (
	SELECT MAX(salary) AS max_sal, MIN(salary) AS min_sal  FROM salaries
) AS ms
WHERE to_date='9999-01-01' AND s.salary != ms.max_sal AND s.salary != ms.min_sal;
-- avg_salary|72012.0159|	排除后的结果
-- avg_salary|72012.2359|	没有排除最值的结果

-- 以下方法更严谨 
-- 选取最值时 是在选择当前的薪水 而不是全局 
-- 但过不了OJ审核。。。
SELECT AVG(salary) AS avg_salary
FROM salaries AS s, (
	SELECT MAX(salary) AS max_sal, MIN(salary) AS min_sal  
    FROM salaries
    WHERE to_date='9999-01-01'
) AS ms
WHERE to_date='9999-01-01' AND s.salary != ms.max_sal AND s.salary != ms.min_sal;
-- avg_salary|72012.0159| 事实上结果一样


-- 55. 分页查询employees表，每5行一页，返回第2页的数据
-- 使用limit来实现分页
-- 第一页 以5行为一页
SELECT * FROM employees LIMIT (1-1)*5,5;
-- 第二页
SELECT * FROM employees LIMIT (2-1)*5,5;


-- 56. 获取所有员工的emp_no、部门编号dept_no以及对应的bonus类型btype和received，没有分配具体的员工不显示
DESC emp_bonus;
SELECT * FROM emp_bonus;
-- 因为没有分配的员工不显示 所以员工表只取dept_emp就行
-- 注意emp_bonus 以前所建立的表 
SELECT de.emp_no, de.dept_no, eb.btype, eb.recevied
FROM dept_emp AS de
LEFT JOIN emp_bonus AS eb
ON de.emp_no=eb.emp_no;


-- 57. 使用含有关键字exists查找未分配具体部门的员工的所有信息。
-- exists()就类似一个函数 
-- 输入de.emp_no 输出是否存在'e.emp_no=de.emp_no'等式成立 返回T/F
SELECT *
FROM employees AS e
WHERE NOT EXISTS (
	SELECT * FROM dept_emp AS de WHERE e.emp_no=de.emp_no
);
-- 上面的结果为空 表示所有员工都分配到了部门


-- 58. 获取employees中的行数据，且这些行也存在于emp_v中。注意不能使用intersect关键字。
-- 与第47题一样
-- 最直观的 emp_v只是在employees的基础上生成的
SELECT * FROM emp_v;

-- 使用where
SELECT em.*
FROM employees AS em, emp_v AS ev 
WHERE em.emp_no=ev.emp_no;

-- 使用连接 找交集
SELECT em.*
FROM employees AS em 
INNER JOIN emp_v AS ev 
ON em.emp_no=ev.emp_no;

-- 使用IN
SELECT * 
FROM employees 
WHERE emp_no IN (
	SELECT emp_no FROM emp_v
);


-- 59. 获取有奖金的员工相关信息。给出emp_no、first_name、last_name、奖金类型btype、对应的当前薪水情况salary以及奖金金额bonus。 
-- bonus类型
-- 	btype为1 其奖金为薪水salary的10%，
-- 	btype为2 其奖金为薪水的20%，
-- 	其他类型均为薪水的30%。

-- 修改emp_bonus表的btype 使用case when 来分类赋值
SELECT * FROM emp_bonus;
UPDATE emp_bonus
SET btype = (
	CASE 
		WHEN emp_no < 10011 THEN 3
		WHEN emp_no < 10026 THEN 2
		ELSE 1
	END
);

-- 获奖员工信息 在使用btype时，除于10.0 
-- 注意要除以10.0，如果除以10的话，结果的小数位会被舍去
SELECT e.emp_no, e.first_name, e.last_name, eb.btype, s.salary, (s.salary*eb.btype/10.0) AS bonus
FROM employees AS e 
INNER JOIN emp_bonus AS eb
ON e.emp_no=eb.emp_no
INNER JOIN salaries AS s 
ON eb.emp_no=s.emp_no AND s.to_date='9999-01-01';

-- 通过case when使用btype
SELECT e.emp_no, e.first_name, e.last_name, eb.btype, s.salary, (
	CASE eb.btype
		WHEN 1 THEN s.salary*0.1
		WHEN 2 THEN s.salary*0.2
		ELSE s.salary*0.3
	END) AS bonus
FROM employees AS e 
INNER JOIN emp_bonus AS eb
ON e.emp_no=eb.emp_no
INNER JOIN salaries AS s 
ON eb.emp_no=s.emp_no AND s.to_date='9999-01-01';


-- 60. 按照salary的累计和running_total，其中running_total为前两个员工的salary累计和，其他以此类推。 
-- 具体结果如下Demo展示。
-- 输出格式:
-- |emp_no |salary  |running_total|
-- |10001  |88958	|88958|
-- |10002  |72527	|161485|
-- |10003  |43311	|204796|

-- 使用小数据量进行测试
SELECT * FROM salaries_test;	-- 2,844,04 --> 94,912

-- 通过group by定位当前计算的emp_no 分组内容为比其emp_no小的员工 然后进行累加
-- 49.581s (+3ms) salaries_test
SELECT s1.emp_no, s1.salary, SUM(s2.salary) AS running_total 
FROM salaries_test AS s1, salaries_test AS s2
WHERE s1.to_date='9999-01-01' AND s2.to_date='9999-01-01'
AND s2.emp_no <= s1.emp_no
GROUP BY s1.emp_no, s1.salary;

-- 使用子查询 更加直观
-- 15.946s (+2ms) salaries_test
SELECT s1.emp_no, s1.salary, 
	(SELECT SUM(s2.salary) 
	FROM salaries_test AS s2 
	WHERE s2.emp_no <= s1.emp_no AND s2.to_date = '9999-01-01') AS running_total 
FROM salaries_test AS s1 
WHERE s1.to_date = '9999-01-01' 
ORDER BY s1.emp_no;

-- 使用@persum作为临时变量 存储上一次累加的薪水总额
-- 9ms (+5ms) salaries
SELECT s.emp_no, s.salary, (@persum:=@persum + s.salary) AS running_total
FROM salaries AS s, (SELECT @persum:=0) AS ps
WHERE s.to_date='9999-01-01'
ORDER BY s.emp_no;


-- 61. 对于employees表中，给出奇数行的first_name
SELECT * FROM employees_test;
-- 此处使用小数据量的进行测试 employees --> employees_sample
CREATE TABLE IF NOT EXISTS employees_sample SELECT * FROM employees WHERE emp_no < 10500;

-- 获取排名为奇数的first_name
SELECT e1.first_name 
FROM (
	-- 得到每个first_name和它的排名	
	SELECT e2.first_name, (
		-- 对每个first_name进行排序编号 计数有多少排在它前面的	
		SELECT COUNT(*) 
    	FROM employees_sample AS e3 
     	WHERE e3.first_name <= e2.first_name) AS rowid 
     FROM employees_sample AS e2) AS e1
WHERE e1.rowid % 2 = 1;

-- 在where 直接判断计数是否为奇数 
SELECT eo.first_name
FROM employees_sample AS eo
WHERE (
	-- 此处在计数eo.first_name的排名
	SELECT COUNT(*)
	FROM employees_sample AS ei
	WHERE ei.first_name <= eo.first_name
) % 2 = 1;
