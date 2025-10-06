import { render, screen } from '@testing-library/react';
import App from './App';

test('renders billing dashboard', () => {
  render(<App />);
  const headingElement = screen.getByText(/billing dashboard/i);
  expect(headingElement).toBeInTheDocument();
});
