-- 以下仅为个人在练习时的一些草稿和想法
USE employees;


-- 1、查找最晚入职员工的所有信息 -- 
SELECT * FROM employees;
-- 先进行逆序排序，然后只输出第一个
SELECT * FROM employees ORDER BY hire_date DESC LIMIT 1;
-- 最晚入职员工可能不只一个，先选出最晚入职时间，再对应到编号，由编号识别出最晚入职员工
SELECT MAX(hire_date) FROM employees;
SELECT * FROM employees WHERE hire_date = (SELECT MAX(hire_date) FROM employees);


-- 2、查找入职员工时间排名倒数第三的员工所有信息
-- 入职时间hire_date 排名倒数ORDER BY ? DESC 第三LIMIT 2,1
SELECT * FROM employees ORDER BY hire_date DESC LIMIT 2,1;
-- 题目的关键信息是入职时间排名 排名的是入职时间
-- 先给入职时间排名(去重)，再从排名时间选出第三个，最后由时间对应员工输出员工信息
SELECT DISTINCT hire_date FROM employees ORDER BY hire_date DESC;
SELECT DISTINCT hire_date FROM employees ORDER BY hire_date DESC LIMIT 2,1;
SELECT * FROM employees 
WHERE hire_date = (
	SELECT DISTINCT hire_date 
	FROM employees ORDER BY hire_date DESC LIMIT 2,1);


-- 3、查找各个部门当前(to_date='9999-01-01')领导当前薪水详情以及其对应部门编号dept_no
SELECT * FROM dept_manager;
SELECT * FROM salaries;
-- 按条件查询，三个条件：两表员工编号相同，部门管理表to_date=当前，薪水表to_date=当前
SELECT * FROM dept_manager WHERE to_date = "9999-01-01";
SELECT dm.dept_no, s.* 
FROM dept_manager dm, salaries s 
WHERE s.emp_no = dm.emp_no AND dm.to_date = "9999-01-01" AND s.to_date = "9999-01-01";
-- 根据题目输出格式，需要换个位置
SELECT s.*, dm.dept_no 
FROM salaries s, dept_manager dm 
WHERE s.emp_no = dm.emp_no AND s.to_date = '9999-01-01' AND dm.to_date = '9999-01-01';

-- 4. 查找所有已经分配部门的员工的last_name和first_name
SELECT * FROM dept_emp;
SELECT * FROM employees;
-- last_name first_name dept_no
-- 按条件查询 部门员工编号=员工编号
SELECT e.last_name, e.first_name, de.dept_no FROM employees e, dept_emp de WHERE e.emp_no = de.emp_no;


-- 5. 查找所有员工的last_name和first_name以及对应部门编号dept_no，也包括展示没有分配具体部门的员工
-- last_name first_name dept_no
-- 员工表的emp_no关联dept_emp的emp_no 与上一题相反
SELECT e.last_name, e.first_name, de.dept_no 
FROM employees e LEFT JOIN dept_emp de 
ON e.emp_no = de.emp_no;


-- 6. 查找所有员工入职时候的薪水情况，给出emp_no以及salary， 并按照emp_no进行逆序
-- emp_no salary (employees, salaries)
-- 按条件查询 两个条件: 员工表职员编号=薪水表职员编号, 员工表hire_date=薪水表from_date
SELECT e.emp_no, s.salary 
FROM employees e, salaries s 
WHERE s.emp_no = e.emp_no AND s.from_date = e.hire_date 
ORDER BY e.emp_no DESC;
-- 另一种解法: 通过在薪水表找出同一职员的最小from_date, 最早的必定是入职时间, 而对应的薪水就是入职薪水
SELECT emp_no, salary FROM salaries GROUP BY emp_no HAVING MIN(from_date) ORDER BY emp_no DESC;
-- 需要修改sql_mode(这样并不好) 可以通过添加临时表来解决问题
SELECT sf.emp_no, s.salary 
FROM salaries AS s 
INNER JOIN (
	SELECT emp_no, MIN(from_date) AS hire_date FROM salaries GROUP BY emp_no) AS sf
ON s.emp_no=sf.emp_no AND s.from_date=sf.hire_date
ORDER By sf.emp_no DESC;


