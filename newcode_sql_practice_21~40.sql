
USE employees;
-- 21. 查找所有员工自入职以来的薪水涨幅情况，给出员工编号emp_no以及其对应的薪水涨幅growth，并按照growth进行升序
-- 通过分组MAX,找出员工在公司的最后一天 
SELECT emp_no, MAX(to_date) FROM salaries GROUP BY emp_no;
-- 通过分组MIN,找出员工入职第一天 
SELECT emp_no, MIN(to_date) FROM salaries GROUP BY emp_no;
-- 员工最后一天的薪水情况
SELECT s.emp_no, s.salary, max_d.to_date FROM 
(SELECT emp_no, MAX(to_date) AS to_date FROM salaries GROUP BY emp_no) AS max_d
LEFT JOIN salaries AS s 
ON s.emp_no=max_d.emp_no AND s.to_date=max_d.to_date;
-- 员工最后一天薪水 - 入职第一天(调用员工表employees的入职时间hire_date)的薪水
SELECT ma.emp_no, (ma.salary-mi.salary) AS growth
FROM (
	SELECT s.emp_no, s.salary, max_d.to_date FROM 
	(SELECT emp_no, MAX(to_date) AS to_date FROM salaries GROUP BY emp_no) AS max_d
	LEFT JOIN salaries AS s 
	ON s.emp_no=max_d.emp_no AND s.to_date=max_d.to_date
) AS ma INNER JOIN (
	SELECT s.emp_no, s.salary FROM 
	employees AS e
	LEFT JOIN salaries AS s 
	ON s.emp_no=e.emp_no AND s.from_date=e.hire_date
) AS mi
ON ma.emp_no=mi.emp_no ORDER BY growth;

-- 通过连接员工表employees和薪水表salaries定位每一位员工
SELECT ma.emp_no, (ma.salary-mi.salary) AS growth
FROM (
    -- 这里有个坑,题目没说是入职到*当前*(to_date='9999-01-01')的薪水情况
    -- 我之前是使用分组group by找到最大to_date来计算的,但没法通过
	SELECT s.emp_no, s.salary, s.to_date 
	FROM employees AS e
	LEFT JOIN salaries AS s 
	ON s.emp_no=e.emp_no AND s.to_date='9999-01-01'
) AS ma INNER JOIN (
	SELECT s.emp_no, s.salary 
	FROM employees AS e
	LEFT JOIN salaries AS s 
	ON s.emp_no=e.emp_no AND s.from_date=e.hire_date
) AS mi
ON ma.emp_no=mi.emp_no ORDER BY growth;


-- 22. 统计各个部门对应员工涨幅的次数总和，给出部门编码dept_no、部门名称dept_name以及次数sum
-- 首先,找到每位员工的涨幅次数 即to_date/from_date的个数
SELECT emp_no, COUNT(from_date) AS `time` FROM salaries GROUP BY emp_no;
-- 再使用部门员工表dept_emp连接员工涨幅表 得到部门编号和每个部门员工涨幅值sum_time
SELECT de.dept_no, SUM(es.`time`) AS sum_time
FROM dept_emp AS de 
LEFT JOIN (
	SELECT emp_no, COUNT(from_date) AS `time` 
	FROM salaries GROUP BY emp_no) AS es
ON de.emp_no=es.emp_no
GROUP BY de.dept_no;
-- 最后连接部门表department 显示部门名称dept_name
SELECT dt.dept_no, ds.dept_name, dt.sum_time AS `sum`
FROM departments AS ds 
INNER JOIN (
	SELECT de.dept_no, SUM(es.`time`) AS sum_time
	FROM dept_emp AS de 
	LEFT JOIN (
		SELECT emp_no, COUNT(from_date) AS `time` 
		FROM salaries GROUP BY emp_no) AS es
	ON de.emp_no=es.emp_no
	GROUP BY de.dept_no) AS dt
ON ds.dept_no=dt.dept_no
ORDER BY dt.dept_no;

