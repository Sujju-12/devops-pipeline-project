package com.devops.employeeapi.service;

import com.devops.employeeapi.model.Employee;
import com.devops.employeeapi.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class EmployeeService {

    @Autowired
    private EmployeeRepository employeeRepository;

    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }

    public Optional<Employee> getEmployeeById(Long id) {
        return employeeRepository.findById(id);
    }

    public Employee createEmployee(Employee employee) {
        return employeeRepository.save(employee);
    }

    public Employee updateEmployee(Long id, Employee updatedEmployee) {
        return employeeRepository.findById(id).map(emp -> {
            emp.setName(updatedEmployee.getName());
            emp.setEmail(updatedEmployee.getEmail());
            emp.setDepartment(updatedEmployee.getDepartment());
            emp.setSalary(updatedEmployee.getSalary());
            return employeeRepository.save(emp);
        }).orElseThrow(() -> new RuntimeException("Employee not found with id: " + id));
    }

    public void deleteEmployee(Long id) {
        employeeRepository.deleteById(id);
    }

    public List<Employee> getEmployeesByDepartment(String department) {
        return employeeRepository.findByDepartment(department);
    }
}