-- 7. 查找薪水涨幅超过15次的员工号emp_no以及其对应的涨幅次数t
-- 计数使用count 通过group by对每个员工编号分组 通过having进行条件筛选
SELECT emp_no, COUNT(emp_no) AS t FROM salaries GROUP BY emp_no HAVING t > 15;


-- 8. 找出所有员工当前(to_date='9999-01-01')具体的薪水salary情况，对于相同的薪水只显示一次,并按照逆序显示
-- 当前to_date 相同薪水只显示一次-去重distinct 逆序ORDER BY DESC
SELECT DISTINCT(salary) FROM salaries WHERE to_date="9999-01-01" ORDER BY salary DESC;
-- 大表一般用distinct效率不高，大数据量的时候都禁止用distinct，可以用group by解决重复问题
SELECT salary FROM salaries WHERE to_date="9999-01-01" GROUP BY salary ORDER BY salary DESC;


-- 9. 获取所有部门当前manager的当前薪水情况，给出dept_no, emp_no以及salary，当前表示to_date='9999-01-01'
-- dept_manager表获得manager的emp_no和dept_no, salaries表获得emp_no对应的薪水
SELECT d.dept_no, d.emp_no, s.salary FROM dept_manager AS d , salaries AS s WHERE s.emp_no = d.emp_no AND s.to_date="9999-01-01" AND d.to_date="9999-01-01";
SELECT d.dept_no, d.emp_no, s.salary FROM dept_manager AS d INNER JOIN salaries AS s ON s.emp_no = d.emp_no AND s.to_date="9999-01-01" AND d.to_date="9999-01-01";


-- 10. 获取所有非manager的员工emp_no
SELECT emp_no FROM dept_manager;
-- 从manager表中选出所有manager员工emp_no, 再从员工表反选
SELECT emp_no FROM employees WHERE emp_no NOT IN (SELECT emp_no FROM dept_manager);
-- 使用连接,选出交集为NULL的值即为不在manager表的emp_no
SELECT e.emp_no, d.dept_no FROM employees AS e LEFT JOIN dept_manager AS d ON e.emp_no=d.emp_no ORDER BY d.dept_no DESC;
SELECT t.emp_no FROM (SELECT e.emp_no, d.dept_no FROM employees AS e LEFT JOIN dept_manager AS d ON e.emp_no=d.emp_no) AS t WHERE t.dept_no IS NULL;
-- 可以直接使用单层SELECT查询
SELECT e.emp_no FROM employees AS e LEFT JOIN dept_manager AS d ON e.emp_no=d.emp_no WHERE d.dept_no IS NULL;


-- 11. 获取所有员工当前的manager，如果当前的manager是自己的话结果不显示，当前表示to_date='9999-01-01'。
-- dept_emp部门员工表找到员工emp_no对应的部门dept_no, dept_manager部门管理表再找到管理者emp_no
SELECT de.emp_no, dm.emp_no AS manager_no FROM dept_emp AS de, dept_manager AS dm WHERE de.emp_no!=dm.emp_no AND dm.dept_no=de.dept_no AND de.to_date="9999-01-01" AND dm.to_date="9999-01-01";
SELECT de.emp_no, dm.emp_no AS manager_no FROM dept_emp AS de INNER JOIN dept_manager AS dm ON dm.dept_no=de.dept_no WHERE de.emp_no!=dm.emp_no AND de.to_date="9999-01-01" AND dm.to_date="9999-01-01";


-- 12. 获取所有部门中当前员工薪水最高的相关信息，给出dept_no, emp_no以及其对应的salary
SELECT MAX(salary) FROM salaries;
-- 先选出薪水最高的数值, 通过最高薪水定位员工, 再通过薪水表的员工emp_no定位dept_emp部门表的dept_no
SELECT de.dept_no, s.emp_no, s.salary FROM dept_emp AS de, salaries AS s WHERE s.salary = (SELECT MAX(salary) FROM salaries) AND de.emp_no=s.emp_no;
-- 部门薪水最高...
-- 通过to_date缩减需要选取的数据 
-- 当前salaries表的emp_no和salary 
SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01';
-- 当前dept_emp表的dept_no和emp_no
SELECT dept_no, emp_no FROM dept_emp WHERE to_date='9999-01-01';
-- 通过部门编号分组, 当前各部门的最高薪水salary和部门编号dept_no
SELECT dm.dept_no, MAX(se.salary) salary
FROM (
	(
		SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01'
	) AS se
	LEFT JOIN
	(
		SELECT dept_no, emp_no FROM dept_emp WHERE to_date='9999-01-01'
	) AS dm
	ON se.emp_no=dm.emp_no)