-- 符合实际需求的一份解答
select d.dept_no, d.dept_name,
    (select
         sum((select
                 sum((select
                     case
                         # 记录数为0说明是第一条记录（原来的答案里有这一条，测试后发现加上去答案和预期不符）
                         # when count(*) = 0 then 0
                         # 最近一次工资变化比当前工资低判定为涨工资
                         when 
                            s0.salary < s.salary then 1
                         # 其他情况判定为不是涨工资
                         else 0 
                         end
                     # 查询最近一次工资变化情况
                     from salaries s0 
                     where s0.emp_no = s.emp_no and s0.to_date < s.to_date 
                     order by s0.to_date desc limit 1))
             # 查询出每个成员的每次工资变化情况
             from salaries s where s.emp_no = de.emp_no))
     # 查询出部门中的每个成员
     from dept_emp de where de.dept_no = d.dept_no) as `sum`
from departments d;


-- 23. 对所有员工的当前(to_date='9999-01-01')薪水按照salary进行按照1-N的排名，相同salary并列且按照emp_no升序排列
SELECT (DISTINCT s.salary), (@id:=@id+1) AS `rank`
FROM salaries AS s,
	(SELECT @id:=0) AS it
WHERE s.to_date='9999-01-01'
ORDER BY s.salary DESC;
-- 首先,找到薪水排行表
SELECT DISTINCT s.salary
FROM salaries AS s
WHERE s.to_date='9999-01-01'
ORDER BY s.salary DESC;
-- 其次,给薪水排行表标号
SELECT sa.salary, (@id:=@id+1) AS `rank`
FROM (SELECT @id:=0) AS it,(
	SELECT DISTINCT s.salary
	FROM salaries AS s
	WHERE s.to_date='9999-01-01'
	ORDER BY s.salary DESC) AS sa;
-- 通过薪水排行去获取员工编号emp_no
SELECT st.emp_no, ra.salary, ra.`rank`
FROM (
	SELECT sa.salary, (@id:=@id+1) AS `rank`
	FROM (SELECT @id:=0) AS it,(
		SELECT DISTINCT s.salary
		FROM salaries AS s
		WHERE s.to_date='9999-01-01'
		ORDER BY s.salary DESC) AS sa ) AS ra
LEFT JOIN (
	SELECT emp_no, salary 
	FROM salaries AS s
	WHERE s.to_date='9999-01-01') AS st
ON st.salary=ra.salary
ORDER BY ra.salary DESC, st.emp_no ASC;

--  以上方法失效了, 可能是不支持@id的自增操作
--  先求出薪水排行表(使用了group by去重)
SELECT s.emp_no, MAX(s.salary) AS sal
FROM salaries AS s
WHERE s.to_date='9999-01-01'
GROUP BY s.emp_no
ORDER BY sal DESC;
-- 通过排行表的薪水数值,其大于薪水表salaries的salary计数,即为其排名
-- 计算所有符合条件,且大于其薪水的 计数count得到排名
-- 跑了将近600s, 还没求出结果...放弃(并且审核系统不予通过...)
SELECT sa.emp_no, sa.sal AS salary, COUNT(DISTINCT a.salary) AS `rank`
FROM (
	SELECT s.emp_no, MAX(s.salary) AS sal
	FROM salaries AS s
	WHERE s.to_date='9999-01-01'
	GROUP BY s.emp_no
	ORDER BY sal DESC) AS sa, salaries AS a
WHERE a.to_date='9999-01-01' AND sa.sal < a.salary
GROUP BY salary DESC, sa.emp_no;
-- 语法没错, 但是耗时过长,没有看到结果...
SELECT so.emp_no, MAX(so.salary) AS sal, 
	(SELECT COUNT(DISTINCT si.salary) 
	FROM salaries AS si 
	WHERE si.to_date='9999-01-01' AND si.salary < MAX(so.salary))
