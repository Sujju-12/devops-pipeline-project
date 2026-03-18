package com.devops.employeeapi;

import com.devops.employeeapi.model.Employee;
import com.devops.employeeapi.repository.EmployeeRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataLoader {

    @Bean
    CommandLineRunner loadData(EmployeeRepository repo) {
        return args -> {
            repo.save(new Employee("Alice Kumar",  "alice@devops.com",  "Engineering", 95000.0));
            repo.save(new Employee("Bob Sharma",   "bob@devops.com",    "DevOps",       88000.0));
            repo.save(new Employee("Carol Reddy",  "carol@devops.com",  "QA",           75000.0));
            repo.save(new Employee("David Nair",   "david@devops.com",  "Engineering",  92000.0));
            repo.save(new Employee("Eva Patel",    "eva@devops.com",    "DevOps",       85000.0));
            System.out.println("✅ Sample data loaded successfully");
        };
    }
}
