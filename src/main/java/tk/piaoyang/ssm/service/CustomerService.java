package tk.piaoyang.ssm.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tk.piaoyang.ssm.mapper.CustomerMapper;
import tk.piaoyang.ssm.pojo.Customer;
import tk.piaoyang.ssm.pojo.CustomerExample;

import java.util.List;

@Service
public class CustomerService {
    @Autowired
    CustomerMapper customerMapper;

    public List<Customer> queryCustomerByQueryVo(CustomerExample customerExample) {
        return customerMapper.selectByExample(customerExample);
    }

    public int countByExample(CustomerExample customerExample) {
        return customerMapper.countByExample(customerExample);
    }

    public Customer selectByPrimaryKey(Integer id) {
        return customerMapper.selectByPrimaryKey((long) id);
    }

    public void updateByPrimaryKeySelective(Customer customer) {
        customerMapper.updateByPrimaryKeySelective(customer);
    }

    public void deleteByPrimaryKey(Integer id) {
        customerMapper.deleteByPrimaryKey((long) id);
    }

}