FROM salaries AS so
WHERE so.to_date='9999-01-01'
GROUP BY so.emp_no
ORDER BY sal DESC, so.emp_no ASC;

-- 在to_date='9999-01-01'的前提下
-- 先从salaries选出一个薪水值,对所有薪水值大于该值的进行计数+1,将该计数称为排名
-- +1是因为第一名没有比他大的,计数为0,但排名需要为1
SELECT so.emp_no, so.salary,
	(SELECT COUNT(DISTINCT si.salary) 
	FROM salaries AS si 
	WHERE si.to_date='9999-01-01' AND si.salary > so.salary)+1 AS `rank`
FROM salaries AS so
WHERE so.to_date='9999-01-01'
ORDER BY `rank`, emp_no;
-- 以上600s多都无法查询出结果...


-- 24. 获取所有非manager员工当前的薪水情况，给出dept_no、emp_no以及salary 
-- 考察JOIN的用法或者NOT IN语法
-- 使用LEFT JOIN语法
-- 使用LEFT JOIN 右表为NULL即表示其记录为左边独有 8ms
SELECT de.dept_no, de.emp_no, sa.salary
FROM salaries AS sa
JOIN dept_emp AS de ON de.emp_no = sa.emp_no
LEFT JOIN dept_manager AS dm ON dm.emp_no = de.emp_no
WHERE dm.emp_no IS NULL
AND sa.to_date='9999-01-01';
-- 使用NOT IN 10ms
SELECT de.dept_no, de.emp_no, s.salary
FROM salaries AS s 
INNER JOIN dept_emp AS de
ON s.emp_no=de.emp_no
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
AND de.emp_no NOT IN (
	SELECT emp_no FROM dept_manager);


-- 25. 获取员工其当前的薪水比其manager当前薪水还高的相关信息
-- 员工薪水情况
SELECT de.dept_no, de.emp_no, sa.salary
FROM salaries AS sa
JOIN dept_emp AS de ON de.emp_no = sa.emp_no
LEFT JOIN dept_manager AS dm ON dm.emp_no = de.emp_no
WHERE dm.emp_no IS NULL
AND sa.to_date='9999-01-01';
-- manager的薪水情况
SELECT dm.dept_no, dm.emp_no, sa.salary
FROM salaries AS sa
JOIN dept_manager AS dm ON dm.emp_no = sa.emp_no
AND sa.to_date='9999-01-01';
-- 两表比较 74ms
-- 通过部门编号dept_no连接员工薪水表es和管理员薪水表ms
SELECT es.emp_no, ms.emp_no AS manager_no, 
	es.salary AS emp_salary, ms.salary AS manager_salary
FROM (
	SELECT de.dept_no, de.emp_no, sa.salary
	FROM salaries AS sa
	JOIN dept_emp AS de ON de.emp_no = sa.emp_no
	LEFT JOIN dept_manager AS dm ON dm.emp_no = de.emp_no
	WHERE dm.emp_no IS NULL
	AND sa.to_date='9999-01-01') AS es
INNER JOIN(
	SELECT dm.dept_no, dm.emp_no, sa.salary
	FROM salaries AS sa
	JOIN dept_manager AS dm ON dm.emp_no = sa.emp_no
	AND sa.to_date='9999-01-01'	) AS ms
ON es.dept_no=ms.dept_no
WHERE es.salary>ms.salary;


-- 26. 汇总各个部门当前员工的title类型的分配数目，结果给出部门编号dept_no、dept_name、其当前员工所有的title以及该类型title对应的数目count
-- 发现每个员工可能有多个title, 部门->员工 1对多 员工->title职称 1对多
SELECT * FROM titles INNER JOIN dept_emp ON titles.emp_no=dept_emp.emp_no;
-- 打算使用三重嵌套,部门(员工(职称))
SELECT de.dept_no, ds.dept_name, de.emp_no, (
	SELECT title FROM titles WHERE emp_no=de.emp_no AND to_date='9999-01-01'
) AS title
FROM dept_emp AS de 
LEFT JOIN departments AS ds 
ON de.dept_no=ds.dept_no AND de.to_date='9999-01-01'
WHERE de.emp_no IN (
	SELECT de2.emp_no
	FROM dept_emp AS de2
	WHERE de2.dept_no=de.dept_no AND de2.to_date='9999-01-01') 
