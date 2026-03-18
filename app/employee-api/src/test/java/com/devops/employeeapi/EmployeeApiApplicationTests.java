package com.devops.employeeapi;

import com.devops.employeeapi.model.Employee;
import com.devops.employeeapi.repository.EmployeeRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class EmployeeApiApplicationTests {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Test
    void contextLoads() {}

    @Test
    void testSaveAndRetrieveEmployee() {
        Employee emp = new Employee("Test User", "test@devops.com", "DevOps", 70000.0);
        Employee saved = employeeRepository.save(emp);
        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getName()).isEqualTo("Test User");
    }

    @Test
    void testFindByDepartment() {
        employeeRepository.save(new Employee("Jane", "jane@devops.com", "Engineering", 80000.0));
        var result = employeeRepository.findByDepartment("Engineering");
        assertThat(result).isNotEmpty();
    }
}