GROUP BY dm.dept_no;
-- 无需分组, 将部门/员工/薪水合并到一个表内
SELECT dm.dept_no, dm.emp_no, se.salary
FROM (
	(
		SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01'
	) AS se
	LEFT JOIN
	(
		SELECT dept_no, emp_no FROM dept_emp WHERE to_date='9999-01-01'
	) AS dm
	ON se.emp_no=dm.emp_no);
-- 通过`部门/最高薪水`的条件 去筛选/定位 `员工编号`
SELECT re1.dept_no, re2.emp_no, re1.salary
FROM (
	SELECT dm.dept_no, MAX(se.salary) salary
	FROM (
		(
			SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01'
		) AS se
		LEFT JOIN
		(
			SELECT dept_no, emp_no FROM dept_emp WHERE to_date='9999-01-01'
		) AS dm
		ON se.emp_no=dm.emp_no)
	GROUP BY dm.dept_no
) AS re1 JOIN (
	SELECT dm.dept_no, dm.emp_no, se.salary
	FROM (
		(
			SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01'
		) AS se
		LEFT JOIN
		(
			SELECT dept_no, emp_no FROM dept_emp WHERE to_date='9999-01-01'
		) AS dm
		ON se.emp_no=dm.emp_no)
) AS re2
ON re2.dept_no=re1.dept_no AND re2.salary=re1.salary
ORDER BY re1.dept_no;

SELECT de.dept_no,sa.emp_no,re.sal AS salary
FROM (
    -- 通过分组,拿到各部门编号以及对应的最高薪水
    SELECT d.dept_no, MAX(s.salary) AS sal
    FROM dept_emp AS d JOIN salaries AS s
    ON d.emp_no=s.emp_no AND d.to_date='9999-01-01' AND s.to_date='9999-01-01'
    GROUP BY d.dept_no
) AS re, dept_emp AS de, salaries AS sa
-- 三表查询 re的最高薪水 部门员工表的部门编号 薪水表的员工编号
WHERE re.dept_no=de.dept_no AND de.emp_no=sa.emp_no AND re.sal=sa.salary;


-- 13. 从titles表获取按照title进行分组，每组个数大于等于2，给出title以及对应的数目t
SELECT title, COUNT(title) AS t FROM titles GROUP BY title HAVING t >= 2;


-- 14. 从titles表获取按照title进行分组，每组个数大于等于2，给出title以及对应的数目t。 注意对于重复的emp_no进行忽略
SELECT title, COUNT(DISTINCT emp_no) AS t FROM titles GROUP BY title HAVING t >= 2;


-- 15. 查找employees表所有emp_no为奇数，且last_name不为Mary的员工信息，并按照hire_date逆序排列
SELECT * FROM employees WHERE emp_no%2=1 AND last_name!='Mary' ORDER BY hire_date DESC;
SELECT * FROM employees WHERE emp_no=(emp_no>>1)<<1 AND last_name!='Mary' ORDER BY hire_date DESC;


-- 16. 统计出当前各个title类型对应的员工当前薪水对应的平均工资。结果给出title以及平均工资avg。
SELECT t.title, AVG(s.salary) AS `avg` FROM titles AS t INNER JOIN salaries AS s ON s.emp_no=t.emp_no AND s.to_date='9999-01-01' AND t.to_date='9999-01-01' GROUP BY title;


-- 17. 获取当前（to_date='9999-01-01'）薪水第二多的员工的emp_no以及其对应的薪水salary
SELECT emp_no, salary FROM salaries WHERE to_date='9999-01-01' ORDER BY salary DESC LIMIT 1,1;
-- 以上方法是有缺陷的,题意是指薪水第二多,而同一薪水可能有多名员工
-- 先求出当前第二多薪水数额
SELECT DISTINCT salary FROM salaries WHERE to_date='9999-01-01' ORDER BY salary DESC LIMIT 1,1;
SELECT salary FROM salaries WHERE to_date='9999-01-01' GROUP BY salary ORDER BY salary DESC LIMIT 1,1;
-- 再通过当前时间和薪水数额定位员工编号
SELECT emp_no, salary FROM salaries WHERE salary = (
	SELECT DISTINCT salary FROM salaries WHERE to_date='9999-01-01' ORDER BY salary DESC LIMIT 1,1
) AND to_date='9999-01-01';