ORDER BY de.dept_no;
-- 尝试使用两个group by分组
-- 先三表连接 看看情况
SELECT ds.*, de.dept_no, de.emp_no, t.emp_no, t.title 
FROM departments AS ds, dept_emp AS de, titles AS t
WHERE de.to_date='9999-01-01' AND t.to_date='9999-01-01'
AND ds.dept_no=de.dept_no AND de.emp_no=t.emp_no;
-- 然后通过dept_no部门编号和title职称分组 	--------2.490s
SELECT de.dept_no,ds.dept_name, t.title, COUNT(t.emp_no) AS `count`
FROM departments AS ds, dept_emp AS de, titles AS t
WHERE de.to_date='9999-01-01' AND t.to_date='9999-01-01'
AND ds.dept_no=de.dept_no AND de.emp_no=t.emp_no
GROUP BY de.dept_no, t.title;

-- 对于多分组的理解
-- 将需要分组的字段都进行排序可能会容易理解一些
SELECT de.dept_no, t.title, de.emp_no
FROM dept_emp AS de 
JOIN titles AS t 
ON de.emp_no=t.emp_no
ORDER BY de.dept_no, t.title;


-- 27. 给出每个员工每年薪水涨幅超过5000的员工编号emp_no、薪水变更开始日期from_date以及薪水涨幅值salary_growth，并按照salary_growth逆序排列。
-- 查看员工薪水详情
SELECT * FROM salaries ORDER BY emp_no, from_date;
-- 这边有个疑问: 薪水变更开始日期是指入职hire_date 还是连续加薪超过5000的某一时间节点
-- 以每年薪水变化数为涨幅 上一年的from_date=这一年to_date
SELECT s1.emp_no, s1.salary AS second_year_salary, 
	s2.salary AS first_year_salary, s1.from_date, s2.from_date
FROM salaries AS s1
INNER JOIN salaries AS s2
ON s1.emp_no=s2.emp_no AND s1.from_date=s2.to_date;
-- 第二年的薪水 - 第一年的薪水 ×  这是上一次薪水 - 这一次薪水...√
SELECT s1.emp_no, s1.salary AS second_year_salary, 
	s2.salary AS first_year_salary, s1.from_date, s2.from_date, 
	(s1.salary-s2.salary) AS salary_growth
FROM salaries AS s1
INNER JOIN salaries AS s2
ON s1.emp_no=s2.emp_no AND s1.from_date=s2.to_date;
-- 方法不太对 时间定位的有问题

-- 获取datetime时间对应的年份函数 SQLite ---> MySQL
-- strftime('%Y', to_date) ---> YEAR
SELECT emp_no, YEAR(from_date), MONTH(from_date), DAY(from_date), from_date
FROM salaries;

-- 拿到相隔一年的薪水差值 但无法直接使用salary_growth作为where的判断条件 是聚类问题
SELECT s1.emp_no, s1.from_date, (s1.salary-s2.salary) AS salary_growth
FROM salaries AS s1, salaries AS s2
WHERE s1.emp_no=s2.emp_no
	AND (YEAR(s1.from_date) - YEAR(s2.from_date) = 1)
	OR (YEAR(s1.to_date) - YEAR(s2.to_date) = 1);
-- 可以直接将薪水差值表作为临时表 过滤抽取数据
SELECT sg.emp_no, sg.from_date, sg.salary_growth
FROM (
	SELECT s1.emp_no, s1.from_date, (s1.salary-s2.salary) AS salary_growth
	FROM salaries AS s1, salaries AS s2
	WHERE s1.emp_no=s2.emp_no
		AND (YEAR(s1.from_date) - YEAR(s2.from_date) = 1)
		OR (YEAR(s1.to_date) - YEAR(s2.to_date) = 1)) AS sg
WHERE sg.salary_growth > 5000
ORDER BY sg.salary_growth DESC;
-- 也可以直接将表达式放入where判断中
SELECT s1.*, s2.*, (s1.salary-s2.salary) AS salary_growth
FROM salaries AS s1, salaries AS s2
WHERE s1.emp_no=s2.emp_no
	AND (s1.salary-s2.salary) > 5000
	AND ((YEAR(s1.from_date) - YEAR(s2.from_date) = 1)
	OR (YEAR(s1.to_date) - YEAR(s2.to_date) = 1));



-- 更换sakila数据库
USE sakila;
-- 28. 查找描述信息中包括robot的电影对应的分类名称以及电影数目，而且还需要该分类对应电影数量>=5部
-- 三个表 film电影信息 category分类信息 film_category电影分类信息
SELECT * FROM film;
DESC film;
-- 文本处理? 查找文本字段包含的'robot'字符
SELECT * FROM film WHERE description LIKE '%robot%';
-- 包含'robot'描述信息的电影对应的分类名称 --> 计数
SELECT ri.film_id, fc.category_id, c.name, (
	SELECT COUNT(*) AS film_num FROM film_category AS fc2 
	WHERE fc2.category_id=fc.category_id
	) AS film_num
FROM (
	SELECT film_id 	FROM film 
	WHERE description LIKE '%robot%') AS ri 
LEFT JOIN film_category AS fc ON ri.film_id=fc.film_id
INNER JOIN category AS c ON fc.category_id=c.category_id;
-- 思路好像错了
SELECT c.*, fc.*, f.*
FROM film AS f, film_category AS fc, category AS c
WHERE f.film_id=fc.film_id
	AND fc.category_id=c.category_id
	AND f.description LIKE '%robot%';
-- 先找出描述信息包含'robot'的电影分类 **加计数!!!**
SELECT fc.category_id, COUNT(fc.category_id) AS c_num
FROM film AS f, film_category AS fc 
WHERE f.film_id=fc.film_id AND f.description LIKE '%robot%'
GROUP BY fc.category_id;
-- 再找出分类电影数目超过5部的电影分类
SELECT c.category_id, COUNT(fc.film_id) AS category_num
FROM film_category AS fc, category AS c
WHERE fc.category_id=c.category_id
GROUP BY c.category_id
HAVING category_num > 5;
-- 两表连接 使用INNER JOIN 选出共有的电影分类 以及包含'robot'的电影数量
SELECT ri.category_id, cn.name, ri.c_num
FROM (
	SELECT DISTINCT  fc.category_id, COUNT(fc.category_id) AS c_num
	FROM film AS f, film_category AS fc 
	WHERE f.film_id=fc.film_id AND f.description LIKE '%robot%'
	GROUP BY fc.category_id) AS ri
INNER JOIN (
	SELECT c.category_id, c.name, COUNT(fc.film_id) AS category_num
	FROM film_category AS fc, category AS c
	WHERE fc.category_id=c.category_id
	GROUP BY c.category_id
	HAVING category_num >= 5) AS cn 
ON ri.category_id=cn.category_id;
-- 讨论区的一份相近的解答, 用于更清晰的理解题意...
-- 正是通过这才发现需要输出的是:包含'robot'的电影数量
SELECT cn.name, ri.`count`
FROM (
	SELECT fc.category_id, COUNT(fc.category_id) AS `count`
	FROM film AS f 
	INNER JOIN film_category AS fc
    ON f.film_id = fc.film_id
    WHERE f.description LIKE '%robot%'
	GROUP BY fc.category_id	) AS ri
INNER JOIN (
    SELECT c.name, fc.category_id, COUNT(fc.category_id) AS c_num
    FROM film_category AS fc
    INNER JOIN category AS c
    ON c.category_id=fc.category_id
    GROUP BY fc.category_id
    HAVING c_num >= 5) AS cn