-- 18. 查找当前薪水(to_date='9999-01-01')排名第二多的员工编号emp_no、薪水salary、last_name以及first_name，不准使用ORDER BY
SELECT s.emp_no, s.salary, e.last_name, e.first_name FROM salaries AS s INNER JOIN employees AS e ON s.emp_no=e.emp_no WHERE s.to_date='9999-01-01';
-- 先找出当前最多薪水数额
SELECT MAX(salary) FROM salaries WHERE to_date='9999-01-01';
-- 使用排除法,在去掉最大值的序列中,此时最大值就原序列的第二大值
SELECT MAX(salary) FROM salaries 
WHERE to_date='9999-01-01' AND salary NOT IN (
	SELECT MAX(salary)  FROM salaries WHERE to_date='9999-01-01'
);
-- 使用以上求取得到的第二大值
SELECT s.emp_no, s.salary, e.last_name, e.first_name 
FROM salaries AS s INNER JOIN employees AS e ON s.emp_no=e.emp_no 
WHERE s.to_date='9999-01-01'
AND s.salary = (
	SELECT MAX(salary) FROM salaries 
	WHERE to_date='9999-01-01' AND salary NOT IN (
		SELECT MAX(salary)  FROM salaries WHERE to_date='9999-01-01'
	)
);


-- 19. 查找所有员工的last_name和first_name以及对应的dept_name，也包括暂时没有分配部门的员工
SELECT e.last_name, e.first_name, d.dept_name FROM employees AS e,dept_emp AS de, departments AS d WHERE d.dept_no=de.dept_no AND de.emp_no=e.emp_no;
-- 先将员工表employees和部门员工表dept_emp连接 合成部门员工详细表ds
SELECT e.emp_no, de.dept_no FROM employees AS e LEFT JOIN dept_emp AS de ON e.emp_no=de.emp_no;
-- 再将部门信息表department和部门员工详细表ds连接
SELECT ds.last_name, ds.first_name, d.dept_name FROM (
	SELECT e.last_name, e.first_name, de.dept_no FROM employees AS e LEFT JOIN dept_emp AS de ON e.emp_no=de.emp_no
) AS ds LEFT JOIN departments AS d ON d.dept_no=ds.dept_no;

-- 第一次 LEFT JOIN 是把未分配部门的员工算进去了，但是只得到了部门号，没有部门名，
-- 所以第二次也要 LEFT JOIN 把含有部门名 departments 连接起来，
-- 否则在第二次连接时就选不上未分配部门的员工了
SELECT e.last_name, e.first_name, d.dept_name
FROM employees AS e 
LEFT JOIN dept_emp AS de ON e.emp_no = de.emp_no
LEFT JOIN departments AS d ON de.dept_no = d.dept_no;


-- 20. 查找员工编号emp_no为10001其自入职以来的薪水salary涨幅值growth
SELECT * FROM salaries WHERE emp_no='10001';
SELECT MAX(salary) MAX_salary , MIN(salary) MIN_salary FROM salaries WHERE emp_no='10001';
SELECT (MAX(salary)-MIN(salary)) AS growth FROM salaries WHERE emp_no='10001';
-- 入职薪水
SELECT salary FROM salaries WHERE emp_no='10001' ORDER BY to_date LIMIT 0,1;
-- 当前薪水
SELECT salary FROM salaries WHERE emp_no='10001' ORDER BY to_date DESC LIMIT 0,1;
-- 薪水salary涨幅值growth 当前薪水-入职薪水
SELECT (ma.salary-mi.salary) AS growth
FROM (
	SELECT salary FROM salaries WHERE emp_no='10001' ORDER BY to_date LIMIT 0,1
) AS mi, (
	SELECT salary FROM salaries WHERE emp_no='10001' ORDER BY to_date DESC LIMIT 0,1
) AS ma;