ON cn.category_id = ri.category_id;


-- 29. 使用join查询方式找出没有分类的电影id以及名称
-- 没有分类,就说明film_category电影分类表中没有出现
-- film表有 而film_category表没有
SELECT f.film_id, f.title
FROM film AS f
LEFT JOIN film_category AS fc 
ON f.film_id=fc.film_id
WHERE fc.film_id IS NULL;


-- 30. 使用子查询的方式找出属于Action分类的所有电影对应的title,description
-- 先通过category,film_category两表连接, 找出'Action'分类对应的film_id
SELECT fc.film_id
FROM film_category AS fc 
INNER JOIN category AS c 
ON fc.category_id=c.category_id AND c.name='Action';
-- 通过上一查询得出的结果film_id 使用film表得到电影的title和description
SELECT title, description
FROM film
WHERE film_id IN (
	SELECT fc.film_id
	FROM film_category AS fc 
	INNER JOIN category AS c 
	ON fc.category_id=c.category_id AND c.name='Action');

-- 如果全程只使用子查询
SELECT title, description 
FROM film 
WHERE film_id IN (
	SELECT film_id 
	FROM film_category 
	WHERE category_id IN (
		SELECT category_id 
		FROM category 
		WHERE name='Action'
	)
);


USE employees;
-- 31. 获取select * from employees对应的执行计划
-- 执行计划 EXPLAIN
EXPLAIN SELECT * FROM employees;


-- 32. 将employees表的所有员工的last_name和first_name拼接起来作为Name，中间以一个空格区分
-- 字段内容拼接
-- 取巧 直接手动加空格作为分隔符 
SELECT CONCAT(last_name, ' ' ,first_name) AS Name 
FROM employees;
-- 使用CONCAT_WS()函数  
SELECT CONCAT_WS(' ', last_name, first_name) AS Name
FROM employees;


USE sakila;
-- 33. 创建一个actor表，包含如下列信息
-- |列表		|类型			|是否为NULL		|含义 |
-- |-- 		| -- 			| -- 		| -- |
-- |actor_id	|smallint(5)	|not null	|主键id |
-- |first_name	|varchar(45)	|not null	|名字|
-- |last_name	|varchar(45)	|not null	|姓氏|
-- |last_update|timestamp		|not null	|最后更新时间，默认是系统的当前时间|

-- sakila示例数据库已有actor表
CREATE TABLE myactor (
	actor_id SMALLINT(5) NOT NULL,
	first_name VARCHAR(45) NOT NULL,
	last_name VARCHAR(45) NOT NULL,
	last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY(actor_id)	
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE myactor;

-- 获取当前时间(日期+时间)
SELECT CURRENT_TIMESTAMP();
-- 日期
SELECT CURDATE();


-- 34. 对于表actor批量插入如下数据
-- actor_id|first_name|last_name|last_update
-- 1|PENELOPE|GUINESS|2006-02-15 12:34:33
-- 2|NICK|WAHLBERG|2006-02-15 12:34:33
-- dbeaver 有以下输出 时间显示问题
--   1|PENELOPE  |GUINESS  |2006-02-16 02:34:33|
--   2|NICK      |WAHLBERG |2006-02-16 02:34:33|

-- 使用insert into语法
INSERT INTO myactor
(actor_id, first_name, last_name, last_update)
VALUES(1,'PENELOPE', 'GUINESS', '2006-02-15 12:34:33'),
(2,'NICK', 'WAHLBERG', '2006-02-15 12:34:33');
-- 使用union select形式
INSERT INTO myactor
SELECT 3,'PENELOPE', 'GUINESS', '2006-02-15 12:34:33'
UNION SELECT 4,'NICK', 'WAHLBERG', '2006-02-15 12:34:33';
-- 查看表内数据
SELECT * FROM myactor;
DELETE FROM myactor WHERE actor_id=3;
-- DBeaver 客户端中时间显示问题解决:https://www.cnblogs.com/peng18/p/9260690.html


-- 35. 对于表actor批量插入如下数据,如果数据已经存在，请忽略，不使用replace操作
-- actor_id	|	first_name	|	last_name	|	last_update
-- '3'		|	'ED'		|	'CHASE'		|	'2006-02-15 12:34:33'

-- 表内没有该数据就插入，有就忽略的效果 不使用replace
INSERT IGNORE INTO myactor
VALUES(3,'ED', 'CHASE', '2006-02-15 12:34:33');

-- 使用replace函数
REPLACE INTO myactor(actor_id, first_name, last_name, last_update)
VALUES(3,'ED', 'CHASE', '2006-02-15 12:34:33');


-- 36. 创建一个actor_name表，将actor表中的所有first_name以及last_name导入改表。 
-- actor_name表结构如下：
-- 列表	|	类型	|	是否为NULL	|	含义
-- first_name|	varchar(45)|	not null|	名字
-- last_name |	varchar(45)|	not null|	姓氏

-- 建表之后将已知表表示导入
CREATE TABLE actor_name (
	first_name varchar(45) NOT NULL,
	last_name varchar(45) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- 可以从现存表直接导入数据
INSERT INTO actor_name SELECT first_name, last_name FROM myactor;

-- 从一个表的基础上创建另一个表
CREATE TABLE actor_name AS SELECT first_name, last_name FROM myactor;
DESC actor_name;
SELECT * FROM actor_name;


-- 37. 针对actor表，对first_name创建唯一索引uniq_idx_firstname，对last_name创建普通索引idx_lastname
-- 对first_name创建唯一索引uniq_idx_firstnam
CREATE UNIQUE INDEX uniq_idx_firstname ON myactor(first_name);
-- 对last_name创建普通索引idx_lastname
CREATE INDEX idx_lastname ON myactor(last_name);

DESC myactor;
SHOW INDEX FROM myactor;


-- 38. 针对actor表创建视图actor_name_view，只包含first_name以及last_name两列，并对这两列重新命名，first_name为first_name_v，last_name修改为last_name_v
-- 创建视图view actor_name_view
CREATE VIEW actor_name_view(first_name_v, last_name_v) 
	AS SELECT first_name, last_name FROM actor;

-- 第二种建视图方式
CREATE VIEW actor_name_view AS
SELECT first_name AS fist_name_v, last_name AS last_name_v
FROM actor 

-- 查看所创建的视图actor_name_view
DESC actor_name_view;
SELECT * FROM actor_name_view;
DROP VIEW actor_name_view;


USE employees;
-- 39. 针对salaries表emp_no字段创建索引idx_emp_no，查询emp_no为10005, 使用强制索引
-- 首先为emp_no字段建立索引
CREATE INDEX idx_emp_no ON salaries(emp_no);
-- 查看表格式
DESC salaries;
SHOW INDEX FROM salaries;
-- 删除索引
DROP INDEX idx_emp_no ON salaries;

-- 查询数据时，强制使用索引
EXPLAIN SELECT * FROM salaries FORCE INDEX(idx_emp_no) WHERE emp_no=10005;
SELECT * FROM salaries WHERE emp_no=10005; -- 4ms (+5ms)
SELECT * FROM salaries FORCE INDEX(idx_emp_no) WHERE emp_no=10005; -- 2ms (+1ms)


USE sakila;
-- 40. 针对actor表，在last_update后面新增加一列名字为create_date, 类型为datetime, NOT NULL，默认值为'0000 00:00:00'
-- 修改表结构
ALTER TABLE myactor 
	ADD create_date DATETIME DEFAULT '1970-01-01 00:00:01' NOT NULL;
-- 查看表结构
DESC myactor;
-- 不能使用'0000-00-00 00:00:00'作为默认值
-- 这是因为`sql_model`有`NO_ZERO_DATE`的选项，在该模式下'0000-00-00 00:00:00'是个无效值